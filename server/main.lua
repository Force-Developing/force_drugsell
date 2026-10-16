local RESOURCE = GetCurrentResourceName()
-- Extra meters on top of a radius (the player's position on the server lags a little behind)
local DISTANCE_MARGIN = 3.0
-- A timed stop may be reported this much before its duration is up (network and frame timing)
local FINISH_EARLY_MS = 1500
-- Minimum time between two finished stops
local STOP_INTERVAL_MS = 2000
-- Minimum time between two spawns of the same sale vehicle (a destroyed vehicle can be replaced)
local RESPAWN_INTERVAL_MS = 10000
-- How long the server waits for a spawned vehicle to exist
local SPAWN_TIMEOUT_MS = 3000

local sales = {}  -- [source] = { id, identifier, startedAt, deadline, done = { [index] = true }, begun, lastStop,
                  --              vehicles = { [name] = entity }, spawnedAt = { [name] = ms } }
local takenBy = {} -- [sale id] = source running it (Config.OneAtATime)
local policeJobs = {}

local function prepareConfig()
  local police = type(Config.Police) == "table" and Config.Police or {}
  Config.Police = police
  -- Accepts { "police" } and { police = true }
  for key, value in pairs(type(police.jobs) == "table" and police.jobs or {}) do
    if type(value) == "string" then policeJobs[value] = true
    elseif type(key) == "string" and value then policeJobs[key] = true end
  end
  police.minimum = math.max(0, math.floor(tonumber(police.minimum) or 0))
  if police.minimum > 0 and next(policeJobs) == nil then
    Log("error", "Config.Police.minimum is set but Config.Police.jobs is empty: nobody can start a sale")
  end
end

local function maxDurationMs()
  return math.max(5, tonumber(Config.MaxDuration) or 45) * 60000
end

local function playerPed(source)
  local ped = GetPlayerPed(source)
  if not ped or ped == 0 then return nil end
  return ped
end

local function isNear(source, coords, distance)
  local ped = playerPed(source)
  return ped ~= nil and #(GetEntityCoords(ped) - coords) <= distance + DISTANCE_MARGIN
end

local function identifierOf(source)
  local ok, identifier = pcall(GetIdentifier, source)
  if not ok then
    Log("error", ("Reading the player's identifier failed: %s"):format(tostring(identifier)))
    return nil
  end
  return type(identifier) == "string" and identifier ~= "" and identifier or nil
end

-- A new vehicle's health is only known on the server once a client synced it
local HEALTH_GRACE_MS = 30000

--- False when the vehicle is gone or destroyed (it may then be replaced)
local function vehicleAlive(entity, spawnedAt)
  if not entity or entity == 0 or not DoesEntityExist(entity) then return false end
  if spawnedAt and GetGameTimer() - spawnedAt < HEALTH_GRACE_MS then return true end
  return GetEntityHealth(entity) > 0
end

local function deleteVehicle(entity)
  if entity and entity ~= 0 and DoesEntityExist(entity) then DeleteEntity(entity) end
end

--- Ends the player's sale (if any) and removes its vehicles. Every way a sale ends goes through here.
local function endSale(source, why)
  local running = sales[source]
  if not running then return nil end
  sales[source] = nil
  if takenBy[running.id] == source then takenBy[running.id] = nil end
  for _, entity in pairs(running.vehicles) do deleteVehicle(entity) end
  Debug("info", "Sale '%s' of %s ended: %s", running.id, tostring(GetPlayerName(source)), why)
  return running
end

--- Ends a sale that ran past Config.MaxDuration and tells the client. Returns true when it did.
local function expire(source)
  local running = sales[source]
  if not running or GetGameTimer() <= running.deadline then return false end
  endSale(source, "max duration")
  TriggerClientEvent(RESOURCE .. ":client:ended", source, "expired")
  return true
end

--- Police on duty, or nil when the framework bridge failed
local function policeOnline()
  local ok, count = pcall(CountPolice, policeJobs, Config.Police.onlyOnDuty ~= false)
  if not ok or type(count) ~= "number" then
    Log("error", ("Counting the police failed: %s"):format(tostring(count)))
    return nil
  end
  return count
end

--- Spawns a sale vehicle on the server (networked, kept when its driver walks away) and gives keys
--- @return number|nil entity
local function spawnVehicle(source, vehicle)
  local c = vehicle.position
  local ok, entity = pcall(CreateVehicleServerSetter, joaat(vehicle.model), vehicle.type, c.x, c.y, c.z, vehicle.heading)
  if not ok or not entity or entity == 0 then
    Log("error", ("Sale vehicle '%s' (%s) could not be created: %s"):format(vehicle.name, vehicle.model, tostring(entity)))
    return nil
  end
  local deadline = GetGameTimer() + SPAWN_TIMEOUT_MS
  while not DoesEntityExist(entity) and GetGameTimer() < deadline do Wait(50) end
  if not DoesEntityExist(entity) then
    Log("error", ("Sale vehicle '%s' (%s) did not appear"):format(vehicle.name, vehicle.model))
    return nil
  end
  pcall(SetEntityOrphanMode, entity, 2)
  local plate = ("DRUG%04d"):format(math.random(0, 9999))
  SetVehicleNumberPlateText(entity, plate)
  -- ox_fuel reads the fuel level from this state bag
  Entity(entity).state:set("fuel", 100.0, true)
  if Config.GiveKeys ~= false then
    local okKeys, err = pcall(GiveVehicleKeys, source, entity, plate)
    if not okKeys then Log("error", ("Giving vehicle keys failed: %s"):format(tostring(err))) end
  end
  return entity
end

--- The sale vehicle `name` as a net id, spawning it when it doesn't exist (or was destroyed)
--- @return number|nil netId, string|nil reason
local function ensureVehicle(source, running, name)
  local vehicle = GetSale(running.id).vehicles[name]
  local current = running.vehicles[name]
  local last = running.spawnedAt[name]
  if vehicleAlive(current, last) then return NetworkGetNetworkIdFromEntity(current) end
  if last and GetGameTimer() - last < RESPAWN_INTERVAL_MS then return nil, "too_fast" end
  running.spawnedAt[name] = GetGameTimer()
  deleteVehicle(current)
  running.vehicles[name] = nil
  local entity = spawnVehicle(source, vehicle)
  -- the sale may have ended while the vehicle spawned
  if sales[source] ~= running then
    deleteVehicle(entity)
    return nil, "no_sale"
  end
  if not entity then return nil, "vehicle_failed" end
  running.vehicles[name] = entity
  return NetworkGetNetworkIdFromEntity(entity)
end

--- Net ids of the sale vehicles that exist
local function vehicleNetIds(running)
  local out = {}
  for name, entity in pairs(running.vehicles) do
    if DoesEntityExist(entity) then out[name] = NetworkGetNetworkIdFromEntity(entity) end
  end
  return out
end

local function inVehicle(source, running, name)
  local entity = running.vehicles[name]
  local ped = playerPed(source)
  return entity ~= nil and ped ~= nil and DoesEntityExist(entity) and GetVehiclePedIsIn(ped, false) == entity
end

lib.callback.register(RESOURCE .. ":server:start", function(source, id)
  if not IsFrameworkReady() then return false, "not_ready" end
  local sale = GetSale(id)
  if not sale then return false, "unknown_sale" end
  local identifier = identifierOf(source)
  if not identifier then return false, "not_ready" end
  expire(source)
  if sales[source] then return false, "busy" end
  if not isNear(source, sale.dealer.position, GetInteractDistance()) then return false, "too_far" end
  if Config.OneAtATime ~= false and takenBy[sale.id] then return false, "dealer_busy" end
  if Config.Police.minimum > 0 then
    local police = policeOnline()
    if not police then return false, "not_ready" end
    if police < Config.Police.minimum then return false, "not_enough_police" end
  end
  local count = GetItemCount(source, sale.item)
  if not count then return false, "not_ready" end
  if count < sale.amount then return false, "not_enough_drugs" end

  local startedAt = GetGameTimer()
  local running = {
    id = sale.id,
    identifier = identifier,
    startedAt = startedAt,
    deadline = startedAt + maxDurationMs(),
    done = {},
    lastStop = 0,
    vehicles = {},
    spawnedAt = {},
  }
  sales[source] = running
  takenBy[sale.id] = source

  -- vehicles without a spawnDistance wait at the dealer
  for name, vehicle in pairs(sale.vehicles) do
    if not vehicle.spawnDistance then
      local netId, reason = ensureVehicle(source, running, name)
      if not netId then
        endSale(source, "start vehicle failed")
        return false, reason or "vehicle_failed"
      end
    end
  end
  Debug("info", "%s started sale '%s'", tostring(GetPlayerName(source)), sale.id)
  return true, vehicleNetIds(running)
end)

-- The client asks for a vehicle that spawns near its spot (or for a replacement of a destroyed one)
lib.callback.register(RESOURCE .. ":server:vehicle", function(source, name)
  local running = sales[source]
  if not running then return false, "no_sale" end
  if expire(source) then return false, "expired" end
  local vehicle = type(name) == "string" and GetSale(running.id).vehicles[name]
  if not vehicle then return false, "failed" end
  local current = running.vehicles[name]
  if vehicleAlive(current, running.spawnedAt[name]) then return true, NetworkGetNetworkIdFromEntity(current) end
  if not isNear(source, vehicle.position, vehicle.spawnDistance or 50.0) then return false, "too_far" end
  local netId, reason = ensureVehicle(source, running, name)
  if not netId then return false, reason end
  return true, netId
end)

--- Checks shared by begin and complete
--- @return table|nil stop, string|nil reason
local function checkStop(source, running, index)
  local sale = GetSale(running.id)
  index = math.tointeger(tonumber(index))
  local stop = index and sale.stops[index]
  if not stop or running.done[index] then return nil, "failed" end
  if stop.group ~= GetCurrentGroup(sale, running.done) then return nil, "failed" end
  return stop
end

--- Where the player (or, for "return", the vehicle) has to be
--- @return boolean ok, string|nil reason
local function checkPlace(source, running, stop, requireVehicle)
  if not isNear(source, stop.coords, stop.radius) then return false, "too_far" end
  if stop.type == "return" then
    local entity = running.vehicles[stop.vehicle]
    -- A destroyed or vanished vehicle doesn't block the sale; the player still has to come back here
    if entity and DoesEntityExist(entity) and #(GetEntityCoords(entity) - stop.coords) > stop.radius + DISTANCE_MARGIN then
      return false, "too_far"
    end
    return true
  end
  if requireVehicle and stop.vehicle and not inVehicle(source, running, stop.vehicle) then return false, "wrong_vehicle" end
  return true
end

-- A stop with a duration starts here (the player is in place, in the right vehicle)
lib.callback.register(RESOURCE .. ":server:begin", function(source, index)
  local running = sales[source]
  if not running then return false, "no_sale" end
  if expire(source) then return false, "expired" end
  local stop, reason = checkStop(source, running, index)
  if not stop then return false, reason end
  if stop.duration <= 0 then return false, "failed" end
  local ok, why = checkPlace(source, running, stop, true)
  if not ok then return false, why end
  running.begun = { index = stop.index, at = GetGameTimer() }
  return true, stop.duration
end)

lib.callback.register(RESOURCE .. ":server:complete", function(source, index)
  local running = sales[source]
  if not running then return false, "no_sale" end
  if expire(source) then return false, "expired" end
  local stop, reason = checkStop(source, running, index)
  if not stop then return false, reason end
  if GetGameTimer() - running.lastStop < STOP_INTERVAL_MS then return false, "too_fast" end
  if stop.duration > 0 then
    local begun = running.begun
    if not begun or begun.index ~= stop.index or GetGameTimer() - begun.at < stop.duration - FINISH_EARLY_MS then
      return false, "too_fast"
    end
  end
  -- A timed stop checked the vehicle when it began (the player steps out of the boat to dump the drugs)
  local ok, why = checkPlace(source, running, stop, stop.duration <= 0)
  if not ok then return false, why end

  running.done[stop.index] = true
  running.begun = nil
  running.lastStop = GetGameTimer()
  if stop.type == "return" then
    deleteVehicle(running.vehicles[stop.vehicle])
    running.vehicles[stop.vehicle] = nil
  end
  local sale = GetSale(running.id)
  local done = 0
  for _ in pairs(running.done) do done = done + 1 end
  return true, done, #sale.stops
end)

lib.callback.register(RESOURCE .. ":server:finish", function(source)
  local running = sales[source]
  if not running then return false, "no_sale" end
  if expire(source) then return false, "expired" end
  local sale = GetSale(running.id)
  -- The character changed (logout / multichar) since the sale started: it belonged to the old one
  if identifierOf(source) ~= running.identifier then
    endSale(source, "character changed")
    return false, "no_sale"
  end
  if GetCurrentGroup(sale, running.done) then return false, "not_done" end
  if not isNear(source, sale.dealer.position, GetInteractDistance()) then return false, "too_far" end

  -- The drugs are taken first; the sale stays open when the player no longer has them
  local count = GetItemCount(source, sale.item)
  if not count then return false, "not_ready" end
  if count < sale.amount then return false, "not_enough_drugs" end
  if not RemoveItem(source, sale.item, sale.amount) then return false, "not_enough_drugs" end

  local okPay, paid = pcall(AddMoney, source, sale.account, sale.reward)
  if not okPay or not paid then
    Log("error", ("Paying $%s (%s) to %s failed%s; giving back %sx %s"):format(sale.reward, sale.account,
      tostring(GetPlayerName(source)), okPay and "" or (": " .. tostring(paid)), sale.amount, sale.item))
    if not AddItem(source, sale.item, sale.amount) then
      Log("error", ("Could not give back %sx %s to player %s (%s)"):format(sale.amount, sale.item, tostring(source),
        tostring(GetPlayerName(source))))
    end
    return false, "payment_failed"
  end

  endSale(source, "paid")
  Debug("info", "%s sold %sx %s for $%s (%s)", tostring(GetPlayerName(source)), sale.amount, sale.item, sale.reward, sale.account)
  TriggerEvent(RESOURCE .. ":saleFinished", source, sale.id, sale.item, sale.amount, sale.reward)
  return true, sale.reward
end)

-- The player cancelled the sale. The drugs stay with the player.
RegisterNetEvent(RESOURCE .. ":server:cancel", function()
  local src = source
  endSale(src, "cancelled")
end)

AddEventHandler("playerDropped", function()
  local src = source
  endSale(src, "player left")
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= RESOURCE then return end
  for src in pairs(sales) do endSale(src, "resource stopped") end
end)

-- Ends sales that ran past Config.MaxDuration
CreateThread(function()
  while true do
    Wait(5000)
    for src in pairs(sales) do expire(src) end
  end
end)

--- The sale id the player is running, or nil
exports("GetActiveSale", function(source)
  local running = sales[tonumber(source) or -1]
  return running and running.id or nil
end)

prepareConfig()
