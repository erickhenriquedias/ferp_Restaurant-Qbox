-- Additional restaurant events for markers system compatibility

-- Duty toggle event
RegisterNetEvent('ferp_restaurant:client:toggleDuty', function()
    -- Check if QBX Core has duty toggle
    if exports.qbx_core then
        TriggerServerEvent('QBCore:ToggleDuty')
        if Config.Debug then print('[DEBUG] Toggled duty') end
    end
end)

-- Fridge event
RegisterNetEvent('ferp_restaurant:client:openFridge', function(restaurantId)
    if Config.Debug then print('[DEBUG] Opening fridge for restaurant:', restaurantId) end
    
    local restaurant = Config.Restaurants[restaurantId]
    if not restaurant then
        return
    end
    
    -- Check if player is employed at this restaurant
    if not exports.ferp_restaurant:IsEmployedAtRestaurant(restaurantId) then
        exports.ox_lib:notify({
            title = 'Acesso Negado',
            description = 'Você não trabalha neste restaurante',
            type = 'error'
        })
        return
    end
    
    -- Generate unique fridge ID for this restaurant
    local fridgeId = 'restaurant_fridge_' .. restaurantId
    
    -- Open ox_inventory stash
    exports.ox_inventory:openInventory('stash', fridgeId)
end)

-- Shelf event
RegisterNetEvent('ferp_restaurant:client:openShelf', function(restaurantId)
    if Config.Debug then print('[DEBUG] Opening shelf for restaurant:', restaurantId) end
    
    local restaurant = Config.Restaurants[restaurantId]
    if not restaurant then
        return
    end
    
    -- Check if player is employed at this restaurant
    if not exports.ferp_restaurant:IsEmployedAtRestaurant(restaurantId) then
        exports.ox_lib:notify({
            title = 'Acesso Negado',
            description = 'Você não trabalha neste restaurante',
            type = 'error'
        })
        return
    end
    
    -- Generate unique shelf ID for this restaurant
    local shelfId = 'restaurant_shelf_' .. restaurantId
    
    -- Open ox_inventory stash
    exports.ox_inventory:openInventory('stash', shelfId)
end)

-- Management event (placeholder)
RegisterNetEvent('ferp_restaurant:client:openManagement', function(restaurantId)
    if Config.Debug then print('[DEBUG] Opening management for restaurant:', restaurantId) end
    
    -- Check if player has management access
    local player = exports.qbx_core:GetPlayerData()
    if not player or not player.job then return end
    
    local restaurant = Config.Restaurants[restaurantId]
    if not restaurant then return end
    
    if player.job.name ~= restaurant.job then
        exports.ox_lib:notify({
            title = 'Acesso Negado',
            description = 'Você não trabalha neste restaurante',
            type = 'error'
        })
        return
    end
    
    if player.job.grade.level < 2 then
        exports.ox_lib:notify({
            title = 'Acesso Negado',
            description = 'Você não tem permissão para acessar o gerenciamento',
            type = 'error'
        })
        return
    end
end)

-- Register additional stashes on resource start
CreateThread(function()
    Wait(3000) -- Wait even longer for ox_inventory to load
    
    for restaurantId, restaurant in pairs(Config.Restaurants) do
        -- Register fridge stash
        if restaurant.zones.fridge then
            local fridgeId = 'restaurant_fridge_' .. restaurantId
            
            local success = pcall(function()
                exports.ox_inventory:RegisterStash(fridgeId, restaurant.name .. ' - Geladeira', 20, 50000)
            end)
            
            if Config.Debug then 
                if success then
                    print('[DEBUG] Successfully registered fridge stash:', fridgeId)
                else
                    print('[DEBUG] Failed to register fridge stash:', fridgeId)
                end
            end
        end
        
        -- Register shelf stash
        if restaurant.zones.shelf then
            local shelfId = 'restaurant_shelf_' .. restaurantId
            
            local success = pcall(function()
                exports.ox_inventory:RegisterStash(shelfId, restaurant.name .. ' - Prateleira', 30, 75000)
            end)
            
            if Config.Debug then 
                if success then
                    print('[DEBUG] Successfully registered shelf stash:', shelfId)
                else
                    print('[DEBUG] Failed to register shelf stash:', shelfId)
                end
            end
        end
    end
end)
