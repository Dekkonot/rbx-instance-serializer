local Api = require(script.Parent.Modules.API, "src.Modules.API")
local GetProperties = require(script.GetProperties, "src.Serializer.GetProperties")
local Options = require(script.Parent.Options, "Options")
local SerializeMinified = require(script.Minified, "Serializer.Minified")
local SerializeVerbose = require(script.Verbose, "Serializer.Verbose")

local PRELOAD_CLASSES = {
    "Part",
    "Frame", "ScrollingFrame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton",
    "Humanoid",
}

coroutine.wrap(function()
    if not Api.isReady() then
        Api.readyEvent:Wait()
    end
    for _, class in ipairs(PRELOAD_CLASSES) do
        GetProperties.getNormalProperties(class)
        GetProperties.getPluginProperties(class)
    end
end)()

local function serialize(...)
    if Options.verbose then
        return SerializeVerbose(...)
    else
        return SerializeMinified(...)
    end
end
    

return serialize