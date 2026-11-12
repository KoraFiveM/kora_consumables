# kora_consumables agent guide

`kora_consumables` is a Kora FiveM resource for server-validated food, drink, liquor and smoke items. It uses a client progress bar, prop and animation, then the server applies status changes and screen effects. It also provides the `qb-smallresources` `AddFood`/`AddDrink`/`AddAlcohol`/`AddCustom` exports. Layout: `shared/Config.lua` (config and items), `shared/deafaults.lua` (class defaults and kora_lib config registration), `server/server.lua` (useables, item removal, status, exports, sync), `client/client.lua` (progress callback, props, movement and visuals), `test/` (offline Lua tests, `test/run.sh`), `tests/` (kora_qa Gherkin scenarios), `items/` (reference QBCore item list and images).

## Documentation

User-facing documentation lives in `docs/` (Markdown, published via the Kora Docusaurus site, kora_docs_next). Read `docs/index.md` first; it has the overview and a documentation map. Layout: `index.md` (hub), `installation.md` (install, requirements, database, commands: none), `how-to-use.md` (use flow, adding items), `api/` (`server-exports.md` for the exports, `configuration.md` for every `Config` option and item field, `internals.md`, `workflow.md`, plus `index.md`), and topic pages `how-it-works.md`, `items.md`, `events.md`, `troubleshooting.md`. There is no `commands.md` because the resource has no commands. Update the page that matches the change.

When you add, change, or remove a feature, config option, command, export, event, item, permission, or database table/column, update the matching page in `docs/` in the same change. Keep docs accurate to the code; do not document behaviour that does not exist.

Docs rules: plain Markdown with `title`/`sidebar_position` front matter (no `id`/`slug`), relative links only between docs pages, assets inside `docs/`, fenced code blocks with a language, and no raw `<`, `>`, `{`, `}` outside code (pages are parsed as MDX). The release version comes from `fxmanifest.lua`'s `version` field.
