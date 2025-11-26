-- ox_target management for restaurants
local activeTargets = {}

-- Debug function
local function debugPrint(message)
    if Config.Debug then
        print('[FERP Restaurant] ' .. message)
    end
end

-- Create restaurant targets
function CreateRestaurantZones(restaurantId, restaurant)
    debugPrint('Creating zones for restaurant: ' .. restaurantId)
    
    if activeTargets[restaurantId] then
        RemoveRestaurantZones(restaurantId)
    end
    
    activeTargets[restaurantId] = {}
    
    -- Test if ox_target export exists
    if not exports.ox_target then
        debugPrint('ERROR: ox_target export not found!')
        return
    end
    
    debugPrint('ox_target found, creating zones...')
    
    -- Management target
    if restaurant.zones.management then
        debugPrint('Creating management zone for ' .. restaurantId)
        local success, managementTarget = pcall(function()
            return exports.ox_target:addSphereZone({
                coords = restaurant.zones.management,
                radius = Config.ZoneRadius * 0.5,
                debug = Config.Debug,
                drawSprite = true,
                drawDistance = 10.0,
                options = {
                    {
                        name = 'restaurant_management_' .. restaurantId,
                        icon = 'fas fa-users-cog',
                        label = 'Management Menu',
                        onSelect = function()
                            debugPrint('Management selected for ' .. restaurantId)
                            TriggerEvent('ferp_restaurant:client:openManagement', restaurantId)
                        end,
                    canInteract = function()
                        return IsEmployedAtRestaurant(restaurantId) and 
                               exports.qbx_core:GetPlayerData().job.grade.level >= 2
                    end
                    }
                }
            })
        end)
        
        if success and managementTarget then
            activeTargets[restaurantId]['management'] = managementTarget
            debugPrint('Management target created for ' .. restaurantId)
        else
            debugPrint('ERROR: Failed to create management target for ' .. restaurantId)
        end
    end
    
    -- Duty target (separate from management)
    if restaurant.zones.duty then
        debugPrint('Creating duty zone for ' .. restaurantId)
        local dutyTarget = exports.ox_target:addSphereZone({
            coords = restaurant.zones.duty,
            radius = Config.ZoneRadius * 0.5,
            debug = Config.Debug,
            drawSprite = true,
            drawDistance = 10.0,
            options = {
                {
                    name = 'restaurant_duty_' .. restaurantId,
                    icon = 'fas fa-clock',
                    label = 'Clock In/Out',
                    onSelect = function()
                        debugPrint('Duty selected for ' .. restaurantId)
                        TriggerEvent('ferp_restaurant:client:toggleDuty', restaurantId, restaurant.job)
                    end,
                    canInteract = function()
                        return IsEmployedAtRestaurant(restaurantId, false) -- false = don't need to be on duty for clock in
                    end
                }
            }
        })
        
        activeTargets[restaurantId]['duty'] = dutyTarget
        debugPrint('Duty target created for ' .. restaurantId)
    end
    
    -- Category-specific cooking targets
    if restaurant.zones.cooking then
        debugPrint('Creating cooking zones for ' .. restaurantId)
        for i, cookingZone in ipairs(restaurant.zones.cooking) do
            local cookingTarget = exports.ox_target:addSphereZone({
                coords = cookingZone.coords,
                radius = Config.ZoneRadius * 0.5,
                debug = Config.Debug,
                drawSprite = true,
                drawDistance = 10.0,
                options = {
                    {
                        name = 'restaurant_cooking_' .. restaurantId .. '_' .. cookingZone.type,
                        icon = 'fas fa-fire-burner',
                        label = 'Cook ' .. string.upper(cookingZone.type:sub(1,1)) .. cookingZone.type:sub(2),
                        onSelect = function()
                            debugPrint('Cooking selected for ' .. restaurantId .. ' category: ' .. cookingZone.type)
                            TriggerEvent('ferp_restaurant:client:openCookingMenu', restaurantId, cookingZone.type)
                        end,
                        canInteract = function()
                            return IsEmployedAtRestaurant(restaurantId)
                        end
                    }
                }
            })
            
            activeTargets[restaurantId]['cooking_' .. cookingZone.type] = cookingTarget
            debugPrint('Cooking target ' .. cookingZone.type .. ' created for ' .. restaurantId)
        end
    end
    
    
    -- Storage targets
    debugPrint('Creating storage zones for ' .. restaurantId)
    
    -- Fridge target
    if restaurant.zones.fridge then
        local fridgeTarget = exports.ox_target:addSphereZone({
            coords = restaurant.zones.fridge,
            radius = Config.ZoneRadius * 0.5,
            debug = Config.Debug,
            drawSprite = true,
            drawDistance = 10.0,
            options = {
                {
                    name = 'restaurant_fridge_' .. restaurantId,
                    icon = 'fas fa-snowflake',
                    label = 'Open Fridge',
                    onSelect = function()
                        debugPrint('Fridge selected for ' .. restaurantId)
                        TriggerEvent('ferp_restaurant:client:openFridge', restaurantId)
                    end,
                    canInteract = function()
                        return IsEmployedAtRestaurant(restaurantId)
                    end
                }
            }
        })
        
        activeTargets[restaurantId]['fridge'] = fridgeTarget
        debugPrint('Fridge target created for ' .. restaurantId)
    end
    
    -- Shelf target
    if restaurant.zones.shelf then
        local shelfTarget = exports.ox_target:addSphereZone({
            coords = restaurant.zones.shelf,
            radius = Config.ZoneRadius * 0.5,
            debug = Config.Debug,
            drawSprite = true,
            drawDistance = 10.0,
            options = {
                {
                    name = 'restaurant_shelf_' .. restaurantId,
                    icon = 'fas fa-archive',
                    label = 'Open Shelf',
                    onSelect = function()
                        debugPrint('Shelf selected for ' .. restaurantId)
                        TriggerEvent('ferp_restaurant:client:openShelf', restaurantId)
                    end,
                    canInteract = function()
                        return IsEmployedAtRestaurant(restaurantId)
                    end
                }
            }
        })
        
        activeTargets[restaurantId]['shelf'] = shelfTarget
        debugPrint('Shelf target created for ' .. restaurantId)
    end
    
    -- Box target
    if restaurant.zones.box then
        local boxTarget = exports.ox_target:addSphereZone({
            coords = restaurant.zones.box,
            radius = Config.ZoneRadius * 0.5,
            debug = Config.Debug,
            drawSprite = true,
            drawDistance = 10.0,
            options = {
                {
                    name = 'restaurant_box_get_' .. restaurantId,
                    icon = 'fas fa-box-open',
                    label = 'Get Delivery Box',
                    onSelect = function()
                        debugPrint('Get box selected for ' .. restaurantId)
                        TriggerServerEvent('ferp_restaurant:server:getBox', restaurantId)
                    end,
                    canInteract = function()
                        local player = exports.qbx_core:GetPlayerData()
                        if not player or not player.job then return false end
                        return player.job.name == restaurant.job and player.job.onduty
                    end
                }
            }
        })
        
        activeTargets[restaurantId]['box'] = boxTarget
        debugPrint('Box target created for ' .. restaurantId)
    end
    
    -- Toy Box target
    if restaurant.zones.toy_box then
        local toyBoxTarget = exports.ox_target:addSphereZone({
            coords = restaurant.zones.toy_box,
            radius = Config.ZoneRadius * 0.5,
            debug = Config.Debug,
            drawSprite = true,
            drawDistance = 10.0,
            options = {
                {
                    name = 'restaurant_toy_box_craft_' .. restaurantId,
                    icon = 'fas fa-gift',
                    label = 'Craft Toy Box',
                    onSelect = function()
                        debugPrint('Craft toy box selected for ' .. restaurantId)
                        TriggerServerEvent('ferp_restaurant:server:craftToyBox', restaurantId)
                    end,
                    canInteract = function()
                        local player = exports.qbx_core:GetPlayerData()
                        if not player or not player.job then return false end
                        return player.job.name == restaurant.job and player.job.onduty
                    end
                }
            }
        })
        
        activeTargets[restaurantId]['toy_box'] = toyBoxTarget
        debugPrint('Toy Box target created for ' .. restaurantId)
    end
    
    -- Stash target (general storage)
    if restaurant.zones.stash then
        local stashTarget = exports.ox_target:addSphereZone({
            coords = restaurant.zones.stash,
            radius = Config.ZoneRadius * 0.5,
            debug = Config.Debug,
            drawSprite = true,
            drawDistance = 10.0,
            options = {
                {
                    name = 'restaurant_stash_' .. restaurantId,
                    icon = 'fas fa-warehouse',
                    label = 'Open Stash',
                    onSelect = function()
                        debugPrint('Stash selected for ' .. restaurantId)
                        TriggerEvent('ferp_restaurant:client:openStash', restaurantId)
                    end,
                    canInteract = function()
                        return IsEmployedAtRestaurant(restaurantId)
                    end
                }
            }
        })
        
        activeTargets[restaurantId]['stash'] = stashTarget
        debugPrint('Stash target created for ' .. restaurantId)
    end
    
    debugPrint('All zones created for restaurant: ' .. restaurantId)
end

-- Remove restaurant targets
function RemoveRestaurantZones(restaurantId)
    if not activeTargets[restaurantId] then return end
    
    debugPrint('Removing zones for restaurant: ' .. restaurantId)
    
    for targetName, targetId in pairs(activeTargets[restaurantId]) do
        exports.ox_target:removeZone(targetId)
        debugPrint('Removed target: ' .. targetName)
    end
    
    activeTargets[restaurantId] = nil
    debugPrint('All zones removed for restaurant: ' .. restaurantId)
end

-- Export functions
exports('CreateRestaurantZones', CreateRestaurantZones)
exports('RemoveRestaurantZones', RemoveRestaurantZones)
