-- Server-side stash registration for restaurants

-- Register restaurant stashes
CreateThread(function()
    Wait(1000) -- Wait for ox_inventory to load
    
    for restaurantId, restaurant in pairs(Config.Restaurants) do
        if restaurant.zones.stash then
            local stashId = 'restaurant_stash_' .. restaurantId
            
            -- Register stash on server side (correct method from docs)
            exports.ox_inventory:RegisterStash(stashId, restaurant.name .. ' - ' .. Config.Stash.label, Config.Stash.slots, Config.Stash.weight, true)
            
            if Config.Debug then print('[DEBUG] Server registered stash:', stashId, 'for restaurant:', restaurant.name) end
        end
        
        -- Register fridge stash
        if restaurant.zones.fridge then
            local fridgeId = 'restaurant_fridge_' .. restaurantId
            exports.ox_inventory:RegisterStash(fridgeId, restaurant.name .. ' - Geladeira', 20, 50000, true)
            if Config.Debug then print('[DEBUG] Server registered fridge:', fridgeId) end
        end
        
        -- Register shelf stash
        if restaurant.zones.shelf then
            local shelfId = 'restaurant_shelf_' .. restaurantId
            exports.ox_inventory:RegisterStash(shelfId, restaurant.name .. ' - Prateleira', 30, 75000, true)
            if Config.Debug then print('[DEBUG] Server registered shelf:', shelfId) end
        end
    end
end)
