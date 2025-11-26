--[[
    Restaurant Fridge System
    Prevents food decay in fridge stashes
]]--

local fridgeStashes = {}

-- Initialize fridge system
CreateThread(function()
    Wait(5000) -- Wait for ox_inventory to load
    
    if Config.Debug then print('[FERP Restaurant] Initializing fridge preservation system...') end
    
    -- Register all restaurant fridges
    for restaurantId, restaurantData in pairs(Config.Restaurants) do
        local stashId = 'restaurant_fridge_' .. restaurantId
        fridgeStashes[stashId] = true
        if Config.Debug then print('[FERP Restaurant] Fridge ' .. stashId .. ' registered for food preservation') end
    end
    
    if Config.Debug then print('[FERP Restaurant] Fridge system initialization complete') end
end)

-- Hook into ox_inventory to modify decay for fridge items
local originalSetMetadata = exports.ox_inventory.SetMetadata or function() end

-- Function to extend food expiry when placed in fridge
local function extendFoodExpiry(item, stashId)
    if not fridgeStashes[stashId] then return item end
    
    -- Check if item is food using the FridgeAllowedItems config
    local isFoodItem = false
    for _, foodType in pairs(Config.FridgeAllowedItems) do
        if item.name == foodType then
            isFoodItem = true
            break
        end
    end
    
    if not isFoodItem then return item end
    
    -- Extend expiry time by 4x when in fridge (refrigeration effect)
    if item.metadata and item.metadata.expiry then
        local currentTime = os.time()
        local originalExpiry = item.metadata.expiry
        local timeRemaining = originalExpiry - currentTime
        
        -- Only extend if item hasn't expired yet
        if timeRemaining > 0 then
            item.metadata.expiry = currentTime + (timeRemaining * 4)
            item.metadata.refrigerated = true
            if Config.Debug then print('[FERP Restaurant] Food item ' .. item.name .. ' refrigerated, expiry extended') end
        end
    elseif item.metadata then
        -- If no expiry set, set one for 24 hours (refrigerated food lasts longer)
        item.metadata.expiry = os.time() + (24 * 60 * 60) -- 24 hours
        item.metadata.refrigerated = true
        if Config.Debug then print('[FERP Restaurant] Food item ' .. item.name .. ' refrigerated, 24h expiry set') end
    end
    
    return item
end

-- Function to reduce expiry when removed from fridge
local function reduceFoodExpiry(item, stashId)
    if not fridgeStashes[stashId] then return item end
    if not item.metadata or not item.metadata.refrigerated then return item end
    
    -- Check if item is food using the FridgeAllowedItems config
    local isFoodItem = false
    for _, foodType in pairs(Config.FridgeAllowedItems) do
        if item.name == foodType then
            isFoodItem = true
            break
        end
    end
    
    if not isFoodItem then return item end
    
    -- Reduce expiry time back to normal when removed from fridge
    if item.metadata.expiry then
        local currentTime = os.time()
        local fridgeExpiry = item.metadata.expiry
        local timeRemaining = fridgeExpiry - currentTime
        
        if timeRemaining > 0 then
            -- Reduce back to 1/4 of the time (normal decay rate)
            item.metadata.expiry = currentTime + math.max(timeRemaining / 4, 300) -- Minimum 5 minutes
            item.metadata.refrigerated = nil
            if Config.Debug then print('[FERP Restaurant] Food item ' .. item.name .. ' removed from fridge, expiry reduced') end
        end
    end
    
    return item
end

-- Register hook to intercept item movements using ox_inventory hook system
CreateThread(function()
    Wait(6000) -- Wait for ox_inventory hooks to be ready
    
    if Config.Debug then print('[FERP Restaurant] Registering ox_inventory hook for fridge system...') end
    
    local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
        if Config.Debug then print('[FERP Restaurant] Hook triggered - Source:', payload.source, 'Action:', payload.action or 'none') end
        if Config.Debug then print('[FERP Restaurant] From:', payload.fromInventory, payload.fromType, 'To:', payload.toInventory, payload.toType) end
        
        local fromInventory = payload.fromInventory
        local toInventory = payload.toInventory
        local fromType = payload.fromType
        local toType = payload.toType
        local fromSlot = payload.fromSlot
        local toSlot = payload.toSlot
        local source = payload.source
        
        -- Check if moving TO a fridge
        if toType == 'stash' and fridgeStashes[toInventory] then
            if Config.Debug then print('[FERP Restaurant] Item being moved TO fridge: ' .. toInventory) end
            
            local itemName = type(fromSlot) == 'table' and fromSlot.name or nil
            if not itemName then
                if Config.Debug then print('[FERP Restaurant] Could not determine item name from fromSlot:', json.encode(fromSlot)) end
                return true
            end
            
            if Config.Debug then print('[FERP Restaurant] Processing item for fridge: ' .. itemName) end
            
            -- Check if item is food
            local isFoodItem = false
            for _, foodType in pairs(Config.FridgeAllowedItems) do
                if itemName == foodType then
                    isFoodItem = true
                    break
                end
            end
            
            if not isFoodItem then
                -- Item is not food - reject the move
                if Config.Debug then print('[FERP Restaurant] REJECTING non-food item from fridge: ' .. itemName) end
                
                TriggerClientEvent('ox_lib:notify', source, {
                    title = 'Fridge Restriction',
                    description = 'Only food items can be stored in the fridge!',
                    type = 'error',
                    duration = 4000
                })
                
                return false
            end
            
            if Config.Debug then print('[FERP Restaurant] Allowing food item to be stored in fridge: ' .. itemName) end
        end
        
        -- Check if moving FROM a fridge
        if fromType == 'stash' and fridgeStashes[fromInventory] then
            if Config.Debug then print('[FERP Restaurant] Item being removed FROM fridge: ' .. fromInventory) end
        end
        
        return true
    end)
    
    if hookId then
        if Config.Debug then print('[FERP Restaurant] Successfully registered ox_inventory swapItems hook with ID: ' .. tostring(hookId)) end
    else
        if Config.Debug then print('[FERP Restaurant] ERROR: Failed to register ox_inventory hook!') end
    end
end)

-- Use createUseableItem hook to handle fridge preservation
CreateThread(function()
    Wait(7000)
    
    if Config.Debug then print('[FERP Restaurant] Setting up fridge preservation system...') end
    
    -- Monitor fridge stashes and pause expiry times
    CreateThread(function()
        while true do
            Wait(5000) -- Check every 5 seconds
            
            for stashId, _ in pairs(fridgeStashes) do
                local inventory = exports.ox_inventory:GetInventory(stashId)
                
                if inventory and inventory.items then
                    for slot, item in pairs(inventory.items) do
                        if item and item.name and item.metadata then
                            -- Check if it's a food item
                            local isFoodItem = false
                            for _, foodType in pairs(Config.FridgeAllowedItems) do
                                if item.name == foodType then
                                    isFoodItem = true
                                    break
                                end
                            end
                            
                            if isFoodItem and item.metadata.expiry then
                                local currentTime = os.time()
                                
                                -- Store original expiry and freeze time
                                if not item.metadata.fridge_stored_at then
                                    item.metadata.fridge_stored_at = currentTime
                                    item.metadata.fridge_original_expiry = item.metadata.expiry
                                    
                                    if Config.Debug then
                                        print('[FERP Restaurant] Food stored in fridge: ' .. item.name .. ' at slot ' .. slot)
                                        print('[FERP Restaurant] Original expiry: ' .. item.metadata.expiry .. ' (in ' .. (item.metadata.expiry - currentTime) .. 's)')
                                    end
                                end
                                
                                -- Keep setting expiry far in the future to prevent decay
                                local timeInFridge = currentTime - item.metadata.fridge_stored_at
                                local newExpiry = currentTime + (24 * 60 * 60) -- Always 24 hours ahead
                                
                                if item.metadata.expiry ~= newExpiry then
                                    item.metadata.expiry = newExpiry
                                    exports.ox_inventory:SetMetadata(stashId, slot, item.metadata)
                                    
                                    if Config.Debug then
                                        print('[FERP Restaurant] Refreshed fridge expiry for ' .. item.name .. ' - Time in fridge: ' .. timeInFridge .. 's')
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
    
    -- Monitor when items are removed from fridge
    local removeHookId = exports.ox_inventory:registerHook('swapItems', function(payload)
        local fromInventory = payload.fromInventory
        local fromType = payload.fromType
        local fromSlot = payload.fromSlot
        
        -- Check if removing FROM a fridge
        if fromType == 'stash' and fridgeStashes[fromInventory] then
            if fromSlot and fromSlot.metadata and fromSlot.metadata.fridge_stored_at then
                local currentTime = os.time()
                local timeInFridge = currentTime - fromSlot.metadata.fridge_stored_at
                local originalExpiry = fromSlot.metadata.fridge_original_expiry
                
                if originalExpiry then
                    -- Calculate how much time would have passed at normal rate
                    local normalDecay = timeInFridge / 4 -- 4x slower in fridge
                    local newExpiry = originalExpiry - normalDecay
                    
                    -- Ensure minimum 5 minutes
                    if newExpiry < currentTime then
                        newExpiry = currentTime + 300 -- 5 minutes minimum
                    end
                    
                    fromSlot.metadata.expiry = math.floor(newExpiry)
                    fromSlot.metadata.fridge_stored_at = nil
                    fromSlot.metadata.fridge_original_expiry = nil
                    
                    if Config.Debug then
                        print('[FERP Restaurant] Food removed from fridge: ' .. fromSlot.name)
                        print('[FERP Restaurant] Was in fridge for: ' .. timeInFridge .. 's')
                        print('[FERP Restaurant] New expiry: ' .. (newExpiry - currentTime) .. 's')
                    end
                end
            end
        end
        
        return true
    end)
    
    if Config.Debug then print('[FERP Restaurant] Fridge preservation system active') end
end)

if Config.Debug then print('[FERP Restaurant] Fridge preservation system loaded with food-only restrictions and hook-based validation') end
