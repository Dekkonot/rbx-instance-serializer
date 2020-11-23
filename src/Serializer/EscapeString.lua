local ESCAPE_SEQUENCES = {
    [7] = "\\a",
    [8] = "\\b",
    [9] = "\\t",
    [10] = "\\n",
    [11] = "\\v",
    [12] = "\\f",
    [13] = "\\r",
    [92] = "\\\\",
    [34] = "\\\"",
}

--- Escapes a string and returns it. Doesn't wrap the string in quotation marks.
---@param str string
---@return string
local function escapeString(str)
    local chars = {}
    local n = 1
    for _, code in utf8.codes(str) do
        if ESCAPE_SEQUENCES[code] then
            chars[n] = ESCAPE_SEQUENCES[code]
        elseif code >= 255 then
            --Unicode displays just fine in scripts, but many unicode characters don't have glyphs
            --I don't have an easy way to programatically check which ones do and don't, so...
            chars[n] = "\\u{"..string.format("%x", code).."}"
        elseif code <= 31 or code >= 127 then
            chars[n] = "\\"..tostring(code)
        elseif code <= 126 then
            chars[n] = utf8.char(code)
        end
        n = n+1
    end
    return table.concat(chars)
end

return escapeString