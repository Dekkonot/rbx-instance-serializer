local gui = script.Parent.Background

local optionContainer = gui.OptionContainer
local serializeContainer = gui.SerializeContainer
local retryContainer = gui.RetryContainer

local verboseOption = optionContainer.VerboseOption
local moduleOption = optionContainer.ModuleOption
local parentOption = optionContainer.ParentOption
local contextOption = optionContainer.ContextOption

local UI = {}

UI.Background = gui

UI.SerializeContainer = serializeContainer
UI.SerializeButton = serializeContainer.SerializeButton
UI.SerializeText = serializeContainer.SerializeText

UI.RetryContainer = retryContainer
UI.RetryButton = retryContainer.RetryButton
UI.RetryText = retryContainer.RetryText

UI.VerboseButton = verboseOption.ToggleButton
UI.VerboseNob = verboseOption.ToggleButton.Nob
UI.VerboseLabel = verboseOption.Label

UI.ModuleButton = moduleOption.ToggleButton
UI.ModuleNob = moduleOption.ToggleButton.Nob
UI.ModuleLabel = moduleOption.Label

UI.ParentButton = parentOption.ToggleButton
UI.ParentNob = parentOption.ToggleButton.Nob
UI.ParentLabel = parentOption.Label

UI.ContextButton = contextOption.ToggleButton
UI.ContextNob = contextOption.ToggleButton.Nob
UI.ContextLabel = contextOption.Label

return UI
