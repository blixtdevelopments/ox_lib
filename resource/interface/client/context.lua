--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

local contextMenus = {}
local openContextMenu = nil
local usingBlixtContext = false

local function blixtContextCall(name, data)
    if GetResourceState('blixt-ui') ~= 'started' then return false end
    local ok, result = pcall(function()
        if name == 'showContext' then return exports['blixt-ui']:showContext(data) end
        if name == 'hideContext' then return exports['blixt-ui']:hideContext() end
        return false
    end)
    return ok and result == true
end

---@class ContextMenuItem
---@field title? string
---@field menu? string
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string
---@field image? string
---@field progress? number
---@field onSelect? fun(args: any)
---@field arrow? boolean
---@field description? string
---@field metadata? string | { [string]: any } | string[]
---@field disabled? boolean
---@field readOnly? boolean
---@field event? string
---@field serverEvent? string
---@field args? any

---@class ContextMenuArrayItem : ContextMenuItem
---@field title string

---@class ContextMenuProps
---@field id string
---@field title string
---@field menu? string
---@field onExit? fun()
---@field onBack? fun()
---@field canClose? boolean
---@field options { [string]: ContextMenuItem } | ContextMenuArrayItem[]

local function closeContext(_, cb, onExit)
    if cb then cb(1) end

    lib.resetNuiFocus()

    if not openContextMenu then return end

    if (cb or onExit) and contextMenus[openContextMenu].onExit then contextMenus[openContextMenu].onExit() end

    if usingBlixtContext then
        blixtContextCall('hideContext')
    elseif not cb then
        SendNUIMessage({ action = 'hideContext' })
    end
    usingBlixtContext = false

    openContextMenu = nil
end

---@param id string
function lib.showContext(id)
    if not contextMenus[id] then error('No context menu of such id found.') end

    local data = contextMenus[id]
    openContextMenu = id

    local payload = {
        title = data.title,
        canClose = data.canClose,
        menu = data.menu,
        options = data.options
    }

    -- Use the same JSON-safe payload as stock ox_lib (onSelect callbacks remain in ox_lib).
    if blixtContextCall('showContext', json.encode(payload, { sort_keys = true })) then
        usingBlixtContext = true
        return
    end

    usingBlixtContext = false
    lib.setNuiFocus(false)
    SendNuiMessage(json.encode({ action = 'showContext', data = payload }, { sort_keys = true }))
end

---@param context ContextMenuProps | ContextMenuProps[]
function lib.registerContext(context)
    for k, v in pairs(context) do
        if type(k) == 'number' then
            contextMenus[v.id] = v
        else
            contextMenus[context.id] = context
            break
        end
    end
end

---@return string?
function lib.getOpenContextMenu() return openContextMenu end

---@param onExit boolean?
function lib.hideContext(onExit) closeContext(nil, nil, onExit) end

local function handleContextOpen(data, cb)
    cb(1)

    local menu = openContextMenu and contextMenus[openContextMenu]
    if data.back and menu and menu.onBack then menu.onBack() end

    lib.showContext(data.id)
end

RegisterNUICallback('openContext', handleContextOpen)

local function handleContextClick(id, cb)
    cb(1)

    if math.type(tonumber(id)) == 'float' then
        id = math.tointeger(id)
    elseif tonumber(id) then
        id += 1
    end

    local menu = openContextMenu and contextMenus[openContextMenu]
    local data = menu and menu.options[id]
    if not data then return end

    if not data.event and not data.serverEvent and not data.onSelect then return end

    openContextMenu = nil

    if usingBlixtContext then
        blixtContextCall('hideContext')
        usingBlixtContext = false
    else
        SendNUIMessage({ action = 'hideContext' })
    end
    lib.resetNuiFocus()

    if data.onSelect then data.onSelect(data.args) end
    if data.event then TriggerEvent(data.event, data.args) end
    if data.serverEvent then TriggerServerEvent(data.serverEvent, data.args) end
end

RegisterNUICallback('clickContext', handleContextClick)

RegisterNUICallback('closeContext', closeContext)

-- Only the Blixt NUI responds to these local events; ox_lib remains the callback owner.
AddEventHandler('blixt-ui:contextAction', function(action, data)
    local noop = function() end
    if action == 'openContext' then handleContextOpen(data, noop)
    elseif action == 'clickContext' then handleContextClick(data, noop)
    elseif action == 'closeContext' then closeContext(data, noop) end
end)



