ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('force_drugsCheckHasStarted', function(source, cb, itemCount)
    local src = source
    local player = ESX.GetPlayerFromId(src)
    local methCount = player.getInventoryItem(Config.DrugItem, count)
    if methCount.count > itemCount then
        cb(true)
        -- TriggerClientEvent('esx:showNotification', src, 'Du har påbörjat försäljningen på 10g meth!')
    else
        TriggerClientEvent('esx:showNotification', src, 'Du behöver minst 50g meth innan du kan sälja!')
    end
end)

RegisterServerEvent('force_drugsellReward')
AddEventHandler('force_drugsellReward', function()
    local player = ESX.GetPlayerFromId(source)

    player.addMoney(Config.RewardMoney)
    player.removeInventoryItem(Config.DrugItem, 50)
end)


ESX.RegisterServerCallback('force_drugsellRewardcb', function(source, cb, itemCount)
    local src = source
    local player = ESX.GetPlayerFromId(src)
    local methCount = player.getInventoryItem(Config.DrugItem, count)
    if methCount.count > itemCount then
        cb(true)
        -- TriggerClientEvent('esx:showNotification', src, 'Du har påbörjat försäljningen på 10g meth!')
    else
        TriggerClientEvent('esx:showNotification', src, 'Du behöver minst 50g meth innan du kan sälja!')
    end
end)