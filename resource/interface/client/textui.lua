--[[
    https://github.com/overextended/ox_lib

    This file is licensed under LGPL-3.0 or higher <https://www.gnu.org/licenses/lgpl-3.0.en.html>

    Copyright © 2025 Linden <https://github.com/thelindat>
]]

---@class TextUIOptions
---@field position? 'right-center' | 'left-center' | 'top-center' | 'bottom-center';
---@field icon? string | {[1]: IconProp, [2]: string};
---@field iconColor? string;
---@field style? string | table;
---@field alignIcon? 'top' | 'center';

local isOpen = false
local currentText
local currentOptions
local usingBlixtText = false

local function blixtTextCall(action, data)
    if GetResourceState('blixt-ui') ~= 'started' then return false end
    local ok, result = pcall(function()
        if action == 'show' then return exports['blixt-ui']:showTextUI(data) end
        return exports['blixt-ui']:hideTextUI()
    end)
    return ok and result == true
end

---@param text string
---@param options? TextUIOptions
function lib.showTextUI(text, options)
    if currentText == text then return end

    if not options then options = {} end
    options.text = text
    currentText = text
    currentOptions = options

    if blixtTextCall('show', options) then
        if isOpen and not usingBlixtText then
            SendNUIMessage({ action = 'textUiHide' })
        end
        usingBlixtText = true
    else
        usingBlixtText = false
        SendNUIMessage({ action = 'textUi', data = options })
    end

    isOpen = true
end

function lib.hideTextUI()
    if usingBlixtText then
        blixtTextCall('hide')
        usingBlixtText = false
    else
        SendNUIMessage({ action = 'textUiHide' })
    end

    isOpen = false
    currentText = nil
    currentOptions = nil
end

---@return boolean, string | nil
function lib.isTextUIOpen()
    return isOpen, currentText
end

AddEventHandler('onClientResourceStop', function(resource)
    if resource == 'blixt-ui' and usingBlixtText and isOpen and currentOptions then
        usingBlixtText = false
        SendNUIMessage({ action = 'textUi', data = currentOptions })
    end
end)
