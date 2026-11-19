Config = {}
Config.Consumables = {}
Config.ConsumableClasses = {}

-- When true (default) a configured prop whose model is not a valid game model is skipped,
-- so the item still gets used. Set false to let the progress bar raise the error instead.
Config.skipInvalidProps = true
-- Prints a client line whenever a prop is skipped or a progress bar fails.
Config.Debug = false
-- true (default): alcohol also gives a drunk walking style for as long as the buzzed effect lasts.
Config.DrunkWalk = true
-- Movement clipset used for the drunk walk.
Config.DrunkWalkClipset = 'move_m@drunk@verydrunk'
-- true (default): show a "Drunk" notification when the buzzed effect starts.
Config.DrunkNotify = true
