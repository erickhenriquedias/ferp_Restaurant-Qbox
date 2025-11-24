-- Client exports for restaurant system

-- Event handlers for hunger/thirst changes (QBX compatible)
RegisterNetEvent('changehunger', function(amount)
    if not amount or amount == 0 then return end
    if Config.Debug then print('[DEBUG] Client changehunger called with amount:', amount) end
    TriggerServerEvent('ferp_restaurant:server:changeHunger', amount)
end)

RegisterNetEvent('changethirst', function(amount)
    if not amount or amount == 0 then return end
    if Config.Debug then print('[DEBUG] Client changethirst called with amount:', amount) end
    TriggerServerEvent('ferp_restaurant:server:changeThirst', amount)
end)

-- Configuration for food buffs based on type and ingredients
local FoodBuffs = {
    Types = {
        main = {
            hunger = math.random(40, 60),
            baseDescription = "A filling main dish"
        },
        side = {
            hunger = math.random(20, 35),
            baseDescription = "A tasty side dish"
        },
        dessert = {
            hunger = math.random(15, 25),
            stress = -math.random(10, 20), -- Desserts reduce stress
            baseDescription = "A sweet dessert"
        },
        drink = {
            thirst = math.random(40, 60),
            baseDescription = "A refreshing beverage"
        }
    },
    
    -- Ingredient-based buffs (enhance food quality based on ingredients)
    Ingredients = {
        ["oil"] = function(percent)
            -- Oils improve food quality and reduce stress from cooking
            local hungerBoost = math.floor(8 * (percent or 0.5))
            local stressReduction = math.floor(15 * (percent or 0.5))
            TriggerServerEvent('ferp_restaurant:server:changeHunger', hungerBoost)
            -- Reduce stress through QBX HUD system
            TriggerServerEvent('hud:server:RelieveStress', stressReduction)
        end,
        ["protein"] = function(percent)
            -- Proteins are the main hunger source
            local extraHunger = math.floor(25 * (percent or 0.5))
            TriggerServerEvent('ferp_restaurant:server:changeHunger', extraHunger)
        end,
        ["vegetables"] = function(percent)
            -- Vegetables add health and moderate hunger
            local healthBoost = math.floor(15 * (percent or 0.5))
            local hungerBoost = math.floor(18 * (percent or 0.5))
            TriggerServerEvent('ferp_restaurant:server:changeHunger', hungerBoost)
            -- Add health if possible
            if GetResourceState('qbx_medical') == 'started' then
                exports.qbx_medical:AddHealth(healthBoost)
            end
        end,
        ["dairy"] = function(percent)
            -- Dairy products add both hunger and thirst
            local hungerBoost = math.floor(15 * (percent or 0.5))
            local thirstBoost = math.floor(12 * (percent or 0.5))
            TriggerServerEvent('ferp_restaurant:server:changeHunger', hungerBoost)
            TriggerServerEvent('ferp_restaurant:server:changeThirst', thirstBoost)
        end,
        ["grain"] = function(percent)
            -- Grains are filling and provide sustained hunger satisfaction
            local hungerBoost = math.floor(30 * (percent or 0.5))
            TriggerServerEvent('ferp_restaurant:server:changeHunger', hungerBoost)
        end,
        ["seasoning"] = function(percent)
            -- Seasonings enhance overall food quality
            local hungerBoost = math.floor(12 * (percent or 0.5))
            TriggerServerEvent('ferp_restaurant:server:changeHunger', hungerBoost)
        end,
        ["sugar"] = function(percent)
            -- Sugar provides quick energy and small hunger boost
            local hungerBoost = math.floor(10 * (percent or 0.5))
            TriggerServerEvent('ferp_restaurant:server:changeHunger', hungerBoost)
        end,
        ["leavening"] = function(percent)
            -- Leavening agents make bread more filling
            local hungerBoost = math.floor(16 * (percent or 0.5))
            TriggerServerEvent('ferp_restaurant:server:changeHunger', hungerBoost)
        end
    }
}

-- Function to apply ingredient-based buffs
local function applyIngredientBuffs(metadata)
    if not metadata or not metadata.ingredients then return end
    
    local ingredients = metadata.ingredients
    if type(ingredients) == 'string' then
        ingredients = json.decode(ingredients) or {}
    end
    
    if Config.Debug then print('[DEBUG] Applying buffs for ingredients:', json.encode(ingredients)) end
    
    -- Calculate ingredient percentages
    local totalIngredients = #ingredients
    if totalIngredients == 0 then return end
    
    local ingredientCounts = {}
    for _, ingredient in pairs(ingredients) do
        ingredientCounts[ingredient] = (ingredientCounts[ingredient] or 0) + 1
    end
    
    -- Apply buffs based on ingredient percentages
    for ingredient, count in pairs(ingredientCounts) do
        local percentage = count / totalIngredients
        local buffFunction = FoodBuffs.Ingredients[ingredient]
        
        if buffFunction then
            print('[DEBUG] Applying buff for:', ingredient, 'with percentage:', percentage)
            buffFunction(percentage)
        end
    end
end

-- Use food item with metadata
exports('useFood', function(data, slot)
    local playerPed = PlayerPedId()
    
    if Config.Debug then print('[DEBUG] useFood called with data:', json.encode(data)) end
    if Config.Debug then print('[DEBUG] slot:', json.encode(slot)) end
    
    -- ox_inventory passes the item data differently - check the actual structure
    local metadata = nil
    local itemData = data
    
    -- The metadata might be in the slot parameter or in the data itself
    if slot and type(slot) == 'table' then
        if slot.metadata then
            metadata = slot.metadata
        elseif slot.info then
            metadata = slot.info
        end
    end
    
    -- If no metadata found in slot, check data
    if not metadata then
        if data and data.metadata then
            metadata = data.metadata
        elseif data and data.info then
            metadata = data.info
        end
    end
    
    if Config.Debug then print('[DEBUG] Final metadata found:', json.encode(metadata)) end
    
    if not metadata then
        if Config.Debug then print('[DEBUG] No metadata found - using default values') end
        -- Use default values if no metadata
        metadata = {
            label = data.label or 'Food',
            description = data.description or 'A delicious meal'
        }
    end
    
    local foodName = metadata.label or data.label or 'Food'
    local description = metadata.description or data.description or 'A delicious meal'
    local restaurantId = metadata.restaurant_id or 'unknown'
    
    -- Determine food type from item name or metadata
    local foodType = 'main' -- default
    if data.name then
        if string.find(data.name, 'side') then
            foodType = 'side'
        elseif string.find(data.name, 'dessert') then
            foodType = 'dessert'
        elseif string.find(data.name, 'drink') then
            foodType = 'drink'
        end
    end
    
    -- Get animation config
    local animConfig = Config.FoodAnimations[foodType] or Config.FoodAnimations.main
    
    -- Use default prop from config (no more random selection)
    local propModel = animConfig.prop.model
    
    -- Progress bar for eating with configurable animation
    if lib.progressBar({
        duration = animConfig.duration or 3000,
        label = 'Eating ' .. foodName,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = false,
            move = false,
            combat = true
        },
        anim = {
            dict = animConfig.anim.dict,
            clip = animConfig.anim.name
        },
        prop = {
            model = propModel,
            pos = animConfig.prop.coords or vec3(0.02, 0.02, -0.02),
            rot = animConfig.prop.rotation or vec3(0.0, 0.0, 0.0)
        }
    }) then
        -- Remove item from inventory - pass correct data structure
        local consumeData = {
            name = data.name,
            slot = slot and slot.slot or data.slot,
            metadata = metadata,
            count = 1
        }
        
        print('[DEBUG] Sending consume data:', json.encode(consumeData))
        TriggerServerEvent('ferp_restaurant:server:consumeFood', consumeData)
        
        -- Apply restaurant buff system
        TriggerEvent('ferp_restaurant:client:item-used', {
            name = data.name,
            metadata = metadata
        })
        
        -- Notification is handled by buff system, no need for duplicate
    end
end)

-- Use drink item with metadata  
exports('useDrink', function(data, slot)
    local playerPed = PlayerPedId()
    
    -- ox_inventory passes the item data differently - check the actual structure
    local metadata = nil
    local itemData = data
    
    -- The metadata might be in the slot parameter or in the data itself
    if slot and type(slot) == 'table' then
        if slot.metadata then
            metadata = slot.metadata
        elseif slot.info then
            metadata = slot.info
        end
    end
    
    -- If no metadata found in slot, check data
    if not metadata then
        if data and data.metadata then
            metadata = data.metadata
        elseif data and data.info then
            metadata = data.info
        end
    end
    
    
    if not metadata then
        -- Use default values if no metadata
        metadata = {
            label = data.label or 'Drink',
            description = data.description or 'A refreshing beverage'
        }
    end
    
    local drinkName = metadata.label or data.label or 'Drink'
    local description = metadata.description or data.description or 'A refreshing beverage'
    local restaurantId = metadata.restaurant_id or 'unknown'
    
    -- Get drink animation config
    local animConfig = Config.FoodAnimations.drink
    
    -- Use default prop from config (no more random selection)
    local propModel = animConfig.prop.model
    
    -- Progress bar for drinking with configurable animation
    if lib.progressBar({
        duration = animConfig.duration or 2500,
        label = 'Drinking ' .. drinkName,
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = false,
            move = false,
            combat = true
        },
        anim = {
            dict = animConfig.anim.dict,
            clip = animConfig.anim.name,
            flag = animConfig.anim.flags or 49
        },
        prop = {
            model = propModel,
            bone = animConfig.prop.bone or 18905,
            pos = animConfig.prop.coords or vector3(0.01, -0.01, 0.06),
            rot = animConfig.prop.rotation or vector3(5.0, 5.0, -180.5)
        }
    }) then
        -- Remove item from inventory - pass correct data structure
        local consumeData = {
            name = data.name,
            slot = slot and slot.slot or data.slot,
            metadata = metadata,
            count = 1
        }
        
        TriggerServerEvent('ferp_restaurant:server:consumeDrink', consumeData)
        
        -- Apply restaurant buff system for drinks
        TriggerEvent('ferp_restaurant:client:item-used', {
            name = data.name,
            metadata = metadata
        })
        
        -- Notification is handled by buff system, no need for duplicate
    end
end)

-- Export for using restaurant box item (opens unique stash for each box)
exports('useRestaurantBox', function(data, slot)
    if Config.Debug then print('[DEBUG] useRestaurantBox called with data:', json.encode(data), 'slot:', json.encode(slot)) end
    
    -- Try to get box ID from metadata
    local boxId = nil
    
    if slot and slot.metadata and slot.metadata.box_id then
        -- New system: use unique box_id from metadata
        boxId = slot.metadata.box_id
        if Config.Debug then print('[DEBUG] Using box_id from metadata:', boxId) end
    elseif data and data.metadata and data.metadata.box_id then
        -- Alternative metadata location
        boxId = data.metadata.box_id
        if Config.Debug then print('[DEBUG] Using box_id from data.metadata:', boxId) end
    else
        -- Fallback: create temporary box ID (should not happen with new system)
        local playerId = GetPlayerServerId(PlayerId())
        boxId = 'box_temp_' .. playerId .. '_' .. os.time()
        if Config.Debug then print('[DEBUG] WARNING: No box_id in metadata, using fallback:', boxId) end
    end
    
    -- Register and open stash on server
    TriggerServerEvent('ferp_restaurant:server:openBoxStash', boxId)
end)

-- Export for using restaurant toy box item (opens random toy)
exports('useRestaurantToyBox', function(data, slot)
    local metadata = slot.metadata or data.metadata
    
    if not metadata or not metadata.restaurant_id then
        lib.notify({
            title = 'Toy Box',
            description = 'Invalid toy box',
            type = 'error'
        })
        return
    end
    
    -- Progress bar for opening box
    if lib.progressBar({
        duration = 2000,
        label = 'Opening toy box...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = false,
            move = false,
            combat = true
        },
        anim = {
            dict = 'mp_common',
            clip = 'givetake1_a'
        }
    }) then
        -- Remove the toy box and get random toy
        TriggerServerEvent('ferp_restaurant:server:openToyBox', metadata.restaurant_id)
        
        -- Remove the box item
        TriggerServerEvent('ferp_restaurant:server:consumeToyBox', data, slot)
    end
end)
