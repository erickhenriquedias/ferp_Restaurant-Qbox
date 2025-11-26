Config = {}

-- Restaurant configurations
Config.Restaurants = {
    ['burger_shot'] = {
        name = 'Burger Shot',
        job = 'burgershot',
        blip = {
            sprite = 106,
            color = 1,
            scale = 0.7
        },
        coords = vector3(-1193.54, -893.53, 13.98),
        radius = 35.0,
        zones = {
            management = vector3(-1198.12, -898.64, 13.8),
            duty = vector3(-1177.71, -897.58, 13.8),
            fridge = vector3(-1193.09, -898.68, 13.8),
            shelf = vector3(-1187.64, -896.97, 13.8),
            box = vector3(-1188.89, -897.69, 13.8),
            toy_box = vector3(-1189.5, -898.5, 13.8),
            stash = vector3(-1190.5, -896.5, 13.8), -- Stash geral do restaurante
            cooking = {
                {coords = vector3(-1186.92, -900.52, 13.8), type = 'main'},
                {coords = vector3(-1187.36, -899.79, 13.8), type = 'side'},
                {coords = vector3(-1183.37, -900.83, 13.8), type = 'dessert'},
                {coords = vector3(-1191.52, -897.71, 13.8), type = 'drink'}
            },
            registers = {
                vector3(-1187.56, -893.58, 13.8),
                vector3(-1189.09, -894.63, 13.8),
                vector3(-1190.63, -895.65, 13.8),
                vector3(-1194.92, -907.73, 13.77)
            }
        }
    },
    
    ['uwu_cafe'] = {
        name = 'UwU Cafe',
        job = 'uwucafe',
        blip = {
            sprite = 214,
            color = 8,
            scale = 0.7
        },
        coords = vector3(-579.2, -1062.65, 23.11),
        radius = 75.0,
        zones = {
            management = vector3(-596.22, -1052.89, 22.34),
            duty = vector3(-594.2, -1052.47, 22.34),
            fridge = vector3(-590.6, -1058.59, 22.34),
            shelf = vector3(-587.33, -1059.59, 22.34),
            box = vector3(-585.51, -1055.45, 22.34),
            toy_box = vector3(-586.0, -1056.0, 22.34),
            stash = vector3(-588.16998291016, -1066.8900146484, 22.5), -- Stash geral do restaurante
            cooking = {
                {coords = vector3(-590.97, -1056.51, 22.36), type = 'main'},
                {coords = vector3(-591.21, -1063.16, 22.36), type = 'side'},
                {coords = vector3(-590.94, -1059.73, 22.34), type = 'dessert'},
                {coords = vector3(-587.02, -1061.82, 22.34), type = 'drink'}
            },
            registers = {
                vector3(-584.08, -1058.72, 22.34),
                vector3(-584.02, -1061.48, 22.34)
            }
        }
    },
    
    ['rooster'] = {
        name = 'Rooster\'s Rest',
        job = 'rooster',
        blip = {
            sprite = 106,
            color = 17,
            scale = 0.7
        },
        coords = vector3(-179.35, 314.25, 97.88),
        radius = 50.0,
        zones = {
            management = vector3(-172.47, 297.81, 93.76),
            duty = vector3(-174.24, 300.50, 93.76),
            fridge = vector3(-175.33, 302.44, 93.76),
            shelf = vector3(-179.96, 318.12, 97.88),
            box = vector3(-177.59, 317.44, 97.88),
            toy_box = vector3(-178.0, 316.0, 97.88),
            stash = vector3(-176.0, 318.0, 97.88), -- Stash geral do restaurante
            cooking = {
                {coords = vector3(-168.19, 294.24, 93.76), type = 'main'},
                {coords = vector3(-172.06, 295.15, 93.76), type = 'side'},
                {coords = vector3(-170.12, 296.34, 93.76), type = 'dessert'},
                {coords = vector3(-169.45, 298.12, 93.76), type = 'drink'}
            },
            registers = {
                vector3(-179.96, 318.12, 97.88),
                vector3(-177.59, 317.44, 97.88)
            }
        }
    }
}

-- Food categories that can be created
Config.FoodTypes = {
    'main',      -- Main dishes
    'side',      -- Side dishes
    'dessert',   -- Desserts
    'drink'      -- Drinks
}

-- Restaurant item configuration for ox_inventory
-- These are the 4 base items that will be used with metadata
Config.RestaurantItems = {
    'restaurant_main',    -- Prato Principal
    'restaurant_side',    -- Acompanhamento  
    'restaurant_dessert', -- Sobremesa
    'restaurant_drink'    -- Bebida
}

-- Items allowed in fridge (only food items)
Config.FridgeAllowedItems = {
    'restaurant_main',
    'restaurant_side', 
    'restaurant_dessert',
    'restaurant_drink'
}

-- Maximum ingredients per dish
Config.MaxIngredients = 5

-- Cooking time in milliseconds
Config.CookingTime = 15000

-- Zone settings
Config.ZoneRadius = 1.5
Config.InteractionDistance = 2.0

-- Notification settings
Config.NotificationDuration = 3000

-- Food consumption animations and props (baseado em emotes funcionais)
Config.FoodAnimations = {
    -- Main dishes - sandwich como nos emotes
    main = {
        anim = {
            dict = 'mp_player_inteat@burger',
            name = 'mp_player_int_eat_burger',
            flags = 49
        },
        prop = {
            model = 'prop_sandwich_01',
            bone = 18905,
            coords = vector3(0.03, 0.02, -0.02),
            rotation = vector3(0.0, 0.0, 0.0) -- reto e centralizado
        },
        duration = 8000
    },
    
    -- Side dishes - chips refinado
    side = {
        anim = {
            dict = 'mp_player_inteat@burger',
            name = 'mp_player_int_eat_burger',
            flags = 49
        },
        prop = {
            model = 'prop_sandwich_01',
            bone = 18905,
            coords = vector3(0.03, 0.02, -0.02),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        duration = 15000
    },
    
    -- Desserts - donut refinado
    dessert = {
        anim = {
            dict = 'mp_player_inteat@burger',
            name = 'mp_player_int_eat_burger',
            flags = 49
        },
        prop = {
            model = 'prop_amb_donut',
            bone = 18905,
            coords = vector3(0.03, 0.03, 0.001),
            rotation = vector3(-10.0, 0.0, 90.0) -- em pé e centralizado
        },
        duration = 6000
    },
    
    -- Drinks - bottle como nos emotes
    drink = {
        anim = {
            dict = 'mp_player_intdrink',
            name = 'loop_bottle',
            flags = 49
        },
        prop = {
            model = 'prop_ld_flow_bottle',
            bone = 18905,
            coords = vector3(0.12, 0.008, 0.03),
            rotation = vector3(240.0, -60.0, 0.0)
        },
        duration = 6000
    }
}

-- Buff system configuration
Config.BuffSystem = {
    enabled = true,          -- Ativar/desativar sistema de buffs
    maxBuffs = 5,           -- Máximo de buffs simultâneos
    stackable = false,      -- Buffs do mesmo tipo não acumulam
    debugMode = false,      -- Debug para desenvolvimento (DESABILITADO EM PRODUÇÃO)
    vegetableHealLimit = 50 -- Máximo de vida que vegetables podem recuperar (50% de 100)
}

-- Ingredient categories mapping (centralized configuration)
Config.Ingredients = {
    -- Proteins (Strength buff)
    ['beef'] = { category = 'protein', label = 'Beef' },
    ['chicken'] = { category = 'protein', label = 'Chicken' },
    ['pork'] = { category = 'protein', label = 'Pork' },
    ['fish'] = { category = 'protein', label = 'Fish' },
    ['eggs'] = { category = 'protein', label = 'Eggs' },
    ['beans'] = { category = 'protein', label = 'Beans' },
    ['wagyu'] = { category = 'protein', label = 'Wagyu Beef' },
    ['caviar'] = { category = 'protein', label = 'Caviar' },
    
    -- Vegetables (Stamina buff + Medical healing)
    ['lettuce'] = { category = 'vegetables', label = 'Lettuce' },
    ['tomato'] = { category = 'vegetables', label = 'Tomato' },
    ['onion'] = { category = 'vegetables', label = 'Onion' },
    ['potato'] = { category = 'vegetables', label = 'Potato' },
    ['carrot'] = { category = 'vegetables', label = 'Carrot' },
    ['broccoli'] = { category = 'vegetables', label = 'Broccoli' },
    ['spinach'] = { category = 'vegetables', label = 'Spinach' },
    ['peppers'] = { category = 'vegetables', label = 'Peppers' },
    ['mushrooms'] = { category = 'vegetables', label = 'Mushrooms' },
    
    -- Leavening (Intelligence buff)
    ['yeast'] = { category = 'leavening', label = 'Yeast' },
    ['baking_powder'] = { category = 'leavening', label = 'Baking Powder' },
    ['baking_soda'] = { category = 'leavening', label = 'Baking Soda' },
    
    -- Dairy (Immediate stress relief)
    ['milk'] = { category = 'dairy', label = 'Milk' },
    ['cheese'] = { category = 'dairy', label = 'Cheese' },
    ['butter'] = { category = 'dairy', label = 'Butter' },
    ['cream'] = { category = 'dairy', label = 'Cream' },
    ['yogurt'] = { category = 'dairy', label = 'Yogurt' },
    
    -- Grains (Immediate hunger boost)
    ['rice'] = { category = 'grain', label = 'Rice' },
    ['wheat'] = { category = 'grain', label = 'Wheat' },
    ['bread'] = { category = 'grain', label = 'Bread' },
    ['pasta'] = { category = 'grain', label = 'Pasta' },
    ['oats'] = { category = 'grain', label = 'Oats' },
    ['corn'] = { category = 'grain', label = 'Corn' },
    
    -- Seasonings (Money luck buff)
    ['salt'] = { category = 'seasoning', label = 'Salt' },
    ['pepper'] = { category = 'seasoning', label = 'Pepper' },
    ['herbs'] = { category = 'seasoning', label = 'Herbs' },
    ['spices'] = { category = 'seasoning', label = 'Spices' },
    ['garlic'] = { category = 'seasoning', label = 'Garlic' },
    ['ginger'] = { category = 'seasoning', label = 'Ginger' },
    ['paprika'] = { category = 'seasoning', label = 'Paprika' },
    ['cumin'] = { category = 'seasoning', label = 'Cumin' },
    ['truffle'] = { category = 'seasoning', label = 'Black Truffle' },
    ['saffron'] = { category = 'seasoning', label = 'Saffron' },
    ['cinnamon'] = { category = 'seasoning', label = 'Cinnamon' },
    
    -- Oils (Immediate stress relief)
    ['oil'] = { category = 'oil', label = 'Cooking Oil' },
    ['olive_oil'] = { category = 'oil', label = 'Olive Oil' },
    ['coconut_oil'] = { category = 'oil', label = 'Coconut Oil' },
    ['sesame_oil'] = { category = 'oil', label = 'Sesame Oil' },
    
    -- Sugars (Speed/Alert buff) 
    ['sugar'] = { category = 'sugar', label = 'Sugar' },
    ['honey'] = { category = 'sugar', label = 'Honey' },
    ['maple_syrup'] = { category = 'sugar', label = 'Maple Syrup' },
    ['brown_sugar'] = { category = 'sugar', label = 'Brown Sugar' },
    ['vanilla'] = { category = 'sugar', label = 'Vanilla' },
    
    -- Additional ingredients (no specific buff category)
    ['flour'] = { category = 'grain', label = 'Flour' },
    ['cocoa'] = { category = 'sugar', label = 'Cocoa Powder' },
    ['chocolate'] = { category = 'sugar', label = 'Chocolate' },
    ['coconut'] = { category = 'grain', label = 'Coconut' },
    ['lemon'] = { category = 'vegetables', label = 'Lemon' },
    ['lime'] = { category = 'vegetables', label = 'Lime' },
    ['orange'] = { category = 'vegetables', label = 'Orange' },
    ['apple'] = { category = 'vegetables', label = 'Apple' },
    ['banana'] = { category = 'vegetables', label = 'Banana' },
    ['strawberry'] = { category = 'vegetables', label = 'Strawberry' },
    ['blueberry'] = { category = 'vegetables', label = 'Blueberry' },
    ['nuts'] = { category = 'protein', label = 'Mixed Nuts' },
    ['almonds'] = { category = 'protein', label = 'Almonds' }
}

-- Stash configuration (general storage for each restaurant)
Config.Stash = {
    slots = 50,         -- Number of slots
    weight = 100000,    -- Weight limit (100kg)
    label = 'Stash'
}

-- Debug mode (DISABLE IN PRODUCTION)
Config.Debug = false
