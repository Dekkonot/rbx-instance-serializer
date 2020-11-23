local ARE_WE_ATTRIBUTES_YET = pcall(game.GetAttributes, game)

local CollectionService = game:GetService("CollectionService")

local Api = require(script.Parent.Parent.Parent.Modules.API, "Modules.API")
local Constants = require(script.Parent.Parent.Constants, "Serializer.Constants")
local GetProperties = require(script.Parent.Parent.GetProperties, "Serializer.GetProperties")
local Options = require(script.Parent.Parent.Parent.Options, "Options")
local ToString = require(script.Parent.Parent.ToString, "Serializer.ToString")

local MAKE_INSTANCE_STRING = Constants.Minified.MAKE_INSTANCE_STRING
local SET_ATTRIBUTE_STRING = Constants.Minified.SET_ATTRIBUTE_STRING
local SET_PROPERTY_STRING = Constants.Minified.SET_PROPERTY_STRING
local SET_TAG_STRING = Constants.Minified.SET_TAG_STRING

local escapeString = require(script.Parent.Parent.EscapeString, "Serializer.EscapeString")
local isService = Api.isService
local toString = ToString.toStringMinified

local defaultStateCache = {}

local function warnf(fmt, ...)
    warn(string.format("[Instance Serializer] %s", string.format(fmt, ...)))
end

local function getProperty(obj, property)
    return obj[property]
end

local function serializeAttributes(object, nameList)
    if not ARE_WE_ATTRIBUTES_YET then
        -- :(
        return {}, 0
    end
    local attributes = object:GetAttributes()
    if next(attributes) == nil then
        return {}, 0
    end
    local objectName = nameList[object]

    local statements = {}
    local outLength = 0
    local statIndex = 1

    for name, value in pairs(attributes) do
        local stringified, valueString = pcall(toString, value)
        if not stringified then
            warnf("cannot serialize attribute %s of %s", name, object:GetFullName())
            continue
        end
        local statement = string.format(SET_ATTRIBUTE_STRING, objectName, escapeString(name), valueString)
        statements[statIndex] = statement
        statIndex += 1
        outLength += #statement
    end

    outLength += #statements - 1 -- For newlines

    return statements, outLength
end

local function serializeTags(object, nameList)
    local tags = CollectionService:GetTags(object)
    if #tags == 0 then
        return {}, 0
    end
    local objectName = nameList[object]

    local statements = {}
    local outLength = 0
    for i, tag in ipairs(tags) do
        local statement = string.format(SET_TAG_STRING, objectName, escapeString(tag))
        statements[i] = statement
        outLength += #statement
    end

    outLength += #statements - 1 -- For newlines

    return statements, outLength
end

--- Serializes the given `object`, pulling its name from `nameList`.
local function serializeNode(object: Instance, nameList: {[Instance]: string})
    local className = object.ClassName
    if isService(className) then
        warnf("cannot serialzie services")
        return false
    end

    local defaultState = defaultStateCache[className]
    if not defaultState then
        local madeObject, newObject = pcall(Instance.new, className)
        if not madeObject then
            warnf("class %s cannot be created", className)
            return false
        end
        defaultStateCache[className] = newObject
        defaultState = newObject
    end

    local getProperties = Options.context and GetProperties.getPluginProperties or GetProperties.getNormalProperties

    local objectName = nameList[object]
    
    local createStatement = string.format(MAKE_INSTANCE_STRING, objectName, className)
    local tags, tagOutLen = serializeTags(object, nameList)
    local attributes, attributeOutLen = serializeAttributes(object, nameList)
    local statements = {}
    local referents = {}

    local outLength = #createStatement + tagOutLen + attributeOutLen
    local statIndex, refIndex = 1, 1

    for propName in pairs(getProperties(className)) do
        if propName == "Parent" then continue end
        local gotValue, value = pcall(getProperty, object, propName)
        if not gotValue then
            warnf("cannot serialize property %s of %s", propName, object:GetFullName())
            continue
        end
        if defaultState[propName] == value then continue end
        if typeof(value) == "Instance" then
            referents[refIndex] = {propName, value}
            refIndex += 1
        else
            local stringified, valueString = pcall(toString, value)
            if not stringified then
                warnf("cannot serialize property %s of %s", propName, object:GetFullName())
                continue
            end
            local statement = string.format(SET_PROPERTY_STRING, objectName, propName, valueString)
            statements[statIndex] = statement
            statIndex += 1
            outLength += #statement
        end
    end

    outLength += #statements - 1 -- For newlines

    return true, {
        create = createStatement,
        tags = tags,
        attributes = attributes,
        properties = statements,
        referents = referents,
        length = outLength,
    }
end

return serializeNode