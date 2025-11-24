# 🍽️ FERP Restaurant System

A comprehensive restaurant management system for QBX Core featuring advanced food crafting, buff systems, employee management, and unique delivery mechanics.

## 📋 Features

### 🏪 **Restaurant Management**
- **Multi-Restaurant Support**: Burger Shot, UwU Cafe, Rooster Rest (easily expandable)
- **Employee Management**: Duty system, grade-based permissions (Manager level 2+)
- **Dynamic Food Creation**: Create custom food items with ingredients
- **Food Control System**: Activate/deactivate menu items for cooking
- **Inventory Integration**: Separate stashes for fridge, shelf, and storage

### 🍳 **Advanced Food System**
- **Ingredient-Based Crafting**: 50+ ingredients across 8 categories
- **Metadata-Rich Items**: Each food item stores ingredients, creation info, expiry
- **Food Preservation**: Fridge system extends food expiry by 4x
- **Cooking Animations**: Realistic cooking process with progress bars
- **Menu System**: Dynamic customer ordering with ingredient display

### 💪 **Buff System**
- **8 Ingredient Categories**: Each provides unique buffs
  - **Protein** → Strength (health, melee damage)
  - **Vegetables** → Stamina + Medical healing (max 50 HP)
  - **Leavening** → Intelligence (XP boost, hacking time)
  - **Dairy** → Stress relief (immediate)
  - **Grain** → Hunger bonus (immediate)
  - **Seasoning** → Money luck (job payment bonus)
  - **Oil** → Stress relief (immediate)
  - **Sugar** → Alert (movement speed)

### 📦 **Unique Delivery System**
- **Individual Box Stashes**: Each delivery box has unique stash with metadata
- **Persistent Storage**: Boxes maintain contents regardless of inventory position
- **Transferable**: Boxes can be given to other players while maintaining contents
- **Restaurant Integration**: Boxes created with restaurant origin tracking

### 🐱 **Ambiance Features**
- **Restaurant Cats**: Interactive cats that reduce stress when petted
- **Toy System**: Create and manage restaurant-themed toys
- **Toy Boxes**: Collectible items with random toy rewards

## 🛠️ Installation

### Dependencies
```
ox_lib
ox_target  
ox_inventory
qbx_core
qbx_management
```

### Database Setup
```sql
-- Import the provided data.sql file
-- Creates restaurants and restaurant_food_items tables
-- Includes sample food items for each restaurant
```

### Resource Installation
1. Place `ferp_restaurant` in your resources folder
2. Add to server.cfg: `ensure ferp_restaurant`
3. Configure restaurants in `shared/config.lua`
4. Import ox_inventory items (see Items section below)

## ⚙️ Configuration

### Restaurant Setup (`shared/config.lua`)
```lua
Config.Restaurants = {
    ['uwu_cafe'] = {
        name = 'UwU Cafe',
        job = 'uwucafe',
        zones = {
            management = {coords = vector3(-583.99, -1058.33, 22.34), radius = 1.5},
            duty = {coords = vector3(-584.08, -1061.35, 22.34), radius = 1.5},
            fridge = {coords = vector3(-590.24, -1058.78, 22.34), radius = 1.5},
            -- ... more zones
        }
    }
}
```

### Debug Configuration
```lua
Config.Debug = false  -- Set to true for development debugging
```

### Buff System
```lua
Config.BuffSystem = {
    enabled = true,
    maxBuffs = 5,
    stackable = false,
    vegetableHealLimit = 50  -- Max HP vegetables can restore
}
```

## 🎮 Usage Guide

### For Restaurant Employees

#### **Getting Started**
1. Go on duty at the duty zone
2. Access management menu (Grade 2+ required)
3. Create food items or manage existing ones

#### **Food Creation Process**
1. Open Management → Food Management → Create Food Item
2. Fill in: Name, Description, Image URL, Food Type
3. Select ingredients (up to 5, required for main dishes)
4. Food item is created and can be activated for cooking

#### **Cooking Process**
1. Use cooking zones (categorized by food type)
2. Select food item to cook
3. System checks for required ingredients
4. Complete cooking animation
5. Receive finished food item with metadata

### For Customers

#### **Ordering Food**
1. Use order zones at restaurants
2. Browse available menu items
3. Select item to order (automatically crafted)
4. Receive food item with ingredients and buffs

### Delivery System

#### **Taking Delivery Boxes**
1. Use "Get Box" interaction at restaurant
2. Each box receives unique ID (e.g., #6536)
3. Box metadata includes: ID, creator, timestamp, restaurant

#### **Using Delivery Boxes**
1. Use box item from inventory
2. Opens unique stash regardless of inventory position
3. Each box maintains separate contents
4. Boxes can be traded/given to other players

## 🔧 Items for ox_inventory

Add these items to your `ox_inventory/data/items.lua`:

```lua
-- Base restaurant items (metadata-driven)
['restaurant_main'] = {
    label = 'Main Dish',
    weight = 300,
    stack = false,
    close = true,
    description = 'A delicious main course',
    client = {
        image = 'restaurant_main.png',
        export = 'ferp_restaurant.useFood'
    }
},

['restaurant_side'] = {
    label = 'Side Dish', 
    weight = 200,
    stack = false,
    close = true,
    description = 'A tasty side dish',
    client = {
        image = 'restaurant_side.png',
        export = 'ferp_restaurant.useFood'
    }
},

['restaurant_dessert'] = {
    label = 'Dessert',
    weight = 150,
    stack = false, 
    close = true,
    description = 'A sweet dessert',
    client = {
        image = 'restaurant_dessert.png',
        export = 'ferp_restaurant.useFood'
    }
},

['restaurant_drink'] = {
    label = 'Beverage',
    weight = 100,
    stack = false,
    close = true,
    description = 'A refreshing drink',
    client = {
        image = 'restaurant_drink.png',
        export = 'ferp_restaurant.useDrink'
    }
},

-- Delivery system
['restaurant_box'] = {
    label = 'Delivery Box',
    weight = 100,
    stack = false,
    close = true,
    description = 'A restaurant delivery box with unique storage',
    client = {
        image = 'restaurant_box.png',
        export = 'ferp_restaurant.useRestaurantBox'
    }
},

-- Toy system  
['restaurant_toy_box'] = {
    label = 'Toy Box',
    weight = 50,
    stack = false,
    close = true,
    description = 'A box containing restaurant toys',
    client = {
        image = 'restaurant_toy_box.png',
        export = 'ferp_restaurant.useRestaurantToyBox'
    }
}
```

## 🎯 Key Features Explained

### **Metadata System**
Every food item contains rich metadata:
```lua
{
    ingredients = {"beef", "cheese", "lettuce"},
    food_type = "main",
    restaurant_id = "uwu_cafe", 
    created_by = "John Doe",
    created_at = "2024-01-01 12:00:00",
    expiry = 1704110400,
    display_name = "UwU Burger"
}
```

### **Fridge Preservation**
- Food placed in restaurant fridges gets 4x longer expiry
- Only food items affected (configured in `Config.FridgeAllowedItems`)
- Uses ox_inventory hook system for real-time processing

### **Buff Calculations**
Buffs scale with ingredient count:
- 1 ingredient = 25% buff strength
- 2 ingredients = 50% buff strength  
- 3 ingredients = 75% buff strength
- 4+ ingredients = 100% buff strength

### **Box Uniqueness System**
Each delivery box gets unique metadata:
```lua
{
    box_id = "box_1_1754086877_6536",
    created_by = "ABC12345", 
    created_at = "2024-01-01 10:00:00",
    restaurant = "uwu_cafe"
}
```

### **Automatic Stash Cleanup System**
- **Orphaned Stash Detection**: Detects when boxes are dropped/destroyed
- **Periodic Cleanup**: Runs every 30 minutes to clean old stashes
- **Grace Period**: 1 hour grace period for stashes with items
- **Age-Based Cleanup**: Removes stashes inactive for 7+ days
- **Admin Command**: `/cleanup_box_stashes` for manual cleanup

## 🐛 Debugging

### Enable Debug Mode
```lua
Config.Debug = true  -- In shared/config.lua
```

### Debug Output Examples
```
[FERP Restaurant] Created box with unique ID: box_1_1754086877_6536
[FERP Restaurant] Opening box stash: box_1_1754086877_6536 for player: 1
[FERP Restaurant] Hook triggered - Action: move From: player To: stash
```

### Common Issues
- **Boxes opening wrong stash**: Check metadata in ox_inventory
- **Buffs not applying**: Verify `Config.BuffSystem.enabled = true`
- **Food not preserving in fridge**: Check fridge hook registration

## 🔄 API & Exports

### Client Exports
```lua
local isEmployed = exports.ferp_restaurant:IsEmployedAtRestaurant('uwu_cafe')

local job = exports.ferp_restaurant:GetPlayerJob() 

local hasStrength = exports.ferp_restaurant:HasActiveBuff('strength')

-- Check if player has any active buff (generic)
local hasBuff = exports.ferp_restaurant:HasActiveBuff('stamina')

-- Get strength of a specific buff (0 if none)
local buffStrength = exports.ferp_restaurant:GetBuffStrength('intelligence')

local currentRestaurant = exports.ferp_restaurant:GetCurrentRestaurant()

-- Apply ingredient-based buffs (manual)
exports.ferp_restaurant:configureBuffs(metadata)

-- Apply specific buff type (manual)
exports.ferp_restaurant:applySpecificBuff('strength', 2)

-- Apply stress relief (manual)
exports.ferp_restaurant:applyStressRelief(1)

-- Apply hunger boost (manual)
exports.ferp_restaurant:applyHungerBoost(1)

-- Apply medical healing (manual)
exports.ferp_restaurant:applyMedicalHealing(10)

-- Use food item (ox_inventory integration)
exports.ferp_restaurant:useFood(data, slot)

-- Use drink item (ox_inventory integration)
exports.ferp_restaurant:useDrink(data, slot)

-- Use restaurant box (abre stash da box)
exports.ferp_restaurant:useRestaurantBox(data, slot)

-- Use restaurant toy box (abre brinquedo aleatório)
exports.ferp_restaurant:useRestaurantToyBox(data, slot)
```

### Server Exports  
```lua
local buffValue = exports.ferp_restaurant:GetPlayerBuff(playerId, 'strength')

local hasBuff = exports.ferp_restaurant:HasPlayerBuff(playerId, 'intelligence')

local allBuffs = exports.ferp_restaurant:GetAllPlayerBuffs(playerId)

-- Check if player has a specific buff (boolean)
local hasBuff = exports.ferp_restaurant:HasPlayerBuff(playerId, 'stamina')

-- Get value/strength of a specific buff
local buffValue = exports.ferp_restaurant:GetPlayerBuff(playerId, 'alert')

local bonus = exports.ferp_restaurant:GetJobPaymentBonus(playerId, baseAmount)

-- Get XP multiplier (buff de inteligência)
local xpMult = exports.ferp_restaurant:GetXPMultiplier(playerId)
```

## 🎨 Customization

### Adding New Restaurants
1. Add restaurant config in `shared/config.lua`
2. Create database entry in restaurants table
3. Set up zones and job integration
4. Configure stashes in server startup

### Creating New Ingredients
```lua
Config.Ingredients = {
    ['new_ingredient'] = { 
        category = 'protein', 
        label = 'New Protein' 
    }
}
```

### Adding New Food Types
```lua
Config.FoodTypes = {
    'main', 'side', 'dessert', 'drink', 'appetizer'  -- Add new types
}
```

## 📞 Support

### Commands for Testing
- `/checkbuffs` - View current active buffs
- `/cleanup_box_stashes` - Admin: Manual cleanup of orphaned box stashes

### File Structure
```
ferp_restaurant/
├── client/           # Client-side scripts
├── server/          # Server-side scripts  
├── shared/          # Shared configuration
├── data.sql         # Database schema
└── fxmanifest.lua   # Resource manifest
