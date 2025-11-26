--[[
    Restaurant Buff System - Simplified version without premium ingredients
    All ingredients provide normal buffs based on category from Config.Ingredients
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
    -- Normal scaling: 1 ingredient = 25% max, up to 100% with 4+ ingredients
    local buffStrength
    
    if ingredientCount == 1 then
        buffStrength = 25 -- 1 ingredient = 25% buff
    elseif ingredientCount == 2 then
        buffStrength = 50 -- 2 ingredients = 50% buff
    elseif ingredientCount == 3 then
        buffStrength = 75 -- 3 ingredients = 75% buff
    else
        buffStrength = 100 -- 4+ ingredients = 100% buff
    end
    
    local duration = 300 -- 5 minutes default (300 seconds)
    
    if buffType == "stamina" then
        duration = 300
    end
    
    if Config.Debug then
        print('[DEBUG] Normal buff calculation - Count:', ingredientCount, 'Strength:', buffStrength, 'Type:', buffType, 'Duration:', duration)
    end
    
    if buffType == "strength" then
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'strength', buffStrength, duration)
    elseif buffType == "stamina" then
        -- Also apply medical healing based on vegetable count
        local healAmount = ingredientCount * 10 -- 10 points per vegetable
        Buffs.applyMedicalHealing(healAmount)
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'stamina', buffStrength, duration)
    elseif buffType == "intelligence" then
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'intelligence', buffStrength, duration)
    elseif buffType == "money" then
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'money_luck', buffStrength, 600) -- 10 minutes
    elseif buffType == "alert" then
        TriggerServerEvent('ferp_restaurant:server:applyBuff', 'alert', buffStrength, 180) -- 3 minutes
    end
end

-- Function to apply stress relief (immediate effect)
function Buffs.applyStressRelief(ingredientCount)
    local stressReduction = math.floor(25 * ingredientCount) -- 25 stress per ingredient
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
        print('[DEBUG] Stress relief applied - Count:', ingredientCount, 'Reduction:', stressReduction)
    end
end

-- Function to apply hunger boost (immediate effect)
function Buffs.applyHungerBoost(ingredientCount)
    local extraHunger = math.floor(30 * ingredientCount) -- 30 hunger per grain ingredient
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
        print('[DEBUG] Hunger boost applied - Count:', ingredientCount, 'Boost:', extraHunger)
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
