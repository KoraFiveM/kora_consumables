---
title: Configuration
sidebar_position: 4
---

# Configuration

Consumable items and class defaults are stored in the database. The schema in `server/schema.lua` contains the shipped seed rows for a fresh install. After startup, SQL is authoritative; create and edit entries with `/consumableCreator`. `Config.Consumables` and `Config.ConsumableClasses` start as empty runtime tables and are filled from the database on the server, then synchronized to clients.

`shared/Config.lua` contains resource-wide behavior settings. They are not the item catalog and do not need to be changed when adding consumables.

## Resource settings

| Setting | Default | Description |
| --- | --- | --- |
| `Config.skipInvalidProps` | `true` | Skip an invalid prop model so the item can still be used. Set false to let the progress bar fail the use. |
| `Config.Debug` | `false` | Write diagnostic messages through `Kora.logging.debug` when a prop is skipped or progress fails. |
| `Config.DrunkWalk` | `true` | Apply the drunk movement clipset while the buzzed effect is active. |
| `Config.DrunkWalkClipset` | `'move_m@drunk@verydrunk'` | Movement clipset for the buzzed effect. |
| `Config.DrunkNotify` | `true` | Show the drunk notification when the buzzed effect starts. |
| `Config.applyStatusOn` | `'complete'` | Live Kora Lib enum. `complete` applies effects only after the progress bar finishes; `start` applies them before the bar. |

## Editing the catalog

Use the creator to manage item and class values, including labels, duration, animation or emote, props, cancellation, movement restrictions, status changes and visual effects. Changes are saved to `kora_consumables_items` or `kora_consumables_classes` and are synchronized to clients.

The shipped item and class data are explicit seed rows in `server/schema.lua`. The SQL seed uses insert-ignore behavior, so it adds missing defaults on a fresh install or upgrade without overwriting saved edits or disabled rows.

Other server resources can add consumables through the [legacy exports](./server-exports.md). Those additions are persisted to SQL as well.

## Source files

- `shared/Config.lua` contains resource-wide behavior settings and initializes empty runtime catalog tables.
- `shared/deafaults.lua` contains the locale-aware label and class-default merge helpers. The filename spelling is retained in the resource.
- `server/schema.lua` declares the tables and shipped seed rows.
- `server/data.lua` loads the database catalog before useables are registered.
- `server/creator.lua` validates and saves creator changes.
