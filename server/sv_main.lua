local Restaurants = {}

-- Initialize restaurants data on resource start
CreateThread(function()
    Wait(1000) -- Wait for database to be ready
    
    for restaurantId, restaurantData in pairs(Config.Restaurants) do
        local result = MySQL.single.await('SELECT * FROM restaurants WHERE id = ?', { restaurantId })
        
        if not result then
            -- Create new restaurant entry
            MySQL.insert.await('INSERT INTO restaurants (id, name, coords, blip, zones, food_items, menu_items, toys) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
                restaurantId,
                restaurantData.name,
                json.encode(restaurantData.coords),
                json.encode(restaurantData.blip),
                json.encode(restaurantData.zones),
                json.encode({}),
                json.encode({}),
                json.encode({})
            })
            
            Restaurants[restaurantId] = {
                id = restaurantId,
                name = restaurantData.name,
                foodItems = {},
                menuItems = {},
                toys = {},
                employees = {}
            }
        else
            -- Load existing restaurant data
            Restaurants[restaurantId] = {
                id = restaurantId,
                name = result.name,
                foodItems = json.decode(result.food_items) or {},
                menuItems = json.decode(result.menu_items) or {},
                toys = json.decode(result.toys) or {},
                employees = {}
            }
        end
        
        if Config.Debug then print(('[FERP Restaurant] Loaded restaurant: %s'):format(restaurantData.name)) end
    end
    
    -- Register stashes for each restaurant
    for restaurantId, restaurantData in pairs(Config.Restaurants) do
        -- Register fridge stash
        exports.ox_inventory:RegisterStash('restaurant_fridge_' .. restaurantId, restaurantData.name .. ' Fridge', 20, 50000, false, {[restaurantData.job] = 0})
        
        -- Register shelf stash
        exports.ox_inventory:RegisterStash('restaurant_shelf_' .. restaurantId, restaurantData.name .. ' Shelf', 15, 30000, false, {[restaurantData.job] = 0})
        
        -- Register box stash (storage box for restaurant items)
        exports.ox_inventory:RegisterStash('restaurant_box_' .. restaurantId, restaurantData.name .. ' Storage Box', 25, 100000, false, {[restaurantData.job] = 0})
        
        if Config.Debug then print(('[FERP Restaurant] Registered stashes for: %s'):format(restaurantData.name)) end
    end
end)

-- Event handlers
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    local job = Player.PlayerData.job.name
    
    -- Check if player is employed at any restaurant
    for restaurantId, restaurantData in pairs(Config.Restaurants) do
        if job == restaurantData.job then
            Restaurants[restaurantId].employees[src] = {
                source = src,
                name = Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
                citizenid = Player.PlayerData.citizenid,
                grade = Player.PlayerData.job.grade.level
            }
            break
        end
    end
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(src)
    for restaurantId, restaurant in pairs(Restaurants) do
        if restaurant.employees[src] then
            restaurant.employees[src] = nil
        end
    end
end)

AddEventHandler('QBCore:Server:OnJobUpdate', function(src, job)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    -- Remove from all restaurants first
    for restaurantId, restaurant in pairs(Restaurants) do
        restaurant.employees[src] = nil
    end
    
    -- Add to new restaurant if applicable
    for restaurantId, restaurantData in pairs(Config.Restaurants) do
        if job.name == restaurantData.job then
            Restaurants[restaurantId].employees[src] = {
                source = src,
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname,
                citizenid = player.PlayerData.citizenid,
                grade = job.grade.level
            }
            break
        end
    end
end)

-- Utility functions
local function SaveRestaurantData(restaurantId)
    if not Restaurants[restaurantId] then return false end
    
    local restaurant = Restaurants[restaurantId]
    MySQL.update.await('UPDATE restaurants SET food_items = ?, menu_items = ?, toys = ? WHERE id = ?', {
        json.encode(restaurant.foodItems),
        json.encode(restaurant.menuItems),
        json.encode(restaurant.toys),
        restaurantId
    })
    
    return true
end

local function GetRestaurantByPlayer(src)
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return nil end
    
    local job = player.PlayerData.job.name
    for restaurantId, restaurantData in pairs(Config.Restaurants) do
        if job == restaurantData.job then
            return restaurantId, restaurantData
        end
    end
    
    return nil
end

local function HasRestaurantPermission(src, restaurantId, minGrade)
    minGrade = minGrade or 2 -- Default minimum grade for management actions
    
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then return false end
    
    return player.PlayerData.job.name == restaurantData.job and player.PlayerData.job.grade.level >= minGrade
end

-- Export functions
exports('GetRestaurants', function()
    return Restaurants
end)

exports('GetRestaurantData', function(restaurantId)
    return Restaurants[restaurantId]
end)

exports('GetPlayerRestaurant', function(src)
    return GetRestaurantByPlayer(src)
end)

-- Dynamic box stash system
local registeredBoxes = {}
local boxStashCleanupQueue = {}

-- Function to clean up orphaned box stashes
local function cleanupOrphanedStash(boxId)
    if registeredBoxes[boxId] then
        -- Check if stash is empty before removing
        local stashInventory = exports.ox_inventory:GetInventory(boxId)
        if stashInventory and stashInventory.items then
            local hasItems = false
            for _, item in pairs(stashInventory.items) do
                if item and item.count and item.count > 0 then
                    hasItems = true
                    break
                end
            end
            
            if not hasItems then
                -- Stash is empty, safe to remove
                exports.ox_inventory:ClearInventory(boxId)
                registeredBoxes[boxId] = nil
                if Config.Debug then print('[FERP Restaurant] Cleaned up empty orphaned stash:', boxId) end
            else
                -- Stash has items, queue for later cleanup (give player time to recover)
                boxStashCleanupQueue[boxId] = os.time() + 3600 -- 1 hour grace period
                if Config.Debug then print('[FERP Restaurant] Orphaned stash has items, queued for cleanup:', boxId) end
            end
        else
            -- No inventory found, remove from tracking
            registeredBoxes[boxId] = nil
            if Config.Debug then print('[FERP Restaurant] Removed non-existent stash from tracking:', boxId) end
        end
    end
end

-- Event to handle box item removal/destruction
RegisterNetEvent('ferp_restaurant:server:boxDestroyed', function(boxId)
    if Config.Debug then print('[FERP Restaurant] Box destroyed event received for:', boxId) end
    cleanupOrphanedStash(boxId)
end)

RegisterNetEvent('ferp_restaurant:server:openBoxStash', function(boxId)
    local src = source
    
    if Config.Debug then print('[FERP Restaurant] Opening box stash:', boxId, 'for player:', src) end
    
    -- Register stash if not exists
    if not registeredBoxes[boxId] then
        exports.ox_inventory:RegisterStash(boxId, 'Delivery Box #' .. string.sub(boxId, -4), 5, 10000, false, false)
        registeredBoxes[boxId] = {
            created = os.time(),
            last_accessed = os.time()
        }
        if Config.Debug then print('[FERP Restaurant] Registered new box stash:', boxId) end
    else
        -- Update last accessed time
        registeredBoxes[boxId].last_accessed = os.time()
    end
    
    -- Open the stash using the correct method
    exports.ox_inventory:forceOpenInventory(src, 'stash', boxId)
end)

-- Give box item to employee (target interaction)
RegisterNetEvent('ferp_restaurant:server:getBox', function(restaurantId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData or player.PlayerData.job.name ~= restaurantData.job or not player.PlayerData.job.onduty then
        return
    end
    
    -- Generate unique box ID using timestamp + random + player ID for true uniqueness
    local uniqueBoxId = 'box_' .. src .. '_' .. os.time() .. '_' .. math.random(1000, 9999)
    
    -- Create metadata with unique box ID
    local boxMetadata = {
        box_id = uniqueBoxId,
        created_by = player.PlayerData.citizenid,
        created_at = os.date('%Y-%m-%d %H:%M:%S'),
        restaurant = restaurantId
    }
    
    -- Check if player can carry the box
    if exports.ox_inventory:CanCarryItem(src, 'restaurant_box', 1) then
        exports.ox_inventory:AddItem(src, 'restaurant_box', 1, boxMetadata)
        if Config.Debug then print('[FERP Restaurant] Created box with unique ID:', uniqueBoxId) end
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Restaurant',
            description = 'You cannot carry more items',
            type = 'error'
        })
    end
end)

-- Toy management system
lib.callback.register('ferp_restaurant:server:getToys', function(source, restaurantId)
    if not Restaurants[restaurantId] then return {} end
    return Restaurants[restaurantId].toys or {}
end)

lib.callback.register('ferp_restaurant:server:createToy', function(source, restaurantId, toyName, toyDescription, toyImage)
    if Config.Debug then print('[FERP Restaurant] CreateToy called with:', source, restaurantId, toyName, toyDescription, toyImage) end
    
    local player = exports.qbx_core:GetPlayer(source)
    if not player then 
        if Config.Debug then print('[FERP Restaurant] CreateToy failed - player not found') end
        return false 
    end
    
    if Config.Debug then print('[FERP Restaurant] Player job:', player.PlayerData.job.name, 'grade:', player.PlayerData.job.grade.level) end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData then
        if Config.Debug then print('[FERP Restaurant] CreateToy failed - restaurant not found in config:', restaurantId) end
        return false
    end
    
    if player.PlayerData.job.name ~= restaurantData.job then
        if Config.Debug then print('[FERP Restaurant] CreateToy failed - wrong job. Player job:', player.PlayerData.job.name, 'required:', restaurantData.job) end
        return false
    end
    
    if player.PlayerData.job.grade.level < 2 then
        if Config.Debug then print('[FERP Restaurant] CreateToy failed - insufficient grade. Player grade:', player.PlayerData.job.grade.level, 'required: 2+') end
        return false
    end
    
    if not Restaurants[restaurantId] then 
        if Config.Debug then print('[FERP Restaurant] CreateToy failed - restaurant not loaded:', restaurantId) end
        return false 
    end
    
    if not Restaurants[restaurantId].toys then 
        Restaurants[restaurantId].toys = {}
        if Config.Debug then print('[FERP Restaurant] Initialized toys table for restaurant:', restaurantId) end
    end
    
    -- Generate unique ID based on existing toys
    local nextId = 1
    for id, _ in pairs(Restaurants[restaurantId].toys) do
        if id >= nextId then
            nextId = id + 1
        end
    end
    
    local newToy = {
        id = nextId,
        name = toyName,
        description = toyDescription,
        image_url = toyImage or 'nui://ox_inventory/web/images/gift.png',
        restaurant = restaurantId
    }
    
    Restaurants[restaurantId].toys[nextId] = newToy
    if Config.Debug then print('[FERP Restaurant] Created toy object:', json.encode(newToy)) end
    if Config.Debug then print('[FERP Restaurant] Toy parameters received - Name:', toyName, 'Description:', toyDescription, 'Image:', toyImage) end
    
    -- Update database
    local result = MySQL.update.await('UPDATE restaurants SET toys = ? WHERE id = ?', {
        json.encode(Restaurants[restaurantId].toys),
        restaurantId
    })
    
    if Config.Debug then print('[FERP Restaurant] Database update result:', result) end
    
    if result and result > 0 then
        if Config.Debug then print('[FERP Restaurant] Successfully created toy:', toyName, 'for restaurant:', restaurantId) end
        return true
    else
        if Config.Debug then print('[FERP Restaurant] Failed to update database for toy:', toyName) end
        return false
    end
end)

lib.callback.register('ferp_restaurant:server:deleteToy', function(source, restaurantId, toyId)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData or player.PlayerData.job.name ~= restaurantData.job or player.PlayerData.job.grade.level < 2 then
        return false
    end
    
    if not Restaurants[restaurantId] or not Restaurants[restaurantId].toys or not Restaurants[restaurantId].toys[toyId] then
        return false
    end
    
    Restaurants[restaurantId].toys[toyId] = nil
    
    -- Update database
    local result = MySQL.update.await('UPDATE restaurants SET toys = ? WHERE id = ?', {
        json.encode(Restaurants[restaurantId].toys),
        restaurantId
    })
    
    return result and result > 0
end)

-- Toy box crafting and opening
RegisterNetEvent('ferp_restaurant:server:craftToyBox', function(restaurantId)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    local restaurantData = Config.Restaurants[restaurantId]
    if not restaurantData or player.PlayerData.job.name ~= restaurantData.job or not player.PlayerData.job.onduty then
        return
    end
    
    -- Check if restaurant has toys
    if not Restaurants[restaurantId] or not Restaurants[restaurantId].toys or #Restaurants[restaurantId].toys == 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Restaurant',
            description = 'This restaurant has no toys configured',
            type = 'error'
        })
        return
    end
    
    -- Check if player can carry the toy box
    if exports.ox_inventory:CanCarryItem(src, 'restaurant_toy_box', 1) then
        local metadata = {
            restaurant_id = restaurantId,
            restaurant_name = restaurantData.name,
            description = 'Mystery toy box from ' .. restaurantData.name
        }
        
        exports.ox_inventory:AddItem(src, 'restaurant_toy_box', 1, metadata)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Restaurant',
            description = 'You cannot carry more items',
            type = 'error'
        })
    end
end)

RegisterNetEvent('ferp_restaurant:server:openToyBox', function(restaurantId)
    local src = source
    
    if not Restaurants[restaurantId] or not Restaurants[restaurantId].toys then
        return
    end
    
    local toys = {}
    for _, toy in pairs(Restaurants[restaurantId].toys) do
        if toy then toys[#toys + 1] = toy end
    end
    
    if #toys == 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Toy Box',
            description = 'This box is empty',
            type = 'error'
        })
        return
    end
    
    -- Select random toy
    local randomToy = toys[math.random(1, #toys)]
    
    -- Give toy item
    if exports.ox_inventory:CanCarryItem(src, 'restaurant_toy', 1) then
        local metadata = {
            label = randomToy.name,
            description = randomToy.description,
            imageurl = randomToy.image_url, -- Campo correto para URL de imagem!
            restaurant_name = Restaurants[restaurantId].name,
            toy_id = randomToy.id,
            restaurant_id = restaurantId,
            type = 'toy',
            quality = 100,
            weight = 100,
            stack = false,
            close = true
        }
        
        -- Debug metadata
        if Config.Debug then print('[FERP Restaurant] Giving toy with metadata:', json.encode(metadata)) end
        if Config.Debug then print('[FERP Restaurant] Random toy selected:', json.encode(randomToy)) end
        
        exports.ox_inventory:AddItem(src, 'restaurant_toy', 1, metadata)
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Toy Box',
            description = 'You got: ' .. randomToy.name,
            type = 'success'
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Toy Box',
            description = 'You cannot carry more items',
            type = 'error'
        })
    end
end)

RegisterNetEvent('ferp_restaurant:server:consumeToyBox', function(data, slot)
    local src = source
    
    -- Remove the toy box from inventory
    exports.ox_inventory:RemoveItem(src, 'restaurant_toy_box', 1, slot.metadata, slot.slot)
end)

-- Server events for hunger/thirst system (QBX compatible)
RegisterNetEvent('ferp_restaurant:server:changeHunger', function(amount)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    -- Add hunger using QBX system
    local currentHunger = player.PlayerData.metadata.hunger or 0
    local newHunger = math.min(100, currentHunger + amount)
    player.Functions.SetMetaData('hunger', newHunger)
    
    -- Update client HUD
    TriggerClientEvent('hud:client:UpdateNeeds', src, newHunger, player.PlayerData.metadata.thirst or 0)
    
    if Config.Debug then print('[DEBUG] Server: Added hunger:', amount, 'new total:', newHunger, 'to player:', src) end
end)

RegisterNetEvent('ferp_restaurant:server:changeThirst', function(amount)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    -- Add thirst using QBX system
    local currentThirst = player.PlayerData.metadata.thirst or 0
    local newThirst = math.min(100, currentThirst + amount)
    player.Functions.SetMetaData('thirst', newThirst)
    
    -- Update client HUD
    TriggerClientEvent('hud:client:UpdateNeeds', src, player.PlayerData.metadata.hunger or 0, newThirst)
    
    if Config.Debug then print('[DEBUG] Server: Added thirst:', amount, 'new total:', newThirst, 'to player:', src) end
end)

-- Periodic cleanup system for orphaned box stashes
CreateThread(function()
    while true do
        Wait(1800000) -- Run every 30 minutes
        
        if Config.Debug then print('[FERP Restaurant] Running periodic stash cleanup...') end
        
        local currentTime = os.time()
        local cleanedCount = 0
        
        -- Clean up stashes queued for removal
        for boxId, cleanupTime in pairs(boxStashCleanupQueue) do
            if currentTime >= cleanupTime then
                cleanupOrphanedStash(boxId)
                boxStashCleanupQueue[boxId] = nil
                cleanedCount = cleanedCount + 1
            end
        end
        
        -- Clean up very old stashes that haven't been accessed (7 days)
        local weekAgo = currentTime - 604800 -- 7 days in seconds
        for boxId, stashInfo in pairs(registeredBoxes) do
            if type(stashInfo) == 'table' and stashInfo.last_accessed and stashInfo.last_accessed < weekAgo then
                if Config.Debug then print('[FERP Restaurant] Cleaning up old stash (7+ days inactive):', boxId) end
                cleanupOrphanedStash(boxId)
                cleanedCount = cleanedCount + 1
            end
        end
        
        if Config.Debug and cleanedCount > 0 then 
            print('[FERP Restaurant] Cleaned up', cleanedCount, 'orphaned stashes') 
        end
    end
end)

-- Hook into ox_inventory to detect when restaurant_box items are removed
CreateThread(function()
    Wait(10000) -- Wait for ox_inventory to fully load
    
    if exports.ox_inventory and exports.ox_inventory.registerHook then
        local hookId = exports.ox_inventory:registerHook('swapItems', function(payload)
            -- Check if a restaurant_box item was removed/destroyed
            if payload.fromInventory and payload.fromInventory.type == 'player' then
                if payload.fromSlot and payload.fromSlot.name == 'restaurant_box' then
                    local metadata = payload.fromSlot.metadata
                    if metadata and metadata.box_id then
                        -- Item was moved/removed, check if it was destroyed
                        if not payload.toInventory or payload.toInventory.type == 'drop' then
                            -- Item was dropped or destroyed
                            if Config.Debug then print('[FERP Restaurant] Box item dropped/destroyed, cleaning stash:', metadata.box_id) end
                            cleanupOrphanedStash(metadata.box_id)
                        end
                    end
                end
            end
            
            return true -- Allow the swap
        end, {
            inventoryFilter = {'player', 'drop'},
            itemFilter = {'restaurant_box'}
        })
        
        if Config.Debug then print('[FERP Restaurant] Registered box cleanup hook with ID:', hookId) end
    else
        if Config.Debug then print('[FERP Restaurant] Warning: Could not register cleanup hook - ox_inventory not available') end
    end
end)

-- Admin command to manually clean up orphaned stashes
RegisterCommand('cleanup_box_stashes', function(source, args)
    local src = source
    
    -- Check if player is admin (you can modify this check based on your admin system)
    local player = exports.qbx_core:GetPlayer(src)
    if not player or not player.PlayerData.job or player.PlayerData.job.name ~= 'police' then -- Modify admin check here
        return
    end
    
    local cleanedCount = 0
    local currentTime = os.time()
    
    -- Force cleanup all orphaned stashes
    for boxId, stashInfo in pairs(registeredBoxes) do
        -- Check if any player has this box in their inventory
        local boxExists = false
        
        -- You could implement a more thorough check here by scanning all player inventories
        -- For now, we'll clean up stashes older than 1 hour
        if type(stashInfo) == 'table' and stashInfo.last_accessed then
            if currentTime - stashInfo.last_accessed > 3600 then -- 1 hour
                cleanupOrphanedStash(boxId)
                cleanedCount = cleanedCount + 1
            end
        end
    end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Admin',
        description = 'Cleaned up ' .. cleanedCount .. ' orphaned box stashes',
        type = 'inform'
    })
    
    if Config.Debug then
        print('[FERP Restaurant] Admin cleanup: removed', cleanedCount, 'orphaned stashes')
    end
end, false)
