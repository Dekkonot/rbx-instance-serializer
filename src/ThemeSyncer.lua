local UI = require(script.Parent.UI)
local Options = require(script.Parent.Options)

local Studio = settings().Studio

local RADIAL_BG_OFF_COLOR3 = {
	["Light"] = Color3.fromRGB(184, 184, 184),
	["Dark"] = Color3.fromRGB(85, 85, 85),
}

local RADIAL_BG_ON_COLOR3 = {
	["Light"] = Color3.fromRGB(2, 183, 87),
	["Dark"] = Color3.fromRGB(2, 183, 87),
}

local RADIAL_NOB_COLOR3 = {
	["Light"] = Color3.fromRGB(255, 255, 255),
	["Dark"] = Color3.fromRGB(192, 192, 192),
}

local function syncTheme()
	local theme = Studio.Theme
	local themeName = theme.Name
	
	local mainBackgroundColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)
	local borderColor3 = theme:GetColor(Enum.StudioStyleGuideColor.Border)
	local mainButtonColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
	local mainTextColor3 = theme:GetColor(Enum.StudioStyleGuideColor.MainText)
	
	local radialNobColor3 = RADIAL_NOB_COLOR3[themeName]
	local radialBgOnColor3 = RADIAL_BG_ON_COLOR3[themeName]
	local radialBgOffColor3 = RADIAL_BG_OFF_COLOR3[themeName]

	UI.Background.BackgroundColor3 = mainBackgroundColor3
	UI.Background.BorderColor3 = borderColor3

	UI.SerializeButton.ImageColor3 = mainButtonColor3
	UI.SerializeText.TextColor3 = mainTextColor3

	UI.RetryButton.ImageColor3 = mainButtonColor3
	UI.RetryText.TextColor3 = mainTextColor3

	UI.VerboseLabel.TextColor3 = mainTextColor3
	UI.VerboseNob.ImageColor3 = radialNobColor3
	if not Options.verbose then -- todo refactor verbose stuff so this can match the rest of the implementation
		UI.VerboseButton.ImageColor3 = radialBgOnColor3
	else
		UI.VerboseButton.ImageColor3 = radialBgOffColor3
	end
	
	UI.ModuleLabel.TextColor3 = mainTextColor3
	UI.ModuleNob.ImageColor3 = radialNobColor3
	if Options.module then
		UI.ModuleButton.ImageColor3 = radialBgOnColor3
	else
		UI.ModuleButton.ImageColor3 = radialBgOffColor3
	end
	
	UI.ParentLabel.TextColor3 = mainTextColor3
	UI.ParentNob.ImageColor3 = radialNobColor3
	if Options.parent then
		UI.ParentButton.ImageColor3 = radialBgOnColor3
	else
		UI.ParentButton.ImageColor3 = radialBgOffColor3
	end
	
	UI.ContextLabel.TextColor3 = mainTextColor3
	UI.ContextNob.ImageColor3 = radialNobColor3
	if Options.context then
		UI.ContextButton.ImageColor3 = radialBgOnColor3
	else
		UI.ContextButton.ImageColor3 = radialBgOffColor3
	end
end

local function colorRadialOn(radial)
	radial.ImageColor3 = RADIAL_BG_ON_COLOR3[Studio.Theme.Name]
end

local function colorRadialOff(radial)
	radial.ImageColor3 = RADIAL_BG_OFF_COLOR3[Studio.Theme.Name]
end

local function init()
	local serializeMouseDown = false
	local retryMouseDown = false
	syncTheme()

	-- What's a memory leak?
	UI.SerializeButton.InputBegan:Connect(function(input)
		if not serializeMouseDown and input.UserInputType == Enum.UserInputType.MouseMovement then
			UI.SerializeButton.ImageColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover)
			UI.SerializeText.TextColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			serializeMouseDown = true
			UI.SerializeButton.ImageColor3 =  Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Pressed)
			UI.SerializeText.TextColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Pressed)
		end
	end)
	UI.SerializeButton.InputEnded:Connect(function(input)
		if not serializeMouseDown and input.UserInputType == Enum.UserInputType.MouseMovement then
			UI.SerializeButton.ImageColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
			UI.SerializeText.TextColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			serializeMouseDown = false
			UI.SerializeButton.ImageColor3 =  Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
			UI.SerializeText.TextColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		end
	end)

	UI.RetryButton.InputBegan:Connect(function(input)
		if not retryMouseDown and input.UserInputType == Enum.UserInputType.MouseMovement then
			UI.RetryButton.ImageColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Hover)
			UI.RetryText.TextColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Hover)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			retryMouseDown = true
			UI.RetryButton.ImageColor3 =  Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton, Enum.StudioStyleGuideModifier.Pressed)
			UI.SerializeText.TextColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText, Enum.StudioStyleGuideModifier.Pressed)
		end
	end)
	UI.RetryButton.InputEnded:Connect(function(input)
		if not retryMouseDown and input.UserInputType == Enum.UserInputType.MouseMovement then
			UI.RetryButton.ImageColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
			UI.RetryText.TextColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			retryMouseDown = false
			UI.RetryButton.ImageColor3 =  Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainButton)
			UI.RetryText.TextColor3 = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainText)
		end
	end)

	Studio.ThemeChanged:Connect(syncTheme)

	return true
end

return {
	init = init,
	colorRadialOn = colorRadialOn,
	colorRadialOff = colorRadialOff,
}