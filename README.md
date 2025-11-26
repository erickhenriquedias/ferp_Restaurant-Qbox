#  FERP Restaurant System

A comprehensive restaurant management system for QBX Core featuring food crafting, buff systems, employee management.

##  Main Features

- **Multi-Restaurant Support**: Burger Shot, UwU Cafe, Rooster Rest
- **Employee Management**: Duty system, grade-based permissions
- **Food Crafting**: Create custom food items with ingredients
- **Buff System**: 8 ingredient categories providing unique buffs
- **Fridge Preservation**: Food lasts 4x longer in fridges
- **Delivery Boxes**: Unique storage boxes for deliveries
- **Restaurant Cats**: Interactive pets that reduce stress

##  Installation

### What You Need
This script requires these other resources to work:
- `ox_lib` - For menus and notifications
- `ox_target` - For interaction points
- `ox_inventory` - For item management
- `qbx_core` - Your QBX framework
- `qbx_management` - For employee/boss menus

### Step-by-Step Installation

#### 1. Download and Place Files
- Extract the `ferp_restaurant` folder
- Put it in your server's `resources` folder (example: `resources/[ox]/ferp_restaurant`)

#### 2. Database Setup
- Open your database manager (HeidiSQL, phpMyAdmin, etc.)
- Open the `data.sql` file from the script folder
- Copy everything and run it in your database
- This creates the tables and adds sample food items

#### 3. Add Items to Inventory
- Go to your `ox_inventory` folder
- Find and open `data/items.lua`
- Scroll to the bottom
- Copy and paste the items from the "Required Items" section below
- Save the file

#### 4. Configure Server
- Open your `server.cfg` file
- Add this line: `ensure ferp_restaurant`
- Make sure it's AFTER ox_lib, ox_target, ox_inventory, and qbx_core

#### 5. Setup Restaurants
- Open `ferp_restaurant/shared/config.lua`
- Edit the restaurant coordinates to match your server
- Change job names if needed (default: burgershot, uwucafe, roostersrest)

#### 6. Start Server
- Restart your server or type `refresh` then `ensure ferp_restaurant` in console
- Check console for any errors
- If you see `[FERP Restaurant] System initialized`, it's working!

### Testing
1. Go to one of the restaurant locations (coordinates in config.lua)
2. You should see interaction points (ox_target)
3. Use `/job set uwucafe 2` to test management features
4. Try creating a food item in the management menu

## ⚙️ Configuration (Optional)

If you want to customize locations or settings, edit `shared/config.lua`:

### Change Restaurant Locations
Find this section and update the coordinates:
```lua
Config.Restaurants = {
    ['uwu_cafe'] = {
        name = 'UwU Cafe',
        job = 'uwucafe',  -- Job name in your database
        zones = {
            management = {coords = vector3(-583.99, -1058.33, 22.34), radius = 1.5},
            duty = {coords = vector3(-584.08, -1061.35, 22.34), radius = 1.5},
            -- Copy these coordinates from your server
        }
    }
}
```
### Enable/Disable Features
```lua
Config.Debug = false  -- Set to true to see detailed messages in console
Config.BuffSystem.enabled = true  -- Set to false to disable food buffs
```

## 🔧 Required Items

Add these to your `ox_inventory/data/items.lua`:

```lua
['restaurant_main'] = {
    label = 'Main Dish',
    weight = 300,
    stack = false,
    close = true,
    description = 'A delicious main course',
    degrade = 6000,
    client = {
        export = 'ferp_restaurant.useFood'
    }
},

['restaurant_side'] = {
    label = 'Side Dish', 
    weight = 200,
    stack = false,
    close = true,
    description = 'A tasty side dish',
    degrade = 6000,
    client = {
        export = 'ferp_restaurant.useFood'
    }
},

['restaurant_dessert'] = {
    label = 'Dessert',
    weight = 150,
    stack = false, 
    close = true,
    description = 'A sweet dessert',
    degrade = 6000,
    client = {
        export = 'ferp_restaurant.useFood'
    }
},

['restaurant_drink'] = {
    label = 'Beverage',
    weight = 100,
    stack = false,
    close = true,
    description = 'A refreshing drink',
    degrade = 6000,
    client = {
        export = 'ferp_restaurant.useDrink'
    }
},

['restaurant_box'] = {
    label = 'Delivery Box',
    weight = 100,
    stack = false,
    close = true,
    description = 'A restaurant delivery box with unique storage',
    client = {
        export = 'ferp_restaurant.useRestaurantBox'
    }
},

['restaurant_toy_box'] = {
    label = 'Toy Box',
    weight = 50,
    stack = false,
    close = true,
    description = 'A box containing restaurant toys',
    client = {
        export = 'ferp_restaurant.useRestaurantToyBox'
    }
},

-- Basic ingredients (examples - add more as needed)
['beef'] = {
    label = 'Beef',
    weight = 100,
    stack = true,
    close = true,
    description = 'Fresh beef'
},

['chicken'] = {
    label = 'Chicken',
    weight = 100,
    stack = true,
    close = true,
    description = 'Fresh chicken'
},

['lettuce'] = {
    label = 'Lettuce',
    weight = 50,
    stack = true,
    close = true,
    description = 'Fresh lettuce'
},

['tomato'] = {
    label = 'Tomato',
    weight = 50,
    stack = true,
    close = true,
    description = 'Fresh tomato'
},

['cheese'] = {
    label = 'Cheese',
    weight = 50,
    stack = true,
    close = true,
    description = 'Fresh cheese'
},

['milk'] = {
    label = 'Milk',
    weight = 100,
    stack = true,
    close = true,
    description = 'Fresh milk'
},

['bread'] = {
    label = 'Bread',
    weight = 100,
    stack = true,
    close = true,
    description = 'Fresh bread'
},

['flour'] = {
    label = 'Flour',
    weight = 100,
    stack = true,
    close = true,
    description = 'Wheat flour'
},

['sugar'] = {
    label = 'Sugar',
    weight = 50,
    stack = true,
    close = true,
    description = 'White sugar'
},

['salt'] = {
    label = 'Salt',
    weight = 50,
    stack = true,
    close = true,
    description = 'Table salt'
},

['oil'] = {
    label = 'Cooking Oil',
    weight = 100,
    stack = true,
    close = true,
    description = 'Cooking oil'
},
```

## 🎮 How to Use

### For Restaurant Employees

#### Getting Started
1. **Go to the restaurant** (UwU Cafe, Burger Shot, or Rooster's Rest)
2. **Go on duty** - Walk to the duty zone and press the interaction key
3. **Open management** (Grade 2+ only) - Walk to management zone

#### Creating Food Items
1. Open the management menu
2. Click "Food Management" → "Create Food Item"
3. Fill in the form:
   - **Name**: What the food is called (e.g., "UwU Burger")
   - **Description**: Short description
   - **Image URL**: Discord image link (optional)
   - **Food Type**: Main, Side, Dessert, or Drink
   - **Ingredients**: Choose up to 5 ingredients
4. Click create - the item is now in the database

#### Cooking Food
1. Walk to a cooking zone (stove, grill, etc.)
2. Select the food you want to cook
3. **Make sure you have the ingredients in your inventory**
4. Wait for the cooking animation to finish
5. Food appears in your inventory

#### Taking Delivery Boxes
1. Walk to the box zone
2. Interact and take a box
3. Put food items inside the box
4. Give the box to customers or delivery drivers

### For Customers

#### Ordering Food
1. Go to any restaurant
2. Find the "Order Here" interaction point
3. Browse the menu
4. Click on an item to order it
5. Pay and receive your food

#### Eating Food
1. Open your inventory
2. Use the food item
3. You'll receive buffs based on the ingredients
4. Check buffs with `/checkbuffs` command

### Understanding Delivery Boxes
- Each box has a **unique ID** (shows in the item name)
- You can put items inside by using the box
- Boxes can be traded to other players
- Items stay in the box even if you drop it

##  Buff System

Each ingredient category provides different buffs:
- **Protein** → Strength
- **Vegetables** → Stamina + Health
- **Leavening** → Intelligence  
- **Dairy** → Stress Relief
- **Grain** → Extra Hunger
- **Seasoning** → Money Luck
- **Oil** → Stress Relief
- **Sugar** → Movement Speed

More ingredients = stronger buffs (up to 4 ingredients for max strength)

## Support & Commands

### Useful Commands
- `/checkbuffs` - See what buffs you currently have active
- `/cleanup_box_stashes` - (Admin only) Clean up old delivery box storage

### Common Issues

**"Script won't start"**
- Check if all dependencies are installed and started first
- Look at console for error messages
- Make sure `data.sql` was imported to database

**"Can't see interaction points"**
- Make sure ox_target is working
- Check if coordinates in config.lua are correct
- Try going on duty first

**"Cooking doesn't work"**
- Make sure you have the required ingredients in inventory
- Check if the food item is activated (in management menu)
- Make sure you're on duty

**"No buffs when eating"**
- Check if `Config.BuffSystem.enabled = true` in config.lua
- Food needs ingredients to give buffs (drinks/no-ingredient items don't give buffs)

**"Boxes opening wrong storage"**
- Each box has unique storage based on its ID
- Make sure you're clicking "Use" on the box item itself

### Getting Help
If you have issues:
1. Enable debug mode: Set `Config.Debug = true` in config.lua
2. Restart the script
3. Check console (F8) for detailed error messages
4. Check server console for errors

---

## 🔌 Exports (For Developers)

### How to Integrate Buffs in Your Scripts

#### Example 1: Hacking Script - Intelligence Buff Extends Hack Time
```lua
-- In your hacking script (client or server side)
RegisterNetEvent('myhack:startHack', function()
    local baseTime = 30000 -- 30 seconds normally
    
    -- Get intelligence buff multiplier
    local xpMult = exports.ferp_restaurant:GetXPMultiplier(source) -- Server
    -- OR on client: local xpMult = exports.ferp_restaurant:GetXPMultiplier()
    
    -- Calculate bonus time (75% buff = 22.5 extra seconds)
    local bonusTime = baseTime * (xpMult - 1.0)
    local totalTime = baseTime + bonusTime
    
    print('Hack time: ' .. totalTime .. 'ms (base: ' .. baseTime .. ', bonus: ' .. bonusTime .. ')')
    -- Start hack with extended time
    TriggerClientEvent('myhack:client:start', source, totalTime)
end)
```

#### Example 2: Job Script - Money Luck Buff Increases Payment
```lua
-- In your job payout script (server side)
RegisterNetEvent('myjob:completeMission', function()
    local src = source
    local basePay = 500 -- Base payment $500
    
    -- Get total payment with buff bonus
    local totalPay = exports.ferp_restaurant:GetJobPaymentBonus(src, basePay)
    
    -- If player has 100% money luck buff, totalPay = $1000
    -- If no buff, totalPay = $500
    
    exports.qbx_core:GetPlayer(src).Functions.AddMoney('cash', totalPay)
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Mission Complete',
        description = 'You earned $' .. totalPay,
        type = 'success'
    })
end)
```

#### Example 3: Check Any Buff Before Action
```lua
-- Client side - Check if player has strength buff
if exports.ferp_restaurant:HasActiveBuff('strength') then
    local buffStrength = exports.ferp_restaurant:GetBuffStrength('strength')
    print('Player has ' .. buffStrength .. '% strength buff!')
    
    -- Apply bonus damage, health regen, etc.
    local bonusDamage = buffStrength / 100 * 20 -- 20% more damage per 100% buff
end

-- Server side - Check if player has stamina buff
local hasBuff = exports.ferp_restaurant:HasPlayerBuff(playerId, 'stamina')
if hasBuff then
    local buffValue = exports.ferp_restaurant:GetPlayerBuff(playerId, 'stamina')
    -- Give stamina bonus, reduce sprint drain, etc.
end
```

#### Example 4: Reduce Police Response Time with Alert Buff
```lua
-- In your dispatch/police script
RegisterNetEvent('dispatch:robbery', function(coords)
    local responseTime = 120000 -- 2 minutes base response time
    
    -- Players with alert buff (sugar ingredients) get faster response
    for _, playerId in ipairs(GetPlayers()) do
        if exports.ferp_restaurant:HasPlayerBuff(playerId, 'alert') then
            local alertValue = exports.ferp_restaurant:GetPlayerBuff(playerId, 'alert')
            local reduction = (alertValue / 100) * 30000 -- Up to 30s faster
            local playerResponseTime = responseTime - reduction
            
            TriggerClientEvent('dispatch:alert', playerId, coords, playerResponseTime)
        end
    end
end)
```

### Available Buff Types
- `strength` - Protein ingredients (beef, chicken, fish, pork, eggs)
- `stamina` - Vegetable ingredients (lettuce, tomato, broccoli, carrot, spinach, potato)
- `intelligence` - Leavening ingredients (yeast, baking_powder, baking_soda)
- `money_luck` - Seasoning ingredients (salt, pepper, herbs, spices, garlic)
- `alert` - Sugar ingredients (sugar, honey, vanilla)
- `stress-relief` and `hunger` are immediate effects, not timed buffs

### Client-Side Exports

#### Check Employment
```lua
local isEmployed = exports.ferp_restaurant:IsEmployedAtRestaurant('uwu_cafe')
```

#### Get Player Job
```lua
local job = exports.ferp_restaurant:GetPlayerJob()
```

#### Check Active Buffs
```lua
local hasBuff = exports.ferp_restaurant:HasActiveBuff('strength')
local buffStrength = exports.ferp_restaurant:GetBuffStrength('intelligence')
```

#### Get Current Restaurant
```lua
local currentRestaurant = exports.ferp_restaurant:GetCurrentRestaurant()
```

#### Manual Buff Application
```lua
exports.ferp_restaurant:configureBuffs(metadata)
exports.ferp_restaurant:applySpecificBuff('strength', 2)
exports.ferp_restaurant:applyStressRelief(1)
exports.ferp_restaurant:applyHungerBoost(1)
exports.ferp_restaurant:applyMedicalHealing(10)
```

#### Item Usage (ox_inventory integration)
```lua
exports.ferp_restaurant:useFood(data, slot)
exports.ferp_restaurant:useDrink(data, slot)
exports.ferp_restaurant:useRestaurantBox(data, slot)
exports.ferp_restaurant:useRestaurantToyBox(data, slot)
```

### Server-Side Exports

#### Get Player Buffs
```lua
local buffValue = exports.ferp_restaurant:GetPlayerBuff(playerId, 'strength')
local hasBuff = exports.ferp_restaurant:HasPlayerBuff(playerId, 'intelligence')
local allBuffs = exports.ferp_restaurant:GetAllPlayerBuffs(playerId)
```

#### Job Payment Bonus (based on money luck buff)
```lua
-- Example: Player has 50% money luck buff, receives 50% more payment
local basePayment = 1000
local bonus = exports.ferp_restaurant:GetJobPaymentBonus(playerId, basePayment)
-- Returns: 1500 (1000 + 50% bonus)
```

#### XP Multiplier (based on intelligence buff)
```lua
-- Example: Player has 75% intelligence buff, gains 75% more XP
-- If player would normally gain 100 XP, they gain 175 XP instead
local xpMult = exports.ferp_restaurant:GetXPMultiplier(playerId)
-- Returns: 1.75 (1.0 + 0.75 from buff)

-- Use this in your XP system:
local baseXP = 100
local finalXP = baseXP * xpMult  -- 175 XP
```
