local UI = require(script.Parent.UI)
local ThemeSyncer = require(script.Parent.ThemeSyncer)

local TweenService = game:GetService("TweenService")

local GetOptions = script.Parent.GetOptions
local SetOptions = script.Parent.SetOptions

local NOB_TWEEN_INFO = TweenInfo.new(
	0.05,
	Enum.EasingStyle.Quad,
	Enum.EasingDirection.Out
)

local OFF_PROPERTIES = { Position = UDim2.new(0, 3, 0.5, 0) }
-- Magic numbers? No, just the size of the nob-3
local ON_PROPERTIES = { Position = UDim2.new(1, -21, 0.5, 0) }

local colorRadialOn = ThemeSyncer.colorRadialOn
local colorRadialOff = ThemeSyncer.colorRadialOff
local themeSyncInit = ThemeSyncer.init

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
	end

	tween:Play()
end

local function init()
	local states = GetOptions:Invoke() -- Forgive me padre for I have sinned :weary:

	local verboseNob, moduleNob = UI.VerboseNob, UI.ModuleNob
	local parentNob, contextNob = UI.ParentNob, UI.ContextNob

	if not states.verbose then -- todo refactor verbose stuff so this can match the rest of the implementation
		turnNobOn(verboseNob)
	end
	if states.module then
		turnNobOn(moduleNob)
	end
	if states.parent then
		turnNobOn(parentNob)
	end
	if states.context then
		turnNobOn(contextNob)
	end

	UI.VerboseButton.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local state = states.verbose
		state = not state
		SetOptions:Fire({ verbose = state })
		states.verbose = state
		if state then
			turnNobOff(verboseNob) -- todo refactor verbose stuff so this can match the rest of the implementation
		else
			turnNobOn(verboseNob)
		end
	end)
	UI.ModuleButton.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local state = states.module
		state = not state
		SetOptions:Fire({ module = state })
		states.module = state
		if state then
			turnNobOn(moduleNob)
		else
			turnNobOff(moduleNob)
		end
	end)
	UI.ParentButton.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local state = states.parent
		state = not state
		SetOptions:Fire({ parent = state })
		states.parent = state
		if state then
			turnNobOn(parentNob)
		else
			turnNobOff(parentNob)
		end
	end)
	UI.ContextButton.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local state = states.context
		state = not state
		SetOptions:Fire({ context = state })
		states.context = state
		if state then
			turnNobOn(contextNob)
		else
			turnNobOff(contextNob)
		end
	end)

	themeSyncInit()
end

return init
