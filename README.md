# force_drugsell

Drug sale runs. Bring 50 grams to a dealer and do the run he asks for: fly meth drops over Blaine County with a plane, take a boat out to sea and dump cocaine, or ride a scooter to five weed buyers. Come back and he pays you. Pairs with [force_drugs](https://github.com/Force-Developing/force_drugs), which gives the same items.

Free and open source. Works on ESX Legacy, QBCore and QBox.

## Features

- Three sales out of the box (meth by plane, cocaine by boat, weed by scooter), each with its own dealer, vehicles, stops and reward
- Sale vehicles are spawned by the server, with keys (qbx_vehiclekeys, qb-vehiclekeys) and full fuel (ox_fuel)
- Server-side checks: sale ids and stop indexes from the config, stop order, distance, the right vehicle, stop durations, pace, the drugs in the inventory, optional police minimum, one player per sale
- The drugs are taken and the reward is paid by the server at the end; a failed payment gives the drugs back
- Payout as cash, bank or dirty money (ESX black_money, QBox black_money item, QBCore markedbills)
- Cancel at the dealer, a maximum duration, and cleanup when the player leaves or the resource restarts
- ox_target, qb-target or [E] with the ox_lib text UI
- ox_inventory, qb-inventory and the ESX inventory
- English and Swedish locales

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- OneSync
- ESX Legacy, QBCore or QBox (other frameworks through `server/custom/frameworks/custom.lua`)
- The items `coke`, `meth` and `weed` in your inventory (see the [items](items) folder)
- Optional: ox_target or qb-target

No database is used.

## Installation

1. Put the folder in your resources as `force_drugsell`.
2. Add the items from the `items` folder to your inventory (skip this if force_drugs is installed already; the items are the same).
3. Add `ensure force_drugsell` to `server.cfg` below `ensure ox_lib`. The order relative to your framework and target resource doesn't matter.
4. Edit `config.lua`: rewards, payout account, the amount per sale and the police minimum.

## Documentation

https://docs.forcedevelopments.com/free-resources/force_drugsell/introduction

## License

Apache 2.0, see [LICENSE](LICENSE).
