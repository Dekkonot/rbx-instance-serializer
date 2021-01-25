local Api = require(script.Parent.Parent.Modules.API)

local PROPERTY_FILTER = {"ReadOnly", "NotScriptable"}
local NORMAL_SECURITY_FILTER = {
    "PluginSecurity", "LocalUserSecurity", "RobloxScriptSecurity",
    "RobloxScriptSecurity", "NotAccessibleSecurity", "RobloxSecurity",
}
local PLUGIN_SECURITY_FILTER = {
    "LocalUserSecurity", "RobloxScriptSecurity",
    "NotAccessibleSecurity", "RobloxSecurity",
}

local FORBIDDEN_PROPERTIES = {
    ["BasePart"] = {
        "Position", "Rotation", "Orientation", "BrickColor", "brickColor"
    },
    ["FormFactorPart"] = {
        "FormFactor",
    },
    ["GuiObject"] = {
        "Transparency",
    },
}

local normalPropertyCache = {}
local pluginPropertyCache = {}

--- Gets the properties of a class that are accessible to normal scripts and returns them.
--- Caches the results.
local function getNormalProperties(class)
    local cache = normalPropertyCache[class]

    if not cache then
        cache = Api.getProperties(class, PROPERTY_FILTER, NORMAL_SECURITY_FILTER)
        for name in pairs(cache) do
            if string.find(name, "Color$") and cache[name .. "3"] then
                cache[name] = nil
            elseif string.find(name, "^%l") then
                if cache[string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)] then
                    cache[name] = nil
                end
            end
        end
        for _, superClass in ipairs(Api.getSuperclasses(class)) do
            if FORBIDDEN_PROPERTIES[superClass] then
                for _, property in ipairs(FORBIDDEN_PROPERTIES[superClass]) do
                    cache[property] = nil
                end
            end
        end

        normalPropertyCache[class] = cache
    end

    return cache
end

--- Gets the properties of a class that are accessible to plugins and returns them.
--- Caches the results.
local function getPluginProperties(class)
    local cache = pluginPropertyCache[class]

    if not cache then
        cache = Api.getProperties(class, PROPERTY_FILTER, PLUGIN_SECURITY_FILTER)
        for name in pairs(cache) do
            if string.find(name, "Color$") and cache[name .. "3"] then
                cache[name] = nil
            elseif string.find(name, "^%l") then
                if cache[string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)] then
                    cache[name] = nil
                end
            end
        end
        for _, superClass in ipairs(Api.getSuperclasses(class)) do
            if FORBIDDEN_PROPERTIES[superClass] then
                for _, property in ipairs(FORBIDDEN_PROPERTIES[superClass]) do
                    cache[property] = nil
                end
            end
        end

        pluginPropertyCache[class] = cache
    end

    return cache
end

return {
    getNormalProperties = getNormalProperties,
    getPluginProperties = getPluginProperties,
}