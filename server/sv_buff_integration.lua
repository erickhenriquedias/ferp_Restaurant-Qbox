-- Example integration for other resources to use restaurant buffs

-- Example: Job system integration (QBX Core)
AddEventHandler('qbx_core:server:GiveJobPayment', function(amount, job)
    local src = source
    
    -- Check if player has money buff
    local bonus = exports['ferp_restaurant']:GetJobPaymentBonus(src, amount)
    if bonus > 0 then
        amount = amount + bonus
        
        -- Notify player about bonus
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Money Buff Bonus!',
            description = 'You earned an extra $' .. bonus .. ' from your food buff!',
            type = 'success',
            duration = 4000
        })
        
        if Config.Debug then print('[DEBUG] Applied money buff bonus:', bonus, 'to job payment for player:', src) end
    end
    
    -- Continue with normal payment logic
    -- ... your existing job payment code here
end)

-- Example: XP system integration  
RegisterNetEvent('your-xp-system:giveXP', function(amount, skill)
    local src = source
    
    -- Check if player has intelligence buff
    local multiplier = exports['ferp_restaurant']:GetXPMultiplier(src)
    if multiplier > 1.0 then
        local originalAmount = amount
        amount = math.floor(amount * multiplier)
        local bonus = amount - originalAmount
        
        if Config.Debug then print('[DEBUG] Applied intelligence buff bonus:', bonus, 'XP to player:', src) end
    end
    
    -- Continue with normal XP giving logic
    -- ... your existing XP code here
end)

-- Example: How other resources can check for buffs
RegisterCommand('checkplayerbuffs', function(source, args)
    local targetId = tonumber(args[1]) or source
    
    local hasStrength = exports['ferp_restaurant']:HasPlayerBuff(targetId, 'strength')
    local hasStamina = exports['ferp_restaurant']:HasPlayerBuff(targetId, 'stamina')  
    local hasIntelligence = exports['ferp_restaurant']:HasPlayerBuff(targetId, 'intelligence')
    local hasMoney = exports['ferp_restaurant']:HasPlayerBuff(targetId, 'money_luck')
    local hasAlert = exports['ferp_restaurant']:HasPlayerBuff(targetId, 'alert')
    
    if Config.Debug then
        print('Player', targetId, 'active buffs:')
        print('- Strength:', hasStrength)
        print('- Stamina:', hasStamina)
        print('- Intelligence:', hasIntelligence)
        print('- Money Luck:', hasMoney)
        print('- Alert:', hasAlert)
        
        if hasStrength then
            local strengthValue = exports['ferp_restaurant']:GetPlayerBuff(targetId, 'strength')
            print('  Strength value:', strengthValue)
        end
    end
end, false)

if Config.Debug then print('[DEBUG] Restaurant buff integration examples loaded') end
