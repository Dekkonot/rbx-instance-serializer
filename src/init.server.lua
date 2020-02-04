--todo make a help menu for the options; open with a plugin menu?

local Serializer = require(script.Serializer)
local UI = require(script.UI)
local UIHandler = require(script.UIHandler)
local Util = require(script.Util)

local Selection = game:GetService("Selection")

local SetOptions = script.SetOptions

local pluginWarn = Util.pluginWarn
local serializerInit, serialize = Serializer.init, Serializer.serialize
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
            local didSerialize, output = serialize(v)
            if didSerialize then
                output.Name = "Serialized_"..string.gsub(v.Name:gsub("[^%w_]+", ""), "^%d+", "")
                output.Parent = v.Parent
            end
        end
    else
        local didSerialize, output = serialize(currentSelection[1])
        if didSerialize then
            Selection:Set({output})
            -- plugin:OpenScript(output)
            output.Parent = currentSelection[1].Parent
        end
    end
end

local function firstLoad()
    local success = serializerInit()
    print('test', success)
    local settings = plugin:GetSetting("settings")
    if not settings then
        settings = {}
    end
    SetOptions:Fire(settings)
    UI.VerboseButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        plugin:SetSetting("settings", { verbose = not settings.verbose })
    end)
    UI.ModuleButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        plugin:SetSetting("settings", { module = not settings.module })
    end)
    UI.ParentButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        plugin:SetSetting("settings", { parent = not settings.parent })
    end)
    UI.ContextButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        plugin:SetSetting("settings", { context = not settings.context })
    end)
    UI.Background.Visible = false
    UIHandler()
    UI.Background.Visible = true
    if success then
        firstLoadCompleted = true
        UI.SerializeContainer.Visible = true
        UI.RetryContainer.Visible = false
        firstLoadConnection:Disconnect()
        UI.SerializeButton.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
            serializeSelected()
        end)
        return true
    else
        UI.SerializeContainer.Visible = false
        UI.RetryContainer.Visible = true
        return false
    end
end

UI.RetryButton.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    firstLoad()
end)

firstLoadConnection = serializePluginGui:GetPropertyChangedSignal("Enabled"):Connect(firstLoad)
if serializePluginGui.Enabled then
    firstLoad()
end

local toolbar = plugin:CreateToolbar("Instance Serializer")
local toggleButton = toolbar:CreateButton("dekkonot-instance-serializer-toggle", "Toggle the serializer widget", "rbxassetid://2794885159", "Toggle Widget")
local action = plugin:CreatePluginAction("dekkonot-instance-serializer-run", "Serialize Selected Instances", "Run the serializer with the current settings", "rbxassetid://2795131004", true)

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