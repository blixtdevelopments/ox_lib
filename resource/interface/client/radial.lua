--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class RadialItem
---@field icon string | {[1]: IconProp, [2]: string};
---@field label string
---@field menu? string
---@field onSelect? fun(currentMenu: string | nil, itemIndex: number) | string
---@field [string] any
---@field keepOpen? boolean
---@field iconWidth? number
---@field iconHeight? number

---@class RadialMenuItem: RadialItem
---@field id string

---@class RadialMenuProps
---@field id string
---@field items RadialItem[]
---@field [string] any

local isOpen = false

local isDisabled = false
local usingBlixtRadial = false

local function blixtRadialCall(name, data)
    if GetResourceState('blixt-ui') ~= 'started' then return false end

    local ok, result = pcall(function()
        if name == 'beginRadial' then return exports['blixt-ui']:beginRadial() end
        if name == 'updateRadial' then return exports['blixt-ui']:updateRadial(data) end
        if name == 'endRadial' then return exports['blixt-ui']:endRadial() end
        return false
    end)

    return ok and result == true
end

local function radialMessage(data)
    if usingBlixtRadial then
        if not blixtRadialCall('updateRadial', data) then
            lib.hideRadial()
        end
    else
        SendNUIMessage({ action = 'openRadialMenu', data = data })
    end
end

---@type table<string, RadialMenuProps>
local menus = {}

---@type RadialMenuItem[]
local menuItems = {}

---@type table<{id: string, option: string}>
local menuHistory = {}

---@type RadialMenuProps?
local currentRadial = nil

---The registered menu opened directly with lib.showRadialMenu.
---@type RadialMenuProps?
local rootRadial = nil

---Open a the global radial menu or a registered radial submenu with the given id.
---@param id string?
---@param option number?
local function showRadial(id, option)
    local radial = id and menus[id]

    if id and not radial then
        return error('No radial menu with such id found.')
    end

    currentRadial = radial

    -- Hide current menu and allow for transition
    radialMessage(false)

    Wait(100)

    -- If menu was closed during transition, don't open the submenu
    if not isOpen then return end

    radialMessage({
        items = radial and radial.items or menuItems,
        sub = radial and radial ~= rootRadial or nil,
        option = option
    })
end

---Refresh the current menu items or return from a submenu to its parent.
local function refreshRadial(menuId)
    if not isOpen then return end

    if currentRadial and menuId then
        if menuId == currentRadial.id then
            return showRadial(menuId)
        else
            for i = 1, #menuHistory do
                local subMenu = menuHistory[i]

                if subMenu.id == menuId then
                    local parent = menus[subMenu.id]

                    for j = 1, #parent.items do
                        -- If we still have a path to the current submenu, refresh instead of returning
                        if parent.items[j].menu == currentRadial.id then
                            return -- showRadial(currentRadial.id)
                        end
                    end

                    currentRadial = parent

                    for j = #menuHistory, i, -1 do
                        menuHistory[j] = nil
                    end

                    return showRadial(currentRadial.id)
                end
            end
        end

        return
    end

    table.wipe(menuHistory)
    showRadial()
end

---Validates requirements and shows the requested radial menu.
---@param id string? If not provided, the global radial menu will be shown.
local function onRadialOpen(id)
    local radial = id and menus[id]

    if isDisabled or (id and not radial) then return end

    if isOpen then
        if rootRadial == radial then
            return lib.hideRadial()
        end

        rootRadial = radial
        table.wipe(menuHistory)
        return showRadial(id)
    end

    local items = radial and radial.items or menuItems
    if #items == 0 or IsNuiFocused() or IsPauseMenuActive() then return end

    isOpen = true
    rootRadial = radial
    table.wipe(menuHistory)

    usingBlixtRadial = blixtRadialCall('beginRadial')

    if not usingBlixtRadial then
        lib.setNuiFocus(true)
        SetCursorLocation(0.5, 0.5)
    end

    showRadial(id)

    while isOpen do
        if usingBlixtRadial and GetResourceState('blixt-ui') ~= 'started' then
            lib.hideRadial()
            break
        end
        DisablePlayerFiring(cache.playerId, true)
        DisableControlAction(0, 1, true)
        DisableControlAction(0, 2, true)
        DisableControlAction(0, 142, true)
        DisableControlAction(2, 199, true)
        DisableControlAction(2, 200, true)
        Wait(0)
    end
end

---Registers a radial sub menu with predefined options.
---@param radial RadialMenuProps
function lib.registerRadial(radial)
    menus[radial.id] = radial
    radial.resource = GetInvokingResource()

    if currentRadial then
        refreshRadial(radial.id)
    end
end

function lib.getCurrentRadialId()
    return currentRadial and currentRadial.id
end

function lib.hideRadial()
    if not isOpen then return end

    if usingBlixtRadial then
        blixtRadialCall('endRadial')
        usingBlixtRadial = false
    else
        SendNUIMessage({ action = 'openRadialMenu', data = false })
        lib.resetNuiFocus()
    end
    table.wipe(menuHistory)

    isOpen = false
    currentRadial = nil
    rootRadial = nil
end

---Registers an item or array of items in the global radial menu.
---@param items RadialMenuItem | RadialMenuItem[]
---@param parentMenuId string? If provided, the item(s) will be added to the specified radial submenu instead of the global menu.
function lib.addRadialItem(items, parentMenuId)
    local targetMenu
    if parentMenuId then
        if not menus[parentMenuId] then
            return error('No radial submenu with such parent id found.')
        end

        targetMenu = menus[parentMenuId].items
    else
        targetMenu = menuItems
    end

    local menuSize = #targetMenu
    local invokingResource = GetInvokingResource()

    items = table.type(items) == 'array' and items or { items }

    for i = 1, #items do
        local item = items[i]
        item.resource = invokingResource

        if menuSize == 0 then
            menuSize += 1
            targetMenu[menuSize] = item
        else
            for j = 1, menuSize do
                if targetMenu[j].id == item.id then
                    targetMenu[j] = item
                    break
                end

                if j == menuSize then
                    menuSize += 1
                    targetMenu[menuSize] = item
                end
            end
        end
    end

    if isOpen and not currentRadial then
        refreshRadial()
    end
end

---Removes an item from the global radial menu or a specific radial submenu with the given id.
---@param id string
---@param parentMenuId string? If provided, the item will be removed from the specified radial submenu instead of the global menu.
function lib.removeRadialItem(id, parentMenuId)
    local menuItem
    local targetMenu
    if parentMenuId then
        if not menus[parentMenuId] then
            return error('No radial sub menu with such parent id found.')
        end

        targetMenu = menus[parentMenuId].items
    else
        targetMenu = menuItems
    end

    for i = 1, #targetMenu do
        menuItem = targetMenu[i]

        if menuItem.id == id then
            table.remove(targetMenu, i)
            break
        end
    end

    if not isOpen then return end

    refreshRadial()
end

---Removes all items from the global radial menu.
function lib.clearRadialItems()
    table.wipe(menuItems)

    if isOpen then
        refreshRadial()
    end
end

local function handleRadialClick(index, cb)
    cb(1)

    if not isOpen or type(index) ~= 'number' or index % 1 ~= 0 then return end
    local itemIndex = index + 1
    local item, currentMenu

    if currentRadial then
        item = currentRadial.items[itemIndex]
        currentMenu = currentRadial.id
    else
        item = menuItems[itemIndex]
    end

    if not item then return end
    local menuResource = currentRadial and currentRadial.resource or item.resource

    if item.menu then
        menuHistory[#menuHistory + 1] = { id = currentRadial and currentRadial.id, option = item.menu }
        showRadial(item.menu)
    elseif not item.keepOpen then
        lib.hideRadial()
    end

    local onSelect = item.onSelect

    if onSelect then
        if type(onSelect) == 'string' then
            return exports[menuResource][onSelect](0, currentMenu, itemIndex)
        end

        onSelect(currentMenu, itemIndex)
    end
end

RegisterNUICallback('radialClick', handleRadialClick)

local function handleRadialBack(_, cb)
    cb(1)

    local numHistory = #menuHistory
    local lastMenu = numHistory > 0 and menuHistory[numHistory]

    if not lastMenu then return end

    menuHistory[numHistory] = nil

    if lastMenu.id then
        return showRadial(lastMenu.id, lastMenu.option)
    end

    currentRadial = nil

    -- Hide current menu and allow for transition
    radialMessage(false)

    Wait(100)

    -- If menu was closed during transition, don't open the submenu
    if not isOpen then return end

    radialMessage({
        items = menuItems,
        option = lastMenu.option
    })
end

RegisterNUICallback('radialBack', handleRadialBack)

local function handleRadialClose(_, cb)
    cb(1)
    if not isOpen then return end

    if usingBlixtRadial then
        lib.hideRadial()
        return
    end

    lib.resetNuiFocus()
    isOpen = false
    currentRadial = nil
    rootRadial = nil
end

RegisterNUICallback('radialClose', handleRadialClose)

AddEventHandler('blixt-ui:radialAction', function(action, data)
    if not usingBlixtRadial or not isOpen then return end

    local noop = function() end
    if action == 'click' then handleRadialClick(data, noop)
    elseif action == 'back' then handleRadialBack(nil, noop)
    elseif action == 'close' then handleRadialClose(nil, noop) end
end)

RegisterNUICallback('radialTransition', function(_, cb)
    Wait(100)

    -- If menu was closed during transition, don't open the submenu
    if not isOpen then return cb(false) end

    cb(true)
end)

---Disallow players from opening the radial menu.
---@param state boolean
function lib.disableRadial(state)
    isDisabled = state

    if isOpen and state then
        return lib.hideRadial()
    end
end

---Shows a registered menu as root without affecting global menus.
---@param id string
function lib.showRadialMenu(id)
    onRadialOpen(id)
end

lib.addKeybind({
    name = 'ox_lib-radial',
    description = locale('open_radial_menu'),
    defaultKey = 'z',
    onPressed = function()
        onRadialOpen()
    end,
    -- onReleased = lib.hideRadial,
})

AddEventHandler('onClientResourceStop', function(resource)
    for i = #menuItems, 1, -1 do
        local item = menuItems[i]

        if item.resource == resource then
            table.remove(menuItems, i)
        end
    end
end)
AddEventHandler('onClientResourceStop', function(resource)
    if resource == 'blixt-ui' and isOpen and usingBlixtRadial then
        lib.hideRadial()
    end
end)
