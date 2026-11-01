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

-- Per-item attachment. A prop table may set model, bone, offset {x,y,z} (metres, in the bone's local
-- space) and rotation {x,y,z} (degrees); anything left out is inherited from the class default for the
-- hand chosen by Config.propHand. Setting only offset/rotation keeps the item on that hand's bone and
-- Config.propHand/propBone still apply. Setting bone pins the item to that bone (the coffee below).
-- Values here are starting points and may need a tweak in game; edit offset/rotation, no code change.
Config.Consumables.drink = {
    -- Bottle held in the left palm (PH_L_Hand 60309); the default zero offset sat it too high.
    water = {prop = {offset = {x = 0.0, y = 0.0, z = -0.03}, rotation = {x = 0.0, y = 0.0, z = 0.0}}},
    -- Same animation and right-hand placement as the kora_emotemenu 'coffee' emote (known-good there):
    -- amb@world_human_drinking@coffee@male@idle_a idle_c with the cup on SKEL_R_Hand 28422.
    coffee = {
        anim = {dict = "amb@world_human_drinking@coffee@male@idle_a", clip = "idle_c"},
        prop = {model = "p_amb_coffeecup_01", bone = 28422,
            offset = {x = 0.0, y = 0.0, z = 0.0}, rotation = {x = 0.0, y = 0.0, z = 130.0}},
    },
    -- Also handled instantly by kora_inventory; listed so they get the progress bar.
    water_bottle = {status = {thirst = 40}, prop = {offset = {x = 0.0, y = 0.0, z = -0.03}, rotation = {x = 0.0, y = 0.0, z = 0.0}}},
    -- Same placement as the common 'soda' emote (rpemotes/dpemotes): the coffee idle_c animation with the
    -- can on SKEL_R_Hand 28422, rotated 130 on z, so the hand wraps the can.
    soda = {
        anim = {dict = "amb@world_human_drinking@coffee@male@idle_a", clip = "idle_c"},
        prop = {model = "prop_ecola_can", bone = 28422,
            offset = {x = 0.0, y = 0.0, z = 0.0}, rotation = {x = 0.0, y = 0.0, z = 130.0}},
        status = {thirst = 25, stress = -3},
    },
}

Config.Consumables.food = {
    sandwich = {prop = {model = "prop_sandwich_01", offset = {x = 0.0, y = 0.0, z = -0.02}, rotation = {x = 0.0, y = 0.0, z = 0.0}}},
    chips = {},
    egg_sandwich = {prop = {model = "prop_sandwich_01", offset = {x = 0.0, y = 0.0, z = -0.02}, rotation = {x = 0.0, y = 0.0, z = 0.0}}},
    hot_dog = {prop = {model = "prop_cs_hotdog_01", offset = {x = 0.0, y = 0.0, z = -0.02}, rotation = {x = 0.0, y = 0.0, z = 0.0}}},
    bread = {status = {hunger = 20}, prop = {offset = {x = 0.0, y = 0.0, z = -0.02}, rotation = {x = 0.0, y = 0.0, z = 0.0}}},
    chocolate_bar = {
        prop = {model = "prop_choc_ego", offset = {x = 0.0, y = 0.0, z = -0.02}, rotation = {x = 0.0, y = 0.0, z = 0.0}},
        status = {hunger = 15, stress = -5},
    },
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
