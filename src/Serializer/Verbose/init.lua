local Constants = require(script.Parent.Constants, "Serializer.Constants")
local MakeNameList = require(script.Parent.MakeNameList, "Serializer.MakeNameList")
local Options = require(script.Parent.Parent.Options, "Options")

local LOCAL_VARIABLE_LIMIT = Constants.LOCAL_VARIABLE_LIMIT
local MAX_SOURCE_LEN = Constants.MAX_SOURCE_LEN

local COLLECTION_SERVICE_STRING = Constants.Verbose.COLLECTION_SERVICE_STRING
local MAKE_INSTANCE_STRING = Constants.Verbose.MAKE_INSTANCE_STRING
local SET_PROPERTY_STRING = Constants.Verbose.SET_PROPERTY_STRING

local makeModuleContainer = require(script.MakeModuleContainer, "Serializer.Verbose.MakeModuleContainer")
local serializeNode = require(script.SerializeNode, "Serializer.Verbose.SerializeNode")
local serializeReferents = require(script.SerializeReferents, "Serializer.Verbose.SerializeReferents")

local makeFullName = MakeNameList.makeFullNameVerbose
local makeNameList = MakeNameList.makeNameListVerbose

local function warnf(fmt, ...)
    warn(string.format("[Instance Serializer] %s", string.format(fmt, ...)))
end

local function getProperty(obj, property)
    return obj[property]
end

local function serialize(root: Instance)
    if not pcall(getProperty, root, "ClassName") then
        warnf("cannot serialize object due to context restrictions")
        return false
    end

    local descendants = root:GetDescendants()
    local serializedDescendants = table.create(#descendants)
    local descendantOutputs = table.create(#descendants)
    local parentStatements = table.create(#descendants)

    local nameList = makeNameList(root, descendants)
    local rootName = nameList[root]

    local serializedRoot, rootOutput = serializeNode(root, nameList)

    if not serializedRoot then
        return false
    end

    local refCount = #rootOutput.referents
    local totalLen = rootOutput.length
    local usesTags = #rootOutput.tags ~= 0

    -- Populate the various descendant tables above
    do
        -- There may be holes in `descendantOutputs` and `parentStatements`
        -- due to `continue`, so to avoid them, we keep our own counter.
        local i = 1
        for _, descendant in ipairs(descendants) do
            if not pcall(getProperty, descendant, "ClassName") then
                warnf("cannot serialize descendant #%u due to context restrictions", i)
                continue
            end

            local serialized, output = serializeNode(descendant, nameList)

            if not serialized then continue end

            totalLen += output.length
            refCount += #output.referents

            descendantOutputs[i] = output
            parentStatements[i] = string.format(
                SET_PROPERTY_STRING,
                nameList[descendant],
                "Parent",
                nameList[descendant.Parent]
            )
            serializedDescendants[i] = descendant

            if #output.tags ~= 0 then
                usesTags = true
            end

            i += 1
        end
    end

    -- If it's too big for one script or if has too many descendants,
    -- put it in series of modules
    if #descendants + 1 > LOCAL_VARIABLE_LIMIT or totalLen > MAX_SOURCE_LEN then
        local containerMap = {}
        local rootContainer
        do
            local madeContainer, container = makeModuleContainer(rootName, rootOutput)
            if not madeContainer then return false end
            
            rootContainer = container
            containerMap[root] = container
        end

        for i, descendant in ipairs(serializedDescendants) do
            local name = nameList[descendant]
            local output = descendantOutputs[i]
            local madeContainer, container = makeModuleContainer(name, output)
            if not madeContainer then return false end

            -- descendants's parent will always be in the map since
            -- GetDescendants is in order of traversal and we're using ipairs
            container.Parent = containerMap[descendant.Parent]

            containerMap[descendant] = container
        end

        local outputStatements = {}
        -- Serialize referents and put them into `outputStatements`.
        do
            local statIndex = 1
            local scopedNodes = {}

            if #rootOutput.referents ~= 0 then
                local refStatements = serializeReferents(
                    scopedNodes, containerMap, nameList, rootOutput.referents, root
                )
                outputStatements[1] = table.concat(refStatements, "\n")
                outputStatements[2] = "\n"
                statIndex = 3
            end

            for l, descendant in ipairs(serializedDescendants) do
                local output = descendantOutputs[l]

                if #output.referents ~= 0 then
                    local refStatements = serializeReferents(
                        scopedNodes, containerMap, nameList, output.referents, descendant
                    )
                    outputStatements[statIndex] = table.concat(refStatements, "\n")
                    outputStatements[statIndex + 1] = "\n"
                    statIndex += 2
                end
            end
        end

        if Options.parent then
            outputStatements[#outputStatements + 1] = string.format(
                SET_PROPERTY_STRING, string.format("require(script.%s)", rootName), "Parent", makeFullName(root.Parent)
            )
        end

        local outputContainer
        if Options.module then
            outputStatements[#outputStatements + 1] = string.format("\nreturn require(script.%s)", rootName)

            outputContainer = Instance.new("ModuleScript")
        else
            outputContainer = Instance.new("Script")
            outputContainer.Disabled = true
        end

        do
            local outputLen = 0
            for _, v in ipairs(outputStatements) do
                outputLen += #v
            end
            if outputLen > MAX_SOURCE_LEN then
                warnf("could not serialize object because the resulting string was too long")
                return false
            end
        end

        outputContainer.Source = table.concat(outputStatements)
        outputContainer.Name = "SerializedInstance"

        rootContainer.Parent = outputContainer

        return true, outputContainer
    end

    local referentStatements = table.create(refCount)
    local refIndex = 0
    --[[
      6 times:
        Instance.new statement,
        properties,
        parent
        tags,
        attributes
        newline after each one
      + 7:
        CollectionService line
        newline after CollectionService
        referents
        newline after referents
        parent for root
        newline after parent
        `return` for module
    ]]
    local source = table.create(((#serializedDescendants + 1) * 6) + 7)
    local sourceIndex = 1
    if usesTags then
        source[1] = COLLECTION_SERVICE_STRING
        source[2] = "" -- HACK: The final concat appends a newline to this so we leave it empty
        sourceIndex = 3
    end

    source[sourceIndex] = string.format(MAKE_INSTANCE_STRING, rootName, root.ClassName)
    sourceIndex += 1
    if #rootOutput.properties ~= 0 then
        source[sourceIndex] = table.concat(rootOutput.properties, "\n")
        sourceIndex += 1
    end
    if #rootOutput.tags ~= 0 then
        source[sourceIndex] = table.concat(rootOutput.tags, "\n")
        sourceIndex += 1
    end
    if #rootOutput.attributes ~= 0 then
        source[sourceIndex] = table.concat(rootOutput.attributes, "\n")
        sourceIndex += 1
    end
    source[sourceIndex] = ""
    sourceIndex += 1

    for i, ref in ipairs(rootOutput.referents) do
        local propValue = ref[2]
        local serialized = nameList[propValue] or makeFullName(propValue)
        referentStatements[refIndex + i] = string.format(SET_PROPERTY_STRING, rootName, ref[1], serialized)
    end
    refIndex += #rootOutput.referents

    for i, v in ipairs(serializedDescendants) do
        local name = nameList[v]
        local output = descendantOutputs[i]
        local parent = parentStatements[i]
        local properties, tags, attributes = output.properties, output.tags, output.attributes
        local referents = output.referents

        source[sourceIndex] = string.format(MAKE_INSTANCE_STRING, nameList[v], v.ClassName)
        sourceIndex += 1
        if #properties ~= 0 then
            source[sourceIndex] = table.concat(properties, "\n")
            source[sourceIndex + 1] = parent 
            sourceIndex += 2
        else
            source[sourceIndex] = parent
            sourceIndex += 1
        end
        if #tags ~= 0 then
            source[sourceIndex] = table.concat(tags, "\n")
            sourceIndex += 1
        end
        if #attributes ~= 0 then
            source[sourceIndex] = table.concat(output.attributes, "\n")
            sourceIndex += 1
        end
        source[sourceIndex] = ""
        sourceIndex += 1

        for l, ref in ipairs(referents) do
            local propValue = ref[2]
            local serialized = nameList[propValue] or makeFullName(propValue)
            referentStatements[refIndex + l] = string.format(SET_PROPERTY_STRING, name, ref[1], serialized)
        end
        refIndex += #referents
    end

    if refCount ~= 0 then
        source[sourceIndex] = table.concat(referentStatements, "\n")
        source[sourceIndex + 1] = ""
        sourceIndex += 2
    end

    if Options.parent then
        source[sourceIndex] = string.format(SET_PROPERTY_STRING, rootName, "Parent", makeFullName(root.Parent))
        source[sourceIndex + 1] = ""
        sourceIndex += 2
    end

    local outputContainer
    if Options.module then
        source[sourceIndex] = string.format("return %s", rootName)

        outputContainer = Instance.new("ModuleScript")
    else

        outputContainer = Instance.new("Script")
        outputContainer.Disabled = true
    end

    do
        local sourceLen = 0
        for _, v in ipairs(source) do
            sourceLen += #v + 1 -- +1 for the newlines
        end
        -- -1 since the last entry doesn't get a newline
        if (sourceLen - 1) > MAX_SOURCE_LEN then
            -- This could happen easily, especially in large models, but
            -- hopefully it won't come up too often, especially since I'm not
            -- really sure how to fix it beyond splitting the module stuff
            -- into its own function, which makes us do this work twice.
            warnf("could not serialize object because the resulting string was too long")
            return false
        end
    end

    outputContainer.Name = "SerializedInstance"
    outputContainer.Source = table.concat(source, "\n")

    return true, outputContainer
end

return serialize