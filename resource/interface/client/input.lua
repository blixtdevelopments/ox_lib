--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local input
local usingBlixtInput = false

local function blixtInputCall(action, payload)
    if GetResourceState('blixt-ui') ~= 'started' then return false end
    local ok, result = pcall(function()
        if action == 'show' then return exports['blixt-ui']:showInputDialog(payload) end
        return exports['blixt-ui']:hideInputDialog()
    end)
    return ok and result == true
end

---@class InputDialogRowProps
---@field type 'input' | 'number' | 'checkbox' | 'select' | 'slider' | 'multi-select' | 'date' | 'date-range' | 'time' | 'textarea' | 'color'
---@field label string
---@field options? { value: string, label: string, default?: string }[]
---@field password? boolean
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string
---@field placeholder? string
---@field default? string | number
---@field disabled? boolean
---@field checked? boolean
---@field min? number
---@field max? number
---@field step? number
---@field autosize? boolean
---@field required? boolean
---@field format? string
---@field returnString? boolean
---@field clearable? boolean
---@field searchable? boolean
---@field description? string
---@field maxSelectedValues? number
---@field minLength? number
---@field maxLength? number

---@class InputDialogOptionsProps
---@field allowCancel? boolean
---@field size? 'xs' | 'sm' | 'md' | 'lg' | 'xl'

---@param heading string
---@param rows string[] | InputDialogRowProps[]
---@param options InputDialogOptionsProps[]?
---@return string[] | number[] | boolean[] | nil
function lib.inputDialog(heading, rows, options)
    if input then return end
    input = promise.new()

    -- Backwards compat with string tables (build a normalized copy, don't mutate caller's rows)
    local normalized = table.create(#rows, 0)

    for i = 1, #rows do
        local row = rows[i]
        normalized[i] = type(row) == 'string'
            and { type = 'input', label = row --[[@as string]] }
            or row
    end

    if blixtInputCall('show', { heading = heading, rows = normalized, options = options }) then
        usingBlixtInput = true
        return Citizen.Await(input)
    end

    usingBlixtInput = false
    lib.setNuiFocus(false)
    SendNUIMessage({
        action = 'openDialog',
        data = {
            heading = heading,
            rows = normalized,
            options = options
        }
    })

    return Citizen.Await(input)
end

function lib.closeInputDialog()
    if not input then return end

    if usingBlixtInput then
        blixtInputCall('hide')
        usingBlixtInput = false
    else
        SendNUIMessage({ action = 'closeInputDialog' })
    end
    lib.resetNuiFocus()

    input:resolve(nil)
    input = nil
end

local function resolveInput(data)
    if not input then return end
    if usingBlixtInput then
        blixtInputCall('hide')
        usingBlixtInput = false
    end
    lib.resetNuiFocus()
    local pending = input
    input = nil
    pending:resolve(data)
end

RegisterNUICallback('inputData', function(data, cb)
    cb(1)
    resolveInput(data)
end)

AddEventHandler('blixt-ui:inputResult', resolveInput)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == 'blixt-ui' and usingBlixtInput then resolveInput(nil) end
end)
