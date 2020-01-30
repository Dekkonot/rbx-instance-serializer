local Util = {}

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

local NAME_CHARACTERS = { [0] =
	"Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l",
	"m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y",
	"z", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L",
	"M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y",
}

function Util.pluginWarn(str, ...)
    warn("[Instance Serializer] "..string.format(str, ...))
    return true
end

function Util.pluginError(str, ...)
    error("[Instance Serializer] "..string.format(str, ...), 3)
    return true
end

function Util.lookupify(tbl)
    for i, v in ipairs(tbl) do
        tbl[i] = nil
        tbl[v] = true
    end
    return tbl
end

function Util.escapeString(str)
    local chars = {}
    local n = 1
    for _, code in utf8.codes(str) do
        if ESCAPE_SEQUENCES[code] then
            chars[n] = ESCAPE_SEQUENCES[code]
        elseif code >= 255 then
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

function Util.makeLuaName(num)
    -- Omits tokens such that 1-26 = a-z, 27-52 = A-Z, 53 = aa, 54 = ba, and so on.
    -- Yes, I would like it to be `ab` too. No, I'm not going to bother fixing it since it doesn't matter.
    local finishedName = ""
    repeat
        finishedName = finishedName..NAME_CHARACTERS[num%52]
        num = math.floor(num/52)
    until num <= 0
	return finishedName
end

return Util