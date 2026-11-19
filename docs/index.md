---
title: kora_consumables
sidebar_position: 1
---

# kora_consumables

`kora_consumables` makes food, drinks, liquor and smokeables usable from the inventory. The server checks the item, then the client shows a progress bar with an animation and an optional hand prop. When the bar finishes, the server removes the item and applies its status changes, such as hunger, thirst or stress. Liquor and smokeables can also start a screen effect. Each item is configured in one shared Lua table. Other server resources can add consumables at runtime through QBCore-compatible `qb-smallresources` exports.

## Features

- **Server-validated use**: every configured item is registered as a useable item with `kora_core`. The server tracks each use, removes the item through `kora_inventory`, and changes the player's metadata. The client only plays the progress bar. See [How it works](./how-it-works.md).
- **Effects applied on completion (default)**: by default, the item is consumed and its status applied only after the progress bar finishes. If the player cancels, nothing is consumed or applied. You can change this with the `applyStatusOn` option.
- **Anti-spam and timing check**: a player can only have one consumable use in progress at a time. If a use reports completion faster than its configured duration allows, the server ignores it.
- **Status changes**: `hunger`, `thirst`, `stress`, `health`, `armor`, `drunk` and `high` metadata are changed and clamped to 0-100.
- **Database-backed classes**: `drink`, `food`, `smoke`, `liquor` and `custom` have editable labels, durations, animations, props, control restrictions, status changes and effects. Each item can override its class values in the creator.
- **Hand props**: each class has a configured default hand and offsets for both hands. The hand and bone can be overridden per class or per item. Props with invalid models are skipped by default so the item can still be used.
- **Walk while consuming**: by default, the animation plays on the upper body and the player can keep walking. Combat and vehicle entry stay blocked. This can be configured globally, per class or per item.
- **Screen effects**: liquor uses a built-in "buzzed" effect: a timecycle modifier, camera shake, an optional drunk walk and an optional notification. Smokeables use the kora_lib visuals `alien`, `coke`, `crack`, `meth` or `trevor`.
- **Limited-use items**: an item with `info.uses` metadata loses one use each time it is used. It is removed only when no uses are left. Items with `keep = true` are never removed.
- **In-game creator**: admins can run `/consumableCreator` to create, edit and delete database-backed consumables. The creator can register a new shared item with `kora_core`, so it is available to all clients after saving. It supports emote names from `kora_emotemenu`, custom animations, two props, status changes and effects. See [Creator](./creator.md).
- **QBCore compatibility exports**: `AddFood`, `AddDrink`, `AddAlcohol` and `AddCustom` are available as `kora_consumables` exports and as `qb-smallresources` exports. Items added this way are saved and synchronized. See [Exports](./api/server-exports.md).
- **Cigarette item**: if no other resource defines a `cigarette` shared item, this resource registers one.

## Documentation map

- [Installation](./installation.md): install steps, start order, requirements, database and commands.
- [How to use](./how-to-use.md): the use flow, adding items and the item classes.
- [Creator](./creator.md): create and manage items in-game.
- [How it works](./how-it-works.md): startup, use flow, movement, screen effects and labels.
- [Items](./items.md): the default consumables and their effective values, and how to add items.
- [Events](./events.md): net events, the progress callback and custom client events.
- [Troubleshooting](./troubleshooting.md): common problems and how to fix them.
- [API reference](./api/index.md): overview of the API pages.
  - [Server exports](./api/server-exports.md): `AddFood`, `AddDrink`, `AddAlcohol`, `AddCustom` and the `qb-smallresources` layer.
  - [Internals and local functions](./api/internals.md): local functions and `ApplyConsumableDefaults`.
  - [Configuration](./api/configuration.md): resource-wide settings and how the database catalog is seeded and edited.
  - [Use flow, security and edge cases](./api/workflow.md): validation, built-in checks and edge cases.
