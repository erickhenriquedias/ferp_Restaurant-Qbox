-- Client-side real buff effects

local ActiveBuffs = {}

-- Stamina buff - reduces stamina loss
RegisterNetEvent('ferp_restaurant:client:applyStaminaBuff', function(strength, duration)
    ActiveBuffs.stamina = {
        strength = strength,
        endTime = GetGameTimer() + (duration * 1000)
    }
    
    if Config.Debug then
        print('[DEBUG] Stamina buff activated - Reduction:', strength .. '%')
    end
    
    -- Hook into stamina system
    CreateThread(function()
        while ActiveBuffs.stamina and GetGameTimer() < ActiveBuffs.stamina.endTime do
            -- Restore stamina faster
            local playerPed = PlayerPedId()
            if IsPedRunning(playerPed) or IsPedSprinting(playerPed) then
                RestorePlayerStamina(PlayerId(), ActiveBuffs.stamina.strength / 10)
            end
            Wait(1000)
        end
        ActiveBuffs.stamina = nil
        if Config.Debug then
            print('[DEBUG] Stamina buff expired')
        end
    end)
end)

-- Strength buff - increases melee damage and health regen
RegisterNetEvent('ferp_restaurant:client:applyStrengthBuff', function(strength, duration)
    ActiveBuffs.strength = {
        strength = strength,
        endTime = GetGameTimer() + (duration * 1000)
    }
    
    if Config.Debug then
        print('[DEBUG] Strength buff activated - Bonus:', strength)
    end
    
    -- Apply strength effects
    CreateThread(function()
        local playerPed = PlayerPedId()
        local originalHealth = GetEntityHealth(playerPed)
        
        while ActiveBuffs.strength and GetGameTimer() < ActiveBuffs.strength.endTime do
            -- Increase max health temporarily
            SetEntityMaxHealth(playerPed, 200 + (ActiveBuffs.strength.strength / 2))
            
            -- Slow health regeneration
            local currentHealth = GetEntityHealth(playerPed)
            if currentHealth < GetEntityMaxHealth(playerPed) and currentHealth > 0 then
                SetEntityHealth(playerPed, math.min(currentHealth + 1, GetEntityMaxHealth(playerPed)))
            end
            
            Wait(5000) -- Regen every 5 seconds
        end
        
        -- Reset max health
        SetEntityMaxHealth(playerPed, 200)
        ActiveBuffs.strength = nil
        if Config.Debug then
            print('[DEBUG] Strength buff expired')
        end
    end)
end)

-- Alert buff - increases reaction time and movement speed
RegisterNetEvent('ferp_restaurant:client:applyAlertBuff', function(strength, duration)
    ActiveBuffs.alert = {
        strength = strength,
        endTime = GetGameTimer() + (duration * 1000)
    }
    
    if Config.Debug then
        print('[DEBUG] Alert buff activated - Speed bonus:', strength .. '%')
    end
    
    -- Apply movement speed boost
    CreateThread(function()
        while ActiveBuffs.alert and GetGameTimer() < ActiveBuffs.alert.endTime do
            local playerPed = PlayerPedId()
            local speedMultiplier = 1.0 + (ActiveBuffs.alert.strength / 1000) -- Convert to multiplier
            
            -- Apply speed multiplier
            SetPedMoveRateOverride(playerPed, speedMultiplier)
            SetRunSprintMultiplierForPlayer(PlayerId(), speedMultiplier)
            
            Wait(100)
        end
        
        -- Reset speed
        local playerPed = PlayerPedId()
        SetPedMoveRateOverride(playerPed, 1.0)
        SetRunSprintMultiplierForPlayer(PlayerId(), 1.0)
        ActiveBuffs.alert = nil
        if Config.Debug then
            print('[DEBUG] Alert buff expired')
        end
    end)
end)

-- Export function to check if player has active buffs (for other resources)
exports('HasActiveBuff', function(buffType)
    return ActiveBuffs[buffType] and GetGameTimer() < ActiveBuffs[buffType].endTime
end)

exports('GetBuffStrength', function(buffType)
    if ActiveBuffs[buffType] and GetGameTimer() < ActiveBuffs[buffType].endTime then
        return ActiveBuffs[buffType].strength
    end
    return 0
end)

-- Melee damage multiplier hook
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkEntityDamage' then
        local victim, attacker, damage, weapon = args[1], args[2], args[4], args[5]
        
        if attacker == PlayerPedId() and ActiveBuffs.strength then
            -- Increase melee damage
            if IsWeaponValid(weapon) and (weapon == GetHashKey('WEAPON_UNARMED') or GetWeaponDamageType(weapon) == 1) then
                local bonusDamage = math.floor(damage * (ActiveBuffs.strength.strength / 1000))
                if Config.Debug then print('[DEBUG] Strength buff melee bonus:', bonusDamage) end
                -- Apply bonus damage - this would need integration with your damage system
            end
        end
    end
end)

if Config.Debug then print('[DEBUG] Real buff effects system loaded') end
