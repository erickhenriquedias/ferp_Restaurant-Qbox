# FERP Restaurant System

> **Advanced Restaurant Management System for QBX Core**

[![Performance](https://img.shields.io/badge/Resmon-0.00ms-success)]()
[![Framework](https://img.shields.io/badge/Framework-QBX%20Core-blue)]()
[![Version](https://img.shields.io/badge/Version-1.8.0-brightgreen)]()

---

##  Why Choose FERP Restaurant?

### Performance Optimized
- Ultra-low resource usage (0.00ms average)
- Efficient database queries with caching
- Optimized for busy servers

### Highly Customizable
- Easy-to-edit configuration files
- 8 unique buff categories
- Support for unlimited restaurants
- Dynamic food creation system

### Developer Friendly
- Comprehensive export system
- Full documentation with examples
- Clean, maintainable code structure
- Active development & support

### Business Ready
- Complete employee management
- Grade-based permissions
- Fridge preservation mechanics

##  Main Features

###  Multi-Restaurant Support
Pre-configured for **Burger Shot**, **UwU Cafe**, and **Rooster's Rest** with easy setup for additional locations.

###  Advanced Employee Management
- Duty system with on/off status
- Grade-based permissions (management access for Grade 2+)
- Boss menu integration via `qbx_management`
- Activity tracking and logging

###  Dynamic Food Crafting System
- Create unlimited custom food items in-game
- Support for 4 food categories (Main, Side, Dessert, Drink)
- Up to 5 ingredients per recipe
- 70+ pre-configured ingredients
- Real-time cooking animations with props
- Ingredient requirement checking

###  Intelligent Buff System
**8 Ingredient Categories with Unique Effects:**

| Category | Buff Type | Effect | Examples |
|----------|-----------|--------|----------|
|  **Protein** | Strength | Combat/Physical boost | Beef, Chicken, Fish, Wagyu |
|  **Vegetables** | Stamina + Health | Regeneration & endurance | Lettuce, Tomato, Spinach |
|  **Leavening** | Intelligence | XP & skill boost | Yeast, Baking Powder |
|  **Dairy** | Stress Relief | Immediate stress reduction | Milk, Cheese, Cream |
|  **Grain** | Hunger Boost | Extra food value | Rice, Bread, Pasta |
|  **Seasoning** | Money Luck | Payment bonuses | Salt, Herbs, Truffle, Saffron |
|  **Oil** | Stress Relief | Calming effect | Olive Oil, Coconut Oil |
|  **Sugar** | Alert/Speed | Movement & reaction time | Sugar, Honey, Vanilla |

**Buff Mechanics:**
- Buff strength scales with ingredient count (1-4 ingredients = 25%-100% strength)
- Non-stackable (prevents buff abuse)
- Configurable durations
- Admin commands for monitoring
- Full export system for integration

###  Unique Delivery Box System
- Each box generates a unique ID
- Persistent storage tied to box instance
- Tradeable between players
- Perfect for delivery roleplay
- Anti-duplication protection

###  Smart Fridge Preservation
- Food lasts **4x longer** when stored in fridges
- Automatic decay management
- Restaurant-specific storage
- Weight and slot configuration

###  Interactive Restaurant Cats
- Stress-reducing pet interactions
- Cooldown system to prevent spam
- Adds immersive roleplay elements

###  Toy Box System
- Random toy rewards for customers
- Collectible items system
- Enhances customer experience

---

##  Dependencies

Ensure these resources are installed and started **before** FERP Restaurant:

| Resource | Version | Purpose | Required |
|----------|---------|---------|----------|
| [ox_lib](https://github.com/overextended/ox_lib) | Latest | UI menus & notifications | ✅ Yes |
| [ox_target](https://github.com/overextended/ox_target) | Latest | Interaction system | ✅ Yes |
| [ox_inventory](https://github.com/overextended/ox_inventory) | Latest | Item management | ✅ Yes |
| [qbx_core](https://github.com/Qbox-project/qbx_core) | Latest | Framework core | ✅ Yes |
| [qbx_management](https://github.com/Qbox-project/qbx_management) | Latest | Boss menus | ✅ Yes |

---

##  Installation Guide

### Step 1: Download & Extract
```bash
# Extract to your resources folder
resources/[ox]/ferp_restaurant/
```

### Step 2: Database Import
Execute the `data.sql` file in your MySQL database:
```sql
-- Creates necessary tables and sample food items
-- Tables: ferp_restaurant_items, ferp_restaurant_box_stashes
```

**Using HeidiSQL/phpMyAdmin:**
1. Open your database manager
2. Select your server database
3. Go to Query/SQL tab
4. Copy contents of `data.sql`
5. Execute the query

### Step 3: Configure Inventory Items
### Step 3: Configure Inventory Items
Add required items to `ox_inventory/data/items.lua`:

```lua
-- Core restaurant items (copy to items.lua)
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
-- See "Required Items" section below for complete list
```

### Step 4: Server Configuration
Edit your `server.cfg`:
```cfg
# Ensure dependencies load first
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure qbx_core
ensure qbx_management

# Load FERP Restaurant
ensure ferp_restaurant
```

### Step 5: Customize Settings (Optional)
Edit `shared/config.lua` to customize:
- Restaurant locations & coordinates
- Job names (default: burgershot, uwucafe, rooster)
- Zone radiuses and interaction distances
- Buff durations and strengths
- Cooking times and animations
- Debug mode settings

### Step 6: Start Server
```bash
# In server console
refresh
ensure ferp_restaurant

# Check for success message
# [FERP Restaurant] System initialized
```

###  Verification
Test the installation:
1. Join your server
2. Go to a restaurant location (coords in config.lua)
3. Look for ox_target interaction points
4. Set your job: `/job set uwucafe 2`
5. Try accessing management menu
6. Create a test food item

---

##  Configuration Guide

### Restaurant Locations
Customize restaurant coordinates in `shared/config.lua`:

```lua
Config.Restaurants = {
    ['uwu_cafe'] = {
        name = 'UwU Cafe',
        job = 'uwucafe',  -- Must match job in database
        blip = {
            sprite = 214,
            color = 8,
            scale = 0.7
        },
        coords = vector3(-579.2, -1062.65, 23.11),  -- Main restaurant location
        radius = 75.0,  -- Detection radius
        zones = {
            management = vector3(-596.22, -1052.89, 22.34),
            duty = vector3(-594.2, -1052.47, 22.34),
            fridge = vector3(-590.6, -1058.59, 22.34),
            shelf = vector3(-587.33, -1059.59, 22.34),
            box = vector3(-585.51, -1055.45, 22.34),
            toy_box = vector3(-586.0, -1056.0, 22.34),
            stash = vector3(-588.17, -1066.89, 22.5),
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
    }
}
```

### Buff System Settings
```lua
Config.BuffSystem = {
    enabled = true,          -- Enable/disable buff system
    maxBuffs = 5,           -- Max simultaneous buffs per player
    stackable = false,      -- Prevent buff stacking abuse
    debugMode = false,      -- Debug logs (disable in production)
    vegetableHealLimit = 50 -- Max health recovery from vegetables (50%)
}
```

### Cooking & Interaction
```lua
Config.CookingTime = 15000               -- Cooking duration (15 seconds)
Config.MaxIngredients = 5                -- Max ingredients per recipe
Config.ZoneRadius = 1.5                  -- ox_target zone size
Config.InteractionDistance = 2.0         -- Interaction range
Config.NotificationDuration = 3000       -- Notification display time
```

### Food Animations
Customize consumption animations and props:
```lua
Config.FoodAnimations = {
    main = {
        anim = {
            dict = 'mp_player_inteat@burger',
            name = 'mp_player_int_eat_burger',
            flags = 49
        },
        prop = {
            model = 'prop_sandwich_01',
            bone = 18905,  -- Right hand
            coords = vector3(0.03, 0.02, -0.02),
            rotation = vector3(0.0, 0.0, 0.0)
        },
        duration = 8000
    },
    -- Configure for side, dessert, drink...
}
```

### Debug Mode
```lua
Config.Debug = true  -- Enable for troubleshooting
-- Shows detailed console logs for:
-- - Buff applications
-- - Food creation/consumption
-- - Database queries
-- - Zone interactions
```

---

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

## 🎮 Usage Guide

### 👨‍💼 For Restaurant Employees

#### Clock In/Out
1. Navigate to the duty zone (check config for coordinates)
2. Interact with ox_target point
3. Toggle duty status on/off

#### Create New Food Items (Grade 2+ Required)
1. Go to management zone
2. Open management menu
3. Select **"Food Management"** → **"Create Food Item"**
4. Fill in details:
   - **Name**: Display name (e.g., "UwU Special Burger")
   - **Description**: Item description (shows in inventory)
   - **Image URL**: Discord CDN image link (optional)
   - **Type**: Main / Side / Dessert / Drink
   - **Ingredients**: Select up to 5 ingredients (determines buffs)
5. Confirm creation
6. Item is now available in cooking menu

#### Cook Food
1. Ensure you have required ingredients in inventory
2. Go to appropriate cooking station:
   - **Main dishes**: Main cooking zone (grill/stove)
   - **Side dishes**: Side prep zone
   - **Desserts**: Dessert station
   - **Drinks**: Drink station
3. Interact and select recipe
4. Wait for cooking animation (~15 seconds)
5. Receive finished food in inventory

#### Manage Delivery Boxes
1. Go to box zone
2. Take a delivery box (unique ID generated)
3. Open box and place food items inside
4. Give box to delivery drivers or customers
5. Each box maintains its own persistent storage

#### Use Restaurant Stash
- Access shared restaurant storage at stash zone
- 50 slots, 100kg capacity
- Shared with all employees
- Perfect for ingredient storage

### 👤 For Customers

#### Order Food
1. Visit any configured restaurant
2. Find the register/order zone
3. Browse available menu items
4. Purchase desired food
5. Receive item in inventory

#### Consume Food & Gain Buffs
1. Open inventory (`I` or configured key)
2. Use food item
3. Watch consumption animation
4. Buffs are automatically applied based on ingredients
5. Check active buffs: `/checkbuffs`

#### Understanding Buffs
- **Buff Strength**: Based on ingredient count
  - 1 ingredient = 25% buff strength
  - 2 ingredients = 50% buff strength
  - 3 ingredients = 75% buff strength
  - 4+ ingredients = 100% buff strength (maximum)
- **Duration**: Varies by buff type (configurable)
- **Stacking**: Buffs don't stack (newest replaces oldest)

### 📦 Delivery Box System

**How Unique Storage Works:**
1. Each box generates a unique ID (e.g., "Delivery Box #1234")
2. Storage is tied to that specific box instance
3. Trade the box → recipient accesses same storage
4. Drop/pick up box → storage persists
5. Perfect for delivery roleplay scenarios

**Using Boxes:**
```
1. Use the box item from inventory
2. Box-specific storage opens
3. Add food items
4. Close inventory
5. Trade/deliver box to recipient
```

---

## 🔧 Commands & Permissions

### Player Commands
| Command | Description | Permission |
|---------|-------------|------------|
| `/checkbuffs` | Display all active buffs | All players |

### Admin Commands
| Command | Description | Permission |
|---------|-------------|------------|
| `/cleanup_box_stashes` | Remove old/unused box storage | Admin only |

### Job Permissions
| Feature | Required Grade |
|---------|---------------|
| Clock in/out | Grade 0+ (All employees) |
| Cook food | Grade 0+ (All employees) |
| Access stash | Grade 0+ (All employees) |
| Food management | Grade 2+ (Manager+) |
| Create recipes | Grade 2+ (Manager+) |
| Edit recipes | Grade 2+ (Manager+) |
| Boss menu | Grade 4 (Boss only) |

---

## 🛠️ Troubleshooting

### Common Issues & Solutions

#### Script Won't Start
**Symptoms:** Resource fails to start, console errors

**Solutions:**
1. Verify all dependencies are installed and started first
2. Check `server.cfg` load order:
   ```cfg
   ensure ox_lib
   ensure ox_target
   ensure ox_inventory
   ensure qbx_core
   ensure qbx_management
   ensure ferp_restaurant
   ```
3. Confirm `data.sql` was successfully imported
4. Check MySQL credentials are correct
5. Look for specific error messages in console

#### No Interaction Points Visible
**Symptoms:** Can't see ox_target zones

**Solutions:**
1. Verify ox_target is running: `ensure ox_target`
2. Check coordinates in `shared/config.lua` match your map
3. Ensure you're within restaurant radius (check `radius` setting)
4. Try going on duty first (some zones require duty status)
5. Test ox_target with other scripts to confirm it's working

#### Cooking Doesn't Work
**Symptoms:** Can't cook food, no menu appears

**Solutions:**
1. Confirm you have ALL required ingredients in inventory
2. Verify you're on duty (`/job` to check)
3. Check if food item is active in database:
   ```sql
   SELECT * FROM ferp_restaurant_items WHERE active = 1;
   ```
4. Enable debug mode: `Config.Debug = true`
5. Check console for specific errors

#### No Buffs Applied
**Symptoms:** Eating food doesn't give buffs

**Solutions:**
1. Verify buff system is enabled:
   ```lua
   Config.BuffSystem.enabled = true
   ```
2. Check food has ingredients (drinks/empty items won't give buffs)
3. Use `/checkbuffs` to see active buffs
4. Enable debug mode to see buff application logs
5. Restart script: `restart ferp_restaurant`

#### Delivery Boxes Opening Wrong Storage
**Symptoms:** Box opens different/empty storage

**Solutions:**
1. Each box has unique ID in item name
2. Metadata must be preserved when trading
3. Don't stack boxes (they're unique items)
4. Check box ID matches: Use box and check metadata
5. Run `/cleanup_box_stashes` if many old boxes exist

#### Performance Issues
**Symptoms:** High resmon usage, server lag

**Solutions:**
1. Normal usage should be 0.20-0.30ms
2. If higher, check for script conflicts
3. Disable debug mode: `Config.Debug = false`
4. Reduce `Config.ZoneRadius` if using many zones
5. Clear old box stashes: `/cleanup_box_stashes`

### Debug Mode
Enable detailed logging for troubleshooting:

```lua
-- In shared/config.lua
Config.Debug = true
Config.BuffSystem.debugMode = true
```

**Console Output Includes:**
- Buff applications and removals
- Food consumption events
- Database queries and results
- Zone enter/exit events
- Ingredient category detection
- Stash access logs

### Getting Additional Help

**Before asking for support:**
1.  Enable `Config.Debug = true`
2.  Check F8 console for client errors
3.  Check server console for server errors
4.  Verify all dependencies are latest versions
5.  Test with minimal other scripts running

**Include in support requests:**
- Console error messages (full text)
- Script version
- Framework version (QBX Core)
- Steps to reproduce issue
- Any modifications made to code

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
