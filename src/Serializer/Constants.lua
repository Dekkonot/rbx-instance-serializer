return {
    LOCAL_VARIABLE_LIMIT = 200,
    MAX_SOURCE_LEN = 199_999,
    
    Verbose = {
        COLLECTION_SERVICE_STRING = "local CollectionService = game:GetService(\"CollectionService\")",
        MAKE_INSTANCE_STRING = "local %s = Instance.new(\"%s\")",
    
        SET_PROPERTY_STRING = "%s.%s = %s",
        SET_ATTRIBUTE_STRING = "%s:SetAttribute(\"%s\", %s)",
        SET_TAG_STRING = "CollectionService:AddTag(%s, \"%s\")",
    
        REQUIRE_OBJECT_STRING = "%s = require(%s)",
        REQUIRE_CHILDREN_STRING = "for _, v in ipairs(script:GetChildren()) do\n\trequire(v).Parent = %s\nend",
    },

    Minified = {
        COLLECTION_SERVICE_STRING = "local _c=game:GetService\"CollectionService\"",
        MAKE_INSTANCE_STRING = "local %s=Instance.new\"%s\"",
    
        SET_PROPERTY_STRING = "%s.%s=%s",
        SET_ATTRIBUTE_STRING = "%s:SetAttribute(\"%s\",%s)",
        SET_TAG_STRING = "_c:AddTag(%s,\"%s\")",
    
        REQUIRE_OBJECT_STRING = "%s=require(%s)",
        REQUIRE_CHILDREN_STRING = "for _,v in ipairs(script:GetChildren())do require(v).Parent=%s end",
    }
}