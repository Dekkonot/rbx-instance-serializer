local Util = require(script.Parent.Util)

local pluginError = Util.pluginError

local plugin = nil

local function init(thing)
    if typeof(thing) == "Instance" and thing:IsA("Plugin") then
        plugin = thing
    else
        pluginError("invalid argument type passed to SettingsHandler.init")
    end
end

local function getSetting(key)
    if typeof(key) ~= "string" then
        pluginError("Invalid key type passed to SettingsHandler.getSetting (expected string, got %s)", typeof(key))
    end
    if not plugin then
        pluginError("SettingsHandler.init has not been called yet")
    end
    return plugin:GetSetting(key)
end

local function setSetting(key, value)
    if typeof(key) ~= "string" then
        pluginError("Invalid key type passed to SettingsHandler.setSetting (expected string, got %s)", typeof(key))
    end
    if value == nil then
        pluginError("value must be provided to SettingsHandler.setSetting")
    end
    if not plugin then
        pluginError("SettingsHandler.init has not been called yet")
    end

    return ( pcall(plugin.SetSetting, plugin, key, value) ) -- Only return the first result from pcall
end

return {
    init = init,
    getSetting = getSetting,
    setSetting = setSetting,
}