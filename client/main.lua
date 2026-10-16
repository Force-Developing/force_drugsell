local RESOURCE = GetCurrentResourceName()
local CALLBACK_TIMEOUT = 15000
local PED_SPAWN_DISTANCE = 50.0
local MARKER_DISTANCE = 200.0
local VEHICLE_REQUEST_INTERVAL = 5000
local SLOW_TICK = 250
local LEAVE_TIMEOUT = 3000
local KEY_E = 38
local BLIP_COLOUR = 46
local DUMP_DICT, DUMP_CLIP = "mp_am_hold_up", "purchase_beerbox_shopkeeper"
local STOP_TEXT = "stop"

local dealers = {}       -- [sale id] = { ped, point, blip }
local requesting = false -- dialog / server request at a dealer in progress
local sale = nil         -- the running sale, see beginSale()
local lastPress = 0

local function notify(message, notifyType)
  lib.notify({ description = message, type = notifyType or "inform" })
end

local function playerLoaded()
  local ok, loaded = pcall(IsPlayerLoaded)
  return ok and loaded == true
end

--- lib.callback with its own timeout (ox_lib waits 5 minutes and throws). Returns nil when the server didn't answer.
local function awaitServer(name, ...)
  local p = promise.new()
  local settled = false
  local function settle(value)
    if settled then return end
    settled = true
    p:resolve(value)
  end
  lib.callback(name, false, function(...)
    settle({ n = select("#", ...), ... })
  end, ...)
  SetTimeout(CALLBACK_TIMEOUT, function() settle(false) end)
  local result = Citizen.Await(p)
  if not result then return nil end
  return table.unpack(result, 1, result.n)
end

--- Notification for a reason the server returned
local function notifyReason(reason, def, stop)
  if reason == "not_enough_drugs" and def then
    return notify(locale("not_enough_drugs", def.amount, def.label), "error")
  end
  if reason == "dealer_busy" and def then return notify(locale("dealer_busy", def.dealer.name), "error") end
  if reason == "wrong_vehicle" and def and stop and stop.vehicle then
    return notify(locale("wrong_vehicle", def.vehicles[stop.vehicle].label), "error")
  end
  local key = type(reason) == "string" and reason or "failed"
  local text = locale(key)
  notify(text == key and locale("failed") or text, "error")
end

local function drawText2D(text, y)
  SetTextFont(4)
  SetTextScale(0.5, 0.5)
  SetTextColour(255, 255, 255, 255)
  SetTextEdge(2, 0, 0, 0, 150)
  SetTextOutline()
  SetTextCentre(true)
  BeginTextCommandDisplayText("STRING")
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(0.5, y)
end

local function setBlipName(blip, text)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandSetBlipName(blip)
end

local function removeBlip(blip)
  if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
end

local function deleteEntity(entity)
  if entity and DoesEntityExist(entity) then DeleteEntity(entity) end
end

--- Loads a model (pcall: lib.requestModel throws on a bad model or timeout). Returns the hash or nil.
local function loadModel(model)
  local hash = type(model) == "number" and model or joaat(model)
  local ok, err = pcall(lib.requestModel, hash, 10000)
  if not ok then
    Debug("error", "Model '%s' could not be loaded: %s", tostring(model), tostring(err))
    return nil
  end
  return hash
end

local function playerCoords()
  return GetEntityCoords(PlayerPedId())
end

-------------------------------------------------------------------------------------------------------------------
-- Sale vehicles (spawned by the server; the client only knows their net ids)
-------------------------------------------------------------------------------------------------------------------

--- The local handle of a sale vehicle, nil when it doesn't exist here (not spawned, out of scope, deleted)
local function vehicleEntity(current, name)
  local netId = current.netIds[name]
  if not netId or not NetworkDoesNetworkIdExist(netId) then return nil end
  local vehicle = NetToVeh(netId)
  if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return nil end
  return vehicle
end

local function inVehicle(current, name)
  local vehicle = vehicleEntity(current, name)
  return vehicle ~= nil and cache.vehicle == vehicle
end

--- Asks the server for a vehicle that spawns near its spot (or a replacement when it was destroyed)
local function requestVehicle(current, name)
  local now = GetGameTimer()
  if (current.vehicleRequests[name] or 0) + VEHICLE_REQUEST_INTERVAL > now then return end
  current.vehicleRequests[name] = now
  CreateThread(function()
    local ok, netId = awaitServer(RESOURCE .. ":server:vehicle", name)
    if sale ~= current or not ok then return end
    current.netIds[name] = tonumber(netId)
  end)
end

-------------------------------------------------------------------------------------------------------------------
-- Sale
-------------------------------------------------------------------------------------------------------------------

local function buyerId(index) return "buyer:" .. index end

--- Removes everything a sale put in the world. Safe to call more than once.
local function endSale()
  local current = sale
  if not current then return end
  sale = nil
  if current.busy then pcall(lib.cancelProgress) end
  if current.frozenVehicle and DoesEntityExist(current.frozenVehicle) then FreezeEntityPosition(current.frozenVehicle, false) end
  for _, blip in pairs(current.blips) do removeBlip(blip) end
  for _, prop in ipairs(current.props) do deleteEntity(prop) end
  for index, ped in pairs(current.buyers) do
    deleteEntity(ped)
    Interact.remove(buyerId(index))
  end
  Interact.hideText(STOP_TEXT)
end

local function cancelSale()
  if not sale then return end
  TriggerServerEvent(RESOURCE .. ":server:cancel")
  endSale()
end

--- Done / total of the stops of one type
local function progressOf(current, stopType)
  local done, total = 0, 0
  for index, stop in ipairs(current.def.stops) do
    if stop.type == stopType then
      total = total + 1
      if current.done[index] then done = done + 1 end
    end
  end
  return done, total
end

--- The stops of the current group, nil when every stop is done
local function currentStops(current)
  local group = GetCurrentGroup(current.def, current.done)
  if not group then return nil end
  local list = {}
  for index, stop in ipairs(current.def.stops) do
    if not current.done[index] and stop.group == group then list[#list + 1] = stop end
  end
  return list
end

--- The vehicle the player still has to get into for the current stops (drop / dump), or nil
local function neededVehicle(current, stops)
  for _, stop in ipairs(stops) do
    if stop.vehicle and stop.type ~= "return" and not inVehicle(current, stop.vehicle) then return stop.vehicle end
  end
  return nil
end

local function onStopDone(current, stop)
  local def = current.def
  if stop.type == "drop" then
    if stop.prop then
      local hash = loadModel(stop.prop)
      if hash and sale == current then
        local pos = playerCoords()
        local prop = CreateObject(hash, pos.x, pos.y, pos.z - 3.0, false, false, false)
        SetModelAsNoLongerNeeded(hash)
        SetEntityDynamic(prop, true)
        ActivatePhysics(prop)
        current.props[#current.props + 1] = prop
      end
    end
    local done, total = progressOf(current, "drop")
    notify(locale("dropped", done, total), "success")
  elseif stop.type == "dump" then
    notify(locale("dumped"), "success")
  elseif stop.type == "sell" then
    local ped = current.buyers[stop.index]
    Interact.remove(buyerId(stop.index))
    if ped and DoesEntityExist(ped) then
      FreezeEntityPosition(ped, false)
      TaskWanderStandard(ped, 10.0, 10)
    end
    local done, total = progressOf(current, "sell")
    notify(locale("sold", def.label, done, total), "success")
  elseif stop.type == "return" then
    notify(locale("returned", def.vehicles[stop.vehicle].label), "success")
  end
  if not GetCurrentGroup(def, current.done) then notify(locale("all_done", def.dealer.name)) end
end

--- Leaves the vehicle and holds it still while the drugs are thrown out
local function prepareDump(current)
  local vehicle = cache.vehicle
  if not vehicle then return end
  TaskLeaveVehicle(cache.ped, vehicle, 0)
  local deadline = GetGameTimer() + LEAVE_TIMEOUT
  while IsPedInVehicle(PlayerPedId(), vehicle, false) and GetGameTimer() < deadline and sale == current do Wait(100) end
  if sale ~= current then return end
  FreezeEntityPosition(vehicle, true)
  current.frozenVehicle = vehicle
end

local function releaseDump(current)
  local vehicle = current.frozenVehicle
  current.frozenVehicle = nil
  if vehicle and DoesEntityExist(vehicle) then FreezeEntityPosition(vehicle, false) end
end

local function runStop(current, stop)
  if stop.duration > 0 then
    local ok, reason = awaitServer(RESOURCE .. ":server:begin", stop.index)
    if sale ~= current then return end
    if ok == nil then return notify(locale("server_no_response"), "error") end
    if not ok then return notifyReason(reason, current.def, stop) end

    if stop.type == "dump" then prepareDump(current) end
    if sale ~= current then return end
    local okBar, finished = pcall(lib.progressBar, {
      duration = stop.duration,
      label = locale(stop.type == "dump" and "progress_dump" or "progress_sell"),
      useWhileDead = false,
      canCancel = true,
      disable = { move = true, car = true, combat = true },
      anim = stop.type == "dump" and { dict = DUMP_DICT, clip = DUMP_CLIP, flag = 1 } or nil,
    })
    if stop.type == "dump" then
      ClearPedTasks(PlayerPedId())
      releaseDump(current)
    end
    if sale ~= current then return end
    if not okBar then Debug("error", "Stop progress failed: %s", tostring(finished)) return end
    if not finished then return end
  end

  local ok, result = awaitServer(RESOURCE .. ":server:complete", stop.index)
  if sale ~= current then return end
  if ok == nil then return notify(locale("server_no_response"), "error") end
  if not ok then
    notifyReason(result, current.def, stop)
    if result == "no_sale" or result == "expired" then endSale() end
    return
  end
  current.done[stop.index] = true
  onStopDone(current, stop)
end

local function handleStop(current, stop)
  if current.busy then return end
  current.busy = true
  Interact.hideText(STOP_TEXT)
  local ok, err = pcall(runStop, current, stop)
  if not ok then
    Debug("error", "Stop %s failed: %s", stop.index, tostring(err))
    releaseDump(current)
  end
  current.busy = false
end

--- Buyer ped and its interaction, while its stop is current and the player is close
local function updateBuyer(current, stop, near)
  local index = stop.index
  if not near then
    if current.buyers[index] then
      deleteEntity(current.buyers[index])
      current.buyers[index] = nil
      Interact.remove(buyerId(index))
    end
    return
  end
  if current.buyers[index] ~= nil then return end
  current.buyers[index] = false -- spawning
  CreateThread(function()
    local ped
    if stop.buyer then
      local hash = loadModel(stop.buyer.model)
      if hash and sale == current and current.buyers[index] == false then
        local c = stop.coords
        ped = CreatePed(4, hash, c.x, c.y, c.z, stop.buyer.heading, false, false)
        SetModelAsNoLongerNeeded(hash)
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
      end
    end
    if sale ~= current or current.buyers[index] ~= false then return deleteEntity(ped) end
    current.buyers[index] = ped or 0
    local c = stop.coords
    Interact.add(buyerId(index), {
      coords = vector3(c.x, c.y, c.z + 1.0),
      distance = GetInteractDistance(),
      size = 1.0,
      label = locale("sell_label", current.def.label),
      icon = "fa-solid fa-hand-holding-dollar",
      text = locale("sell_textui", current.def.label),
      canInteract = function()
        return sale == current and not current.busy and not current.done[index]
            and GetCurrentGroup(current.def, current.done) == stop.group
      end,
      onSelect = function() CreateThread(function() handleStop(current, stop) end) end,
    })
  end)
end

--- Adds, moves and removes the sale's blips. wanted[key] = { coords = vector3 | entity = handle, label, route }
local function setBlips(current, wanted)
  for key, blip in pairs(current.blips) do
    local want = wanted[key]
    local stale = not DoesBlipExist(blip)
    if not want or stale or (want.entity and current.blipEntity[key] ~= want.entity) then
      removeBlip(blip)
      current.blips[key], current.blipEntity[key] = nil, nil
    end
  end
  for key, want in pairs(wanted) do
    if not current.blips[key] then
      local blip
      if want.entity then
        blip = AddBlipForEntity(want.entity)
        current.blipEntity[key] = want.entity
      else
        blip = AddBlipForCoord(want.coords.x, want.coords.y, want.coords.z)
      end
      SetBlipColour(blip, BLIP_COLOUR)
      setBlipName(blip, want.label)
      if want.route then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, BLIP_COLOUR)
      end
      current.blips[key] = blip
    end
  end
end

--- Blips, hint, buyers and vehicle requests (every SLOW_TICK ms)
local function update(current)
  local def = current.def
  local pos = playerCoords()
  local wanted = {}

  -- remember where the sale vehicles are, and that the player got in
  for name in pairs(def.vehicles) do
    local vehicle = vehicleEntity(current, name)
    if vehicle then
      current.lastSeen[name] = GetEntityCoords(vehicle)
      if cache.vehicle == vehicle then current.entered[name] = true end
    end
  end

  local stops = currentStops(current)
  current.stops = stops
  if not stops then
    wanted.dealer = { coords = def.dealer.position, label = def.dealer.name, route = true }
    current.hint = locale("hint_dealer", def.dealer.name)
    return setBlips(current, wanted)
  end

  -- vehicles that wait at the dealer: marked until the player got in once
  for name, vehicle in pairs(def.vehicles) do
    local entity = not vehicle.spawnDistance and not current.entered[name] and vehicleEntity(current, name)
    if entity and not cache.vehicle then wanted["start:" .. name] = { entity = entity, label = vehicle.label } end
  end

  local needed = neededVehicle(current, stops)
  if needed then
    local vehicle = def.vehicles[needed]
    local entity = vehicleEntity(current, needed)
    local spot = current.lastSeen[needed] or vehicle.position
    if entity and not IsEntityDead(entity) then
      wanted["vehicle:" .. needed] = { entity = entity, label = vehicle.label, route = true }
    else
      wanted["vehicle:" .. needed] = { coords = spot, label = vehicle.label, route = true }
      if #(pos - vehicle.position) <= (vehicle.spawnDistance or PED_SPAWN_DISTANCE) then requestVehicle(current, needed) end
    end
    current.hint = locale("hint_vehicle", vehicle.label)
  else
    local closest, closestDistance = nil, math.huge
    for _, stop in ipairs(stops) do
      local distance = #(pos - stop.coords)
      if distance < closestDistance then closest, closestDistance = stop, distance end
    end
    for _, stop in ipairs(stops) do
      wanted["stop:" .. stop.index] = {
        coords = stop.coords,
        label = locale(stop.type == "return" and "blip_return" or "blip_stop"),
        route = stop == closest,
      }
    end
    local first = stops[1]
    if first.type == "drop" then
      local done, total = progressOf(current, "drop")
      current.hint = locale("hint_drop", def.label, done, total)
    elseif first.type == "sell" then
      local done, total = progressOf(current, "sell")
      current.hint = locale("hint_sell", done, total)
    elseif first.type == "return" then
      current.hint = locale("hint_return", def.vehicles[first.vehicle].label)
    else
      current.hint = locale("hint_dump")
    end
  end

  -- buyers of the current stops appear when the player is close; served buyers walk off and stay until the end
  for _, stop in ipairs(def.stops) do
    if stop.type == "sell" and not current.done[stop.index] then
      updateBuyer(current, stop, stop.group == stops[1].group and #(pos - stop.coords) <= PED_SPAWN_DISTANCE)
    end
  end
  setBlips(current, wanted)
end

local function drawMarker(stop, inside)
  local c = stop.coords
  local r, g = inside and 0 or 255, inside and 255 or 0
  if stop.type == "return" then
    DrawMarker(1, c.x, c.y, c.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, stop.radius * 2.0, stop.radius * 2.0, 1.0,
      r, g, 0, 90, false, false, 2, false, nil, nil, false)
  else
    DrawMarker(28, c.x, c.y, c.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, stop.radius, stop.radius, stop.radius,
      r, g, 0, 50, false, false, 2, false, nil, nil, false)
  end
end

local function promptFor(current, stop)
  if stop.type == "drop" then return locale("prompt_drop", current.def.label) end
  if stop.type == "dump" then return locale("prompt_dump") end
  if stop.type == "return" then return locale("prompt_return", current.def.vehicles[stop.vehicle].label) end
  return nil
end

--- Markers, the [E] prompt of the vehicle stops and the hint (every frame while a sale runs)
local function frame(current)
  if Config.ShowHints ~= false and current.hint then drawText2D(current.hint, 0.93) end
  local stops = current.stops
  if not stops or current.busy then return Interact.hideText(STOP_TEXT) end
  local pos = playerCoords()
  local prompt
  for _, stop in ipairs(stops) do
    if stop.type ~= "sell" then
      local distance = #(pos - stop.coords)
      if distance <= MARKER_DISTANCE then
        local inside = distance <= stop.radius
          and (stop.type == "return" or not stop.vehicle or inVehicle(current, stop.vehicle))
        drawMarker(stop, inside)
        if inside and not prompt then prompt = stop end
      end
    end
  end
  if not prompt then return Interact.hideText(STOP_TEXT) end
  Interact.showText(STOP_TEXT, promptFor(current, prompt))
  if IsControlJustReleased(0, KEY_E) and GetGameTimer() - lastPress > 500 then
    lastPress = GetGameTimer()
    CreateThread(function() handleStop(current, prompt) end)
  end
end

local function runSale(current)
  local nextUpdate = 0
  while sale == current do
    if GetGameTimer() >= nextUpdate then
      nextUpdate = GetGameTimer() + SLOW_TICK
      local ok, err = pcall(update, current)
      if not ok then Debug("error", "Sale update failed: %s", tostring(err)) end
    end
    local ok, err = pcall(frame, current)
    if not ok then Debug("error", "Sale frame failed: %s", tostring(err)) end
    Wait(0)
  end
end

local function beginSale(def, netIds)
  local current = {
    def = def,
    done = {},
    netIds = {},
    vehicleRequests = {},
    lastSeen = {},
    entered = {},
    blips = {},
    blipEntity = {},
    buyers = {},
    props = {},
  }
  for name, netId in pairs(type(netIds) == "table" and netIds or {}) do
    if def.vehicles[name] then current.netIds[name] = tonumber(netId) end
  end
  sale = current
  CreateThread(function() runSale(current) end)
  CreateThread(function()
    notify(locale("dialog_start", def.label))
    for name, vehicle in pairs(def.vehicles) do
      if not vehicle.spawnDistance and current.netIds[name] then
        Wait(2000)
        if sale ~= current then return end
        return notify(locale("dialog_vehicle", vehicle.label))
      end
    end
  end)
end

-------------------------------------------------------------------------------------------------------------------
-- Dealers
-------------------------------------------------------------------------------------------------------------------

local function confirmStart(def)
  local answer = lib.alertDialog({
    header = locale("confirm_header", def.label, def.dealer.name),
    content = locale("confirm_content", def.dealer.name, def.amount, def.label, def.reward),
    centered = true,
    cancel = true,
  })
  if answer ~= "confirm" then return notify(locale("declined"), "error") end
  if sale then return notify(locale("busy"), "error") end
  local ok, result = awaitServer(RESOURCE .. ":server:start", def.id)
  if ok == nil then return notify(locale("server_no_response"), "error") end
  if not ok then return notifyReason(result, def) end
  beginSale(def, result)
end

local function deliver(current)
  local ok, result = awaitServer(RESOURCE .. ":server:finish")
  if sale ~= current then return end
  if ok == nil then return notify(locale("server_no_response"), "error") end
  if not ok then
    notifyReason(result, current.def)
    if result == "no_sale" or result == "expired" then endSale() end
    return
  end
  notify(locale("rewarded", tonumber(result) or current.def.reward), "success")
  endSale()
end

local function askCancel(current)
  local answer = lib.alertDialog({
    header = locale("not_finished_header", current.def.dealer.name),
    content = locale("not_finished_content"),
    centered = true,
    cancel = true,
  })
  if answer == "confirm" and sale == current then
    cancelSale()
    notify(locale("cancelled"))
  end
end

local function talkToDealer(def)
  if requesting then return end
  if not IsFrameworkReady() or not playerLoaded() then return notify(locale("not_ready"), "error") end
  local current = sale
  if current and current.def.id ~= def.id then return notify(locale("busy"), "error") end
  if current and current.busy then return end
  requesting = true
  local ok, err
  if not current then
    ok, err = pcall(confirmStart, def)
  elseif not GetCurrentGroup(def, current.done) then
    ok, err = pcall(deliver, current)
  else
    ok, err = pcall(askCancel, current)
  end
  requesting = false
  if not ok then
    Debug("error", "Talking to the dealer failed: %s", tostring(err))
    notify(locale("server_no_response"), "error")
  end
end

local function deleteDealer(id)
  local dealer = dealers[id]
  if not dealer then return end
  deleteEntity(dealer.ped)
  dealer.ped = nil
end

local function spawnDealer(def)
  local dealer = dealers[def.id]
  if not dealer or (dealer.ped and DoesEntityExist(dealer.ped)) then return end
  local hash = loadModel(def.dealer.model)
  if not hash then return end
  -- the player may have walked away while the model loaded
  if not dealer.near or (dealer.ped and DoesEntityExist(dealer.ped)) then
    SetModelAsNoLongerNeeded(hash)
    return
  end
  local c = def.dealer.position
  local ped = CreatePed(4, hash, c.x, c.y, c.z, def.dealer.heading, false, false)
  SetModelAsNoLongerNeeded(hash)
  FreezeEntityPosition(ped, true)
  SetEntityInvincible(ped, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetPedCanRagdoll(ped, false)
  dealer.ped = ped
  if def.dealer.scenario then
    TaskStartScenarioInPlace(ped, def.dealer.scenario, 0, true)
  elseif def.dealer.anim then
    local anim = def.dealer.anim
    local ok, err = pcall(lib.requestAnimDict, anim.dict, 5000)
    if not ok then return Debug("error", "Dealer animation could not be loaded: %s", tostring(err)) end
    if not DoesEntityExist(ped) then return end
    TaskPlayAnim(ped, anim.dict, anim.clip, 8.0, -8.0, -1, 1, 0, false, false, false)
    RemoveAnimDict(anim.dict)
  end
end

local function setupDealer(def)
  local dealer = {}
  dealers[def.id] = dealer
  local c = def.dealer.position
  dealer.point = lib.points.new({
    coords = c,
    distance = PED_SPAWN_DISTANCE,
    onEnter = function()
      dealer.near = true
      CreateThread(function() spawnDealer(def) end)
    end,
    onExit = function()
      dealer.near = false
      deleteDealer(def.id)
    end,
  })
  Interact.add("dealer:" .. def.id, {
    coords = vector3(c.x, c.y, c.z + 1.0),
    distance = GetInteractDistance(),
    size = 1.0,
    label = locale("talk_label", def.dealer.name),
    icon = "fa-solid fa-comments",
    text = locale("talk_textui", def.dealer.name),
    canInteract = function() return not requesting and not (sale and sale.busy) and playerLoaded() end,
    onSelect = function() CreateThread(function() talkToDealer(def) end) end,
  })
  local blip = def.dealer.blip
  if blip then
    dealer.blip = AddBlipForCoord(c.x, c.y, c.z)
    SetBlipSprite(dealer.blip, tonumber(blip.sprite) or 51)
    SetBlipColour(dealer.blip, tonumber(blip.colour) or 2)
    SetBlipScale(dealer.blip, (tonumber(blip.scale) or 0.7) + 0.0)
    SetBlipAsShortRange(dealer.blip, true)
    setBlipName(dealer.blip, type(blip.label) == "string" and blip.label or def.dealer.name)
  end
end

-- The server ended the sale (Config.MaxDuration)
RegisterNetEvent(RESOURCE .. ":client:ended", function(reason)
  if not sale then return end
  endSale()
  if reason == "expired" then notify(locale("expired"), "error") end
end)

OnEnvironmentReady(function()
  for _, id in ipairs(GetSaleIds()) do
    local def = GetSale(id)
    local ok, err = pcall(setupDealer, def)
    if not ok then Log("error", ("Dealer of sale '%s' could not be set up: %s"):format(id, tostring(err))) end
  end
end)

AddEventHandler("onResourceStop", function(resource)
  if resource ~= RESOURCE then return end
  if requesting then pcall(lib.closeAlertDialog) end
  endSale()
  for id, dealer in pairs(dealers) do
    deleteDealer(id)
    removeBlip(dealer.blip)
    if dealer.point then dealer.point:remove() end
  end
  Interact.removeAll()
end)
