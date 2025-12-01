-- Use the global 'lib' table provided by ox_lib

-- Alternative event that accepts only restaurantId
RegisterNetEvent('ferp_restaurant:client:openManagement', function(restaurantId)
    if Config.Debug then print('[DEBUG] Management event triggered for restaurant: ' .. tostring(restaurantId)) end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then
        if Config.Debug then print('[DEBUG] Restaurant data not found for: ' .. tostring(restaurantId)) end
        return
    end
    
    if Config.Debug then print('[DEBUG] Restaurant data found, triggering management menu') end
    TriggerEvent('ferp_restaurant:client:openManagementMenu', restaurantId, restaurantData)
end)

RegisterNetEvent('ferp_restaurant:client:openManagementMenu', function(restaurantId, restaurantData)
    if Config.Debug then print('[DEBUG] Management menu event triggered for: ' .. tostring(restaurantId)) end
    
    if not IsEmployedAtRestaurant(restaurantId) then
        if Config.Debug then print('[DEBUG] Not employed at restaurant: ' .. tostring(restaurantId)) end
        return lib.notify({
            title = 'Restaurant',
            description = 'You are not employed at this restaurant',
            type = 'error'
        })
    end
    
    if Config.Debug then print('[DEBUG] Employment check passed') end
    
    local PlayerJob = GetPlayerJob()
    if Config.Debug then print('[DEBUG] Player job: ' .. json.encode(PlayerJob)) end
    
    if not PlayerJob or not PlayerJob.grade then
        if Config.Debug then print('[DEBUG] Invalid player job data') end
        return lib.notify({
            title = 'Management',
            description = 'Invalid job data',
            type = 'error'
        })
    end
    
    if PlayerJob.grade.level < 2 then
        if Config.Debug then print('[DEBUG] Insufficient permissions. Grade level: ' .. tostring(PlayerJob.grade.level)) end
        return lib.notify({
            title = 'Management',
            description = 'You do not have management permissions (need grade 2+)',
            type = 'error'
        })
    end
    
    if Config.Debug then print('[DEBUG] Permission check passed, opening management menu') end
    
    local options = {
        {
            title = 'QBX Management',
            description = 'Open employee management system',
            icon = 'users',
            onSelect = function()
                -- Block management zone interaction
                BossMenuOpen = true
                
                CreateThread(function()
                    Wait(100)
                    
                    local ok = pcall(function()
                        exports.qbx_management:OpenBossMenu('job')
                    end)
                    
                    if not ok then
                        lib.notify({
                            title = 'Management',
                            description = 'Boss menu not available',
                            type = 'error'
                        })
                        BossMenuOpen = false
                        return
                    end
                    
                    -- Wait until NUI focus is released
                    while IsNuiFocused() do
                        Wait(200)
                    end
                    
                    
                    Wait(300)
                    
                    -- Hide the TextUI that qbx_management
                    lib.hideTextUI()
                    
                    BossMenuOpen = false
                end)
            end
        },
        {
            title = 'Food Management',
            description = 'Create and manage food items',
            icon = 'utensils',
            onSelect = function()
                OpenFoodManagement(restaurantId)
            end
        },
        {
            title = 'Food Control',
            description = 'Activate/deactivate food items for cooking',
            icon = 'toggle-on',
            onSelect = function()
                OpenFoodControlMenu(restaurantId)
            end
        },
        {
            title = 'Toy Management',
            description = 'Create and manage restaurant toys',
            icon = 'gift',
            onSelect = function()
                OpenToyManagement(restaurantId)
            end
        },
    }
    
    lib.registerContext({
        id = 'ferp_restaurant_management',
        title = restaurantData.name .. ' Management',
        options = options
    })
    
    lib.showContext('ferp_restaurant_management')
end)

-- Food management functions
function OpenFoodManagement(restaurantId)
    local foodItems = lib.callback.await('ferp_restaurant:server:getFoodItems', false, restaurantId)
    
    local options = {
        {
            title = 'Create Food Item',
            description = 'Add a new food item',
            icon = 'plus',
            onSelect = function()
                CreateFoodItem(restaurantId)
            end
        }
    }

    -- Add existing food items option if there are items
    if foodItems and next(foodItems) ~= nil then
        options[#options + 1] = {
            title = 'Manage Existing Items',
            description = 'View and manage existing food items',
            icon = 'edit',
            onSelect = function()
                ShowExistingFoodItems(restaurantId, foodItems)
            end
        }
    end

    options[#options + 1] = {
        title = 'Back',
        description = 'Return to management menu',
        icon = 'arrow-left',
        onSelect = function()
            TriggerServerEvent('ferp_restaurant:server:openManagement', restaurantId)
        end
    }
    
    lib.registerContext({
        id = 'ferp_restaurant_food_mgmt',
        title = 'Food Management',
        options = options
    })
    
    lib.showContext('ferp_restaurant_food_mgmt')
end

function CreateFoodItem(restaurantId)
    local input = lib.inputDialog('Create Food Item', {
        {type = 'input', label = 'Food Name', description = 'Enter the name of the food', required = true, max = 50},
        {type = 'textarea', label = 'Description', description = 'Enter food description', required = true, max = 200},
        {type = 'input', label = 'Image URL', description = 'Enter image URL for the food', required = true},
        {type = 'select', label = 'Food Type', description = 'Select the type of food', required = true, options = {
            {value = 'main', label = 'Main Dish'},
            {value = 'side', label = 'Side Dish'},
            {value = 'dessert', label = 'Dessert'},
            {value = 'drink', label = 'Drink'}
        }}
    })

    -- Check if user cancelled the first dialog
    if not input then 
        if Config.Debug then print('[DEBUG] User cancelled food item creation') end
        return 
    end

    local data = {
        name = input[1],
        description = input[2],
        image_url = input[3],
        food_type = input[4]
    }

    -- Validate required fields
    if not data.name or data.name == '' or not data.description or data.description == '' or not data.image_url or data.image_url == '' then
        lib.notify({
            title = 'Error',
            description = 'All fields are required',
            type = 'error'
        })
        return
    end

    -- Show ingredient selection for all food types
    local ingredientOptions = {}
    for ingredientId, ingredientData in pairs(Config.Ingredients) do
        ingredientOptions[#ingredientOptions + 1] = {
            value = ingredientId,
            label = ingredientData.label
        }
    end

    local ingredientInput = lib.inputDialog('Select Ingredients (up to ' .. Config.MaxIngredients .. ') - Optional for ' .. data.food_type, {
        {type = 'multi-select', label = 'Ingredients', description = 'Select ingredients (optional for non-main dishes)', required = data.food_type == 'main', options = ingredientOptions}
    })

    -- Check if user cancelled ingredient selection
    if not ingredientInput then
        -- User cancelled ingredient selection - always cancel the whole process
        if Config.Debug then print('[DEBUG] User cancelled ingredient selection, cancelling food creation') end
        return
    elseif ingredientInput and ingredientInput[1] then
        -- Process selected ingredients
        for i, ingredient in ipairs(ingredientInput[1]) do
            if i <= Config.MaxIngredients then
                data['ingredient_' .. i] = ingredient
            end
        end
    elseif data.food_type == 'main' then
        -- Main dish but no ingredients selected (empty array)
        return
    end

    local success, message = lib.callback.await('ferp_restaurant:server:createFoodItem', false, data)
    
    if success then
        lib.notify({
            title = 'Food Management',
            description = message or 'Food item created successfully',
            type = 'success'
        })
        OpenFoodManagement(restaurantId)
    else
        lib.notify({
            title = 'Food Management',
            description = message or 'Failed to create food item',
            type = 'error'
        })
    end
end

function ShowExistingFoodItems(restaurantId, foodItems)
    local options = {}
    
    for itemId, item in pairs(foodItems) do
        local ingredientsText = ''
        if item.ingredients and #item.ingredients > 0 then
            local ingredientLabels = {}
            for _, ingredient in pairs(item.ingredients) do
                local ingredientData = Config.Ingredients[ingredient]
                if ingredientData then
                    ingredientLabels[#ingredientLabels + 1] = ingredientData.label
                end
            end
            ingredientsText = '\nIngredients: ' .. table.concat(ingredientLabels, ', ')
        end
        
        options[#options + 1] = {
            title = item.name .. ' (' .. item.food_type:gsub("^%l", string.upper) .. ')',
            description = item.description .. ingredientsText,
            icon = 'trash',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = 'Delete Food Item',
                    content = 'Are you sure you want to delete "' .. item.name .. '"?',
                    centered = true,
                    cancel = true
                })
                
                if confirm == 'confirm' then
                    local success, message = lib.callback.await('ferp_restaurant:server:deleteFoodItem', false, itemId, restaurantId, item.name)
                    
                    if success then
                        lib.notify({
                            title = 'Food Management',
                            description = message or 'Food item deleted successfully',
                            type = 'success'
                        })
                        OpenFoodManagement(restaurantId)
                    else
                        lib.notify({
                            title = 'Food Management',
                            description = message or 'Failed to delete food item',
                            type = 'error'
                        })
                    end
                end
            end
        }
    end
    
    options[#options + 1] = {
        title = 'Back',
        description = 'Return to food management',
        icon = 'arrow-left',
        onSelect = function()
            OpenFoodManagement(restaurantId)
        end
    }
    
    lib.registerContext({
        id = 'ferp_restaurant_existing_food',
        title = 'Existing Food Items',
        options = options
    })
    
    lib.showContext('ferp_restaurant_existing_food')
end

-- Duty toggle function
function ToggleDuty(restaurantId)
    local success, message = lib.callback.await('ferp_restaurant:server:toggleDuty', false, restaurantId)
    
    if success then
        lib.notify({
            title = 'Duty Status',
            description = message,
            type = 'success'
        })
    else
        lib.notify({
            title = 'Duty Status',
            description = message or 'Failed to toggle duty',
            type = 'error'
        })
    end
end

-- Food control menu function (for activating/deactivating items)
function OpenFoodControlMenu(restaurantId)
    local foodItems = lib.callback.await('ferp_restaurant:server:getFoodItems', false, restaurantId)
    
    if Config.Debug then print('[DEBUG] Got food items:', json.encode(foodItems)) end
    
    if not foodItems or #foodItems == 0 then
        lib.notify({
            title = 'Food Control',
            description = 'No food items found',
            type = 'error'
        })
        return
    end
    
    local options = {}
    
    -- Group items by category
    local categories = {
        main = {title = 'Main Dishes', items = {}},
        side = {title = 'Side Dishes', items = {}},
        dessert = {title = 'Desserts', items = {}},
        drink = {title = 'Drinks', items = {}}
    }
    
    for _, item in pairs(foodItems) do
        if Config.Debug then print('[DEBUG] Processing item:', item.name, 'type:', item.food_type) end
        if categories[item.food_type] then
            table.insert(categories[item.food_type].items, item)
            if Config.Debug then print('[DEBUG] Added to category:', item.food_type, 'total items:', #categories[item.food_type].items) end
        else
            if Config.Debug then print('[DEBUG] Unknown food_type for item:', item.name, 'type:', item.food_type) end
        end
    end
    
    -- Create menu options for each category
    for categoryKey, categoryData in pairs(categories) do
        if Config.Debug then print('[DEBUG] Category:', categoryKey, 'has', #categoryData.items, 'items') end
        if #categoryData.items > 0 then
            options[#options + 1] = {
                title = categoryData.title .. ' (' .. #categoryData.items .. ')',
                description = 'Manage ' .. string.lower(categoryData.title),
                icon = 'list',
                onSelect = function()
                    ShowCategoryFoodControl(restaurantId, categoryKey, categoryData.items)
                end
            }
        end
    end
    
    options[#options + 1] = {
        title = 'Back',
        description = 'Return to management menu',
        icon = 'arrow-left',
        onSelect = function()
            TriggerEvent('ferp_restaurant:client:openManagement', restaurantId)
        end
    }
    
    lib.registerContext({
        id = 'ferp_restaurant_food_control',
        title = 'Food Control Center',
        options = options
    })
    
    lib.showContext('ferp_restaurant_food_control')
end

-- Show food control for specific category
function ShowCategoryFoodControl(restaurantId, category, items)
    local options = {}
    
    for _, item in pairs(items) do
        -- Handle active status with same logic as server
        local isActive = false
        if item.active == nil then
            isActive = true -- Default to active if NULL
        elseif type(item.active) == 'boolean' then
            isActive = item.active
        elseif type(item.active) == 'number' then
            isActive = item.active == 1
        else
            -- Handle other types (strings, etc.)
            isActive = item.active == 1 or item.active == '1' or item.active == true or item.active == 'true'
        end
        
        local statusIcon = isActive and '✅' or '❌'
        local statusText = isActive and 'Active' or 'Inactive'
        
        options[#options + 1] = {
            title = statusIcon .. ' ' .. item.name,
            description = 'Status: ' .. statusText .. ' - Click to toggle',
            image = item.image_url,
            onSelect = function()
                ToggleFoodItemStatus(restaurantId, item.name, category, items)
            end
        }
    end
    
    options[#options + 1] = {
        title = 'Back',
        description = 'Return to food control menu',
        icon = 'arrow-left',
        onSelect = function()
            OpenFoodControlMenu(restaurantId)
        end
    }
    
    lib.registerContext({
        id = 'ferp_restaurant_category_control',
        title = string.upper(category:sub(1,1)) .. category:sub(2) .. ' Control',
        options = options
    })
    
    lib.showContext('ferp_restaurant_category_control')
end

-- Toggle food item active status
function ToggleFoodItemStatus(restaurantId, itemName, category, items)
    if Config.Debug then print('[FERP Restaurant Client] Toggling status for item: ' .. itemName .. ' in restaurant: ' .. restaurantId) end
    
    local success = lib.callback.await('ferp_restaurant:server:toggleFoodItemActive', false, restaurantId, itemName)
    
    if Config.Debug then print('[FERP Restaurant Client] Toggle result: ' .. tostring(success)) end
    
    if success == true then
        lib.notify({
            title = 'Food Control',
            description = itemName .. ' has been activated',
            type = 'success'
        })
        
        -- Refresh the menu to show updated status
        Wait(1000) -- Increased delay to ensure database update
        
        -- Get fresh data from server before refreshing
        local updatedFoodItems = lib.callback.await('ferp_restaurant:server:getFoodItems', false, restaurantId)
        local updatedItems = {}
        
        for _, item in pairs(updatedFoodItems) do
            if item.food_type == category then
                table.insert(updatedItems, item)
            end
        end
        
        ShowCategoryFoodControl(restaurantId, category, updatedItems)
    elseif success == false then
        lib.notify({
            title = 'Food Control',
            description = itemName .. ' has been deactivated',
            type = 'success'
        })
        
        -- Refresh the menu to show updated status
        Wait(1000) -- Increased delay to ensure database update
        
        -- Get fresh data from server before refreshing
        local updatedFoodItems = lib.callback.await('ferp_restaurant:server:getFoodItems', false, restaurantId)
        local updatedItems = {}
        
        for _, item in pairs(updatedFoodItems) do
            if item.food_type == category then
                table.insert(updatedItems, item)
            end
        end
        
        ShowCategoryFoodControl(restaurantId, category, updatedItems)
    elseif success == nil then
        lib.notify({
            title = 'Error',
            description = 'Failed to toggle food item status. Check permissions or database column.',
            type = 'error'
        })
    else
        lib.notify({
            title = 'Food Control',
            description = 'Unexpected response: ' .. tostring(success),
            type = 'error'
        })
    end
end

function OpenToyManagement(restaurantId)
    lib.callback('ferp_restaurant:server:getToys', false, function(toys)
        if not toys then return end
        
        local options = {}
        
        -- Add create toy option
        table.insert(options, {
            title = 'Create Toy',
            description = 'Create a new toy for the restaurant',
            icon = 'plus',
            onSelect = function()
                CreateToy(restaurantId)
            end
        })
        
        -- Add existing toys
        for _, toy in pairs(toys) do
            table.insert(options, {
                title = toy.name,
                description = 'Description: ' .. toy.description,
                icon = 'gift',
                onSelect = function()
                    lib.registerContext({
                        id = 'ferp_restaurant_toy_options',
                        title = toy.name,
                        options = {
                            {
                                title = 'Delete Toy',
                                description = 'Remove this toy from the restaurant',
                                icon = 'trash',
                                onSelect = function()
                                    DeleteToy(restaurantId, toy.id)
                                end
                            }
                        }
                    })
                    lib.showContext('ferp_restaurant_toy_options')
                end
            })
        end
        
        if #options == 1 then
            table.insert(options, {
                title = 'No toys available',
                description = 'Create your first toy',
                icon = 'info',
                disabled = true
            })
        end
        
        lib.registerContext({
            id = 'ferp_restaurant_toy_management',
            title = 'Toy Management',
            options = options
        })
        lib.showContext('ferp_restaurant_toy_management')
    end, restaurantId)
end

function CreateToy(restaurantId)
    local input = lib.inputDialog('Create Toy', {
        {type = 'input', label = 'Toy Name', description = 'Name of the toy', required = true, max = 50},
        {type = 'input', label = 'Description', description = 'Description of the toy', required = true, max = 100},
        {type = 'input', label = 'Image URL', description = 'URL of the toy image (optional)', required = false, max = 255}
    })
    
    if not input then return end
    
    local toyName = input[1]
    local toyDescription = input[2]
    local toyImage = input[3]
    
    if not toyName or toyName == '' or not toyDescription or toyDescription == '' then
        lib.notify({
            title = 'Error',
            description = 'Name and description are required',
            type = 'error'
        })
        return
    end
    
    lib.callback('ferp_restaurant:server:createToy', false, function(success)
        if success then
            lib.notify({
                title = 'Success',
                description = 'Toy created successfully',
                type = 'success'
            })
            OpenToyManagement(restaurantId) -- Refresh the menu
        else
            lib.notify({
                title = 'Error',
                description = 'Failed to create toy',
                type = 'error'
            })
        end
    end, restaurantId, toyName, toyDescription, toyImage)
end

function DeleteToy(restaurantId, toyId)
    lib.callback('ferp_restaurant:server:deleteToy', false, function(success)
        if success then
            lib.notify({
                title = 'Success',
                description = 'Toy deleted successfully',
                type = 'success'
            })
            OpenToyManagement(restaurantId) -- Refresh the menu
        else
            lib.notify({
                title = 'Error',
                description = 'Failed to delete toy',
                type = 'error'
            })
        end
    end, restaurantId, toyId)
end
