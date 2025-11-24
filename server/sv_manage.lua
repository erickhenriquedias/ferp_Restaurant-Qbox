-- Event for opening fridge
RegisterNetEvent('ferp_restaurant:server:openFridge', function(restaurantId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    if Config.Debug then print('[FERP Restaurant] Fridge opening event triggered for restaurant: ' .. restaurantId) end

    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then 
        if Config.Debug then print('[FERP Restaurant] ERROR: Restaurant data not found for: ' .. restaurantId) end
        return 
    end

    -- Check if player is employed at this restaurant
    if player.PlayerData.job.name ~= restaurantData.job then
        if Config.Debug then print('[FERP Restaurant] Player not employed at restaurant. Job: ' .. player.PlayerData.job.name .. ', Required: ' .. restaurantData.job) end
        return lib.notify(src, {
            title = 'Restaurant',
            description = 'You are not employed at this restaurant',
            type = 'error'
        })
    end

    local stashId = 'restaurant_fridge_' .. restaurantId
    if Config.Debug then print('[FERP Restaurant] Opening fridge stash: ' .. stashId) end
    
    -- Apply refrigeration effect to existing items
    local stashInventory = exports.ox_inventory:GetInventory(stashId)
    if stashInventory and stashInventory.items then
        local preservedItems = 0
        for slot, item in pairs(stashInventory.items) do
            if item and item.metadata then
                -- Check if item is food
                local isFoodItem = false
                for _, foodType in pairs(Config.FridgeAllowedItems) do
                    if item.name == foodType then
                        isFoodItem = true
                        break
                    end
                end
                
                if isFoodItem and not item.metadata.refrigerated then
                    -- Apply refrigeration effect (extend expiry by 4x)
                    if item.metadata.expiry then
                        local currentTime = os.time()
                        local timeRemaining = item.metadata.expiry - currentTime
                        if timeRemaining > 0 then
                            item.metadata.expiry = currentTime + (timeRemaining * 4)
                            item.metadata.refrigerated = true
                            -- Update item metadata using the correct ox_inventory method
                            exports.ox_inventory:SetMetadata(stashId, slot, item.metadata)
                            preservedItems = preservedItems + 1
                        end
                    else
                        -- Set 24 hour expiry for refrigerated food
                        item.metadata.expiry = os.time() + (24 * 60 * 60)
                        item.metadata.refrigerated = true
                        -- Update item metadata using the correct ox_inventory method
                        exports.ox_inventory:SetMetadata(stashId, slot, item.metadata)
                        preservedItems = preservedItems + 1
                    end
                end
            end
        end
        
        -- Notify player if items were preserved
        if preservedItems > 0 then
            if Config.Debug then print('[FERP Restaurant] ' .. preservedItems .. ' food items were preserved by refrigeration') end
            TriggerClientEvent('ox_lib:notify', src, {
                title = 'Fridge',
                description = preservedItems .. ' food items preserved by refrigeration!',
                type = 'success',
                duration = 3000
            })
        else
            if Config.Debug then print('[FERP Restaurant] No food items needed preservation') end
        end
    else
        if Config.Debug then print('[FERP Restaurant] No items found in fridge or empty inventory') end
    end

    -- Open the fridge stash
    if Config.Debug then print('[FERP Restaurant] Opening fridge inventory for player') end
    exports.ox_inventory:forceOpenInventory(src, 'stash', 'restaurant_fridge_' .. restaurantId)
end)

-- Event for opening shelf
RegisterNetEvent('ferp_restaurant:server:openShelf', function(restaurantId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then return end
    
    -- Check if player is employed at this restaurant
    if player.PlayerData.job.name ~= restaurantData.job then
        return lib.notify(src, {
            title = 'Restaurant',
            description = 'You are not employed at this restaurant',
            type = 'error'
        })
    end
    
    -- Open the shelf stash
    exports.ox_inventory:forceOpenInventory(src, 'stash', 'restaurant_shelf_' .. restaurantId)
end)

-- Callback for getting employee list
lib.callback.register('ferp_restaurant:server:getEmployees', function(source, restaurantId)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return {} end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then return {} end
    
    -- Check if player is employed at this restaurant with management permissions
    if player.PlayerData.job.name ~= restaurantData.job or player.PlayerData.job.grade.level < 2 then
        return {}
    end
    
    local Restaurants = exports['ferp_restaurant']:GetRestaurants()
    local restaurant = Restaurants[restaurantId]
    if not restaurant then return {} end
    
    return restaurant.employees or {}
end)

-- Callback for duty status
lib.callback.register('ferp_restaurant:server:toggleDuty', function(source, restaurantId)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then return false end
    
    -- Check if player is employed at this restaurant
    if player.PlayerData.job.name ~= restaurantData.job then
        return false, 'You are not employed at this restaurant'
    end
    
    local onDuty = not player.PlayerData.job.onduty
    exports.qbx_core:ToggleDuty(source, onDuty)
    
    local Restaurants = exports['ferp_restaurant']:GetRestaurants()
    local restaurant = Restaurants[restaurantId]
    if restaurant and restaurant.employees[source] then
        restaurant.employees[source].onDuty = onDuty
    end
    
    return true, onDuty and 'You are now on duty' or 'You are now off duty'
end)

-- Event for opening management menu
RegisterNetEvent('ferp_restaurant:server:openManagement', function(restaurantId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then return end
    
    -- Check if player is employed at this restaurant with management permissions
    if player.PlayerData.job.name ~= restaurantData.job then
        return lib.notify(src, {
            title = 'Restaurant',
            description = 'You are not employed at this restaurant',
            type = 'error'
        })
    end
    
    if player.PlayerData.job.grade.level < 2 then
        return lib.notify(src, {
            title = 'Management',
            description = 'You do not have management permissions',
            type = 'error'
        })
    end
    
    -- Open QBX Management menu
    TriggerClientEvent('ferp_restaurant:client:openManagementMenu', src, restaurantId, restaurantData)
end)

-- Event for salary payout (if needed)
RegisterNetEvent('ferp_restaurant:server:paySalary', function(restaurantId, employeeId, amount)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then return end
    
    -- Check permissions
    if player.PlayerData.job.name ~= restaurantData.job or player.PlayerData.job.grade.level < 3 then
        return lib.notify(src, {
            title = 'Management',
            description = 'Insufficient permissions for payroll',
            type = 'error'
        })
    end
    
    local targetPlayer = exports.qbx_core:GetPlayerByCitizenId(employeeId)
    if not targetPlayer then
        return lib.notify(src, {
            title = 'Payroll',
            description = 'Employee not found online',
            type = 'error'
        })
    end
    
    -- Add money to employee
    exports.qbx_core:AddMoney(targetPlayer.PlayerData.source, 'bank', amount, 'Restaurant salary from ' .. restaurantData.name)
    
    -- Notify both players
    lib.notify(src, {
        title = 'Payroll',
        description = ('Paid $%d to %s'):format(amount, targetPlayer.PlayerData.charinfo.firstname .. ' ' .. targetPlayer.PlayerData.charinfo.lastname),
        type = 'success'
    })
    
    lib.notify(targetPlayer.PlayerData.source, {
        title = 'Salary',
        description = ('Received $%d salary from %s'):format(amount, restaurantData.name),
        type = 'success'
    })
end)
