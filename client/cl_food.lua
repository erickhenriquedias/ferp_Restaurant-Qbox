-- Food management client functions
local currentRestaurantData = {}

-- Event to update food items when changed
RegisterNetEvent('ferp_restaurant:client:foodItemsUpdated', function(restaurantId)
    -- Refresh cached data
    currentRestaurantData[restaurantId] = nil
end)

-- Event to update menu when changed
RegisterNetEvent('ferp_restaurant:client:menuUpdated', function(restaurantId)
    -- Refresh cached data
    currentRestaurantData[restaurantId] = nil
end)

-- Open cooking menu (updated to support category filtering)
RegisterNetEvent('ferp_restaurant:client:openCookingMenu', function(restaurantId, category)
    if Config.Debug then print('[FERP Restaurant Client] openCookingMenu called for: ' .. tostring(restaurantId) .. ', category: ' .. tostring(category)) end
    
    if not IsEmployedAtRestaurant(restaurantId) then
        if Config.Debug then print('[FERP Restaurant Client] Not employed at restaurant') end
        return lib.notify({
            title = 'Restaurant',
            description = 'You are not employed at this restaurant',
            type = 'error'
        })
    end
    
    if Config.Debug then print('[FERP Restaurant Client] Calling getActiveFoodItems callback...') end
    
    -- Get active food items for this restaurant using ox_lib callback
    local foodItems = lib.callback.await('ferp_restaurant:server:getActiveFoodItems', false, restaurantId)
    
    if Config.Debug then print('[FERP Restaurant Client] Callback response received. Items: ' .. (foodItems and #foodItems or 'nil')) end
    
    if not foodItems or next(foodItems) == nil then
        if Config.Debug then print('[FERP Restaurant Client] No food items found') end
        return lib.notify({
            title = 'Cooking',
            description = 'No food items configured for this restaurant',
            type = 'error'
        })
    end
        
    if Config.Debug then print('[FERP Restaurant Client] Processing ' .. #foodItems .. ' food items') end
    
    -- If category is specified, show items directly for that category
    if category then
        local categoryItems = {}
        for _, item in pairs(foodItems) do
            if item.food_type == category then
                categoryItems[#categoryItems + 1] = item
            end
        end
        
        if #categoryItems == 0 then
            return lib.notify({
                title = 'Cooking',
                description = 'No items available for ' .. category,
                type = 'error'
            })
        end
        
        ShowFoodTypeMenu(restaurantId, categoryItems, category)
        return
    end
end)

-- Show food type submenu
function ShowFoodTypeMenu(restaurantId, items, foodType)
    local options = {}
    
    for _, item in pairs(items) do
        -- Show ingredients needed for crafting
        local ingredientsText = ''
        if item.ingredients and #item.ingredients > 0 then
            local ingredientLabels = {}
            for _, ingredient in pairs(item.ingredients) do
                local ingredientData = Config.Ingredients[ingredient]
                if ingredientData then
                    ingredientLabels[#ingredientLabels + 1] = ingredientData.label
                end
            end
            if #ingredientLabels > 0 then
                ingredientsText = '\nIngredients needed: ' .. table.concat(ingredientLabels, ', ')
            end
        end
        
        options[#options + 1] = {
            title = item.display_name or item.name,
            description = (item.description or 'Delicious food') .. ingredientsText,
            icon = 'utensils',
            image = item.image_url, -- Adiciona prévia da imagem
            onSelect = function()
                StartCooking(restaurantId, item)
            end
        }
    end
    
    lib.registerContext({
        id = 'ferp_restaurant_food_type',
        title = string.upper(foodType:sub(1,1)) .. foodType:sub(2) .. ' Dishes',
        options = options
    })
    
    lib.showContext('ferp_restaurant_food_type')
end

-- Start cooking process
function StartCooking(restaurantId, item)
    if Config.Debug then print('[FERP Restaurant Client] Starting cooking for item: ' .. (item.display_name or item.name)) end
    
    -- First, ask for quantity
    local input = lib.inputDialog('Select Quantity', {
        {
            type = 'number',
            label = 'Quantity to Cook',
            description = 'How many ' .. (item.display_name or item.name) .. ' do you want to cook?',
            required = true,
            min = 1,
            max = 50,
            default = 1
        }
    })
    
    if not input or not input[1] then
        return
    end
    
    local quantity = tonumber(input[1])
    if not quantity or quantity < 1 then
        return lib.notify({
            title = 'Invalid Quantity',
            description = 'Please enter a valid quantity',
            type = 'error'
        })
    end
    
    -- Check if player has required ingredients (multiplied by quantity)
    if item.ingredients and #item.ingredients > 0 then
        -- Create ingredient list with quantities
        local requiredIngredients = {}
        for _, ingredient in pairs(item.ingredients) do
            requiredIngredients[ingredient] = (requiredIngredients[ingredient] or 0) + quantity
        end
        
        -- Check ingredients via server callback
        local hasIngredients, missingIngredients = lib.callback.await('ferp_restaurant:server:checkIngredients', false, item.ingredients, quantity)
        
        if not hasIngredients then
            local missingText = ''
            if missingIngredients and #missingIngredients > 0 then
                local missingLabels = {}
                for _, ingredient in pairs(missingIngredients) do
                    local ingredientData = Config.Ingredients[ingredient]
                    if ingredientData then
                        missingLabels[#missingLabels + 1] = ingredientData.label .. ' x' .. quantity
                    end
                end
                missingText = '\nMissing: ' .. table.concat(missingLabels, ', ')
            end
            
            return lib.notify({
                title = 'Cooking Failed',
                description = 'You don\'t have the required ingredients' .. missingText,
                type = 'error'
            })
        end
    end
    
    -- Show progress bar (duration scales with quantity)
    local success = lib.progressBar({
        duration = math.min(3000 + (quantity * 1000), 15000), -- Min 3s, max 15s
        label = 'Cooking ' .. quantity .. 'x ' .. (item.display_name or item.name),
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@amb@business@coc@coc_unpack_cut@',
            clip = 'fullcut_cycle_v6_cokecutter'
        }
    })
    
    if success then
        if Config.Debug then print('[FERP Restaurant Client] Cooking completed successfully') end
        
        -- Craft items (consume ingredients and give result) via server
        TriggerServerEvent('ferp_restaurant:server:craftItem', item, quantity)
    else
        if Config.Debug then print('[FERP Restaurant Client] Cooking was cancelled') end
        
        lib.notify({
            title = 'Cooking Cancelled',
            description = 'You stopped cooking',
            type = 'error'
        })
    end
end

