---
title: "Installation"
sidebar_position: 2
---


# Installation

Kora Consumables makes food, drink, liquor and smoke items usable. The player holds the item, a progress bar runs on the client, and the server removes the item and applies hunger, thirst, stress and similar status values only after the bar finishes. It exposes four server exports for legacy QBCore resources and is otherwise configured through `Config`.

## Install Kora Consumables

1. **Add the folder** — Place `kora_consumables` in your resources directory (on the Kora recipe it is `resources/[kora]/kora_consumables`). Keep the folder name: other resources and the progress callback use the `kora_consumables` identity.

2. **Make sure the dependencies exist** — The manifest declares `kora_lib` and `kora_core`. The server script also calls `exports.kora_inventory:removeItem` and `exports['qb-inventory']:SetItemData` (the latter is registered by `kora_inventory/server/compat/qb.lua`), but `kora_inventory` is NOT declared in the manifest. Start it before this resource. Without it, finishing a use fails when the item is removed.

3. **Start it after its dependencies** — Start it after Kora Lib, Kora Core, Kora SQL and Kora Inventory.

   ```bash title="server.cfg"
   ensure kora_lib
   ensure kora_core
   ensure kora_sql
   ensure kora_inventory
   ensure kora_consumables
   ```

4. **Check the manifest** — The shared scripts load the Kora Lib loader first, then every `shared/**.lua` file (`Config.lua`, then `deafaults.lua`; the spelling of that file name is the source's).

   ```lua title="fxmanifest.lua"
   fx_version 'cerulean'
   game 'gta5'
   lua54 'yes'
   version '0.2.0'

   dependency 'kora_lib'
   dependency 'kora_core'
   dependency 'kora_sql'

   shared_script {
       '@kora_lib/init.lua',
       'shared/**.lua'
   }

   server_scripts {
       '@kora_sql/init.lua',
       'server/schema.lua',
       'server/data.lua',
       'server/server.lua',
       'server/creator.lua',
   }

   client_scripts {
       'client/**.lua'
   }
   ```

5. **Database setup** — The schema includes seed rows for the shipped items and class defaults. `kora_sql` inserts missing rows when the resource starts, so a fresh install receives the resource's catalog automatically. Existing database rows stay authoritative and are not overwritten by the seed data.

6. **Make sure inventory images exist** — The in-game creator can register new shared items in `kora_core`; place any custom image in the inventory's image directory. Configured items already defined in `kora_core` continue to work as before.

## Start order and startup behavior

- The server creates/loads the database catalog before calling `createUseable` for each active consumable.
- When `kora_inventory` starts (or restarts) after this resource, the `onResourceStart` handler in `server/server.lua` calls `registerUseables()` again, because the inventory's own built-in handlers would otherwise replace ours.
- The client asks for the active database catalog as it starts; the server sends it to every joining client.
- A full item configuration is merged at load by `ApplyConsumableDefaults` (see Configuration). Edits to `shared/Config.lua` need a resource restart.

## Things that surprise people

- `/consumableCreator` opens the in-game editor for players granted the `command` ACE permission. Everything else starts from using an item in the inventory.
- The only exports are the four legacy ones documented here. They are registered under `exports.kora_consumables` and also under `exports['qb-smallresources']`.
- In `shared/Config.lua` the liquor keys are `beer_pisswaser3` and `beer_pisswaser4`, matching the item names in `items/items.md`.

## Requirements

| Resource | Why |
| --- | --- |
| [kora_lib](https://github.com/KoraFiveM/kora_lib) | Declared `dependency`; loaded via `@kora_lib/init.lua`. Provides `Kora.callback`, `Kora.progressbar`, `Kora.visuals`, `Kora.notify`, `Kora.config` and `Kora.compat`. |
| [kora_core](https://github.com/KoraFiveM/kora_core) | Declared `dependency`. Provides shared item registration, `createUseable` and player metadata updates. |
| `kora_sql` | Declared `dependency`; creates and reads the persistent item catalog. |
| [kora_inventory](https://github.com/KoraFiveM/kora_inventory) | Not declared in `fxmanifest.lua`, but required at runtime: items are removed with `exports.kora_inventory:removeItem`. Limited-use items are updated through the `qb-inventory` compatibility export `SetItemData`. |

## Database

The `kora_consumables_items` table stores class, item key, complete configuration JSON and an enabled flag. `kora_consumables_classes` stores editable class defaults. The schema ships seed rows for the default catalog; inserts preserve existing rows, including disabled rows, so saved edits and deletions remain authoritative. Class labels continue to come from the active locale when no saved label overrides them. Status changes are written through `kora_core` player metadata.

## Commands

`/consumableCreator` opens the in-game creator. It requires the `command` ACE permission.

See [Items](./items.md) for the default consumables and how to add new ones.
