--[[
    Restaurant Fridge System
    Restricts fridge to food items only and extends food preservation
]]--

local ox_inventory = exports.ox_inventory
local fridgeStashes = {}

-- Initialize fridge system
CreateThread(function()
    Wait(2000) -- Wait for ox_inventory to load
    
    if Config.Debug then print('[FERP Restaurant] Initializing fridge system...') end
    
    -- Register all restaurant fridges
    for restaurantId, restaurantData in pairs(Config.Restaurants) do
        local stashId = 'restaurant_fridge_' .. restaurantId
        fridgeStashes[stashId] = true
        if Config.Debug then print('[FERP Restaurant] Fridge registered: ' .. stashId) end
    end
    
    if Config.Debug then print('[FERP Restaurant] Fridge system initialized') end
end)

-- Function to check if item is allowed in fridge (only restaurant food items)
local function IsRestaurantFoodItem(itemName)
    for _, foodType in pairs(Config.RestaurantItems) do
        if itemName == foodType then
            return true
        end
    end
    return false
end

-- Monitor fridge inventories and remove non-food items + preserve food
CreateThread(function()
    while true do
        Wait(50000) -- Check every 50 seconds for faster preservation
        
        for stashId, _ in pairs(fridgeStashes) do
            local inventory = ox_inventory:GetInventory(stashId, false)
            
            if inventory and inventory.items then
                for slot, item in pairs(inventory.items) do
                    if item and item.name then
                        local isFood = IsRestaurantFoodItem(item.name)
                        
                        if not isFood then
                            -- Remove non-food item from fridge
                            local removed = ox_inventory:RemoveItem(stashId, item.name, item.count, item.metadata, slot)
                            
                            if removed and Config.Debug then
                                print('[FERP Restaurant] Removed non-restaurant item from fridge: ' .. item.name .. ' from ' .. stashId)
                            end
                        else
                            -- Preserve food items by maintaining durability at maximum
                            if item.metadata and item.metadata.durability then
                                local currentDurability = item.metadata.durability
                                
                                -- Keep food at 100% durability (frozen state)
                                if currentDurability < 100 then
                                    item.metadata.durability = 100
                                    ox_inventory:SetMetadata(stashId, slot, item.metadata)
                                    
                                    if Config.Debug then
                                        print('[FERP Restaurant] Restored ' .. item.name .. ' to 100% durability in fridge')
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)

if Config.Debug then print('[FERP Restaurant] Fridge system loaded - food-only restriction active') end
