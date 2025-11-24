local CATS = {
    -- UwU Cafe cats
    {
        position = vector4(-577.14, -1069.22, 21.99, 0.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ground@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-586.85, -1064.68, 22.35, 0.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ground@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-576.49, -1054.94, 21.42, 350.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ground@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-582.07, -1055.92, 21.43, 250.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ground@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-583.32, -1069.32, 21.99, 90.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ground@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-584.33, -1062.76, 22.40, 223.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ground@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-575.53, -1049.41, 22.53, 90.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ground@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-584.71, -1054.55, 22.10, 280.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ledge@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-576.78, -1057.52, 24.15, 0.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ledge@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-583.55, -1048.88, 24.50, 240.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ledge@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-595.29, -1055.54, 21.43, 180.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ledge@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-587.4, -1059.6, 22.3, 180.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@amb@world_cat_sleeping_ledge@base",
            name = "base",
            flag = 1
        }
    },
    {
        position = vector4(-571.65, -1057.26, 21.54, 90.0),
        model = `a_c_cat_01`,
        animation = {
            dict = "creatures@cat@move",
            name = "gallop",
            flag = 1
        }
    },
}

local spawnedCats = {}
local petCooldown = {} -- Cooldown para fazer carinho nos gatos

-- Function to pet a cat and reduce stress
local function petCat(cat, index)
    local playerPed = PlayerPedId()
    local playerId = GetPlayerServerId(PlayerId())
    
    -- Check cooldown (30 seconds per cat)
    local cooldownKey = playerId .. '_' .. index
    if petCooldown[cooldownKey] and (GetGameTimer() - petCooldown[cooldownKey]) < 30000 then
        local remainingTime = math.ceil((30000 - (GetGameTimer() - petCooldown[cooldownKey])) / 1000)
        TriggerEvent('ox_lib:notify', {
            title = 'Cat is Resting',
            description = 'Wait ' .. remainingTime .. ' seconds before petting this cat again',
            type = 'error'
        })
        return
    end
    
    -- Check if player is close enough
    local catCoords = GetEntityCoords(cat)
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(catCoords - playerCoords)
    
    if distance > 3.0 then
        TriggerEvent('ox_lib:notify', {
            title = 'Too Far',
            description = 'You need to get closer to the cat',
            type = 'error'
        })
        return
    end
    
    -- Play petting animation
    local success = exports.ox_lib:progressBar({
        duration = 3000,
        label = 'Petting Cat...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
            clip = 'machinic_loop_mechandplayer'
        }
    })
    
    if success then
        -- Set cooldown
        petCooldown[cooldownKey] = GetGameTimer()
        
        -- Reduce stress by 3-7 points
        local stressReduction = math.random(3, 7)
        TriggerServerEvent('hud:server:RelieveStress', stressReduction)
        
        if Config.Debug then print('[FERP Restaurant] Player petted cat ' .. index .. ', stress reduced by ' .. stressReduction) end
    end
end

-- Function to spawn a single cat
local function spawnCat(catData, index)
    RequestModel(catData.model)
    while not HasModelLoaded(catData.model) do
        Wait(100)
    end
    
    local cat = CreatePed(0, catData.model, catData.position.x, catData.position.y, catData.position.z, catData.position.w, false, true)
    
    if DoesEntityExist(cat) then
        -- Set cat properties
        SetEntityInvincible(cat, true)
        FreezeEntityPosition(cat, true)
        SetEntityCanBeDamaged(cat, false)
        SetPedCanRagdoll(cat, false)
        SetEntityCollision(cat, true, true) -- Enable collision for targeting
        SetBlockingOfNonTemporaryEvents(cat, true)
        SetPedFleeAttributes(cat, 0, false)
        SetPedCombatAttributes(cat, 17, true)
        SetPedRandomComponentVariation(cat, 0)
        
        -- Load and play animation if specified
        if catData.animation then
            RequestAnimDict(catData.animation.dict)
            while not HasAnimDictLoaded(catData.animation.dict) do
                Wait(100)
            end
            
            TaskPlayAnim(cat, catData.animation.dict, catData.animation.name, 8.0, 8.0, -1, catData.animation.flag, 0.0, false, false, false)
        end
        
        -- Wait a bit for entity to be fully loaded
        Wait(500)
        
        -- Add ox_target interaction for petting
        if exports.ox_target then
            exports.ox_target:addLocalEntity(cat, {
                {
                    name = 'pet_cat_' .. index,
                    icon = 'fas fa-heart',
                    label = 'Cat',
                    distance = 2.5,
                    drawSprite = true,
                    onSelect = function()
                        petCat(cat, index)
                    end
                }
            })
            if Config.Debug then print('[FERP Restaurant] Target added for cat ' .. index) end
        else
            if Config.Debug then print('[FERP Restaurant] ERROR: ox_target not found!') end
        end
        
        spawnedCats[index] = cat
        if Config.Debug then print('[FERP Restaurant] Cat spawned at position ' .. index) end
    else
        if Config.Debug then print('[FERP Restaurant] Failed to spawn cat at position ' .. index) end
    end
    
    SetModelAsNoLongerNeeded(catData.model)
end

-- Function to spawn all cats
local function spawnAllCats()
    if Config.Debug then print('[FERP Restaurant] Spawning restaurant cats...') end
    
    for i, catData in ipairs(CATS) do
        spawnCat(catData, i)
        Wait(500) -- Small delay between spawns
    end
    
    if Config.Debug then print('[FERP Restaurant] All cats spawned successfully!') end
end

-- Function to despawn all cats
local function despawnAllCats()
    if Config.Debug then print('[FERP Restaurant] Despawning restaurant cats...') end
    
    for i, cat in pairs(spawnedCats) do
        if DoesEntityExist(cat) then
            -- Remove ox_target interaction
            exports.ox_target:removeLocalEntity(cat, {'pet_cat_' .. i})
            
            -- Delete the cat
            DeletePed(cat)
            if Config.Debug then print('[FERP Restaurant] Cat ' .. i .. ' despawned') end
        end
    end
    
    spawnedCats = {}
end

-- Initialize cats when resource starts
CreateThread(function()
    Wait(5000) -- Wait longer for world and ox_target to load
    
    -- Verify ox_target is available
    if not exports.ox_target then
        if Config.Debug then print('[FERP Restaurant] ERROR: ox_target not available, cats will not have interactions') end
        return
    end
    
    if Config.Debug then print('[FERP Restaurant] ox_target confirmed, spawning cats...') end
    spawnAllCats()
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        despawnAllCats()
    end
end)

-- Export functions for external control
exports('spawnCats', spawnAllCats)
exports('despawnCats', despawnAllCats)
