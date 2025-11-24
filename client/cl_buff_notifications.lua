-- Client-side buff notification system

-- Buff applied notification
RegisterNetEvent('ferp_restaurant:client:buffApplied', function(buffType, strength, duration)
    local buffNames = {
        strength = 'Forte',
        stamina = 'Resistente', 
        intelligence = 'Inteligente',
        money_luck = 'Sortudo',
        alert = 'Alerta'
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
        title = 'Efeito Ativo',
        description = 'Você se sente mais ' .. buffName .. ' (' .. timeText .. ')',
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
        strength = 'Forte',
        stamina = 'Resistente',
        intelligence = 'Inteligente', 
        money_luck = 'Sortudo',
        alert = 'Alerta'
    }
    
    local buffName = buffNames[buffType] or buffType
    
    TriggerEvent('ox_lib:notify', {
        title = 'Efeito Expirado',
        description = 'Você não se sente mais ' .. buffName,
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
                strength = 'Forte',
                stamina = 'Resistente',
                intelligence = 'Inteligente', 
                money_luck = 'Sortudo',
                alert = 'Alerta'
            }
            local buffName = buffNames[buffType] or buffType
            activeBuffs[#activeBuffs + 1] = buffName
        end
    end
    
    if #activeBuffs > 0 then
        TriggerEvent('ox_lib:notify', {
            title = 'Efeitos Ativos',
            description = 'Você se sente: ' .. table.concat(activeBuffs, ', '),
            type = 'inform',
            duration = 5000
        })
    else
        TriggerEvent('ox_lib:notify', {
            title = 'Efeitos Ativos',
            description = 'Nenhum efeito ativo no momento',
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
