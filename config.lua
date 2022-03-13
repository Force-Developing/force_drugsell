Config = {}

-----------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------METH----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------

--Main Ped (Jesper)
Config.MainPedPos = vector3(-1404.1535644531, -629.71197509766, 28.673377990723 - 0.985)
Config.MainPedPosText = {x = -1404.1535644531, y = -629.71197509766, z = 28.673377990723}
Config.MainPedHeading = 175.0
Config.MainPedHash = 'cs_josef'
--Item
Config.DrugItem = 'meth'
--Start Marker
Config.StartMarker = vector3(-1404.1561279297, -630.37719726563, 28.673393249512 - 0.985)
--Start Vehicle
Config.VehicleSpawn = {
    {x = -1409.1976318359, y = -636.57086181641, z= 28.673374176025, h = 210.0, hasSpawned = false, vehicleHash = 'mesa'},
}
Config.AirPlanceSpawn = {
    {x = 2131.8845214844, y = 4785.904296875, z= 40.970287322998, h = 20.0, hasSpawned = false, vehicleHash = 'velum2'},
}
--Airplane
Config.AirplanePos = vector3(2131.8845214844, 4785.904296875, 40.970287322998)
Config.MethDestinations = {
    {x = 932.75982666016, y = 3570.3115234375, z = 147.65585327148, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
    {x = 1558.4713134766, y = 3584.4912109375, z = 147.7477722168, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
    {x = 1718.5031738281, y = 3875.9106445313, z = 147.56378173828, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
    {x = 1340.4449462891, y = 4269.3657226563, z = 146.43304443359, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
    {x = 1701.3365478516, y = 4785.0317382813, z = 147.55024719238, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
    {x = 2418.7849121094, y = 5004.986328125, z = 147.77307128906, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
    {x = 2563.52734375, y = 4718.20703125, z = 168.78115844727, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
    {x = 2860.6572265625, y = 4359.1030273438, z = 161.98887634277, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
    {x = 1735.0725097656, y = 3282.4453125, z = 196.43481445313, hasSpawned = false, blipName = 'madebyforce', hasDelivered = false},
}
Config.deliveredPosistions = 9
Config.RewardMoney = 30000
Config.Object = {
    {hasSpawned = false, objectHash = 'prop_drop_armscrate_01', objectName = 'madeByForce#3883'},
}

-----------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------COKE----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------

--Coke Main Ped (Håkan)
Config.CokePedMainPos = vector3(2471.9777832031, 4112.3701171875, 38.064697265625 - 0.985)
Config.MainCokePedPosText = {x = 2471.9777832031, y = 4112.3701171875, z = 38.064697265625}
Config.CokePedMainPosHeading = 75.0
Config.CokePedMainHash = 'a_m_o_salton_01'
--CokeStartMarker
Config.CokeStartMarker = vector3(2470.8505859375, 4112.7290039063, 38.064716339111 - 0.985)
--Item
Config.CokeItem = 'coke'
--Main Vehicle
Config.CokeMainVehicle = {
    {hasSpawed = false, vehicleHash = 'blazer', x = 2472.3591308594, y = 4116.2109375, z = 38.064697265625, h = 330.0},
}
--Coke Boat
Config.CokeBoatMain = {
    {hasSpawed = false, vehicleHash = 'dinghy', x = -2087.8386230469, y = 2607.1936035156, z = 0.1195353269577, h = 115.0, blipSpawned = false},
}
--Drop Coke Pos
Config.DropCokePos = vector3(-3926.8818359375, 2935.6413574219, 0.5860401391983)
--Reward Money
Config.RewardMoneyCoke = 40000

-----------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------WEED----------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------

Config.WeedMainPedPos = vector3(169.15658569336, 2779.0915527344, 45.702838897705 - 0.985)
Config.WeedMainPedPosText = {x = 169.15658569336, y = 2779.0915527344, z = 45.702838897705}
Config.WeedMainPedPosHeading = 100.0
Config.WeedMainPedHash = 'a_m_y_soucent_02'
Config.WeedStartMarker = vector3(168.34031677246, 2778.9011230469, 45.702835083008 - 0.985)
Config.RewardMoneyWeed = 25000
Config.WeedItem = 'weed'
Config.WeedMainVehicle = {
    {x = 170.85552978516, y = 2774.1130371094, z = 45.702831268311, h = 270.0, hasSpawned = false, vehicleHash = 'faggio', vehicleBlipSpawned = false},
}
Config.WeedSellPos = {
    {hasDelivered = false, pedHasSpawned = false, blipHasSpawned = false, pedName = force1, pedHash = 'a_m_m_genfat_01', x = 257.30462646484, y = 3112.447265625, z = 42.487194061279 - 0.985, h = 275.0, nmr = 1},
    {hasDelivered = false, pedHasSpawned = false, blipHasSpawned = false, pedName = force2, pedHash = 'a_m_m_ktown_01', x = 364.14105224609, y = 2616.6823730469, z = 44.492565155029 - 0.985, h = 210.0, nmr = 2},
    {hasDelivered = false, pedHasSpawned = false, blipHasSpawned = false, pedName = force3, pedHash = 'a_m_m_farmer_01', x = 619.16265869141, y = 2784.6713867188, z = 43.481216430664 - 0.985, h = 0.0, nmr = 3},
    {hasDelivered = false, pedHasSpawned = false, blipHasSpawned = false, pedName = force4, pedHash = 'a_m_m_mexlabor_01', x = 436.28753662109, y = 2996.4323730469, z = 41.283630371094 - 0.985, h = 20.0, nmr = 4},
    {hasDelivered = false, pedHasSpawned = false, blipHasSpawned = false, pedName = force5, pedHash = 'a_m_m_paparazzi_01', x = 221.69412231445, y = 2581.89453125, z = 45.815498352051 - 0.985, h = 200.0, nmr = 5},
}