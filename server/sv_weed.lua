ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('force_drugsCheckWeedAmount', function(source, cb, weedCount)
    local src = source
    local player = ESX.GetPlayerFromId(src)
    local weedAmount = player.getInventoryItem(Config.WeedItem, count)
    if weedAmount.count > weedCount then
        cb(true)
    else
        TriggerClientEvent('esx:showNotification', src, 'Du behöver minst 50g Weed innan du kan påbörja denna försäljning!')
    end
end)

RegisterServerEvent('force_drugsellRewardWeed')
AddEventHandler('force_drugsellRewardWeed', function()
    local player = ESX.GetPlayerFromId(source)

    player.addMoney(Config.RewardMoneyWeed)
    player.removeInventoryItem(Config.WeedItem, 50)
end)

ESX.RegisterServerCallback('force_drugsellRewardcbWeed', function(source, cb, weedCount)
    local src = source
    local player = ESX.GetPlayerFromId(src)
    local weedAmount = player.getInventoryItem(Config.WeedItem, count)
    if weedAmount.count > weedCount then
        cb(true)
    else
        TriggerClientEvent('esx:showNotification', src, 'Du behöver minst 50g Weed innan du kan sälja!')
    end
end)