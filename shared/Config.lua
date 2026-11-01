Config = {}
Config.Consumables = {}

Config.Consumables.drink = {
    water = {},
    coffee = {},
    -- Also handled instantly by kora_inventory; listed so they get the progress bar.
    water_bottle = {status = {thirst = 40}},
    soda = {status = {thirst = 25, stress = -3}},
}

Config.Consumables.food = {
    sandwich = {},
    chips = {},
    egg_sandwich = {},
    hot_dog = {},
    bread = {status = {hunger = 20}},
    chocolate_bar = {status = {hunger = 15, stress = -5}},
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