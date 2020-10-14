local Maid = require(script.Parent.Modules.Maid)
local UI = require(script.Parent.UI)
local ThemeSyncer = require(script.Parent.ThemeSyncer)
local SettingsHandler = require(script.Parent.SettingsHandler)
local Options = require(script.Parent.Options)

local TweenService = game:GetService("TweenService")

local CleanupMaid = Maid.new()

local NOB_TWEEN_INFO = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local OFF_PROPERTIES = { Position = UDim2.new(0, 3, 0.5, 0) }
local ON_PROPERTIES = { Position = UDim2.new(1, -21, 0.5, 0) } -- Magic numbers? No, just the size of the nob-3

local colorRadialOn, colorRadialOff, themeSyncInit = ThemeSyncer.colorRadialOn, ThemeSyncer.colorRadialOff, ThemeSyncer.init

local onTweens = {}
local offTweens = {}

local function turnNobOn(nob)
    local tween = onTweens[nob]
    if not tween then
        tween = TweenService:Create(nob, NOB_TWEEN_INFO, ON_PROPERTIES)
        tween.Completed:Connect(function()
            colorRadialOn(nob.Parent)
        end)
        onTweens[nob] = tween
        CleanupMaid:Give(tween)
    end

    tween:Play()
end

local function turnNobOff(nob)
    local tween = offTweens[nob]
    if not tween then
        tween = TweenService:Create(nob, NOB_TWEEN_INFO, OFF_PROPERTIES)
        tween.Completed:Connect(function()
            colorRadialOff(nob.Parent)
        end)
        offTweens[nob] = tween
        CleanupMaid:Give(tween)
    end

    tween:Play()
end

local function init()-- Friendship with sin ended, now good design is my new best friend
    local verboseNob, moduleNob, parentNob, contextNob = UI.VerboseNob, UI.ModuleNob, UI.ParentNob, UI.ContextNob

    if not Options.verbose then -- todo refactor verbose stuff so this can match the rest of the implementation
        turnNobOn(verboseNob)
    end
    if Options.module then
        turnNobOn(moduleNob)
    end
    if Options.parent then
        turnNobOn(parentNob)
    end
    if Options.context then
        turnNobOn(contextNob)
    end

    --UI connections are disconnected when the UI is destroyed
    UI.VerboseButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local state = Options.verbose
        state = not state
        Options.verbose = state
        SettingsHandler.setSetting("settings", Options)
        if state then
            turnNobOff(verboseNob) -- todo refactor verbose stuff so this can match the rest of the implementation
        else
            turnNobOn(verboseNob)
        end
    end)
    UI.ModuleButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local state = Options.module
        state = not state
        Options.module = state
        SettingsHandler.setSetting("settings", Options)
        if state then
            turnNobOn(moduleNob)
        else
            turnNobOff(moduleNob)
        end
    end)
    UI.ParentButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local state = Options.parent
        state = not state
        Options.parent = state
        SettingsHandler.setSetting("settings", Options)
        if state then
            turnNobOn(parentNob)
        else
            turnNobOff(parentNob)
        end
    end)
    UI.ContextButton.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local state = Options.context
        state = not state
        Options.context = state
        SettingsHandler.setSetting("settings", Options)
        if state then
            turnNobOn(contextNob)
        else
            turnNobOff(contextNob)
        end
    end)

    CleanupMaid:Give(themeSyncInit())

    return CleanupMaid
end

return init