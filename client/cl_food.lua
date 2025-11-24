-- Food management client functions
-- Use the global 'lib' table provided by ox_lib (do NOT assign exports.ox_lib)
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
    
    if not exports['ferp_restaurant']:IsEmployedAtRestaurant(restaurantId) then
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
        
    -- Create context menu options (show all categories)
    local options = {}
    
    -- Group by food type
    local groupedItems = {
        main = {},
        side = {},
        dessert = {},
        drink = {}
    }
    
    for _, item in pairs(foodItems) do
        if groupedItems[item.food_type] then
            groupedItems[item.food_type][#groupedItems[item.food_type] + 1] = item
        end
    end
        
        -- Add main dishes
        if #groupedItems.main > 0 then
            options[#options + 1] = {
                title = '🍽️ Main Dishes',
                description = 'Cook main course meals',
                icon = 'utensils',
                onSelect = function()
                    ShowFoodTypeMenu(restaurantId, groupedItems.main, 'main')
                end
            }
        end
        
        -- Add side dishes
        if #groupedItems.side > 0 then
            options[#options + 1] = {
                title = '🥗 Side Dishes',
                description = 'Cook side dishes',
                icon = 'leaf',
                onSelect = function()
                    ShowFoodTypeMenu(restaurantId, groupedItems.side, 'side')
                end
            }
        end
        
        -- Add desserts
        if #groupedItems.dessert > 0 then
            options[#options + 1] = {
                title = '🍰 Desserts',
                description = 'Prepare desserts',
                icon = 'birthday-cake',
                onSelect = function()
                    ShowFoodTypeMenu(restaurantId, groupedItems.dessert, 'dessert')
                end
            }
        end
        
        -- Add drinks
        if #groupedItems.drink > 0 then
            options[#options + 1] = {
                title = '🥤 Drinks',
                description = 'Prepare beverages',
                icon = 'glass-whiskey',
                onSelect = function()
                    ShowFoodTypeMenu(restaurantId, groupedItems.drink, 'drink')
                end
            }
        end
        
        if #options == 0 then
            return lib.notify({
                title = 'Cooking',
                description = 'No food items available to cook',
                type = 'error'
            })
        end
        
        -- Show context menu
        lib.registerContext({
            id = 'ferp_restaurant_cooking',
            title = 'Cooking Menu',
            options = options
        })
        
        lib.showContext('ferp_restaurant_cooking')
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
        for i = 1, quantity do
            TriggerServerEvent('ferp_restaurant:server:craftItem', item)
        end
        
        lib.notify({
            title = 'Cooking Complete',
            description = 'You successfully cooked ' .. quantity .. 'x ' .. (item.display_name or item.name),
            type = 'success'
        })
    else
        if Config.Debug then print('[FERP Restaurant Client] Cooking was cancelled') end
        
        lib.notify({
            title = 'Cooking Cancelled',
            description = 'You stopped cooking',
            type = 'error'
        })
    end
end

-- Open customer menu (for ordering)
RegisterNetEvent('ferp_restaurant:client:openMenu', function(restaurantId)
    if Config.Debug then print('[FERP Restaurant Client] Opening customer menu for: ' .. tostring(restaurantId)) end
    
    -- Get menu items for this restaurant using ox_lib callback
    local menuItems = lib.callback.await('ferp_restaurant:server:getMenuItems', false, restaurantId)
    
    if Config.Debug then print('[FERP Restaurant Client] Menu callback response received. Items: ' .. (menuItems and #menuItems or 'nil')) end
    
    if not menuItems or next(menuItems) == nil then
        if Config.Debug then print('[FERP Restaurant Client] No menu items found') end
        return lib.notify({
            title = 'Restaurant Menu',
            description = 'No menu items available at this restaurant',
            type = 'error'
        })
    end
    
    if Config.Debug then print('[FERP Restaurant Client] Processing ' .. #menuItems .. ' menu items') end
    
    -- Create context menu options
    local options = {}
    
    for _, item in pairs(menuItems) do
        -- Show ingredients instead of price
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
                ingredientsText = '\nIngredients: ' .. table.concat(ingredientLabels, ', ')
            end
        end
        
        options[#options + 1] = {
            title = item.display_name or item.name,
            description = (item.description or 'Delicious food') .. ingredientsText,
            icon = 'hamburger',
            onSelect = function()
                if Config.Debug then print('[FERP Restaurant Client] Ordering item: ' .. (item.display_name or item.name)) end
                -- Order this item (craft with ingredients)
                TriggerServerEvent('ferp_restaurant:server:craftItem', restaurantId, item)
            end
        }
    end
    
    if #options == 0 then
        return lib.notify({
            title = 'Restaurant Menu',
            description = 'No menu items available',
            type = 'error'
        })
    end
    
    if Config.Debug then print('[FERP Restaurant Client] Showing menu with ' .. #options .. ' options') end
    
    -- Show context menu
    lib.registerContext({
        id = 'ferp_restaurant_menu',
        title = 'Restaurant Menu',
        options = options
    })
    
    lib.showContext('ferp_restaurant_menu')
end)
