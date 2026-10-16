-- Runs once force_drugsell knows the framework is "qbx" (Config.Framework, or detected by the server).
-- Keep your code inside this function. Items go through ox_inventory (server/custom/inventory.lua).
RegisterFramework("qbx", function()
  local function getPlayer(source)
    if GetResourceState("qbx_core") ~= "started" then return nil end
    local ok, player = pcall(function() return exports.qbx_core:GetPlayer(source) end)
    return ok and player or nil
  end

  --- Citizen id (a sale belongs to this character), nil while the player has no character loaded
  --- @param source number
  --- @return string|nil
  function GetIdentifier(source)
    local player = getPlayer(source)
    return player and player.PlayerData and player.PlayerData.citizenid or nil
  end

  --- Players with one of the police jobs (on duty when onlyOnDuty)
  --- @param jobs table<string, true>
  --- @param onlyOnDuty boolean
  --- @return number
  function CountPolice(jobs, onlyOnDuty)
    if GetResourceState("qbx_core") ~= "started" then return 0 end
    local ok, players = pcall(function() return exports.qbx_core:GetQBPlayers() end)
    if not ok or type(players) ~= "table" then return 0 end
    local count = 0
    for _, player in pairs(players) do
      local job = player.PlayerData and player.PlayerData.job
      if type(job) == "table" and jobs[job.name] and (not onlyOnDuty or job.onduty) then count = count + 1 end
    end
    return count
  end

  --- Pays the sale reward. Return true only when the money was added.
  --- "dirty": the black_money item in ox_inventory.
  --- @param account "cash"|"bank"|"dirty"
  --- @return boolean
  function AddMoney(source, account, amount)
    if account == "dirty" then return AddItem(source, "black_money", amount) end
    local player = getPlayer(source)
    if not player then return false end
    return player.Functions.AddMoney(account, amount, "drug-sale") ~= false
  end

  --- qbx_vehiclekeys (Config.GiveKeys)
  function GiveVehicleKeys(source, vehicle, plate)
    if GetResourceState("qbx_vehiclekeys") ~= "started" then return end
    local ok, err = pcall(function() exports.qbx_vehiclekeys:GiveKeys(source, vehicle) end)
    if not ok then Log("error", ("qbx_vehiclekeys GiveKeys failed: %s"):format(tostring(err))) end
  end
end)
