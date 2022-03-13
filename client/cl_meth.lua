ESX              = nil
local PlayerData = {}
local deliveredPosistions = 0
local hasDeletedAirplane = false
local hasStarted = false
local hasGottenReward = false
local drugCrates = {}

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(player)
  PlayerData = player   
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
		local dist1 = #(pCoords - Config.MainPedPos)

		if dist1 < 50 then
			madebyforce = true
			RequestModel(Config.MainPedHash) while not HasModelLoaded(Config.MainPedHash) do Wait(7) end
			if not DoesEntityExist(MainPed) then
				MainPed = CreatePed(4, Config.MainPedHash, Config.MainPedPos, Config.MainPedHeading, false, true)
				FreezeEntityPosition(MainPed, true)
				SetBlockingOfNonTemporaryEvents(MainPed, true)
				SetEntityInvincible(MainPed, true)
				TaskStartScenarioInPlace(MainPed, "WORLD_HUMAN_SMOKING", 0, true)
			end
		else
			madebyforce = false
		end

		if madebyforce then sleepThread = 5 else sleepThread = 500 end

		if dist1 >= 1.5 and dist1 <= 6 then
			if not hasStarted then
				DrawText3Ds(Config.MainPedPosText.x, Config.MainPedPosText.y, Config.MainPedPosText.z+1, '[~r~E~w~] Jesper', 0.4)
				DrawMarker(6, Config.StartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
			end
		end

		if dist1 < 1.5 then
			if not hasStarted then
				DrawText3Ds(Config.MainPedPosText.x, Config.MainPedPosText.y, Config.MainPedPosText.z+1, '[~g~E~w~] Jesper', 0.4)
				ESX.ShowHelpNotification('~INPUT_PICKUP~ Snacka med Jesper')
				DrawMarker(6, Config.StartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)
				if IsControlJustPressed(1, 38) then
					sleepThread = 100
					SellDrugMenu()
				end
			end
		end
		Wait(sleepThread)
	end
end)

RegisterNetEvent('force_drugsellMeth')
AddEventHandler('force_drugsellMeth', function()
	while hasStarted do
		Wait(7)
		local player = GetPlayerPed(-1)
		local pCoords = GetEntityCoords(player)
		local dist1 = #(pCoords - Config.AirplanePos)
		local dist2 = #(pCoords - Config.StartMarker)

		for _,vehicles in pairs(Config.VehicleSpawn) do
			RequestModel(vehicles.vehicleHash) while not HasModelLoaded(vehicles.vehicleHash) do Wait(7) end
			if not vehicles.hasSpawned then
				MainVehicle = CreateVehicle(vehicles.vehicleHash, vehicles.x, vehicles.y, vehicles.z, vehicles.h, false, true)
				vehicles.hasSpawned = true
				SetVehRadioStation(MainVehicle, "OFF")
				MainVehicleBlip = AddBlipForEntity(MainVehicle)
				BlipDetails(MainVehicleBlip, 'Ditt fordon', 46, true)
			end
		end

		if IsPedInVehicle(player, MainVehicle, false) then
			DrawMissionText('Ta dig till din angivna position på GPS:en för vidare information!', 0.96, 0.5)
			RemoveBlip(MainVehicleBlip)
			if not DoesBlipExist(AirplaneBlip) then
				AirplaneBlip = AddBlipForCoord(Config.AirplanePos)
				BlipDetails(AirplaneBlip, 'Destination', 46, true)
			end
		end

		for _,airplanes in pairs(Config.AirPlanceSpawn) do
			if dist1 < 50 then
				RemoveBlip(AirplaneBlip)
				RequestModel(airplanes.vehicleHash) while not HasModelLoaded(airplanes.vehicleHash) do Wait(7) end
				if not airplanes.hasSpawned then
					AirPlane = CreateVehicle(airplanes.vehicleHash, airplanes.x, airplanes.y, airplanes.z, airplanes.h, false, true)
					airplanes.hasSpawned = true
					AirplaneVehicleBlip = AddBlipForEntity(AirPlane)
					BlipDetails(AirplaneVehicleBlip, 'Ditt flygplan', 46, true)
				end
			end
		end

		if IsPedInVehicle(player, AirPlane, false) and deliveredPosistions < Config.deliveredPosistions then
			DrawMissionText('Antal destinationer: ' .. deliveredPosistions .. '/' .. Config.deliveredPosistions, 0.0, 0.5)
			DrawMissionText('Ta dig till dina angivna positioner och leverera Meth:et!', 0.96, 0.5)
			RemoveBlip(AirplaneBlip)
			RemoveBlip(MainVehicleBlip)
			RemoveBlip(AirplaneVehicleBlip)
			for _,deliverBlips in pairs(Config.MethDestinations) do
				if not deliverBlips.hasSpawned then
					deliverBlips.blipName = AddBlipForCoord(deliverBlips.x, deliverBlips.y, deliverBlips.z)
					BlipDetails(deliverBlips.blipName, 'Levererings position', 46, true)
					deliverBlips.hasSpawned = true
				end
			end
		end
			for _,deliverBlips in pairs(Config.MethDestinations) do
				if GetDistanceBetweenCoords(pCoords, deliverBlips.x, deliverBlips.y, deliverBlips.z, true) < 800 and not deliverBlips.hasDelivered and IsPedInVehicle(player, AirPlane, false) then
					DrawMarker(28, deliverBlips.x, deliverBlips.y, deliverBlips.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 35.0, 35.0, 35.0, 255, 0, 0, 50, false, true, 2, false, false, false, false)
				if GetDistanceBetweenCoords(pCoords, deliverBlips.x, deliverBlips.y, deliverBlips.z, true) < 35 and not deliverBlips.hasDelivered and IsPedInVehicle(player, AirPlane, false) then
					ESX.ShowHelpNotification('~INPUT_PICKUP~ leverera amfetamin')
					DrawMarker(28, deliverBlips.x, deliverBlips.y, deliverBlips.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 35.0, 35.0, 35.0, 0, 255, 0, 50, false, true, 2, false, false, false, false)
					if IsControlJustPressed(1, 38) then
								deliveredPosistions = deliveredPosistions + 1
								deliverBlips.hasDelivered = true
								RemoveBlip(deliverBlips.blipName)
								ESX.ShowNotification('Du levererade drogerna på ' .. deliveredPosistions .. '/' .. Config.deliveredPosistions .. ' ställen')
						for _,object in pairs(Config.Object) do
							RequestModel(object.objectHash) while not HasModelLoaded(object.objectHash) do Wait(7) end
							if not object.hasSpawned then
								object.objectName = CreateObject(object.objectHash, pCoords.x, pCoords.y, pCoords.z - 3, true, true, true)
								SetEntityDynamic(object.objectName, true)
								table.insert(drugCrates, object.objectName)
							end
						end
					end
				end
			end
		end
		for _,deliverBlips in pairs(Config.MethDestinations) do
			if deliveredPosistions >= Config.deliveredPosistions and not hasDeletedAirplane then
				DrawMissionText('Ta dig till din angivna position och lämna flygplanet', 0.96, 0.5)
				if not DoesBlipExist(returnAirplane) then
					returnAirplane = AddBlipForCoord(Config.AirplanePos - 0.985)
					BlipDetails(returnAirplane, 'Lämna flygplanet', 46, true)
				end
				if dist1 < 10 and not hasDeletedAirplane then
					RemoveBlip(returnAirplane)
					ESX.ShowHelpNotification('~INPUT_PICKUP~ lämna flygplan')
					if IsControlJustPressed(1, 38) then
						for _,deleteObject in pairs(drugCrates) do
							DeleteObject(deleteObject)
						end
						hasDeletedAirplane = true
						ESX.Game.DeleteVehicle(AirPlane)
						ESX.ShowNotification('Ta dig till din angivna position på GPS:en för din belöning!')
					end
				end
			end
		end
		if deliveredPosistions >= Config.deliveredPosistions and hasDeletedAirplane and not hasGottenReward then
			RemoveBlip(AirplaneBlip)
			if not DoesBlipExist(returnToJesper) then
				returnToJesper = AddBlipForCoord(Config.StartMarker - 0.985)
				BlipDetails(returnToJesper, 'Jesper', 46, true)
			end
			if dist2 >= 1.5 and dist2 <= 6 then
				DrawMarker(6, Config.StartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
			end
			if dist2 < 1.5 then
				DrawMarker(6, Config.StartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)
				ESX.ShowHelpNotification('~INPUT_PICKUP~ få din belöning')
				if IsControlJustPressed(1, 38) then
					-- TriggerServerEvent('force_drugsellReward')
					ESX.TriggerServerCallback('force_drugsellRewardcb', function(itemCount)
						if itemCount then
							TriggerServerEvent('force_drugsellReward')
							ESX.ShowNotification('Du fick din belöning på ' .. Config.RewardMoney .. 'kr')
						end
					end, 49)
					hasGottenReward = true
					RemoveBlip(MainVehicleBlip)
					RemoveBlip(AirplaneBlip)
					RemoveBlip(returnToJesper)
					deliveredPosistions = 0
					Wait(1000)
					for _,deliverBlips in pairs(Config.MethDestinations) do
						for _,vehicles in pairs(Config.VehicleSpawn) do
							for _,airplanes in pairs(Config.AirPlanceSpawn) do
								airplanes.hasSpawned = false
								deliverBlips.hasSpawned = false
								deliverBlips.hasDelivered = false
								vehicles.hasSpawned = false
								hasDeletedAirplane = false
								hasStarted = false
								hasGottenReward = false
							end
						end
					end
				end
			end
		end
	end
end)

RegisterNetEvent('force_drugsellDialog')
AddEventHandler('force_drugsellDialog', function()
	ESX.ShowNotification('Tjenare, Tack för att du vill sälja meth hos mig!')
	Wait(2000)
	ESX.ShowNotification('Sätt dig i bilen bakom dig för vidare information!')
end)

function SellDrugMenu()
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'weamenu',
    {
        title = 'Vill du sälja meth hos Jesper?',
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
			ESX.TriggerServerCallback('force_drugsCheckHasStarted', function(itemCount)
				if itemCount then
					hasStarted = true
					TriggerEvent('force_drugsellMeth')
					TriggerEvent('force_drugsellDialog')
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

-- RegisterCommand('hejhej', function()
-- 	ESX.TriggerServerCallback('force_drugsellRewardcb', function(itemCount)
-- 		if itemCount then
-- 			TriggerServerEvent('force_drugsellReward')
-- 			ESX.ShowNotification('Du fick din belöning på ' .. Config.RewardMoney .. 'kr')
-- 		end
-- 	end, 49)
-- end, false)

-- RegisterCommand('startmethsell', function()
-- 			ESX.TriggerServerCallback('force_drugsCheckHasStarted', function(itemCount)
-- 				if itemCount then
-- 					hasStarted = true
-- 					TriggerEvent('force_drugsellMeth')
-- 					TriggerEvent('force_drugsellDialog')
-- 				end
-- 			end, 49)
-- end, false)