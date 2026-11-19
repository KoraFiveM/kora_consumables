---
title: How it works
sidebar_position: 6
---

# How it works

## Startup

1. `shared/Config.lua` defines resource-wide behavior settings and initializes empty runtime catalog tables.
2. `server/schema.lua` declares the item and class tables and includes the shipped catalog as explicit seed rows.
3. `server/data.lua` asks `kora_sql` to create the tables, loads the database rows, fills locale-based class labels and applies class defaults. The database is authoritative after seeding.
4. The server registers every active database item with `exports.kora_core:createUseable`. Before that, it registers a `cigarette` shared item if no resource has defined one.
5. `kora_inventory` has its own instant handlers for some of the same items, such as `water_bottle`, `sandwich` and `beer`. To keep this resource's handlers active, the server registers all useables again whenever `kora_inventory` starts.
6. When the client starts, it requests the active database catalog. The server sends the same catalog to clients when creator edits are saved or another resource adds an item through the [exports](./api/server-exports.md).

When an item is created or edited, the server saves it to SQL, updates its in-memory row, registers a fresh usable handler with Kora Core, and broadcasts the current item and class catalog to every client.

## Using an item

When a player uses a configured item from the inventory:

1. The server checks whether the player already has a use in progress. If so, it ignores the new use and the useable callback returns `false`.
2. With `applyStatusOn = 'complete'` (default):
   1. The server triggers the client callback `kora_consumables:progress` with the payload `{ class, item }` and waits for the result.
   2. The client looks up the item in its synchronized database catalog. It drops the prop if its model is invalid (see `skipInvalidProps`). It applies the movement rules and starts `Kora.progressbar.start` with the label, duration, animation, prop, `disable` flags, `canCancel`, `useWhileDead` and `emote`.
   3. If the player finishes the bar, the client starts the item's screen effect, if any, and returns `true`. If the player cancels or the progress bar fails, it returns `false`.
   4. If the result is not `true`, nothing happens: the item is kept and no status is applied.
   5. The server also checks timing. If the result arrived sooner than the item's `duration` (default `1000` ms) minus 250 ms, the use is ignored and a line is printed to the server console.
   6. Otherwise, the server consumes the item and applies its status (see below).
3. With `applyStatusOn = 'start'`, the server consumes the item and applies its status right away, then shows the progress bar. Cancelling the bar does not undo the item use or status changes. The screen effect still runs only if the bar finishes.

### Consuming the item

- If the used item has an `info.uses` number, it is decremented and saved with `exports['qb-inventory']:SetItemData`. The item is removed only when `uses` reaches 0. If the save fails, nothing is applied.
- If the item has no `info.uses` and is not marked `keep = true`, one is removed from the used slot with `exports.kora_inventory:removeItem`. If the removal fails, for example because the player no longer has the item, nothing is applied.
- Items with `keep = true` and no `uses` are not removed.

### Applying status

Each key in the item's `status` table is added to the matching player metadata value through `exports.kora_core:incrementMetaData` and clamped to 0-100. Supported keys are `hunger`, `thirst`, `stress`, `health`, `armor`, `drunk` and `high`. Negative values lower the value. Other keys are ignored.

If the item has an `event` field, the server sends that client event to the player afterwards with the item name as its argument. See [Events](./events.md).

## Movement while using

On the client, movement rules are resolved in this order:

1. The item's own `allowMovement` (`true` or `false`), if set.
2. The database class's `allowMovement`, if set.
3. If neither is set, movement is allowed.

When movement is allowed, `disable.move` is changed to `false` for that use. Flags 16 (upper body) and 32 (player control) are added to the animation flag, with a base of `1` if the animation has no flag. Combat and vehicle restrictions are not changed. A `disable.vehicle` value is also copied to `disable.car` for the progress bar.

## Screen effects

When the bar finishes, the client starts the item's `effects` according to `effects.visual`:

| `visual` | Effect |
| --- | --- |
| `none` (or no `effects`) | No effect. |
| `buzzed` | Built-in drunk effect: timecycle `drug_drive_blend01` at strength 0.6 and `DRUNK_SHAKE` camera shake. If `Config.DrunkWalk` is on, it also sets the `Config.DrunkWalkClipset` walk style; if `Config.DrunkNotify` is on, it shows a "Drunk" notification. Everything is reset after `duration`. If another buzzed effect starts, its timer replaces the earlier one. |
| `alien`, `coke`, `crack`, `meth`, `trevor` | Calls `Kora.visuals.<name>(duration)` from kora_lib. |

`effects.duration` is in milliseconds and defaults to 15000.

## Label

If an item has no `label`, the server uses its locale-aware class label followed by the item's shared-item label before syncing the catalog. The client can also complete a prefix label when its `kora_core` item registry becomes available.
