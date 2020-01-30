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

local function firstLoad()
    local success = serializerInit()
    local settings = plugin:GetSetting("settings")
    if not settings then
        settings = {}
    end
    SetOptions:Invoke(settings)
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
    UIHandler()
    if success then
        UI.SerializeContainer.Visible = true
        UI.RetryContainer.Visible = false
        firstLoadConnection:Disconnect()
        UI.SerializeButton.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
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
        end)
    else
        UI.SerializeContainer.Visible = false
        UI.RetryContainer.Visible = true
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