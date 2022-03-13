ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

ESX.RegisterServerCallback('force_drugsCheckCokeAmount', function(source, cb, cokeCount)
    local src = source
    local player = ESX.GetPlayerFromId(src)
    local cokeAmount = player.getInventoryItem(Config.CokeItem, count)
    if cokeAmount.count > cokeCount then
        cb(true)
    else
        TriggerClientEvent('esx:showNotification', src, 'Du behöver minst 50g coke innan du kan påbörja denna försäljning!')
    end
end)

RegisterServerEvent('force_drugsellRewardCoke')
AddEventHandler('force_drugsellRewardCoke', function()
    local player = ESX.GetPlayerFromId(source)

    player.addMoney(Config.RewardMoneyCoke)
    player.removeInventoryItem(Config.CokeItem, 50)
end)


ESX.RegisterServerCallback('force_drugsellRewardcbCoke', function(source, cb, cokeCount)
    local src = source
    local player = ESX.GetPlayerFromId(src)
    local cokeAmount = player.getInventoryItem(Config.CokeItem, count)
    if cokeAmount.count > cokeCount then
        cb(true)
        -- TriggerClientEvent('esx:showNotification', src, 'Du har påbörjat försäljningen på 10g meth!')
    else
        TriggerClientEvent('esx:showNotification', src, 'Du behöver minst 50g coke innan du kan sälja!')
    end
end)