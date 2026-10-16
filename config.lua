Config = {}

-- Prints extra info to the F8 / server console. Setup errors are always printed.
Config.Debug = false

-- "en", "sv" or "auto" (follows the replicated ox:locale convar: setr ox:locale "sv")
Config.Locale = "en"

-- "auto" (detected by the server: qbx_core, es_extended, qb-core), "esx", "qb", "qbx" or "custom"
Config.Framework = "auto"

-- "auto" (ox_target, then qb-target, else [E] + text UI), "ox_target", "qb-target" or "none" ([E] + text UI).
-- Used for the dealers and the weed buyers. Stops you reach in a vehicle always use [E].
Config.Target = "auto"

-- How close (meters) the player has to stand to a dealer or a buyer. The server allows a small margin on top.
Config.InteractDistance = 2.0

-- Police needed online to start a sale. 0 = no requirement.
Config.Police = {
    jobs = { "police", "sheriff" },
    minimum = 0,
    onlyOnDuty = true, -- QBCore / QBox duty, ESX job.onDuty where your ESX version has it
}

-- Only one player at a time per sale (their vehicles spawn on the same spots)
Config.OneAtATime = true

-- Minutes a sale may take. After that it is cancelled and its vehicles are removed.
Config.MaxDuration = 45

-- Give the player keys for the sale vehicles (qbx_vehiclekeys, qb-vehiclekeys; see server/custom/frameworks)
Config.GiveKeys = true

-- Draw what to do next at the bottom of the screen during a sale
Config.ShowHints = true

--[[
  The sales. The key is the sale id.
  label    = name of the drug in texts
  item     = item the dealer buys (the same items force_drugs gives)
  amount   = items needed to start, taken when the reward is paid
  reward   = money paid at the end
  account  = "cash", "bank" or "dirty" (ESX black_money; QBox / ox_inventory black_money item; QBCore markedbills)
  dealer   = { name, model, coords = vec4, scenario or anim = { dict, clip }, blip = false | { sprite, colour, scale } }
  vehicles = sale vehicles, spawned by the server. { model, coords = vec4, type, label, spawnDistance }
             type: "automobile", "bike", "boat", "plane", "heli". Without spawnDistance the vehicle spawns when the
             sale starts; with it, when the player gets that close.
  stops    = what has to be done, in order of `group` (stops with the same group can be done in any order):
             type = "drop"   fly / drive through coords (radius) in `vehicle` and press E (prop falls when set)
                    "dump"   be in `vehicle` at coords, press E, then wait `duration` seconds
                    "sell"   walk up to the buyer ped at coords and sell (takes `duration` seconds)
                    "return" bring `vehicle` back to coords and leave it (the vehicle is removed)
]]
Config.Sales = {
    meth = {
        label = "Meth",
        item = "meth",
        amount = 50,
        reward = 30000,
        account = "cash",
        dealer = {
            name = "Jesper",
            model = "cs_josef",
            coords = vec4(-1404.15, -629.71, 27.69, 175.0),
            scenario = "WORLD_HUMAN_SMOKING",
            blip = false,
        },
        vehicles = {
            car = { model = "mesa", type = "automobile", label = "your car", coords = vec4(-1409.20, -636.57, 28.67, 210.0) },
            plane = { model = "velum2", type = "plane", label = "your plane", coords = vec4(2131.88, 4785.90, 40.97, 20.0), spawnDistance = 50.0 },
        },
        stops = {
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(932.76, 3570.31, 147.66) },
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(1558.47, 3584.49, 147.75) },
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(1718.50, 3875.91, 147.56) },
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(1340.44, 4269.37, 146.43) },
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(1701.34, 4785.03, 147.55) },
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(2418.78, 5004.99, 147.77) },
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(2563.53, 4718.21, 168.78) },
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(2860.66, 4359.10, 161.99) },
            { type = "drop", group = 1, vehicle = "plane", radius = 35.0, prop = "prop_drop_armscrate_01", coords = vec3(1735.07, 3282.45, 196.43) },
            { type = "return", group = 2, vehicle = "plane", radius = 10.0, coords = vec3(2131.88, 4785.90, 40.97) },
        },
    },
    coke = {
        label = "Cocaine",
        item = "coke",
        amount = 50,
        reward = 40000,
        account = "cash",
        dealer = {
            name = "Håkan",
            model = "a_m_o_salton_01",
            coords = vec4(2471.98, 4112.37, 37.08, 75.0),
            anim = { dict = "anim@heists@fleeca_bank@ig_7_jetski_owner", clip = "owner_idle" },
            blip = false,
        },
        vehicles = {
            quad = { model = "blazer", type = "automobile", label = "your quad", coords = vec4(2472.36, 4116.21, 38.06, 330.0) },
            boat = { model = "dinghy", type = "boat", label = "your boat", coords = vec4(-2087.84, 2607.19, 0.12, 115.0), spawnDistance = 80.0 },
        },
        stops = {
            { type = "dump", group = 1, vehicle = "boat", radius = 20.0, duration = 60, coords = vec3(-3926.88, 2935.64, 0.59) },
        },
    },
    weed = {
        label = "Weed",
        item = "weed",
        amount = 50,
        reward = 25000,
        account = "cash",
        dealer = {
            name = "Apon",
            model = "a_m_y_soucent_02",
            coords = vec4(169.16, 2779.09, 44.72, 100.0),
            blip = false,
        },
        vehicles = {
            scooter = { model = "faggio", type = "bike", label = "your scooter", coords = vec4(170.86, 2774.11, 45.70, 270.0) },
        },
        stops = {
            { type = "sell", group = 1, radius = 3.0, duration = 10, buyer = { model = "a_m_m_genfat_01", heading = 275.0 }, coords = vec3(257.30, 3112.45, 41.50) },
            { type = "sell", group = 2, radius = 3.0, duration = 10, buyer = { model = "a_m_m_ktown_01", heading = 210.0 }, coords = vec3(364.14, 2616.68, 43.51) },
            { type = "sell", group = 3, radius = 3.0, duration = 10, buyer = { model = "a_m_m_farmer_01", heading = 0.0 }, coords = vec3(619.16, 2784.67, 42.50) },
            { type = "sell", group = 4, radius = 3.0, duration = 10, buyer = { model = "a_m_m_mexlabor_01", heading = 20.0 }, coords = vec3(436.29, 2996.43, 40.30) },
            { type = "sell", group = 5, radius = 3.0, duration = 10, buyer = { model = "a_m_m_paparazzi_01", heading = 200.0 }, coords = vec3(221.69, 2581.89, 44.83) },
            { type = "return", group = 6, vehicle = "scooter", radius = 3.0, coords = vec3(170.86, 2774.11, 45.70) },
        },
    },
}
