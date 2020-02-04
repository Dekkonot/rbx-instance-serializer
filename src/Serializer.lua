local util = require(script.Parent.Util)
local toString = require(script.Parent.ToString)
local getAPI = require(script.Parent.API)

local GetOptions = script.Parent.GetOptions
local SetOptions = script.Parent.SetOptions

local LOCAL_VARIABLE_LIMIT = 255

local INSTANCE_STRING_VERBOSE = "local %s = Instance.new(%q)"
local PROPERTY_STRING_VERBOSE = "%s.%s = %s"
local GETSERVICE_STRING_VERBOSE = "game:GetService(%q)"
local REQUIRE_CHILDREN_STRING_VERBOSE = "\nfor _, v in ipairs(script:GetChildren()) do\n    require(v).Parent = %s\nend\n"
local INSTANCE_STRING = "local %s=Instance.new%q"
local PROPERTY_STRING = "%s.%s=%s"
local GETSERVICE_STRING = "game:GetService%q"
local REQUIRE_CHILDREN_STRING = "\nfor _,v in next,script:GetChildren() do require(v).Parent=%s end\n"

local KEYWORDS = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true, ["elseif"] = true,
    ["end"] = true, ["false"] = true, ["for"] = true, ["function"] = true, ["if"] = true,
    ["in"] = true, ["local"] = true, ["nil"] = true, ["not"] = true, ["or"] = true,
    ["repeat"] = true, ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true, ["while"] = true,
}

local isService, getProperties

local pluginWarn = util.pluginWarn
local makeLuaName = util.makeLuaName
local escapeString = util.escapeString

local default_state_check = {}

local is_plugin_context = true
local make_verbose = true
local parent_highest_ancestor = true
local handle_big_output = true
local make_module = true

local function makeFullName(obj)
    if obj == game then
        return "game"
    elseif obj == workspace then
        return "workspace"
    elseif isService(obj.ClassName) then
        return string.format(make_verbose and GETSERVICE_STRING_VERBOSE or GETSERVICE_STRING, obj.ClassName)
    end
    local fullName = ""
    repeat
        local name = obj.Name
        if obj == game then
            fullName = "game"..fullName
            break -- Technically unnecessary but it's better to be consistent than rely upon it's parent being `nil`
        elseif obj == workspace then
            fullName = "workspace"..fullName
            break
        elseif isService(obj.ClassName) then
            fullName = string.format(make_verbose and GETSERVICE_STRING_VERBOSE or GETSERVICE_STRING, obj.ClassName)..fullName
            break
        elseif name:find("[^%w_]") or obj.Name:find("^%d") then
            fullName = string.format("[%q]", escapeString(name))..fullName
        else
            fullName = "."..name..fullName
        end
        obj = obj.Parent
    until not obj
    return fullName
end

local function makeNameList(obj, descendants)
    local fenv = getfenv()
    local objects = table.create(#descendants+1)
    objects[1] = obj
    for i, v in ipairs(descendants) do
        objects[i+1] = v
    end
    local objToNameMap = {}
    if make_verbose then -- This isn't a great solution to the problem, but it isn't that slow so I think it's fine
        local nameList = {}
        for _, v in ipairs(objects) do
            local name = string.gsub(string.gsub(v.Name, "[^%w_]", ""), "^[%d_]+", "")
            name = name == "" and v.ClassName or name
            if nameList[name] then
                for i = 1, math.huge do
                    local newName = name..tostring(i)
                    if not nameList[newName] then
                        nameList[newName] = true
                        if KEYWORDS[newName] or fenv[newName] then
                            newName = newName.."_"
                        end
                        name = newName
                        break
                    end
                end
            else
                nameList[name] = true
                if KEYWORDS[name] or fenv[name] then
                    name = name.."_"
                end
            end
            objToNameMap[v] = name
        end
    else
        for i, v in ipairs(objects) do
            local name = makeLuaName(i)
            if KEYWORDS[name] or fenv[name] then
                name = name.."_"
            end
            objToNameMap[v] = name
        end
    end
    return objToNameMap
end

local function getProperty(obj, property)
    return obj[property]
end

local function serializeObject(nameList, obj)
    local className = obj.ClassName
    if isService(className) then
        pluginWarn("cannot serialize services")
        return false
    end

    local defaultState = default_state_check[className]
    if not defaultState then
        local success, newThing = pcall(Instance.new, className)
        if not success then
            pluginWarn("class %s cannot be created", className)
            return false
        end
        default_state_check[className] = newThing
        defaultState = newThing
    end

    local objName = nameList[obj]
    local toStringFunc, instanceString, propertyString
    if make_verbose then
        toStringFunc = toString.toStringVerbose
        instanceString = INSTANCE_STRING_VERBOSE
        propertyString = PROPERTY_STRING_VERBOSE
    else
        toStringFunc = toString.toString
        instanceString = INSTANCE_STRING
        propertyString = PROPERTY_STRING
    end

    local instString = string.format(instanceString, objName, className)
    local statements = {instString}
    local refs = {}
    local len = #instString
    local c = 2
    for _, name in ipairs(getProperties(className, is_plugin_context)) do
        if name ~= "Parent" then
            local success, value = pcall(getProperty, obj, name)
            if success then
                if defaultState[name] ~= value then
                    if typeof(value) == "Instance" then
                        refs[#refs+1] = {name, value}
                    else
                        local stat = string.format(propertyString, objName, name, toStringFunc(value))
                        statements[c] = stat
                        len = len+#stat
                        c = c+1
                    end
                end
            else
                pluginWarn("cannot serialize property '%s' of %s", name, obj:GetFullName())
            end
        end
    end
    
    return len, statements, refs
end

local function serialize(obj)
    local canIndex = pcall(getProperty, obj, "Name")
    if not canIndex then
        pluginWarn("cannot serialize object due to context restrictions")
        return false
    end

    local propertyString = make_verbose and PROPERTY_STRING_VERBOSE or PROPERTY_STRING
    
    local actualDescendants = {}
    local descendants = obj:GetDescendants()
    local parentStats = table.create(#descendants)
    local statLists = table.create(#descendants)
    local refLists = table.create(#descendants)
    local lenList = table.create(#descendants)

    local nameList = makeNameList(obj, descendants)
    local objName = nameList[obj]

    local topStatLen, topStats, topRefs = serializeObject(nameList, obj)
    if not topStatLen then
        return false
    end

    local totalLen = topStatLen
    -- check if can index; if not, warn and move on
    -- for each descendant:
        -- serialize
        -- make parent stat
        -- add statList to statLists, add parentStats to parentStats, add total len to lenList
    -- combine, splitting if neccessary (and split_if_too_big is true)
    -- add ancestor parent stat (if parent_highest_ancestor is true)

    local descC = 1
    for i, v in ipairs(descendants) do
        local canIndexDesc = pcall(getProperty, v, "Name")
        -- We can actually guarantee that no ancestor of this instance is locked by doing this
        -- Because RobloxLocked is recursive!
        if not canIndexDesc then
            pluginWarn("cannot index descendant #%u due to context restrictions", i)
        else
            local len, statList, refs = serializeObject(nameList, v)
            if len then
                local parentName = nameList[v.Parent] -- Every descendant's parent will have a name
                actualDescendants[descC] = v
                statLists[descC] = statList
                parentStats[descC] = string.format(propertyString, nameList[v], "Parent", parentName)
                refLists[descC] = refs
                lenList[descC] = len+(#statList-1)
                totalLen = totalLen+len+(#statList-1) -- To account for the newlines
                descC = descC+1
            end
        end
    end

    
    local topParent = ""
    if parent_highest_ancestor then
        topParent = makeFullName(obj.Parent)
    end

    if #actualDescendants+1 > LOCAL_VARIABLE_LIMIT or totalLen > 199999 then
        if handle_big_output then
            local childString = make_verbose and REQUIRE_CHILDREN_STRING_VERBOSE or REQUIRE_CHILDREN_STRING
            local childStringLen = #childString
            
            
            local mainStatList = {}
            local containerMap = {}

            if topStatLen+childStringLen+#objName+9 > 199999 then -- This might read 199,998 characters as 199,999 but that's ok
                pluginWarn("serialized string is too large or has too many descendants to write to output script")
                return false
            end

            local objContainer = Instance.new("ModuleScript")
            containerMap[obj] = objContainer
            
            objContainer.Name = objName
            objContainer.Source = table.concat(topStats, "\n")..string.format(childString, objName).."\nreturn "..objName

            for i, v in ipairs(actualDescendants) do
                local name = nameList[v]

                if lenList[i]+childStringLen+#name+9 > 199999 then
                    pluginWarn("serialized string is too large or has too many descendants to write to output script")
                    return false
                end

                local container = Instance.new("ModuleScript")
                containerMap[v] = container
                
                container.Parent = containerMap[v.Parent]
                container.Name = name
                container.Source = table.concat(statLists[i], "\n")..string.format(childString, name).."\nreturn "..name
            end
            
            local statC = 1

            if #topRefs ~= 0 then
                mainStatList[statC] = objName.." = require(script."..objContainer:GetFullName()..")"
                for l, k in ipairs(topRefs) do
                    local propName, propValue = k[1], k[2]
                    local valueStat = ""
                    if propValue == obj then
                        valueStat = objName
                    elseif obj:IsAncestorOf(propValue) or propValue == obj then
                        valueStat = "require(script."..containerMap[propValue]:GetFullName()..")"
                    else
                        valueStat = makeFullName(propValue)
                    end
                    mainStatList[statC+l] = objName.."."..propName.." = "..valueStat
                end
                statC = statC+#topRefs+1
            end

            for i, v in ipairs(actualDescendants) do -- We want to make sure all of the containers exist first
                local name = nameList[v]
                local container = containerMap[v]
                local refs = refLists[i]
                if #refs ~= 0 then
                    mainStatList[statC] = name.." = require(script."..container:GetFullName()..")"
                    for l, k in ipairs(refs) do
                        local propName, propValue = k[1], k[2]
                        local valueStat = ""
                        if propValue == v then
                            valueStat = name
                        elseif obj:IsAncestorOf(propValue) or propValue == obj then
                            valueStat = "require(script."..containerMap[propValue]:GetFullName()..")"
                        else
                            valueStat = makeFullName(propValue)
                        end
                        mainStatList[statC+l] = name.."."..propName.." = "..valueStat
                    end
                    statC = statC+#refs+1
                end
            end

            
            mainStatList[statC] = "return require(script."..objName..")"
            
            local mainStatLen = #mainStatList-1
            for _, v in ipairs(mainStatList) do
                mainStatLen = mainStatLen+#v
            end
            if mainStatLen > 199999 then
                pluginWarn("serialized string is too large or has too many descendants to write to output script")
                return false
            end
            
            if make_module then
                local mainContainer = Instance.new("ModuleScript")
                mainContainer.Name = "SerializerOutput"
                mainContainer.Source = table.concat(mainStatList, "\n")
                objContainer.Parent = mainContainer
                return true, mainContainer
            else                
                local mainContainer = Instance.new("Script")
                mainContainer.Disabled = true
                mainContainer.Name = "SerializerOutput"
                mainContainer.Source = table.concat(mainStatList, "\n")
                return true, mainContainer
            end
        else
            pluginWarn("serialized string is too large or has too many descendants to write to output script")
            return false
        end
    else
        local src = table.concat(topStats, "\n")
        if make_verbose then
            src = src.."\n"
            for i, v in ipairs(statLists) do
                local thing = actualDescendants[i]
                local parent = thing.Parent
                local name = nameList[thing]
                src = src.."\n"
                src = src..table.concat(v, "\n")
                src = src.."\n"..string.format(propertyString, name, "Parent", nameList[parent]).."\n"
            end
            src = src.."\n"

            for i, v in ipairs(refLists) do
                local name = nameList[actualDescendants[i]]
                for _, k in ipairs(v) do
                    local propName, propValue = k[1], k[2]
                    src = src..string.format(propertyString, name, propName, nameList[propValue] or makeFullName(propValue)).."\n"
                end
                if #v ~= 0 then
                    src = src.."\n"
                end
            end

            for _, v in ipairs(topRefs) do
                local propName, propValue = v[1], v[2]
                src = src..string.format(propertyString, objName, propName, nameList[propValue] or makeFullName(propValue)).."\n"
            end

            if parent_highest_ancestor then
                src = src..string.format(propertyString, objName, "Parent", topParent)
            end

            if make_module then
                src = src.."\nreturn "..objName
            end
        else
            for i, v in ipairs(statLists) do
                local thing = actualDescendants[i]
                local parent = thing.Parent
                local name = nameList[thing]
                src = src.."\n"
                src = src..table.concat(v, "\n")
                src = src.."\n"..string.format(propertyString, name, "Parent", nameList[parent])
            end
            src = src.."\n"

            for i, v in ipairs(refLists) do
                local name = nameList[actualDescendants[i]]
                for _, k in ipairs(v) do
                    local propName, propValue = k[1], k[2]
                    src = src..string.format(propertyString, name, propName, nameList[propValue] or makeFullName(propValue)).."\n"
                end
            end

            for _, v in ipairs(topRefs) do
                local propName, propValue = v[1], v[2]
                src = src..string.format(propertyString, objName, propName, nameList[propValue] or makeFullName(propValue)).."\n"
            end

            if parent_highest_ancestor then
                src = src..string.format(propertyString, objName, "Parent", topParent)
            end

            if make_module then
                src = src.."\nreturn "..objName
            end
        end

        if #src > 199999 then
            pluginWarn("serialized string is too large or has too many descendants to write to output script")
            return false
        end

        if make_module then
            local container = Instance.new("ModuleScript")
            container.Name = "SerializerOutput"
            container.Source = src
            return true, container
        else
            local container = Instance.new("Script")
            container.Disabled = true
            container.Name = "SerializerOutput"
            container.Source = src
            return true, container
        end
    end
end

local function setOptions(optionTable)
    if optionTable.verbose ~= nil then
        make_verbose = optionTable.verbose
    end
    if optionTable.module ~= nil then
        make_module = optionTable.module
    end
    if optionTable.parent ~= nil then
        parent_highest_ancestor = optionTable.parent
    end
    if optionTable.context ~= nil then
        is_plugin_context = optionTable.context
    end
end

local function getOptions()
    return {
        verbose = make_verbose,
        module = make_module,
        parent = parent_highest_ancestor,
        context = is_plugin_context
    }
end

local function init()
    local success, API = getAPI()
    if not success then
        return false
    else
        isService = API.isService
        getProperties = API.getProperties
        return true
    end
end

SetOptions.Event:Connect(setOptions)
GetOptions.OnInvoke = getOptions

return {
    serialize = serialize,
    init = init
}