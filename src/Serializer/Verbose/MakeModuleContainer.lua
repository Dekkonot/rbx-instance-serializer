local Constants = require(script.Parent.Parent.Constants)

local MAX_SOURCE_LEN = Constants.MAX_SOURCE_LEN

local COLLECTION_SERVICE_STRING = Constants.Verbose.COLLECTION_SERVICE_STRING
local REQUIRE_CHILDREN_STRING = Constants.Verbose.REQUIRE_CHILDREN_STRING

local function warnf(fmt, ...)
    warn(string.format("[Instance Serializer] %s", string.format(fmt, ...)))
end

local function makeModuleContainer(name, serialized)
    local requireString = string.format(REQUIRE_CHILDREN_STRING, name)

    if serialized.length + #requireString + 6 > MAX_SOURCE_LEN then
        warnf("could not serialize object because the resulting string was too long")
        return false
    end

    local container = Instance.new("ModuleScript")
    container.Name = name

    local create = serialized.create
    local tags = serialized.tags
    local attributes = serialized.attributes
    local properties = serialized.properties

    -- I thought about better solutions but since `table.insert` is slow,
    -- they all suck.
    local source = { -- FIXME this is a bad solution
        COLLECTION_SERVICE_STRING
    }
    local i
    if #tags ~= 0 then
        source[2] = create
        i = 3
    else
        source[1] = create
        i = 2
    end
    if #properties ~= 0 then
        source[i] = table.concat(properties, "\n")
    end
    -- We aren't concating with a newline in tags and attributes since they're
    -- newlined in the constants table.
    -- (this saves us some processing in the normal serializer) 
    if #tags ~= 0 then
        i += 1
        source[i] = table.concat(tags)
    end
    if #attributes ~= 0 then
        i += 1
        source[i] = table.concat(attributes)
    end

    source[i + 1] = requireString

    container.Source = table.concat(source, "\n")

    return true, container
end

return makeModuleContainer