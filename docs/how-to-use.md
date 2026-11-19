---
title: How to use
sidebar_position: 3
---

# How to use

Consumable items and their class defaults are managed in the in-game creator and stored in SQL. Open `/consumableCreator` as a Kora admin to create or edit entries. The item must exist in the `kora_core` shared item catalog; the creator can register a new shared item when needed.

## What happens when a player uses an item

- Kora Core calls the useable handler registered by `registerUseable`. If the player already has a use in flight (`using[src]`), the handler returns `false` and nothing happens.
- The server triggers the Kora callback `kora_consumables:progress` on that player with `{ class, item }`. The client looks the item up in its database-synchronized catalog and starts `Kora.progressbar.start`.
- If the item has `effects`, the client plays the visual only when the progress bar completes.
- The client reports the result. In the default mode (`Config.applyStatusOn = 'complete'`) the server ignores a result that arrives faster than the item's duration minus 250 ms and applies nothing.
- Otherwise the server consumes the item, applies its status values through `exports.kora_core:incrementMetaData`, and fires `data.event` on the player's client if configured.
- With `Config.applyStatusOn = 'start'`, item consumption and status changes happen before the progress bar.

## Create and edit consumables

1. Open `/consumableCreator` as a Kora admin.
2. Create a class or choose one that already exists.
3. Create an item, select its shared item, and set the animation or emote, props, cancel and movement options, statuses, and effects.
4. Save. The creator writes the row to SQL, replaces that item's Kora Core usable handler with the updated data, and synchronizes the full catalog to all clients.

See [Creator](./creator.md) for the full editor details.

## Add an item from another resource

Server resources written for qb-smallresources can call the legacy exports. The item must already exist in the shared item catalog and must not already be configured.

```lua title="server.lua"
local ok, reason = exports.kora_consumables:AddFood('burrito', 35)
if not ok then
    Kora.logging.warn('food.add_failed', 'Food was not added', {item = 'burrito', reason = tostring(reason)})
end
```

These exports persist the consumable in SQL. See [Server exports](./api/server-exports.md).

## Item classes

Class defaults are database rows editable from the creator. New items inherit the selected class values for fields they leave unset.

## More detail

- [How it works](./how-it-works.md): startup, movement, screen effects and labels.
- [Server exports](./api/server-exports.md) and [Configuration](./api/configuration.md): API and resource-wide settings.
- [Items](./items.md): shipped catalog and shared item requirements.
