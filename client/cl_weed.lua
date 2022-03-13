ESX              = nil
local PlayerData = {}
local deliverNumber = 1
local totalDeliveryPositions = 0

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
        local dist1 = #(pCoords - Config.WeedStartMarker)   

        if dist1 < 50 then
            sleepThread = 5
            RequestModel(Config.WeedMainPedHash) while not HasModelLoaded(Config.WeedMainPedHash) do Wait(7) end
            if not DoesEntityExist(weedMainPed) then
                weedMainPed = CreatePed(4, Config.WeedMainPedHash, Config.WeedMainPedPos, Config.WeedMainPedPosHeading, false, true)
                SetBlockingOfNonTemporaryEvents(weedMainPed, true)
                FreezeEntityPosition(weedMainPed, true)
                SetEntityInvincible(weedMainPed, true)
            end
        end

        if dist1 >= 1.5 and dist1 <= 6 and not weedProcess then
            DrawText3Ds(Config.WeedMainPedPosText.x, Config.WeedMainPedPosText.y, Config.WeedMainPedPosText.z+1, '[~r~E~w~] Apon', 0.4)
            DrawMarker(6, Config.WeedStartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
        end

        if dist1 < 1.5 and not weedProcess then
            DrawText3Ds(Config.WeedMainPedPosText.x, Config.WeedMainPedPosText.y, Config.WeedMainPedPosText.z+1, '[~g~E~w~] Apon', 0.4)
            DrawMarker(6, Config.WeedStartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)
            ESX.ShowHelpNotification('~INPUT_PICKUP~ prata med Apon')
            if IsControlJustPressed(1, 38) then
                WeedMainMenu()
            end
        end
        Wait(sleepThread)
    end
end)

RegisterNetEvent('force_drugsellWeedProcess')
AddEventHandler('force_drugsellWeedProcess', function()
    while weedProcess do
        Wait(7)

        local player = GetPlayerPed(-1)
        local pCoords = GetEntityCoords(player)

		for _,weedMainVehicle in pairs(Config.WeedMainVehicle) do
			RequestModel(weedMainVehicle.vehicleHash) while not HasModelLoaded(weedMainVehicle.vehicleHash) do Wait(7) end
			if not weedMainVehicle.hasSpawned then
				weedVehicleMain = CreateVehicle(weedMainVehicle.vehicleHash, weedMainVehicle.x, weedMainVehicle.y, weedMainVehicle.z, weedMainVehicle.h, false, true)
				weedMainVehicle.hasSpawned = true
                SetVehRadioStation(weedVehicleMain, "OFF")
				weedMainVehicleBlip = AddBlipForEntity(weedVehicleMain)
				BlipDetails(weedMainVehicleBlip, 'Din motorcykel', 46, true)
			end
        end

        if IsPedInVehicle(player, weedVehicleMain, false) and not hasDeliveredAllWeed then
            RemoveBlip(weedMainVehicleBlip)
            DrawMissionText('Ta dig till din angivna position på din GPS!', 0.96, 0.5)
        end

        if DoesEntityExist(weedVehicleMain) then
            for _,p in pairs(Config.WeedSellPos) do
                if p.hasDelivered then
                    deliverNumber = deliverNumber + 1
                end

                totalDeliveryPositions = totalDeliveryPositions + 1
                if p.nmr == deliverNumber then
                    if not DoesBlipExist(currentDeliveryLocation) then
                        currentDeliveryLocation = AddBlipForCoord(p.x, p.y, p.z)
                        BlipDetails(currentDeliveryLocation, '' .. p.nmr, 46, true)
                    end

                    if GetDistanceBetweenCoords(pCoords, p.x, p.y, p.z) < 50 then
                        RequestModel(p.pedHash) while not HasModelLoaded(p.pedHash) do Wait(7) end
                        if not p.pedHasSpawned then
                            p.pedName = CreatePed(4, p.pedHash, p.x, p.y, p.z, p.h, false, true)
                            p.pedHasSpawned = true
                            SetBlockingOfNonTemporaryEvents(p.pedName, true)
                            SetEntityAsMissionEntity(p.pedName, true, true)
                            FreezeEntityPosition(p.pedName, true)
                        end
                    end

                    pedCoords = GetEntityCoords(p.pedName)
                    local ped, pedDst = ESX.Game.GetClosestPed(pCoords)
                    if GetDistanceBetweenCoords(pCoords, pedCoords.x, pedCoords.y, pedCoords.z) >= 1.5 and GetDistanceBetweenCoords(pCoords, pedCoords.x, pedCoords.y, pedCoords.z) <= 6 then
                        DrawText3Ds(pedCoords.x, pedCoords.y, pedCoords.z+0.5, '[~r~E~w~] Sälj Weed', 0.4)
                    end

                    if GetDistanceBetweenCoords(pCoords, pedCoords.x, pedCoords.y, pedCoords.z) < 1.5 then
                        DrawText3Ds(pedCoords.x, pedCoords.y, pedCoords.z+0.5, '[~g~E~w~] Sälj Weed', 0.4)
                        ESX.ShowHelpNotification('~INPUT_PICKUP~ sälj Weed')
                        if IsControlJustPressed(1, 38) then
                            exports["btrp_progressbar"]:StartDelayedFunction({
                                ["text"] = "Förhandlar...",
                                ["delay"] = 10000
                            })
                            FreezeEntityPosition(player, true)
                            FreezeEntityPosition(weedVehicleMain, true)
                            Wait(10000)
                            FreezeEntityPosition(p.pedName, false)
                            SetPedAsNoLongerNeeded(p.pedName)
                            FreezeEntityPosition(weedVehicleMain, false)
                            FreezeEntityPosition(player, false)
                            ESX.ShowNotification('Du sålde 10g Weed!')
                            p.hasDelivered = true
                            RemoveBlip(currentDeliveryLocation)
                        end
                    end
                end
            end

            for _,weedMainVehicle in pairs(Config.WeedMainVehicle) do
                if deliverNumber == totalDeliveryPositions + 1 and not returnVehicle then
                    if not DoesBlipExist(returnVehicleBlip) then
                        ESX.ShowNotification('Åk till din GPS destination och lämna fordonet.')
                        returnVehicleBlip = AddBlipForCoord(weedMainVehicle.x, weedMainVehicle.y, weedMainVehicle.z)
                        BlipDetails(returnVehicleBlip, 'Lämna fordon', 46, true)
                    end
                    DrawMissionText('Ta dig till din angivna position och lämna fordonet', 0.96, 0.5)
                    hasDeliveredAllWeed = true
                    if  GetDistanceBetweenCoords(pCoords, weedMainVehicle.x, weedMainVehicle.y, weedMainVehicle.z) < 3 then
                        ESX.ShowHelpNotification('~INPUT_PICKUP~ lämna fordon')
                        if IsControlJustPressed(1, 38) then
                            ESX.Game.DeleteVehicle(weedVehicleMain)
                            RemoveBlip(returnVehicleBlip)
                            ESX.ShowNotification('Du lämnade tillbaka fordonet, ta dig nu till Apon för din belöning.')
                            returnVehicle = true
                        end
                    end
                end
                deliverNumber = 1
                totalDeliveryPositions = 0
            end
        end

        if GetDistanceBetweenCoords(pCoords, Config.WeedMainPedPos, true) >= 1.5 and GetDistanceBetweenCoords(pCoords, Config.WeedMainPedPos, true) <= 6 and returnVehicle and not hasGottenRewardWeed then
            DrawMarker(6, Config.WeedStartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 255, 0, 0, 100, false, true, 2, false, false, false, false)
        end

        if GetDistanceBetweenCoords(pCoords, Config.WeedMainPedPos, true) < 1.5 and returnVehicle and not hasGottenRewardWeed then
            DrawMarker(6, Config.WeedStartMarker, 0.0, 0.0, 0.0, 270.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, false, false, false, false)
			ESX.ShowHelpNotification('~INPUT_PICKUP~ få din belöning')
				if IsControlJustPressed(1, 38) then
					ESX.TriggerServerCallback('force_drugsellRewardcbWeed', function(itemCount)
						if itemCount then
							TriggerServerEvent('force_drugsellRewardWeed')
							ESX.ShowNotification('Du fick din belöning på ' .. Config.RewardMoney .. 'kr')
						end
					end, 49)
                    hasGottenRewardWeed = true
                    Wait(1000)
                for _,p in pairs(Config.WeedSellPos) do
                    for _,weedMainVehicle in pairs(Config.WeedMainVehicle) do
                        weedMainVehicle.hasSpawned = false
                        p.hasDelivered = false
                        p.pedHasSpawned = false
                        weedProcess = false
                        hasGottenRewardWeed = false
                        returnVehicle = false
                        hasDeliveredAllWeed = false
                        RemoveBlip(returnVehicleBlip)
                        RemoveBlip(currentDeliveryLocation)
                        RemoveBlip(weedMainVehicleBlip)
                    end
                end
            end
        end
    end
end)

RegisterNetEvent('force_drugsellWeedProcessDialog')
AddEventHandler('force_drugsellWeedProcessDialog', function()
    ESX.ShowNotification('Tja bror, tack för att du vill hjälpa mig med att sälja Weed!')
    Wait(3000)
    ESX.ShowNotification('Sätt dig på hojjen bakom dig för mer information yani.')
end)

function WeedMainMenu()
    ESX.UI.Menu.CloseAll()

    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'weamenu',
    {
        title = 'Vill du sälja Weed hos Apon?',
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
			ESX.TriggerServerCallback('force_drugsCheckWeedAmount', function(weedCount)
				if weedCount then
                    weedProcess = true
                    TriggerEvent('force_drugsellWeedProcess')
                    TriggerEvent('force_drugsellWeedProcessDialog')
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