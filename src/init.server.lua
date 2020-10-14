local API = require(script.Modules.API)
local Serialize = require(script.Serializer)
local SettingsHandler = require(script.SettingsHandler)
local Maid = require(script.Modules.Maid)
local Options = require(script.Options)
local UI = require(script.UI)
local UIHandler = require(script.UIHandler)
local Util = require(script.Util)

local Selection = game:GetService("Selection")

local UnloadingMaid = Maid.new()

local pluginWarn = Util.pluginWarn
local firstLoadConnection

local firstLoadCompleted = false

local serializePluginGui = plugin:CreateDockWidgetPluginGui("dekkonot-instance-serializer-main", DockWidgetPluginGuiInfo.new(
    Enum.InitialDockState.Float, --initDockState
    true, --initEnabled
    false, --overrideEnabledRestore
    250, 200,--floatXSize, floatYSize
    0, 0 --minWidth, minHeight
))
serializePluginGui.Name = "InstanceSerializer"
serializePluginGui.Title = "Instance Serializer"

UI.Background.Parent = serializePluginGui

local function serializeSelected()
    local currentSelection = Selection:Get()
    if #currentSelection == 0 then
        pluginWarn("An Instance must be selected to serialize!")
    elseif #currentSelection > 1 then
        for _, v in ipairs(currentSelection) do
            local didSerialize, output = Serialize(v)
            if didSerialize then
                output.Name = "Serialized_"..string.gsub(v.Name:gsub("[^%w_]+", ""), "^%d+", "")
                output.Parent = v.Parent
            end
        end
    else
        local didSerialize, output = Serialize(currentSelection[1])
        if didSerialize then
            output.Parent = currentSelection[1].Parent
            Selection:Set({output})
            -- plugin:OpenScript(output)
        end
    end
end

local function firstLoad()
    SettingsHandler.init(plugin)
    local settings = SettingsHandler.getSetting("settings")
    if not settings then
        settings = {}
        for k, v in pairs(Options) do
            settings[k] = v
        end
        SettingsHandler.setSetting("settings", settings)
    end
    for k, v in pairs(settings) do
        Options[k] = v
    end

    UI.Background.Visible = false -- Significant performance gain in making the UI updates happen all at once
    UnloadingMaid:Give(UIHandler())
    UI.Background.Visible = true

    if not API.isReady() then
        UI.SerializeContainer.Visible = false
        API.readyEvent:Wait()
    end
    UI.SerializeContainer.Visible = true
    firstLoadCompleted = true
    firstLoadConnection:Disconnect()
    firstLoadConnection = nil

    UI.SerializeButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        serializeSelected()
    end)

    return true
end

UI.RetryButton.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    firstLoad()
end)

firstLoadConnection = serializePluginGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if serializePluginGui.Enabled then
        firstLoad()
    end
end)
if serializePluginGui.Enabled then
    firstLoad()
end

local toolbar = plugin:CreateToolbar("Instance Serializer")
local toggleButton = toolbar:CreateButton("dekkonot-instance-serializer-toggle", "Toggle the serializer widget", "rbxassetid://2794885159", "Toggle Widget")
local action = plugin:CreatePluginAction("dekkonot-instance-serializer-run", "Serialize Selected Instances", "Run the serializer with the current settings", "rbxassetid://2795131004", true)

toggleButton.ClickableWhenViewportHidden = true

if serializePluginGui.Enabled then
    toggleButton:SetActive(true)
end

toggleButton.Click:Connect(function()
    serializePluginGui.Enabled = not serializePluginGui.Enabled
    toggleButton:SetActive(serializePluginGui.Enabled)
end)

action.Triggered:Connect(function()
    if firstLoadCompleted then
        serializeSelected()
    else
        local success = firstLoad()
        if success then
            serializeSelected()
        end
    end
end)

UnloadingMaid:Give(toolbar)
UnloadingMaid:Give(toggleButton)
UnloadingMaid:Give(action)
UnloadingMaid:Give(serializePluginGui)

UnloadingMaid:Give(plugin.Unloading:Connect(function()
    UnloadingMaid:Sweep()
end))