local PlayerJob = {}
local CurrentRestaurant = nil

-- Initialize with retry mechanism
CreateThread(function()
    local attempts = 0
    local maxAttempts = 10
    
    -- Wait for QBX Core to fully load
    Wait(2000)
    
    while attempts < maxAttempts do
        local playerData = exports.qbx_core:GetPlayerData()
        if playerData and playerData.job then
            PlayerJob = playerData.job
            if Config.Debug then print('[FERP Restaurant] PlayerJob initialized:', json.encode(PlayerJob)) end
            break
        else
            attempts = attempts + 1
            if Config.Debug then print('[FERP Restaurant] Waiting for player data... Attempt:', attempts) end
            Wait(1000)
        end
    end
    
    if not PlayerJob or not PlayerJob.name then
        if Config.Debug then print('[FERP Restaurant] WARNING: Failed to initialize PlayerJob after', maxAttempts, 'attempts') end
    end
    
    -- Create blips for restaurants
    for restaurantId, restaurant in pairs(Config.Restaurants) do
        local blip = AddBlipForCoord(restaurant.coords.x, restaurant.coords.y, restaurant.coords.z)
        SetBlipSprite(blip, restaurant.blip.sprite)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, restaurant.blip.scale)
        SetBlipColour(blip, restaurant.blip.color)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(restaurant.name)
        EndTextCommandSetBlipName(blip)
    end
end)

-- Job update handler
RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerJob = JobInfo
end)

-- Restaurant zone entry/exit
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local sleep = 1000
        
        for restaurantId, restaurant in pairs(Config.Restaurants) do
            local distance = #(coords - restaurant.coords)
            
            if distance <= 100 then
                sleep = 100
                
                if distance <= 20 and CurrentRestaurant ~= restaurantId then
                    CurrentRestaurant = restaurantId
                    TriggerEvent('ferp_restaurant:client:enteredRestaurant', restaurantId, restaurant)
                elseif distance > 20 and CurrentRestaurant == restaurantId then
                    CurrentRestaurant = nil
                    TriggerEvent('ferp_restaurant:client:leftRestaurant', restaurantId)
                end
                break
            end
        end
        
        Wait(sleep)
    end
end)

-- Restaurant entry event
RegisterNetEvent('ferp_restaurant:client:enteredRestaurant', function(restaurantId, restaurant)
    if Config.Debug then
        print('[DEBUG] Entered restaurant:', restaurant.name)
    end
    
    -- Setup zones for this restaurant
    exports['ferp_restaurant']:CreateRestaurantZones(restaurantId, restaurant)
end)

-- Restaurant exit event
RegisterNetEvent('ferp_restaurant:client:leftRestaurant', function(restaurantId)
    if Config.Debug then
        print('[DEBUG] Left restaurant:', restaurantId)
    end
    
    -- Remove zones for this restaurant
    exports['ferp_restaurant']:RemoveRestaurantZones(restaurantId)
end)

-- Export functions
exports('GetCurrentRestaurant', function()
    return CurrentRestaurant
end)

exports('GetPlayerJob', function()
    return PlayerJob
end)

exports('IsEmployedAtRestaurant', function(restaurantId, checkDuty)
    if checkDuty == nil then checkDuty = true end -- Default: check duty status
    
    if Config.Debug then
        print('[FERP Restaurant] IsEmployedAtRestaurant called with: ' .. tostring(restaurantId) .. ', checkDuty: ' .. tostring(checkDuty))
    end
    
    -- Always get fresh player data
    local playerData = exports.qbx_core:GetPlayerData()
    if not playerData or not playerData.job then
        if Config.Debug then
            print('[FERP Restaurant] No fresh player data available')
        end
        return false
    end
    
    -- Update cached PlayerJob with fresh data
    PlayerJob = playerData.job
    
    if not restaurantId then 
        if Config.Debug then
            print('[FERP Restaurant] Missing restaurantId')
        end
        return false 
    end
    
    local restaurant = Config.Restaurants[restaurantId]
    if not restaurant then 
        if Config.Debug then
            print('[FERP Restaurant] Restaurant not found: ' .. restaurantId)
        end
        return false 
    end
    
    local isEmployed = PlayerJob.name == restaurant.job
    local isOnDuty = not checkDuty or PlayerJob.onduty
    
    if Config.Debug then
        print('[FERP Restaurant] Fresh PlayerJob.name: ' .. tostring(PlayerJob.name))
        print('[FERP Restaurant] Fresh PlayerJob.onduty: ' .. tostring(PlayerJob.onduty))
        print('[FERP Restaurant] Restaurant.job: ' .. tostring(restaurant.job))
        print('[FERP Restaurant] IsEmployed: ' .. tostring(isEmployed))
        print('[FERP Restaurant] IsOnDuty: ' .. tostring(isOnDuty))
        print('[FERP Restaurant] Final result: ' .. tostring(isEmployed and isOnDuty))
    end
    
    return isEmployed and isOnDuty
end)

-- Event to toggle duty status
RegisterNetEvent('ferp_restaurant:client:toggleDuty', function(restaurantId, jobName)
    local player = exports.qbx_core:GetPlayerData()
    if not player or not player.job then return end
    
    if player.job.name ~= jobName then
        lib.notify({
            title = 'Restaurant',
            description = 'You are not employed at this restaurant',
            type = 'error'
        })
        return
    end
    
    -- Toggle duty status
    TriggerServerEvent('QBCore:ToggleDuty')
    
    local dutyStatus = player.job.onduty and 'off' or 'on'
    lib.notify({
        title = 'Restaurant',
        description = 'You are now ' .. dutyStatus .. ' duty',
        type = 'success'
    })
end)

-- Storage interaction events
RegisterNetEvent('ferp_restaurant:client:openFridge', function(restaurantId)
    local player = exports.qbx_core:GetPlayerData()
    if not player or not player.job or not player.job.onduty then
        lib.notify({
            title = 'Restaurant',
            description = 'You must be on duty',
            type = 'error'
        })
        return
    end
    
    -- Trigger server event to handle fridge preservation system
    TriggerServerEvent('ferp_restaurant:server:openFridge', restaurantId)
end)

RegisterNetEvent('ferp_restaurant:client:openShelf', function(restaurantId)
    local player = exports.qbx_core:GetPlayerData()
    if not player or not player.job or not player.job.onduty then
        lib.notify({
            title = 'Restaurant',
            description = 'You must be on duty',
            type = 'error'
        })
        return
    end
    
    exports.ox_inventory:openInventory('stash', 'restaurant_shelf_' .. restaurantId)
end)

RegisterNetEvent('ferp_restaurant:client:openBox', function(restaurantId)
    local player = exports.qbx_core:GetPlayerData()
    if not player or not player.job or not player.job.onduty then
        lib.notify({
            title = 'Restaurant',
            description = 'You must be on duty',
            type = 'error'
        })
        return
    end
    
    exports.ox_inventory:openInventory('stash', 'restaurant_box_' .. restaurantId)
end)
