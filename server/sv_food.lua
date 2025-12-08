-- ox_lib Callback
lib.callback.register('ferp_restaurant:server:checkIngredients', function(source, ingredients, quantity)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    
    local missingIngredients = {}
    local checkQuantity = quantity or 1
    
    for _, ingredient in pairs(ingredients) do
        -- Get the actual item name from config
        local ingredientData = Config.Ingredients[ingredient]
        local itemName = ingredientData and ingredientData.item or ingredient
        
        local hasItem = exports.ox_inventory:GetItemCount(source, itemName)
        if not hasItem or hasItem < checkQuantity then
            missingIngredients[#missingIngredients + 1] = ingredient
        end
    end
    
    return #missingIngredients == 0, missingIngredients
end)

-- Event handlers for hunger/thirst changes
local function setPlayerHunger(source, amount)
    if not amount or amount == 0 then return end
    
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    local currentHunger = player.PlayerData.metadata.hunger or 0
    local newHunger = math.max(0, math.min(100, currentHunger + amount))
    
    if Config.Debug then print('[DEBUG] Server hunger change - Player:', source, 'Current:', currentHunger, 'Amount:', amount, 'New:', newHunger) end
    
    -- Update metadata via QBX Core
    player.Functions.SetMetaData('hunger', newHunger)
end

local function setPlayerThirst(source, amount)
    if not amount or amount == 0 then return end
    
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    local currentThirst = player.PlayerData.metadata.thirst or 0
    local newThirst = math.max(0, math.min(100, currentThirst + amount))
    
    if Config.Debug then print('[DEBUG] Server thirst change - Player:', source, 'Current:', currentThirst, 'Amount:', amount, 'New:', newThirst) end
    
    -- Update metadata via QBX Core  
    player.Functions.SetMetaData('thirst', newThirst)
end

RegisterNetEvent('ferp_restaurant:server:changeHunger', function(amount)
    if type(amount) ~= 'number' or amount < 0 or amount > 100 then
        if Config.Debug then print('[SECURITY] Invalid hunger from player:', source, amount) end
        return
    end
    setPlayerHunger(source, amount)
end)

RegisterNetEvent('ferp_restaurant:server:changeThirst', function(amount)
    if type(amount) ~= 'number' or amount < 0 or amount > 100 then
        if Config.Debug then print('[SECURITY] Invalid thirst from player:', source, amount) end
        return
    end
    setPlayerThirst(source, amount)
end)

-- Event to apply limited vegetable health (max 50% health, no injury healing)
RegisterNetEvent('ferp_restaurant:server:applyVegetableHealth', function(healAmount)
    local source = source
    
    -- Validate healAmount
    if type(healAmount) ~= 'number' or healAmount < 0 or healAmount > 100 then
        if Config.Debug then print('[SECURITY] Invalid heal amount from player:', source, healAmount) end
        return
    end
    
    -- Limit healing to configured maximum (default 50% of 100 health)
    local limitedHealAmount = math.min(healAmount, Config.BuffSystem.vegetableHealLimit or 50)
    
    -- Try multiple methods to apply health
    if GetResourceState('qbx_medical') == 'started' then
        -- Try QBX Medical export first
        local success = pcall(function()
            exports.qbx_medical:AddHealth(source, limitedHealAmount)
        end)
        
        if not success then
            -- Try client event
            TriggerClientEvent('qbx_medical:client:AddHealth', source, limitedHealAmount)
        end
        
        if Config.Debug then print('[DEBUG] QBX Medical health applied via export/event') end
    else
        -- Fallback: Use native SetEntityHealth
        TriggerClientEvent('ferp_restaurant:client:addHealthNative', source, limitedHealAmount)
        if Config.Debug then print('[DEBUG] QBX Medical not available, using native health') end
    end
    
    if Config.Debug then
        print('[DEBUG] Applied limited vegetable health - Amount:', limitedHealAmount, 'Original:', healAmount, 'Limit:', Config.BuffSystem.vegetableHealLimit)
    end
end)

-- ox_lib Callback for getting restaurant food items
lib.callback.register('ferp_restaurant:server:getFoodItems', function(source, restaurantId)
    if Config.Debug then print('[FERP Restaurant Server] getFoodItems called for restaurant: ' .. tostring(restaurantId)) end
    
    local result = MySQL.query.await('SELECT * FROM restaurant_food_items WHERE restaurant_id = ?', {restaurantId})
    
    if not result then
        if Config.Debug then print('[FERP Restaurant Server] No food items found for restaurant: ' .. tostring(restaurantId)) end
        return {}
    end
    
    -- Process ingredients from JSON string to table
    for i, item in ipairs(result) do
        if item.ingredients then
            item.ingredients = json.decode(item.ingredients) or {}
        else
            item.ingredients = {}
        end
        
        -- Handle active status with same logic as toggle function
        local currentActive = item.active
        if currentActive == nil then
            item.active = true -- Default to active if NULL
        elseif type(currentActive) == 'boolean' then
            item.active = currentActive
        elseif type(currentActive) == 'number' then
            item.active = currentActive == 1
        else
            -- Handle other types (strings, etc.)
            item.active = currentActive == 1 or currentActive == '1' or currentActive == true or currentActive == 'true'
        end
    end
    
    if Config.Debug then print('[FERP Restaurant Server] Returning ' .. #result .. ' food items') end
    return result
end)

-- ox_lib Callback for getting active restaurant food items (for cooking)
lib.callback.register('ferp_restaurant:server:getActiveFoodItems', function(source, restaurantId)
    if Config.Debug then print('[FERP Restaurant Server] getActiveFoodItems called for restaurant: ' .. tostring(restaurantId)) end
    
    local result = MySQL.query.await('SELECT * FROM restaurant_food_items WHERE restaurant_id = ? AND (active = 1 OR active IS NULL)', {restaurantId})
    
    if not result then
        if Config.Debug then print('[FERP Restaurant Server] No active food items found for restaurant: ' .. tostring(restaurantId)) end
        return {}
    end
    
    -- Process ingredients from JSON string to table
    for i, item in ipairs(result) do
        if item.ingredients then
            item.ingredients = json.decode(item.ingredients) or {}
        else
            item.ingredients = {}
        end
        
        -- Handle active status with same logic as toggle function
        local currentActive = item.active
        if currentActive == nil then
            item.active = true -- Default to active if NULL
        elseif type(currentActive) == 'boolean' then
            item.active = currentActive
        elseif type(currentActive) == 'number' then
            item.active = currentActive == 1
        else
            -- Handle other types (strings, etc.)
            item.active = currentActive == 1 or currentActive == '1' or currentActive == true or currentActive == 'true'
        end
    end
    
    if Config.Debug then print('[FERP Restaurant Server] Returning ' .. #result .. ' active food items') end
    return result
end)

-- Callback for creating new food item
lib.callback.register('ferp_restaurant:server:createFoodItem', function(source, data)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    
    local restaurantId, restaurantData = GetPlayerRestaurant(source)
    if not restaurantId then
        return false, 'You are not employed at a restaurant'
    end
    
    -- Check permissions (grade 2+ for management)
    if player.PlayerData.job.grade.level < 2 then
        return false, 'Insufficient permissions'
    end
    
    -- Validate input data
    if not data.name or not data.description or not data.image_url or not data.food_type then
        return false, 'Missing required fields'
    end
    
    -- Process ingredients for all food types
    local ingredients = {}
    for i = 1, Config.MaxIngredients do
        local ingredient = data['ingredient_' .. i]
        if ingredient and ingredient ~= '' and Config.Ingredients[ingredient] then
            ingredients[#ingredients + 1] = ingredient
        end
    end
    
    -- Only require ingredients for main dishes
    if data.food_type == 'main' and #ingredients == 0 then
        return false, 'Main dishes require at least one ingredient'
    end
    
    -- Insert into database
    local success = MySQL.insert.await('INSERT INTO restaurant_food_items (restaurant_id, name, description, image_url, food_type, ingredients) VALUES (?, ?, ?, ?, ?, ?)', {
        restaurantId,
        data.name,
        data.description,
        data.image_url,
        data.food_type,
        json.encode(ingredients)
    })
    
    if success then
        TriggerClientEvent('ferp_restaurant:client:foodItemsUpdated', -1, restaurantId)
        return true, 'Food item created successfully'
    else
        return false, 'Failed to save food item'
    end
end)

-- Callback for deleting food item
lib.callback.register('ferp_restaurant:server:deleteFoodItem', function(source, itemId, restaurantId, itemName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then 
        return false, 'Player not found'
    end
    
    -- Get restaurant from player's job
    local playerJob = player.PlayerData.job.name
    local playerRestaurantId = nil
    
    -- Find which restaurant corresponds to this job
    for restId, restData in pairs(Config.Restaurants) do
        if restData.job == playerJob then
            playerRestaurantId = restId
            break
        end
    end
    
    if not playerRestaurantId then
        return false, 'You are not employed at a restaurant'
    end
    
    -- Check permissions
    if player.PlayerData.job.grade.level < 2 then
        return false, 'Insufficient permissions (need grade 2+)'
    end
    
    -- Delete from database using name and restaurant
    local deleteResult = MySQL.update.await('DELETE FROM restaurant_food_items WHERE name = ? AND restaurant_id = ?', {
        itemName,
        playerRestaurantId
    })
    
    if deleteResult and deleteResult > 0 then
        TriggerClientEvent('ferp_restaurant:client:foodItemsUpdated', -1, playerRestaurantId)
        return true, 'Food item deleted successfully'
    else
        return false, 'Failed to delete food item - item not found in your restaurant'
    end
end)

-- Event for crafting food
RegisterNetEvent('ferp_restaurant:server:craftItem', function(item, quantity)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    quantity = quantity or 1
    if type(quantity) ~= 'number' or quantity < 1 then quantity = 1 end
    
    -- Validate item structure
    if type(item) ~= 'table' or not item.name or not item.food_type then
        if Config.Debug then print('[SECURITY] Invalid item data from player:', src) end
        return
    end
    
    -- Validate food_type
    local validTypes = {main = true, side = true, dessert = true, drink = true}
    if not validTypes[item.food_type] then
        if Config.Debug then print('[SECURITY] Invalid food_type from player:', src, item.food_type) end
        return
    end
    
    if Config.Debug then print('[DEBUG] Crafting item:', json.encode(item), 'Quantity:', quantity) end
    
    -- Use the category-based item name
    local itemName = 'restaurant_' .. item.food_type
    if Config.Debug then print('[DEBUG] Using category item name:', itemName) end
    
    -- Check if item has ingredients
    if not item.ingredients or #item.ingredients == 0 then
        -- If no ingredients, just give the item
        if Config.Debug then print('[DEBUG] No ingredients needed, giving item directly') end
        
        -- Create metadata for ox_inventory
        local metadata = {
            label = item.name,
            description = item.description,
            imageurl = item.image_url,
            restaurant_id = item.restaurant_id or 'unknown',
            food_id = item.id,
            ingredients = {},
            crafted_by = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
            crafted_at = os.date('%Y-%m-%d %H:%M:%S'),
            quality = 100,
            weight = 250,
            type = 'food',
            stack = true,
            close = true
        }
        
        if Config.Debug then print('[DEBUG] Metadata being sent:', json.encode(metadata)) end
        
        local success = exports.ox_inventory:AddItem(src, itemName, quantity, metadata)
        if Config.Debug then print('[DEBUG] AddItem result:', success) end
        
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Cooking Complete',
                description = 'You cooked ' .. quantity .. 'x ' .. item.name,
                type = 'success'
            })
        else
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Cooking Failed',
                description = 'Could not add item to inventory',
                type = 'error'
            })
        end
        return
    end
    
    -- Count how many of each ingredient is needed
    local ingredientCounts = {}
    for _, ingredient in pairs(item.ingredients) do
        ingredientCounts[ingredient] = (ingredientCounts[ingredient] or 0) + quantity
    end
    
    -- Check if player has enough of each ingredient
    local missingIngredients = {}
    for ingredient, count in pairs(ingredientCounts) do
        local ingredientData = Config.Ingredients[ingredient]
        local ingredientItemName = ingredientData and ingredientData.item or ingredient
        local hasItem = exports.ox_inventory:GetItemCount(src, ingredientItemName)
        
        if hasItem < count then
            missingIngredients[#missingIngredients + 1] = ingredient .. ' (' .. count .. 'x)'
        end
    end
    
    if #missingIngredients > 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Cooking Failed',
            description = 'Missing: ' .. table.concat(missingIngredients, ', '),
            type = 'error'
        })
        return
    end
    
    -- Remove ingredients from inventory
    for ingredient, count in pairs(ingredientCounts) do
        local ingredientData = Config.Ingredients[ingredient]
        local ingredientItemName = ingredientData and ingredientData.item or ingredient
        exports.ox_inventory:RemoveItem(src, ingredientItemName, count)
    end
    
    -- Give crafted item with metadata
    if Config.Debug then print('[DEBUG] Adding crafted item to inventory:', itemName, 'Quantity:', quantity) end
    
    -- Create metadata for ox_inventory
    local metadata = {
        label = item.name,
        description = item.description,
        imageurl = item.image_url, 
        restaurant_id = item.restaurant_id or 'unknown',
        food_id = item.id,
        ingredients = item.ingredients,
        crafted_by = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        crafted_at = os.date('%Y-%m-%d %H:%M:%S'),
        quality = 100,
        weight = 250,
        type = 'food',
        stack = true,
        close = true
    }
    
    if Config.Debug then print('[DEBUG] Metadata being sent:', json.encode(metadata)) end
    
    local success = exports.ox_inventory:AddItem(src, itemName, quantity, metadata)
    if Config.Debug then print('[DEBUG] AddItem result:', success) end
    
    if success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Cooking Complete',
            description = 'You cooked ' .. quantity .. 'x ' .. item.name,
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Cooking Failed',
            description = 'Could not add item to inventory',
            type = 'error'
        })
        
        -- Return ingredients to player if crafting failed
        for _, ingredient in pairs(item.ingredients) do
            local ingredientData = Config.Ingredients[ingredient]
            local ingredientItemName = ingredientData and ingredientData.item or ingredient
            exports.ox_inventory:AddItem(src, ingredientItemName, 1)
        end
    end
end)

-- Event for cooking food
RegisterNetEvent('ferp_restaurant:server:cookFood', function(foodData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local restaurantId = foodData.restaurant
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then return end
    
    -- Check if player is employed at this restaurant
    if player.PlayerData.job.name ~= restaurantData.job then
        return TriggerClientEvent('ox_lib:notify', src, {
            title = 'Restaurant',
            description = 'You are not employed at this restaurant',
            type = 'error'
        })
    end
    
    -- Check ingredients for main dishes
    if foodData.food_type == 'main' and foodData.ingredients then
        for _, ingredient in pairs(foodData.ingredients) do
            local ingredientData = Config.Ingredients[ingredient]
            local ingredientItemName = ingredientData and ingredientData.item or ingredient
            local hasItem = exports.ox_inventory:GetItemCount(src, ingredientItemName)
            if hasItem < 1 then
                return TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Cooking',
                    description = 'You need ' .. (ingredientData and ingredientData.label or ingredient),
                    type = 'error'
                })
            end
        end
        
        -- Remove ingredients
        for _, ingredient in pairs(foodData.ingredients) do
            local ingredientData = Config.Ingredients[ingredient]
            local ingredientItemName = ingredientData and ingredientData.item or ingredient
            exports.ox_inventory:RemoveItem(src, ingredientItemName, 1)
        end
    end
    
    -- Add the cooked food item using category-based item name
    local success = exports.ox_inventory:AddItem(src, 'restaurant_' .. foodData.food_type, 1, {
        label = foodData.name,
        description = foodData.description,
        imageurl = foodData.image_url, -- Campo correto para URL de imagem!
        restaurant_id = restaurantId,
        food_id = foodData.id,
        ingredients = foodData.ingredients or {},
        cooked_by = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
        cooked_at = os.date('%Y-%m-%d %H:%M:%S')
    })
    
    if success then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Cooking',
            description = 'Successfully cooked ' .. foodData.name,
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Cooking',
            description = 'Failed to cook food - inventory full?',
            type = 'error'
        })
    end
end)

-- Event for consuming food items
RegisterNetEvent('ferp_restaurant:server:consumeFood', function(consumeData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    if Config.Debug then print('[DEBUG] consumeFood called with consumeData:', json.encode(consumeData)) end
    
    -- Get the correct item name and metadata structure
    local itemName = consumeData.name
    local slot = consumeData.slot
    local metadata = consumeData.metadata or {}
    
    if Config.Debug then print('[DEBUG] Attempting to remove item:', itemName, 'from slot:', slot, 'with metadata:', json.encode(metadata)) end
    
    -- Remove the item from inventory using the correct slot-based removal
    local success = exports.ox_inventory:RemoveItem(src, itemName, 1, metadata, slot)
    
    if success then
        if Config.Debug then print('[DEBUG] Food consumed successfully') end
        
        -- Apply server-side benefits based on food type and ingredients
        applyFoodBenefits(src, metadata, itemName)
    else
        if Config.Debug then print('[DEBUG] Failed to consume food item') end
        -- Try alternative removal methods
        local altSuccess = exports.ox_inventory:RemoveItem(src, itemName, 1)
        if Config.Debug then print('[DEBUG] Alternative removal result:', altSuccess) end
        
        if altSuccess then
            applyFoodBenefits(src, metadata, itemName)
        end
    end
end)

-- Event for consuming drink items
RegisterNetEvent('ferp_restaurant:server:consumeDrink', function(consumeData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    if Config.Debug then print('[DEBUG] consumeDrink called with consumeData:', json.encode(consumeData)) end
    
    -- Get the correct item name and metadata structure
    local itemName = consumeData.name
    local slot = consumeData.slot
    local metadata = consumeData.metadata or {}
    
    if Config.Debug then print('[DEBUG] Attempting to remove drink:', itemName, 'from slot:', slot, 'with metadata:', json.encode(metadata)) end
    
    -- Remove the item from inventory using the correct slot-based removal
    local success = exports.ox_inventory:RemoveItem(src, itemName, 1, metadata, slot)
    
    if success then
        if Config.Debug then print('[DEBUG] Drink consumed successfully') end
        
        -- Apply server-side benefits for drinks
        applyDrinkBenefits(src, metadata, itemName)
    else
        if Config.Debug then print('[DEBUG] Failed to consume drink item') end
        -- Try alternative removal methods
        local altSuccess = exports.ox_inventory:RemoveItem(src, itemName, 1)
        if Config.Debug then print('[DEBUG] Alternative removal result:', altSuccess) end
        
        if altSuccess then
            applyDrinkBenefits(src, metadata, itemName)
        end
    end
end)

-- Function to apply food benefits on server side
function applyFoodBenefits(source, metadata, itemName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    if Config.Debug then print('[DEBUG] Applying food benefits for:', itemName) end
    
    -- Determine food type
    local foodType = 'main'
    if string.find(itemName, 'side') then
        foodType = 'side'
    elseif string.find(itemName, 'dessert') then
        foodType = 'dessert'
    elseif string.find(itemName, 'drink') then
        foodType = 'drink'
    end
    
    -- Base benefits based on food type
    local baseBenefits = {
        main = { hunger = math.random(40, 60) },
        side = { hunger = math.random(20, 35) },
        dessert = { hunger = math.random(15, 25), stress = -math.random(10, 20) },
        drink = { thirst = math.random(30, 50) }
    }
    
    local benefits = baseBenefits[foodType] or baseBenefits.main
    
    -- Apply base benefits via server metadata updates (QBX style)
    if benefits.hunger then
        setPlayerHunger(source, benefits.hunger)
    end
    if benefits.thirst then
        setPlayerThirst(source, benefits.thirst)
    end
    -- Note: Stress effects removed as qbx_needs doesn't exist
    
    -- Apply ingredient-based bonuses
    if metadata and metadata.ingredients then
        local ingredients = metadata.ingredients
        if type(ingredients) == 'string' then
            ingredients = json.decode(ingredients) or {}
        end
        
        applyIngredientBonuses(source, ingredients)
    end
    
    if Config.Debug then print('[DEBUG] Applied food benefits - Type:', foodType, 'Benefits:', json.encode(benefits)) end
end

-- Function to apply drink benefits
function applyDrinkBenefits(source, metadata, itemName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end
    
    if Config.Debug then print('[DEBUG] Applying drink benefits for:', itemName) end
    
    -- Base thirst benefit for drinks
    local thirstBonus = math.random(30, 50)
    setPlayerThirst(source, thirstBonus)
    
    -- Apply ingredient-based bonuses if drink has ingredients
    if metadata and metadata.ingredients then
        local ingredients = metadata.ingredients
        if type(ingredients) == 'string' then
            ingredients = json.decode(ingredients) or {}
        end
        
        applyIngredientBonuses(source, ingredients)
    end
    
    if Config.Debug then print('[DEBUG] Applied drink benefits - Thirst:', thirstBonus) end
end

-- Function to apply ingredient-based bonuses (with random variation based on quality)
function applyIngredientBonuses(source, ingredients)
    if not ingredients or #ingredients == 0 then return end
    
    if Config.Debug then print('[DEBUG] Calculating ingredient quality bonuses for:', json.encode(ingredients)) end
    
    -- Calculate total ingredient quality bonus
    local totalHungerBonus = 0
    local totalThirstBonus = 0
    local totalHealthBonus = 0
    
    for _, ingredient in pairs(ingredients) do
        local ingredientConfig = Config.Ingredients[ingredient]
        
        if ingredientConfig then
            local category = ingredientConfig.category
            
            -- Each ingredient adds a random bonus within a range based on its quality
            if category == 'protein' then
                local bonus = math.random(20, 35) -- High-quality proteins vary
                totalHungerBonus = totalHungerBonus + bonus
                if Config.Debug then print('[DEBUG] Protein', ingredient, 'added hunger bonus:', bonus) end
            elseif category == 'grain' then
                local bonus = math.random(18, 28) -- Grains provide good base
                totalHungerBonus = totalHungerBonus + bonus
                if Config.Debug then print('[DEBUG] Grain', ingredient, 'added hunger bonus:', bonus) end
            elseif category == 'vegetables' then
                local bonus = math.random(10, 20) -- Vegetables are healthy
                local health = math.random(8, 15)
                totalHungerBonus = totalHungerBonus + bonus
                totalHealthBonus = totalHealthBonus + health
                if Config.Debug then print('[DEBUG] Vegetable', ingredient, 'added hunger:', bonus, 'health:', health) end
            elseif category == 'dairy' then
                local hunger = math.random(8, 18)
                local thirst = math.random(6, 14)
                totalHungerBonus = totalHungerBonus + hunger
                totalThirstBonus = totalThirstBonus + thirst
                if Config.Debug then print('[DEBUG] Dairy', ingredient, 'added hunger:', hunger, 'thirst:', thirst) end
            elseif category == 'seasoning' or category == 'oil' then
                local bonus = math.random(5, 12) -- Seasonings enhance flavor
                totalHungerBonus = totalHungerBonus + bonus
                if Config.Debug then print('[DEBUG] Seasoning/Oil', ingredient, 'enhanced food quality:', bonus) end
            elseif category == 'sugar' then
                local bonus = math.random(6, 15) -- Sugar gives quick energy
                totalHungerBonus = totalHungerBonus + bonus
                if Config.Debug then print('[DEBUG] Sugar', ingredient, 'added quick energy:', bonus) end
            elseif category == 'leavening' then
                local bonus = math.random(8, 16) -- Makes bread more filling
                totalHungerBonus = totalHungerBonus + bonus
                if Config.Debug then print('[DEBUG] Leavening', ingredient, 'made food more filling:', bonus) end
            end
        else
            if Config.Debug then
                print('[DEBUG] Unknown ingredient:', ingredient)
            end
        end
    end
    
    -- Apply calculated bonuses
    if totalHungerBonus > 0 then
        setPlayerHunger(source, totalHungerBonus)
        if Config.Debug then
            print('[DEBUG] Applied total ingredient hunger bonus:', totalHungerBonus)
        end
    end
    
    if totalThirstBonus > 0 then
        setPlayerThirst(source, totalThirstBonus)
        if Config.Debug then
            print('[DEBUG] Applied total ingredient thirst bonus:', totalThirstBonus)
        end
    end
    
    if totalHealthBonus > 0 then
        -- Apply limited vegetable health through our custom event
        TriggerEvent('ferp_restaurant:server:applyVegetableHealth', totalHealthBonus)
        if Config.Debug then
            print('[DEBUG] Triggered vegetable health event with amount:', totalHealthBonus)
        end
    end
end

-- Function to get bonus amount for ingredient category
function getBonusForCategory(category)
    local bonuses = {
        protein = 20,
        vegetables = 15,
        dairy = 15,
        grain = 25,
        seasoning = 10,
        oil = 12,
        sugar = 12,
        leavening = 15
    }
    
    return bonuses[category] or 10
end

-- Test command to check active column functionality
RegisterCommand('testfoodactive', function(source, args)
    if source == 0 then return end -- Console only
    
    local restaurantId = args[1] or 'burgershot'
    local itemName = args[2] or 'test'
    
    if Config.Debug then
        print('[FERP Restaurant Test] Testing active column for restaurant: ' .. restaurantId .. ', item: ' .. itemName)
    end
    
    -- Test query
    local result = MySQL.query.await('SELECT * FROM restaurant_food_items WHERE restaurant_id = ? LIMIT 5', {restaurantId})
    
    if result and #result > 0 then
        print('[FERP Restaurant Test] Found ' .. #result .. ' items:')
        for i, item in ipairs(result) do
            print('[FERP Restaurant Test] Item ' .. i .. ': ' .. item.name .. ', active: ' .. tostring(item.active))
        end
    else
        print('[FERP Restaurant Test] No items found for restaurant: ' .. restaurantId)
    end
    
    -- Test update
    local updateResult = MySQL.update.await('UPDATE restaurant_food_items SET active = 0 WHERE restaurant_id = ? LIMIT 1', {restaurantId})    
end, true)

-- ox_lib Callback for toggling food item active status
lib.callback.register('ferp_restaurant:server:toggleFoodItemActive', function(source, restaurantId, itemName)    
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then
        if Config.Debug then print('[FERP Restaurant Server] Player not found') end
        return nil
    end
    
    local playerData = Player.PlayerData
    local currentJob = playerData.job and playerData.job.name or 'none'
    
    -- Get restaurant from player's job (similar to delete function)
    local playerRestaurantId = nil
    for restId, restData in pairs(Config.Restaurants) do
        if restData.job == currentJob then
            playerRestaurantId = restId
            break
        end
    end
    
    if not playerRestaurantId or playerRestaurantId ~= restaurantId then
        print('[FERP Restaurant Server] Player job mismatch - Current job: ' .. currentJob .. ', Player restaurant: ' .. tostring(playerRestaurantId) .. ', Required: ' .. restaurantId)
        return nil
    end
    
    -- Check permissions
    if playerData.job.grade.level < 2 then
        print('[FERP Restaurant Server] Insufficient permissions. Grade level: ' .. tostring(playerData.job.grade.level))
        return nil
    end
    
    -- Check if active column exists by trying to query it
    local testQuery = MySQL.query.await('SHOW COLUMNS FROM restaurant_food_items LIKE "active"', {})
    
    if not testQuery or #testQuery == 0 then
        if Config.Debug then print('[FERP Restaurant Server] Active column does not exist in database!') end
        return nil
    end
    
    -- First get current status with more complete query
    local currentItem = MySQL.query.await('SELECT * FROM restaurant_food_items WHERE restaurant_id = ? AND name = ?', {restaurantId, itemName})
    
    if not currentItem or #currentItem == 0 then
        print('[FERP Restaurant Server] Food item not found - Restaurant: ' .. restaurantId .. ', Item: ' .. itemName)
        return nil
    end
    
    local item = currentItem[1]
    local currentActive = item.active
    
    -- Handle different data types and NULL values properly
    local isCurrentlyActive = false
    if currentActive == nil then
        isCurrentlyActive = true -- Default to active if NULL
        if Config.Debug then print('[FERP Restaurant Server] Active column was NULL, treating as active') end
    elseif type(currentActive) == 'boolean' then
        isCurrentlyActive = currentActive
        if Config.Debug then print('[FERP Restaurant Server] Active column is boolean: ' .. tostring(currentActive)) end
    elseif type(currentActive) == 'number' then
        isCurrentlyActive = currentActive == 1
        if Config.Debug then print('[FERP Restaurant Server] Active column is number: ' .. tostring(currentActive) .. ' -> ' .. tostring(isCurrentlyActive)) end
    else
        -- Handle other types (strings, etc.)
        isCurrentlyActive = currentActive == 1 or currentActive == '1' or currentActive == true or currentActive == 'true'
        print('[FERP Restaurant Server] Active column is other type: ' .. tostring(currentActive) .. ' -> ' .. tostring(isCurrentlyActive))
    end
    
    -- Toggle the status: if currently active, make inactive (0), if inactive, make active (1)
    local newActive = isCurrentlyActive and 0 or 1
        
    -- Update the active status
    local updateResult = MySQL.update.await('UPDATE restaurant_food_items SET active = ? WHERE restaurant_id = ? AND name = ?', {
        newActive, restaurantId, itemName
    })
        
    if updateResult and updateResult > 0 then
        
        -- Trigger client update
        TriggerClientEvent('ferp_restaurant:client:foodItemsUpdated', -1, restaurantId)
        
        return newActive == 1
    else
        return nil
    end
end)
