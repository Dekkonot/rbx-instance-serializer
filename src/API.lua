local TESTING_LOCALLY = false -- If true, there must be a module named `api` that returns the api dump json

local util = require(script.Parent.Util)
local pluginWarn, pluginError = util.pluginWarn, util.pluginError

local HttpService = game:GetService("HttpService")

local API_URL = "https://raw.githubusercontent.com/CloneTrooper1019/Roblox-Client-Tracker/roblox/API-Dump.json"

local PROPERTY_RESTRICTED_TAGS = { "ReadOnly", "NotScriptable" }
local INSTANCE_RESTRICTED_TAGS = { "NotScriptable" }
local SECURITY_RESTRICTED_TAGS = {
    ["RobloxSecurity"] = true,
    ["NotAccessibleSecurity"] = true,
    ["RobloxScriptSecurity"] = true,
}

local FORBIDDEN_PROPERTIES = {
    ["BasePart"] = {
        ["Position"] = true, -- Position, Rotation, and Orientation are all overruled by CFrame
        ["Rotation"] = true,
        ["Orientation"] = true,
        ["BrickColor"] = true,
        ["brickColor"] = true, -- Could be solved by moving how forbidden properties are handled but I don't care enough to fix it
    },
    ["GuiObject"] = {
        ["Transparency"] = true,
    },
}

local PRELOAD_CLASSES = {
    "Part",
    "Frame", "ScrollingFrame", "TextLabel", "TextButton", "TextBox", "ImageLabel", "ImageButton",
    "Humanoid",
}

local function tablesOverlap(tbl1, tbl2)
    local longTbl = #tbl1 > #tbl2 and tbl1 or tbl2
    local shortTbl = longTbl == tbl1 and tbl2 or tbl1
    for _, v1 in ipairs(longTbl) do -- This is probably the best way to do this
        for _, v2 in ipairs(shortTbl) do
            if v1 == v2 then
                return true
            end
        end
    end
    return false
end

local requestData = {
    Url = API_URL,
    Method = "GET",   
}

local function generateAPI()
    local jsonSuccess, apiJson
    if TESTING_LOCALLY then
        jsonSuccess, apiJson = pcall(HttpService.JSONDecode, HttpService, require(game.ServerScriptService.api))
    else
        local requestSuccess, requestResponse = pcall(HttpService.RequestAsync, HttpService, requestData)
        if not requestSuccess then -- HttpService not on
            pluginWarn("HttpService.HttpEnabled is not true. HttpService is required briefly upon loading the serializer to get the Roblox API.")
            pluginWarn("Please enable HttpEnabled and retry.")
            return false
        end
        if not requestResponse.Success then
            pluginWarn("RequestAsync failed to get the API dump (status: %i %s)", requestResponse.StatusCode, requestResponse.StatusMessage)
            pluginWarn("Please retry. If this persists, contact Dekkonot.")
            return false
        end
        jsonSuccess, apiJson = pcall(HttpService.JSONDecode, HttpService, requestResponse.Body)
    end
    if not jsonSuccess then
        pluginWarn("API dump failed to decode. Please retry. If this persists, contact Dekkonot.")
        return false
    end

    local classMap = {}
    local inheritanceMap = {}
    local classCache = {
        normal = {},
        plugin = {},
    }

    for _, classApi in ipairs(apiJson.Classes) do
        if not classApi.Tags or not tablesOverlap(INSTANCE_RESTRICTED_TAGS, classApi.Tags) then
            -- Boy I really wish I had `continue` right now :/
            local forbiddenTable = FORBIDDEN_PROPERTIES[classApi.Name]
            local classTable = {
                ["$superclass"] = classApi.Superclass,
                ["$service"] = not not (classApi.Tags and table.find(classApi.Tags, "Service")),
            }
            for _, memberTable in ipairs(classApi.Members) do
                if memberTable.MemberType == "Property" then
                    if not forbiddenTable or not forbiddenTable[memberTable.Name] then
                        if not memberTable.Tags or not tablesOverlap(PROPERTY_RESTRICTED_TAGS, memberTable.Tags) then
                            if not (SECURITY_RESTRICTED_TAGS[memberTable.Security.Write] or SECURITY_RESTRICTED_TAGS[memberTable.Security.Read]) then
                                classTable[memberTable.Name] = memberTable.Security.Write ~= "None" or memberTable.Security.Read ~= "None"
                            end
                        end
                    end
                end
            end
            for name in pairs(classTable) do
                if string.find(name, "Color$") and classTable[name.."3"] ~= nil then -- Kill BrickColor properties
                    classTable[name] = nil
                elseif name:find("^%l") then
                    if classTable[name:sub(1, 1):upper()..name:sub(2)] ~= nil then
                        classTable[name] = nil
                    end
                end 
            end
            classMap[classApi.Name] = classTable
        end
    end
    for _, classApi in ipairs(apiJson.Classes) do
        local superRoute = {}
        local root = classApi.Name
		while classMap[root] do
			table.insert(superRoute, 1, root) -- This is because properties may be overwritten by descendant classes (Value objects...)
			root = classMap[root]["$superclass"]
        end
        inheritanceMap[classApi.Name] = superRoute
    end

    local function getProperties(class, pluginContext)
        if pluginContext == nil then
            pluginError("pluginContext must be passed to API.getProperties")
        end
        local cacheTable = classCache[pluginContext and "plugin" or "normal"]
        if cacheTable[class] then
            return cacheTable[class]
        else
            local properties = {}
            if pluginContext then
                for _, superClass in ipairs(inheritanceMap[class]) do
                    for k in pairs(classMap[superClass]) do
                        if k ~= "$service" and k ~= "$superclass" then
                            properties[#properties+1] = k
                        end
                    end
                end
            else
                for _, superClass in ipairs(inheritanceMap[class]) do
                    for k, v in pairs(classMap[superClass]) do
                        if not v then
                            if k ~= "$service" and k ~= "$superclass" then
                                properties[#properties+1] = k
                            end
                        end
                    end
                end
            end
            cacheTable[class] = properties
            return properties
        end
    end

    local function isService(class)
        local map = classMap[class]
        return map["$service"]
    end

    for _, v in ipairs(PRELOAD_CLASSES) do
        getProperties(v, false)
        getProperties(v, true)
    end

    return true, {
        getProperties = getProperties,
        isService = isService,
    }
end

return generateAPI