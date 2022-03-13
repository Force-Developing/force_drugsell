ESX              = nil
local PlayerData = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
  PlayerData = xPlayer   
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
  PlayerData.job = job
end)

Citizen.CreateThread(function()
	while true do
		local sleepThread = 500

		local player = GetPlayerPed(-1)
		local pCoords = GetEntityCoords(player)	
		local dist1 = #(pCoords - Config.CokeStartMarker)

		if dist1 < 50 then
			sleepThread = 5
			RequestModel(Config.CokePedMainHash) while not HasModelLoaded(Config.CokePedMainHash) do Wait(7) end
			if not DoesEntityExist(CokePedMain) then
				CokePedMain = CreatePed(4, Config.CokePedMainHash, Config.CokePedMainPos, Config.CokePedMainPosHeading, false, true)
				FreezeEntityPosition(CokePedMain, true)
				SetBlockingOfNonTemporaryEvents(CokePedMain, true)
				SetEntityInvincible(CokePedMain, true)
				ESX.LoadAnimDict("anim@heists@fleeca_bank@ig_7_jetski_owner")
                TaskPlayAnim(CokePedMain, 'anim@heists@fleeca_bank@ig_7_jetski_owner', 'owner_idle', 1.0, -1.0, -1, 69, 0, 0, 0, 0)
			end
		end	

		if dist1 >= 1.5 and dist1 <= 7 and not cokeHasStarted then
			DrawText3Ds(Config.MainCokePedPosText.x, Config.MainCokePedPosText.y, Config.MainCokePedPosText.z+0.3, '[~r~E~w~] Håkan', 0.4)
			DrawMarker(6, Config.CokeStartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
		end

		if dist1 < 1.5 and not cokeHasStarted then
			DrawText3Ds(Config.MainCokePedPosText.x, Config.MainCokePedPosText.y, Config.MainCokePedPosText.z+0.3, '[~g~E~w~] Håkan', 0.4)
			DrawMarker(6, Config.CokeStartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)
			ESX.ShowHelpNotification('~INPUT_PICKUP~ snacka med Håkan')
			if IsControlJustPressed(1, 38) then
				CokeMenuMain()
			end
		end
		Wait(sleepThread)
	end
end)

RegisterNetEvent('force_drugsellCokeProcess')
AddEventHandler('force_drugsellCokeProcess', function()
	while cokeHasStarted do
		Wait(7)
		local player = GetPlayerPed(-1)
		local pCoords = GetEntityCoords(player)
		local dist1 = #(pCoords - Config.DropCokePos)
		local dist2 = #(pCoords - Config.CokeStartMarker)

		for _,cokeMainVehicle in pairs(Config.CokeMainVehicle) do
			RequestModel(cokeMainVehicle.vehicleHash) while not HasModelLoaded(cokeMainVehicle.vehicleHash) do Wait(7) end
			if not cokeMainVehicle.hasSpawned then
				cokeVehicleMain = CreateVehicle(cokeMainVehicle.vehicleHash, cokeMainVehicle.x, cokeMainVehicle.y, cokeMainVehicle.z, cokeMainVehicle.h, false, true)
				cokeMainVehicle.hasSpawned = true
				cokeMainVehicleBlip = AddBlipForEntity(cokeVehicleMain)
				BlipDetails(cokeMainVehicleBlip, 'Din fyrhjuling', 46, true)
			end
		end

		for _,cokeBoatMain in pairs(Config.CokeBoatMain) do
			if IsPedInVehicle(player, cokeVehicleMain, false) then
				DrawMissionText('Ta dig till din angivna position och sätt dig i båten', 0.96, 0.5)
				if not cokeBoatMain.blipSpawned then
					BoatBlip = AddBlipForCoord(cokeBoatMain.x, cokeBoatMain.y, cokeBoatMain.z)
					BlipDetails(BoatBlip, 'Din båt', 46, true)
					cokeBoatMain.blipSpawned = true
					RemoveBlip(cokeMainVehicleBlip)
				end
			end

			if GetDistanceBetweenCoords(pCoords, cokeBoatMain.x, cokeBoatMain.y, cokeBoatMain.z, false) < 80 then
				RequestModel(cokeBoatMain.vehicleHash) while not HasModelLoaded(cokeBoatMain.vehicleHash) do Wait(7) end
				if not cokeBoatMain.hasSpawned then
					cokeMainBoat = CreateVehicle(cokeBoatMain.vehicleHash, cokeBoatMain.x, cokeBoatMain.y, cokeBoatMain.z, cokeBoatMain.h, false, true)
					cokeBoatMain.hasSpawned = true
				end
			end

			if IsPedInVehicle(player, cokeMainBoat, false) then
				RemoveBlip(BoatBlip)
				RemoveBlip(cokeMainVehicleBlip)
				if not DropCokeBlipExist then
					DropCokeBlip = AddBlipForCoord(Config.DropCokePos)
					BlipDetails(DropCokeBlip, 'Drog position', 46, true)
					DropCokeBlipExist = true
				end

				if dist1 < 200 and not hasDroppedDrugs then
					DrawMarker(28, Config.DropCokePos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 20.0, 20.0, 20.0, 255, 0, 0, 50, false, true, 2, false, false, false, false)
				end

				if dist1 < 20 and not hasDroppedDrugs then
					DrawMarker(28, Config.DropCokePos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 20.0, 20.0, 20.0, 0, 255, 0, 50, false, true, 2, false, false, false, false)
					ESX.ShowHelpNotification('~INPUT_PICKUP~ kasta droger')
					RemoveBlip(DropCokeBlip)
					if IsControlJustPressed(1, 38) then
						TaskLeaveVehicle(player, cokeMainBoat, 0)
						DisableControls = true
						Wait(1800)
						exports["btrp_progressbar"]:StartDelayedFunction({
							["text"] = "Kastar ut drogerna",
							["delay"] = 60000
						})
						FreezeEntityPosition(cokeMainBoat, true)
						ESX.LoadAnimDict("mp_am_hold_up")
						TaskPlayAnim(player, 'mp_am_hold_up', 'purchase_beerbox_shopkeeper', 1.0, -1.0, 60000, 69, 0, 0, 0, 0)
						Wait(60000)
						DisableControls = false
						FreezeEntityPosition(cokeMainBoat, false)
						hasDroppedDrugs = true
					end
				end
			end

			if hasDroppedDrugs and not hasGottenRewardCoke then
				if not hasDroppedDrugsDoneBlipHasSpawned then
					hasDroppedDrugsDone = AddBlipForCoord(Config.CokeStartMarker)
					BlipDetails(hasDroppedDrugsDone, 'Håkan', 46, true)
					ESX.ShowNotification('Tack, ta dig tillbaka till mig för din belöning.')
					hasDroppedDrugsDoneBlipHasSpawned = true
				end
				DrawMissionText('Ta dig till din angivna position och hämta din belöning', 0.96, 0.5)
				if dist2 >= 1.5 and dist2 <= 7 then
					DrawMarker(6, Config.CokeStartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
				end
				if dist2 < 1.5 then
					DrawMarker(6, Config.CokeStartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)
					ESX.ShowHelpNotification('~INPUT_PICKUP~ ta din belöning')
					if IsControlJustPressed(1, 38) then
						ESX.TriggerServerCallback('force_drugsellRewardcbCoke', function(itemCount)
							if itemCount then
								TriggerServerEvent('force_drugsellRewardCoke')
								ESX.ShowNotification('Du fick din belöning på ' .. Config.RewardMoneyCoke .. 'kr')
							end
						end, 49)
						hasGottenRewardCoke = true
						Wait(1000)
						cokeHasStarted = false
						hasDroppedDrugs = false
						hasDroppedDrugsDoneBlipHasSpawned = false
						hasGottenRewardCoke = false
						DropCokeBlipExist = false
						cokeBoatMain.hasSpawned = false
						cokeBoatMain.blipSpawned = false
						RemoveBlip(hasDroppedDrugsDone)
						RemoveBlip(DropCokeBlip)
						RemoveBlip(BoatBlip)
						RemoveBlip(cokeMainVehicleBlip)
						for _,cokeMainVehicle in pairs(Config.CokeMainVehicle) do
							cokeMainVehicle.hasSpawned = false
						end
					end
				end
			end
		end
	end
end)

RegisterNetEvent('force_drugsellCokeDialog')
AddEventHandler('force_drugsellCokeDialog', function()
	ESX.ShowNotification('Tjenare, du skulle inte vilja hjälpa mig att dela ut lite kokain.')
	Wait(2000)
	ESX.ShowNotification('Sätt dig på fyrhjulingen för vidare information.')
end)

function CokeMenuMain()
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'weamenu',
    {
        title = 'Vill du sälja Coke hos Håkan?',
        align = 'center',
        elements = {
			{label = 'Ja', option = 'ja'},
            {label = 'Nej', option = 'nej'},
        }
    },

    function(data, menu)
        -- menu.close()
        local chosen = data.current.option

		if chosen == 'ja' then
			menu.close()
			Wait(100)
			ESX.TriggerServerCallback('force_drugsCheckCokeAmount', function(cokeCount)
				if cokeCount then
					cokeHasStarted = true
					TriggerEvent('force_drugsellCokeProcess')
					TriggerEvent('force_drugsellCokeDialog')
				end
			end, 49)
		elseif chosen == 'nej' then
			menu.close()
			ESX.ShowNotification('Nehe, Stick och brinn.')
        end
    end,
    function(data, menu)
        menu.close()
		ESX.ShowNotification('Nehe, Stick och brinn.')
    end)
end

Citizen.CreateThread(function()
    while true do
        local sleepThread = 1000

        if DisableControls then
            sleepThread = 5
            DisableAllControlActions(true)
        end
        Wait(sleepThread)
    end
end) 

-- RegisterCommand('Dugillarbarn', function()
-- 	ESX.TriggerServerCallback('force_drugsCheckCokeAmount', function(cokeCount)
-- 		if cokeCount then
-- 			cokeHasStarted = true
-- 			TriggerEvent('force_drugsellCokeProcess')
-- 			TriggerEvent('force_drugsellCokeDialog')
-- 		end
-- 	end, 49)
-- end, false)

-- RegisterCommand('force#3883', function()
-- 	ESX.TriggerServerCallback('force_drugsellRewardcbCoke', function(itemCount)
-- 		if itemCount then
-- 			TriggerServerEvent('force_drugsellRewardCoke')
-- 			ESX.ShowNotification('Du fick din belöning på ' .. Config.RewardMoneyCoke .. 'kr')
-- 		end
-- 	end, 49)
-- end, false)