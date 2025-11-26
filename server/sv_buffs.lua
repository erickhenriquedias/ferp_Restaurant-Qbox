-- Server-side buff management system
local PlayerBuffs = {}

-- Initialize player buffs on join (QBX Core events)
AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    local src = Player.PlayerData.source
    PlayerBuffs[src] = {
        strength = { active = false, endTime = 0, value = 0 },
        stamina = { active = false, endTime = 0, value = 0 },
        intelligence = { active = false, endTime = 0, value = 0 },
        money_luck = { active = false, endTime = 0, value = 0 },
        alert = { active = false, endTime = 0, value = 0 }
    }
    
    if Config.Debug then print('[DEBUG] Initialized buffs for player:', src) end
end)

-- Alternative initialization for when player spawns
AddEventHandler('playerJoining', function()
    local src = source
    Wait(2000) -- Give time for player to fully load
    
    if not PlayerBuffs[src] then
        PlayerBuffs[src] = {
            strength = { active = false, endTime = 0, value = 0 },
            stamina = { active = false, endTime = 0, value = 0 },
            intelligence = { active = false, endTime = 0, value = 0 },
            money_luck = { active = false, endTime = 0, value = 0 },
            alert = { active = false, endTime = 0, value = 0 }
        }
        if Config.Debug then
            print('[DEBUG] Initialized buffs for joining player:', src)
        end
    end
end)

-- Clean up buffs on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if PlayerBuffs[src] then
        PlayerBuffs[src] = nil
        if Config.Debug then
            print('[DEBUG] Cleaned up buffs for player:', src)
        end
    end
end)

-- Apply buff event
RegisterNetEvent('ferp_restaurant:server:applyBuff', function(buffType, strength, duration)
    local src = source
    
    -- Validate inputs
    if type(buffType) ~= 'string' or type(strength) ~= 'number' or type(duration) ~= 'number' then
        if Config.Debug then print('[SECURITY] Invalid buff parameters from player:', src) end
        return
    end
    
    -- Validate buff type
    local validBuffs = {strength = true, stamina = true, intelligence = true, money_luck = true, alert = true}
    if not validBuffs[buffType] then
        if Config.Debug then print('[SECURITY] Invalid buff type from player:', src, buffType) end
        return
    end
    
    -- Validate ranges
    if strength < 0 or strength > 100 or duration < 0 or duration > 600 then
        if Config.Debug then print('[SECURITY] Invalid buff values from player:', src, strength, duration) end
        return
    end
    
    -- Force initialize player buffs if not exists (immediate fix)
    if not PlayerBuffs[src] then
        PlayerBuffs[src] = {
            strength = { active = false, endTime = 0, value = 0 },
            stamina = { active = false, endTime = 0, value = 0 },
            intelligence = { active = false, endTime = 0, value = 0 },
            money_luck = { active = false, endTime = 0, value = 0 },
            alert = { active = false, endTime = 0, value = 0 }
        }
        if Config.Debug then
            print('[DEBUG] Force initialized buffs for player during buff application:', src)
        end
    end
    
    local currentTime = GetGameTimer()
    local endTime = currentTime + (duration * 1000) -- Convert to milliseconds
    
    -- Apply the buff
    if PlayerBuffs[src][buffType] then
        PlayerBuffs[src][buffType] = {
            active = true,
            endTime = endTime,
            value = strength
        }
        
        -- Notify client about buff
        TriggerClientEvent('ferp_restaurant:client:buffApplied', src, buffType, strength, duration)
        
        -- Apply real buff effects
        if buffType == "money_luck" then
            -- Money buff affects job payments
            TriggerEvent('ferp_restaurant:server:applyMoneyBuff', src, strength, duration)
        elseif buffType == "stamina" then
            -- Stamina buff affects player stamina
            TriggerClientEvent('ferp_restaurant:client:applyStaminaBuff', src, strength, duration)
        elseif buffType == "intelligence" then
            -- Intelligence buff affects XP gain
            TriggerEvent('ferp_restaurant:server:applyIntelligenceBuff', src, strength, duration)
        elseif buffType == "strength" then
            -- Strength buff affects damage/health
            TriggerClientEvent('ferp_restaurant:client:applyStrengthBuff', src, strength, duration)
        elseif buffType == "alert" then
            -- Alert buff affects reaction time
            TriggerClientEvent('ferp_restaurant:client:applyAlertBuff', src, strength, duration)
        end
        
        if Config.Debug then print('[DEBUG] Applied buff:', buffType, 'to player:', src, 'strength:', strength, 'duration:', duration) end
        if Config.Debug then print('[DEBUG] Player buffs after application:', json.encode(PlayerBuffs[src])) end
        
        -- Start buff expiration timer
        SetTimeout(duration * 1000, function()
            if PlayerBuffs[src] and PlayerBuffs[src][buffType] then
                PlayerBuffs[src][buffType].active = false
                TriggerClientEvent('ferp_restaurant:client:buffExpired', src, buffType)
                if Config.Debug then print('[DEBUG] Buff expired:', buffType, 'for player:', src) end
            end
        end)
    else
        if Config.Debug then print('[DEBUG] ERROR: Invalid buff type:', buffType, 'for player:', src) end
    end
end)

-- Get player buffs (for other resources to check)
RegisterNetEvent('ferp_restaurant:server:getPlayerBuffs', function()
    local src = source
    TriggerClientEvent('ferp_restaurant:client:receivePlayerBuffs', src, PlayerBuffs[src] or {})
end)

-- Real buff effect implementations

-- Money buff - increases job payments
RegisterNetEvent('ferp_restaurant:server:applyMoneyBuff', function(playerId, strength, duration)
    -- Hook into job payment system
    local originalPayment = nil
    
    -- Override payment calculation temporarily
    RegisterNetEvent('qb-phone:server:GiveJobPayment', function(amount, job)
        local src = source
        if src == playerId and PlayerBuffs[playerId] and PlayerBuffs[playerId].money_luck and PlayerBuffs[playerId].money_luck.active then
            local bonus = math.floor(amount * (strength / 1000)) -- Convert buff strength to percentage
            amount = amount + bonus
            if Config.Debug then print('[DEBUG] Money buff applied - Original:', amount - bonus, 'Bonus:', bonus, 'Total:', amount) end
        end
        -- Call original event logic here if needed
    end)
end)

-- Intelligence buff - increases XP gain
RegisterNetEvent('ferp_restaurant:server:applyIntelligenceBuff', function(playerId, strength, duration)
    -- This would integrate with your XP system
    if Config.Debug then print('[DEBUG] Intelligence buff active for player:', playerId, 'XP bonus:', strength .. '%') end
    -- Example: When player gains XP, multiply by (1 + strength/100)
end)

-- Export function to check if player should get buff bonus
exports('GetJobPaymentBonus', function(playerId, baseAmount)
    if PlayerBuffs[playerId] and PlayerBuffs[playerId].money_luck and PlayerBuffs[playerId].money_luck.active then
        local currentTime = GetGameTimer()
        if currentTime < PlayerBuffs[playerId].money_luck.endTime then
            local bonus = math.floor(baseAmount * (PlayerBuffs[playerId].money_luck.value / 1000))
            return bonus
        end
    end
    return 0
end)

-- Export function to get XP multiplier
exports('GetXPMultiplier', function(playerId)
    if PlayerBuffs[playerId] and PlayerBuffs[playerId].intelligence and PlayerBuffs[playerId].intelligence.active then
        local currentTime = GetGameTimer()
        if currentTime < PlayerBuffs[playerId].intelligence.endTime then
            return 1 + (PlayerBuffs[playerId].intelligence.value / 100) -- Convert to multiplier
        end
    end
    return 1.0
end)

-- Consume item event
RegisterNetEvent('ferp_restaurant:server:consumeItem', function(itemData)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end
    
    -- Remove item from inventory
    local itemName = itemData.name or itemData.Item
    local slot = itemData.slot or itemData.Slot
    local metadata = itemData.metadata or itemData.Metadata
    
    if exports.ox_inventory:RemoveItem(src, itemName, 1, metadata, slot) then
        if Config.Debug then print('[DEBUG] Removed consumed item:', itemName, 'from player:', src) end
    else
        if Config.Debug then print('[DEBUG] Failed to remove item:', itemName, 'from player:', src) end
    end
end)

-- functions for other resources
exports('GetPlayerBuff', function(playerId, buffType)
    if PlayerBuffs[playerId] and PlayerBuffs[playerId][buffType] then
        local buff = PlayerBuffs[playerId][buffType]
        if buff.active and GetGameTimer() < buff.endTime then
            return buff.value
        end
    end
    return 0
end)

exports('HasPlayerBuff', function(playerId, buffType)
    if PlayerBuffs[playerId] and PlayerBuffs[playerId][buffType] then
        local buff = PlayerBuffs[playerId][buffType]
        return buff.active and GetGameTimer() < buff.endTime
    end
    return false
end)

exports('GetAllPlayerBuffs', function(playerId)
    return PlayerBuffs[playerId] or {}
end)

-- Buff cleanup thread
CreateThread(function()
    while true do
        local currentTime = GetGameTimer()
        
        for playerId, buffs in pairs(PlayerBuffs) do
            for buffType, buffData in pairs(buffs) do
                if buffData.active and currentTime >= buffData.endTime then
                    buffData.active = false
                    TriggerClientEvent('ferp_restaurant:client:buffExpired', playerId, buffType)
                    if Config.Debug then print('[DEBUG] Auto-expired buff:', buffType, 'for player:', playerId) end
                end
            end
        end
        
        Wait(10000) -- Check every 10 seconds
    end
end)

-- Debug command to test buffs
RegisterCommand('testbuff', function(source, args)
    local src = source
    local buffType = args[1] or 'strength'
    local strength = tonumber(args[2]) or 100
    local duration = tonumber(args[3]) or 300
    
    -- Force initialize player buffs if not exists
    if not PlayerBuffs[src] then
        PlayerBuffs[src] = {
            strength = { active = false, endTime = 0, value = 0 },
            stamina = { active = false, endTime = 0, value = 0 },
            intelligence = { active = false, endTime = 0, value = 0 },
            money_luck = { active = false, endTime = 0, value = 0 },
            alert = { active = false, endTime = 0, value = 0 }
        }
        if Config.Debug then print('[DEBUG] Force initialized buffs for player:', src) end
    end
    
    TriggerEvent('ferp_restaurant:server:applyBuff', buffType, strength, duration)
    if Config.Debug then print('[DEBUG] Manual buff test triggered:', buffType, strength, duration) end
end, false)

-- Debug command to check buffs
RegisterCommand('checkbuffs', function(source)
    local src = source
    
    -- Force initialize if not exists
    if not PlayerBuffs[src] then
        PlayerBuffs[src] = {
            strength = { active = false, endTime = 0, value = 0 },
            stamina = { active = false, endTime = 0, value = 0 },
            intelligence = { active = false, endTime = 0, value = 0 },
            money_luck = { active = false, endTime = 0, value = 0 },
            alert = { active = false, endTime = 0, value = 0 }
        }
        if Config.Debug then print('[DEBUG] Force initialized buffs for checkbuffs command:', src) end
    end
    
    if Config.Debug then print('[DEBUG] Current player buffs for player', src, ':', json.encode(PlayerBuffs[src])) end
    TriggerClientEvent('ferp_restaurant:client:receivePlayerBuffs', src, PlayerBuffs[src])
end, false)

if Config.Debug then print('[DEBUG] Restaurant buff server system loaded') end

-- Calculate hack time with intelligence buff
exports('GetHackTimeWithBuff', function(playerId, baseTimeSeconds)
    if not playerId or not baseTimeSeconds then return baseTimeSeconds or 30 end
    
    local hasIntelligence = exports['ferp_restaurant']:HasPlayerBuff(playerId, 'intelligence')
    
    if hasIntelligence then
        local intelligenceValue = exports['ferp_restaurant']:GetPlayerBuff(playerId, 'intelligence')
        
        -- Intelligence buff increases hack time by 25-100% based on strength
        local timeMultiplier = 1 + (intelligenceValue / 100) -- 20 value = +20%, 100 value = +100%
        local newTime = math.floor(baseTimeSeconds * timeMultiplier)
        
        -- Ensure minimum increase of 10 seconds and maximum of 180 seconds
        newTime = math.max(baseTimeSeconds + 10, math.min(newTime, 180))
        
        if Config.Debug then print('[DEBUG] Intelligence buff applied to hack time. Base:', baseTimeSeconds, 'New:', newTime, 'Buff value:', intelligenceValue) end
        return newTime
    end
    
    return baseTimeSeconds
end)

-- Check if player should get extended hack time
exports('ShouldExtendHackTime', function(playerId)
    if not playerId then return false end
    return exports['ferp_restaurant']:HasPlayerBuff(playerId, 'intelligence')
end)
