--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@type promise?
local skillcheck
local usingBlixtSkill = false

---@alias SkillCheckDifficulity 'easy' | 'medium' | 'hard' | { areaSize: number, speedMultiplier: number }

local function blixtSkillCall(name, data)
    if GetResourceState('blixt-ui') ~= 'started' then return false end

    local ok, result = pcall(function()
        if name == 'start' then return exports['blixt-ui']:startSkillCheck(data) end
        if name == 'cancel' then return exports['blixt-ui']:cancelSkillCheck() end
        return false
    end)

    return ok and result == true
end

local function finishSkillCheck(success)
    if not skillcheck then return end

    usingBlixtSkill = false
    lib.resetNuiFocus()
    skillcheck:resolve(success)
    skillcheck = nil
end

---@param difficulty SkillCheckDifficulity | SkillCheckDifficulity[]
---@param inputs string[]?
---@return boolean?
function lib.skillCheck(difficulty, inputs)
    if skillcheck then return end
    skillcheck = promise:new()

    if blixtSkillCall('start', { difficulty = difficulty, inputs = inputs }) then
        usingBlixtSkill = true
    else
        usingBlixtSkill = false
        lib.setNuiFocus(false, true)
        SendNUIMessage({
            action = 'startSkillCheck',
            data = {
                difficulty = difficulty,
                inputs = inputs
            }
        })
    end

    return Citizen.Await(skillcheck)
end

function lib.cancelSkillCheck()
    if not skillcheck then
        error('No skillCheck is active')
    end

    if usingBlixtSkill then
        if not blixtSkillCall('cancel') then
            finishSkillCheck(false)
        end
        return
    end

    SendNUIMessage({action = 'skillCheckCancel'})
end

---@return boolean
function lib.skillCheckActive()
    return skillcheck ~= nil
end

RegisterNUICallback('skillCheckOver', function(success, cb)
    cb(1)

    if skillcheck and not usingBlixtSkill then
        finishSkillCheck(success)
    end
end)

AddEventHandler('blixt-ui:skillCheckOver', function(success)
    if skillcheck and usingBlixtSkill then
        finishSkillCheck(success == true)
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == 'blixt-ui' and skillcheck and usingBlixtSkill then
        finishSkillCheck(false)
    end
end)
