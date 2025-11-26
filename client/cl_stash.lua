-- Restaurant stash system (ox_inventory integration)

-- Open stash event
RegisterNetEvent('ferp_restaurant:client:openStash', function(restaurantId)
    if Config.Debug then print('[DEBUG] Opening stash for restaurant:', restaurantId) end
    
    local restaurant = Config.Restaurants[restaurantId]
    if not restaurant then
        if Config.Debug then print('[DEBUG] Restaurant not found:', restaurantId) end
        return
    end
    
    -- Check if player is employed at this restaurant
    if not IsEmployedAtRestaurant(restaurantId) then
        exports.ox_lib:notify({
            title = 'Acesso Negado',
            description = 'Você não trabalha neste restaurante',
            type = 'error'
        })
        return
    end
    
    -- Generate unique stash ID for this restaurant
    local stashId = 'restaurant_stash_' .. restaurantId
    
    if Config.Debug then print('[DEBUG] Opening stash with ID:', stashId) end
    
    -- Open ox_inventory stash (correct method from docs)
    exports.ox_inventory:openInventory('stash', {id = stashId})
end)
