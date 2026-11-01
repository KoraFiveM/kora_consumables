Config = {}
Config.Consumables = {}

-- When true (default) a configured prop whose model is not a valid game model is skipped,
-- so the item still gets used. Set false to let the progress bar raise the error instead.
Config.skipInvalidProps = true
-- Prints a client line whenever a prop is skipped or a progress bar fails.
Config.Debug = false
-- true (default): the player can walk while eating, drinking or smoking; the animation is
-- played on the upper body (anim flag 49) and movement is not frozen. Combat and vehicle
-- restrictions from the item defaults still apply. false: freeze movement for the whole use.
-- May also be a table per class, e.g. { food = true, drink = true, smoke = false, liquor = false }
-- (classes left out count as true). A single item can override this with allowMovement = true/false.
Config.allowMovement = true

-- Hand the prop is attached to, matching the hand the eat/drink animation raises to the mouth.
-- 'left' or 'right', or a table per class; classes left out use their default
-- (drink = 'left', food = 'left', liquor = 'right'). Each hand has its own bone, offset and rotation.
Config.propHand = { drink = 'left', food = 'left', liquor = 'right' }
-- Optional bone override (a bone id such as 18905 SKEL_L_Hand, or a table per class) applied on top of
-- the chosen hand. nil keeps the hand's default bone. A single item can set prop.bone, prop.offset
-- and prop.rotation to override everything.
Config.propBone = nil

Config.Consumables.drink = {
    water = {},
    coffee = {prop = {model = "p_amb_coffeecup_01"}},
    -- Also handled instantly by kora_inventory; listed so they get the progress bar.
    water_bottle = {status = {thirst = 40}},
    soda = {prop = {model = "prop_ecola_can"}, status = {thirst = 25, stress = -3}},
}

Config.Consumables.food = {
    sandwich = {prop = {model = "prop_sandwich_01"}},
    chips = {},
    egg_sandwich = {prop = {model = "prop_sandwich_01"}},
    hot_dog = {prop = {model = "prop_cs_hotdog_01"}},
    bread = {status = {hunger = 20}},
    chocolate_bar = {prop = {model = "prop_choc_ego"}, status = {hunger = 15, stress = -5}},
}

Config.Consumables.smoke = {
    cigarette = {effects = {visual = 'none', duration = 0}},
    ak47_joint = {},
    amnesia_joint = {},
    blue_dream_joint = {},
    og_kush_joint = {},
    purple_haze_joint = {},
    skunk_joint = {},
}

Config.Consumables.liquor = {
    ambeer = {},
    beer = {},
    beer_dusche = {},
    beer_logger = {},
    beer_pisswaser = {},
    beer_pisswaser2 = {},
    beer_posswaser3 = {},
    beer_posswaser4 = {},
    whiskey = {},
    vodka = {},
    wine = {},
}
