--[[
    Restaurant Buff System 
]]--

local Buffs = {}

-- Category to buff type mapping
local CategoryBuffs = {
    ["protein"] = "strength",
    ["vegetables"] = "stamina", 
    ["leavening"] = "intelligence",
    ["dairy"] = "stress-relief",
    ["grain"] = "hunger",
    ["seasoning"] = "money",
    ["oil"] = "stress-relief",
    ["sugar"] = "alert"
}

-- Function to configure ingredient-based buffs
function Buffs.configureBuffs(metadata)
    -- Check if buff system is enabled
    if not Config.BuffSystem or not Config.BuffSystem.enabled then
        if Config.Debug then
            print('[DEBUG] Buff system is disabled in config')
        end
        return
    end
    
    if Config.Debug then
        print('[DEBUG] configureBuffs called with metadata:', json.encode(metadata))
    end
    
    if not metadata or not metadata.ingredients then
        if Config.Debug then
            print('[DEBUG] No ingredients found in metadata')
        end
        return
    end
    
    local ingredients = metadata.ingredients
    if type(ingredients) == 'string' then
        ingredients = json.decode(ingredients) or {}
    end
    
    if type(ingredients) ~= 'table' or #ingredients == 0 then
        if Config.Debug then
            print('[DEBUG] Invalid ingredients format or empty ingredients')
        end
        return
    end
    
    if Config.Debug then
        print('[DEBUG] Processing ingredients:', json.encode(ingredients))
    end
    
    -- Count ingredients per category
    local categoryCount = {}
    
    for _, ingredient in pairs(ingredients) do
        local ingredientData = Config.Ingredients[ingredient]
        if ingredientData then
            local category = ingredientData.category
            categoryCount[category] = (categoryCount[category] or 0) + 1
        end
    end
    
    if Config.Debug then
        print('[DEBUG] Category counts:', json.encode(categoryCount))
    end
    
    -- Apply buffs based on category counts
    for category, count in pairs(categoryCount) do
        local buffType = CategoryBuffs[category]
        
        if Config.Debug then
            print('[DEBUG] Processing category:', category, 'count:', count, 'buffType:', buffType)
        end
        
        if buffType then
            if category == "stress-relief" or category == "oil" or category == "dairy" then
                -- Immediate stress relief (not a buff)
                Buffs.applyStressRelief(count)
            elseif category == "hunger" or category == "grain" then
                -- Immediate hunger boost (not a buff)
                Buffs.applyHungerBoost(count)
            else
                -- Timed buffs
                Buffs.applySpecificBuff(buffType, count)
            end
        end
    end
end

-- Function to apply specific buff types
function Buffs.applySpecificBuff(buffType, ingredientCount)
    -- Get buff strength from config
    local baseStrength = Config.BuffStrength.strengthPerIngredient[ingredientCount] or Config.BuffStrength.strengthPerIngredient[4]
    
    -- Apply type-specific multiplier
    local typeMultiplier = Config.BuffStrength.globalMultipliers[buffType] or 1.0
    
    -- Apply global multiplier
    local globalMultiplier = Config.BuffStrength.globalMultipliers.allBuffs or 1.0
    
    -- Calculate final strength
    local buffStrength = math.floor(baseStrength * typeMultiplier * globalMultiplier)
    
    -- Get duration from config
    local duration = Config.BuffStrength.duration[buffType] or 300
    
    if Config.Debug then
        print('[DEBUG] Buff calculation - Type:', buffType, 'Count:', ingredientCount, 'Base:', baseStrength, 'TypeMult:', typeMultiplier, 'GlobalMult:', globalMultiplier, 'Final:', buffStrength, 'Duration:', duration)
    end
    
    if buffType == "strength" then
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'strength', buffStrength, duration)
    elseif buffType == "stamina" then
        -- Also apply medical healing based on vegetable count
        local healAmount = ingredientCount * Config.BuffStrength.immediate.healthPerVegetable
        Buffs.applyMedicalHealing(healAmount)
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'stamina', buffStrength, duration)
    elseif buffType == "intelligence" then
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'intelligence', buffStrength, duration)
    elseif buffType == "money" then
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'money_luck', buffStrength, duration)
    elseif buffType == "alert" then
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'alert', buffStrength, duration)
    end
end

-- Function to apply stress relief (immediate effect)
function Buffs.applyStressRelief(ingredientCount)
    -- Get stress reduction from config with multipliers
    local baseReduction = Config.BuffStrength.immediate.stressPerIngredient * ingredientCount
    local stressMultiplier = Config.BuffStrength.globalMultipliers.stress or 1.0
    local globalMultiplier = Config.BuffStrength.globalMultipliers.allBuffs or 1.0
    local stressReduction = math.floor(baseReduction * stressMultiplier * globalMultiplier)
    
    TriggerServerEvent('hud:server:RelieveStress', stressReduction)
    
    -- Show notification
    TriggerEvent('ox_lib:notify', {
        title = 'Comfort Food',
        description = 'Comfort foods help you relax! (-' .. stressReduction .. ' stress)',
        type = 'success',
        duration = 3000,
        icon = 'heart'
    })
    
    if Config.Debug then
        print('[DEBUG] Stress relief applied - Count:', ingredientCount, 'Base:', baseReduction, 'Multipliers:', stressMultiplier, globalMultiplier, 'Final:', stressReduction)
    end
end

-- Function to apply hunger boost (immediate effect)
function Buffs.applyHungerBoost(ingredientCount)
    -- Get hunger boost from config with multipliers
    local baseHunger = Config.BuffStrength.immediate.hungerPerIngredient * ingredientCount
    local hungerMultiplier = Config.BuffStrength.globalMultipliers.hunger or 1.0
    local globalMultiplier = Config.BuffStrength.globalMultipliers.allBuffs or 1.0
    local extraHunger = math.floor(baseHunger * hungerMultiplier * globalMultiplier)
    
    TriggerEvent("changehunger", extraHunger)
    
    -- Show notification
    TriggerEvent('ox_lib:notify', {
        title = 'Filling Meal',
        description = 'Hearty grains provide extra nutrition! (+' .. extraHunger .. ' hunger)',
        type = 'success',
        duration = 3000,
        icon = 'bread-slice'
    })
    
    if Config.Debug then
        print('[DEBUG] Hunger boost applied - Count:', ingredientCount, 'Base:', baseHunger, 'Multipliers:', hungerMultiplier, globalMultiplier, 'Final:', extraHunger)
    end
end

-- Function to apply medical healing (QBX Medical integration)
function Buffs.applyMedicalHealing(healAmount)
    if healAmount > 0 then
        TriggerServerEvent('ferp_restaurant:server:applyVegetableHealth', healAmount)
        
        if Config.Debug then
            print('[DEBUG] Medical healing applied - Amount:', healAmount)
        end
    end
end

-- Main consumption handler (simplified version)
RegisterNetEvent("ferp_restaurant:client:item-used", function(itemData)
    local metadata = itemData.metadata or {}
    
    if Config.Debug then
        print('[DEBUG] Restaurant item buff processing:', json.encode(itemData))
    end
    
    -- Apply ingredient-based buffs
    Buffs.configureBuffs(metadata)
end)

-- Event to add health using native functions (fallback when QBX Medical fails)
RegisterNetEvent('ferp_restaurant:client:addHealthNative', function(healAmount)
    local playerPed = PlayerPedId()
    local currentHealth = GetEntityHealth(playerPed)
    local maxHealth = GetEntityMaxHealth(playerPed)
    
    -- Calculate new health (limit to max health)
    local newHealth = math.min(currentHealth + healAmount, maxHealth)
    
    -- Apply the health
    SetEntityHealth(playerPed, newHealth)
    
    if Config.Debug then
        print('[DEBUG] Native health applied - Current:', currentHealth, 'Added:', healAmount, 'New:', newHealth, 'Max:', maxHealth)
    end
    
    -- Show notification about health gained
    local actualHealing = newHealth - currentHealth
    if actualHealing > 0 then
        TriggerEvent('ox_lib:notify', {
            title = 'Health Restored',
            description = 'You gained ' .. actualHealing .. ' health points',
            type = 'success',
            duration = 3000,
            icon = 'heart-pulse'
        })
    end
end)

-- Export functions
exports('configureBuffs', Buffs.configureBuffs)
exports('applySpecificBuff', Buffs.applySpecificBuff)
exports('applyStressRelief', Buffs.applyStressRelief)
exports('applyHungerBoost', Buffs.applyHungerBoost)
exports('applyMedicalHealing', Buffs.applyMedicalHealing)

return Buffs
