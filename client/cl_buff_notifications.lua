-- Client-side buff notification system

-- Buff applied notification
RegisterNetEvent('ferp_restaurant:client:buffApplied', function(buffType, strength, duration)
    local buffNames = {
        strength = 'Strong',
        stamina = 'Energized', 
        intelligence = 'Smart',
        money_luck = 'Lucky',
        alert = 'Alert'
    }
    
    local buffName = buffNames[buffType] or buffType
    local minutes = math.floor(duration / 60)
    local seconds = duration % 60
    
    local timeText = ""
    if minutes > 0 then
        timeText = minutes .. "m"
        if seconds > 0 then
            timeText = timeText .. " " .. seconds .. "s"
        end
    else
        timeText = seconds .. "s"
    end
    
    if Config.Debug then
        print('[DEBUG] Buff applied client notification:', buffType, strength, duration)
    end
    
    TriggerEvent('ox_lib:notify', {
        title = 'Buff Active',
        description = 'You feel more ' .. buffName .. ' (' .. timeText .. ')',
        type = 'success',
        duration = 4000
    })
    
    if Config.Debug then
        print('[DEBUG] Buff notification:', buffName, 'for', timeText)
    end
end)

-- Buff expired notification  
RegisterNetEvent('ferp_restaurant:client:buffExpired', function(buffType)
    local buffNames = {
        strength = 'Strong',
        stamina = 'Energized',
        intelligence = 'Smart', 
        money_luck = 'Lucky',
        alert = 'Alert'
    }
    
    local buffName = buffNames[buffType] or buffType
    
    TriggerEvent('ox_lib:notify', {
        title = 'Buff Expired',
        description = 'You no longer feel ' .. buffName,
        type = 'inform',
        duration = 3000
    })
    
    if Config.Debug then
        print('[DEBUG] Buff expired notification:', buffName)
    end
end)

-- Receive player buffs
RegisterNetEvent('ferp_restaurant:client:receivePlayerBuffs', function(buffs)
    if Config.Debug then
        print('[DEBUG] Current player buffs:', json.encode(buffs))
    end
    
    local activeBuffs = {}
    for buffType, buffData in pairs(buffs) do
        if buffData.active then
            local buffNames = {
                strength = 'Strong',
                stamina = 'Energized',
                intelligence = 'Smart', 
                money_luck = 'Lucky',
                alert = 'Alert'
            }
            local buffName = buffNames[buffType] or buffType
            activeBuffs[#activeBuffs + 1] = buffName
        end
    end
    
    if #activeBuffs > 0 then
        TriggerEvent('ox_lib:notify', {
            title = 'Active Buffs',
            description = 'You feel: ' .. table.concat(activeBuffs, ', '),
            type = 'inform',
            duration = 5000
        })
    else
        TriggerEvent('ox_lib:notify', {
            title = 'Active Buffs',
            description = 'No active buffs at the moment',
            type = 'inform',
            duration = 3000
        })
    end
end)

-- Command to check current buffs
RegisterCommand('checkbuffs', function()
    TriggerServerEvent('ferp_restaurant:server:getPlayerBuffs')
end, false)

if Config.Debug then
    print('[DEBUG] Restaurant buff client system loaded')
end
