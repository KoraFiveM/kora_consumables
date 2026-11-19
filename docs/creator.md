---
title: In-game creator
sidebar_position: 3
---

# In-game consumable creator

The command `/consumableCreator` opens the creator for players with Kora admin permission. It is registered through `Kora.commands.add`, and both the command and its callbacks require the `admin` level through `Kora.permissions.hasLevel`. This accepts `kora_core.admin` or `group.admin`; a `god` level also qualifies. The schema ships explicit item and class seed rows for fresh installs. The database loads before useable handlers are registered and is authoritative afterwards.

The sidebar has separate **Create Item** and **Create Class** pages. On **Create Item**, choose a class, then search the `kora_core` shared item catalog by item name or display label. Images use each shared item's `imageUrl` when available, then fall back to the inventory CDN's `<item name>.webp` URL. Search results and saved consumables use those resolved URLs. The animation selector shows either an emote-name field or the animation-set fields for dictionary, clip, flag, and both props.

The **Classes** view creates and edits class defaults, including the progress label, duration, animation, prop placement, control restrictions, movement, status changes and visual effects. New consumables start with the selected class's defaults and can then be edited individually. Selecting **Edit** opens that consumable in its own left sidebar entry named `<item> Edit`. Item and class status changes use a dropdown plus an amount field; each selected change is added to a list where it can be removed. The item status editor appears below the other item settings when creating or editing a consumable. Item use options are grouped in one checkbox list, and class movement, combat and vehicle restrictions use the same style as Kora Crafting's **Disable While Crafting** setting. A class can only be deleted after its consumables are removed or moved. The `custom` class is reserved for legacy `AddCustom` integrations.

Choose the item's class, progress text, duration, cancellation behavior, item retention, movement restrictions, metadata changes, and optional visual effect. For the animation mode, use the `Emote` option and enter the emote name defined by `kora_emotemenu`, or choose `Animation` and enter a dictionary, clip, flag, and optional first and second props. Each prop can set its model, bone, offset and rotation. The emote resource must be started when an emote is used.

The creator only accepts item keys containing letters, numbers, underscores or hyphens. Metadata changes are limited to -100 through 100. Duration is limited to 250 through 120000 milliseconds. Deleting a consumable disables that useable in the database; it keeps the shared item registered so existing inventory stacks remain valid.

## Database

`kora_consumables_items` uses `(class, item)` as its primary key. `data` stores the complete editable consumable and shared item definition as JSON. `enabled = 0` is a retained deletion marker, which prevents deleted built-in entries from being seeded back on the next start. `kora_consumables_classes` stores each class's defaults and enabled state. `kora_sql` must be started before this resource.
