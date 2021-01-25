local escapeString = require(script.Parent.EscapeString)

local ROUND_TO_PLACE = 7

---Rounds `n` to `place` digits.
local function round(n)
    local pow = 10 ^ ROUND_TO_PLACE
    return math.floor(n * pow + 0.5) / pow
end

local function toStringVerbose(v)
    local dataType = typeof(v)
    if dataType == "string" then
        return string.format("\"%s\"", escapeString(v))
    elseif dataType == "boolean" or dataType == "nil" then
        return tostring(v)
    elseif dataType == "number" then
        return string.format("%.14g", round(v))
    elseif dataType == "Axes" then
        return string.format(
            "Axes.new(%s%s%s)",
            v.X and "Enum.Axis.X, " or "",
            v.Y and "Enum.Axis.Y, " or "",
            v.Z and "Enum.Axis.Z" or ""
        )
    elseif dataType == "BrickColor" then
        return string.format("BrickColor.new(\"%s\"", v.Name)
    elseif dataType == "CFrame" then
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
        --Ideally we would check a range but I'm feeling lazy and this line is long enough as-is
        if r00 == 1 and r01 == 0 and r02 == 0 and r10 == 0 and r11 == 1 and r12 == 0 and r20 == 0 and r21 == 0 and r22 == 1 then
            return string.format("CFrame.new(%.14g, %.14g, %.14g)", round(x), round(y), round(z))
        else
            return string.format(
                "CFrame.new(%.14g, %.14g, %.14g, %.14g, %.14g, %.14g, %.14g, %.14g, %.14g, %.14g, %.14g, %.14g)",
                round(x), round(y), round(z), round(r00), round(r01), round(r02), round(r10),
                round(r11), round(r12), round(r20), round(r21), round(r22)
            )
        end
    elseif dataType == "Color3" then
        return string.format("Color3.fromRGB(%i, %i, %i)", (v.R * 255) + 0.5, (v.G * 255) + 0.5, (v.B * 255) + 0.5)
    elseif dataType == "ColorSequence" then
        local keypoints = v.Keypoints
        if #keypoints == 2 then
            if keypoints[1].Value == keypoints[2].Value then
                local color = keypoints[1].Value
                return string.format(
                    "ColorSequence.new(Color3.fromRGB(%i, %i, %i))",
                    (color.R * 255) + 0.5, (color.G * 255) + 0.5, (color.B * 255) + 0.5
                )
            else
                local color1, color2 = keypoints[1].Value, keypoints[2].Value
                return string.format(
                    "ColorSequence.new(Color3.fromRGB(%i, %i, %i), Color3.fromRGB(%i, %i, %i))",
                    (color1.R * 255) + 0.5, (color1.G * 255) + 0.5, (color1.B * 255) + 0.5,
                    (color2.R * 255) + 0.5, (color2.G * 255) + 0.5, (color2.B * 255) + 0.5
                )
            end
        else
            local sequences = table.create(#keypoints)
            for i, keypoint in ipairs(keypoints) do
                local color = keypoint.Value
                sequences[i] = string.format(
                    "ColorSequence.new(%.14g, Color3.fromRGB(%i, %i, %i)",
                    keypoint.Time, (color.R * 255) + 0.5, (color.G * 255) + 0.5, (color.B * 255) + 0.5
                )
            end
            return string.format("ColorSequence.new({%s})", table.concat(keypoints, ", "))
        end
    elseif dataType == "EnumItem" then
        return string.format("Enum.%s.%s", tostring(v.EnumType), v.Name) -- Relying on tostring :(
    elseif dataType == "Faces" then
        return string.format(
            "Faces.new(%s%s%s%s%s%s)",
            v.Front and "Enum.NormalId.Front, " or "",
            v.Right and "Enum.NormalId.Right, " or "",
            v.Top and "Enum.NormalId.Top, " or "",
            v.Back and "Enum.NormalId.Back, " or "",
            v.Left and "Enum.NormalId.Left, " or "",
            v.Bottom and "Enum.NormalId.Bottom" or ""
        )
    elseif dataType == "NumberRange" then
        return string.format("NumberRange.new(%.14g, %.14g)", round(v.Min), round(v.Max))
    elseif dataType == "NumberSequence" then
        local keypoints = v.Keypoints
        if #keypoints == 2 then
            if keypoints[1].Value == keypoints[2].Value then
                return string.format("NumberSequence.new(%.14g)", keypoints[1].Value)
            else
                return string.format("NumberSequence.new(%.14g, %.14g)", keypoints[1].Value, keypoints[2].Value)
            end
        else
            local sequences = table.create(#keypoints)
            for i, keypoint in ipairs(keypoints) do
                sequences[i] = string.format(
                    "NumberSequenceKeypoint.new(%.14g, %.14g, %.14g",
                    keypoint.Time, keypoint.Value, keypoint.Envelope
                )
            end
            return string.format("NumberSequence.new({%s})", table.concat(keypoints, ", "))
        end
    elseif dataType == "PhysicalProperties" then
        local fWeight, eWeight = v.FrictionWeight, v.ElasticityWeight
        if fWeight == 1 and eWeight == 1 then
            return string.format(
                "PhysicalProperties.new(%.14g, %.14g, %.14g)",
                round(v.Density), round(v.Friction), round(v.Elasticity)
            )
        else
            return string.format(
                "PhysicalProperties.new(%.14g, %.14g, %.14g, %.14g, %.14g)",
                round(v.Density), round(v.Friction), round(v.Elasticity), round(fWeight), round(eWeight)
            )
        end
    elseif dataType == "Ray" then
        local origin, dir = v.Origin, v.Direction
        return string.format(
            "Ray.new(Vector3.new(%.14g, %.14g, %.14g), Vector3.new(%.14g, %.14g, %.14g))",
            round(origin.X), round(origin.Y), round(origin.Z),
            round(dir.X), round(dir.Y), round(dir.Z)
        )
    elseif dataType == "Rect" then
        return string.format(
            "Rect.new(%.14g, %.14g, %.14g, %.14g)",
            v.Min.X, v.Min.Y, v.Max.X, v.Max.Y
        )
    elseif dataType == "UDim" then
        --Offset doesn't currently support non-integers, but one day Roblox might support subpixels.
        --One day... :-(
        return string.format("UDim.new(%.14g, %.14g)", round(v.Scale), round(v.Offset))
    elseif dataType == "UDim2" then
        return string.format(
            "UDim2.new(%.14g, %.14g, %.14g, %.14g)",
            round(v.X.Scale), round(v.X.Offset), round(v.Y.Scale), round(v.Y.Offset)
        )
    elseif dataType == "Vector2" then
        return string.format("Vector2.new(%.14g, %.14g)", v.X, v.Y)
    elseif dataType == "Vector3" then
        return string.format("Vector3.new(%.14g, %.14g, %.14g)", v.X, v.Y, v.Z)
    else
        error(string.format(
            "unknown datatype '%s' passed to Serializer - contact Dekkonot", dataType
        ), 2)
    end
end

local function toStringMinified(v)
    local dataType = typeof(v)
    if dataType == "string" then
        return string.format("\"%s\"", escapeString(v))
    elseif dataType == "boolean" or dataType == "nil" then
        return tostring(v)
    elseif dataType == "number" then
        return string.format("%.14g", round(v))
    elseif dataType == "Axes" then
        return string.format(
            "Axes.new(%s%s%s)",
            v.X and "Enum.Axis.X," or "",
            v.Y and "Enum.Axis.Y," or "",
            v.Z and "Enum.Axis.Z" or ""
        )
    elseif dataType == "BrickColor" then
        return string.format("BrickColor.new(%i)", v.Number)
    elseif dataType == "CFrame" then
        local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
        --Ideally we would check a range but I'm feeling lazy and this line is long enough as-is
        if r00 == 1 and r01 == 0 and r02 == 0 and r10 == 0 and r11 == 1 and r12 == 0 and r20 == 0 and r21 == 0 and r22 == 1 then
            return string.format("CFrame.new(%.14g,%.14g,%.14g)", round(x), round(y), round(z))
        else
            return string.format(
                "CFrame.new(%.14g,%.14g,%.14g,%.14g,%.14g,%.14g,%.14g,%.14g,%.14g,%.14g,%.14g,%.14g)",
                round(x), round(y), round(z), round(r00), round(r01), round(r02), round(r10),
                round(r11), round(r12), round(r20), round(r21), round(r22)
            )
        end
    elseif dataType == "Color3" then
        return string.format("Color3.fromRGB(%i,%i,%i)", (v.R * 255) + 0.5, (v.G * 255) + 0.5, (v.B * 255) + 0.5)
    elseif dataType == "ColorSequence" then
        local keypoints = v.Keypoints
        if #keypoints == 2 then
            if keypoints[1].Value == keypoints[2].Value then
                local color = keypoints[1].Value
                return string.format(
                    "ColorSequence.new(Color3.fromRGB(%i,%i,%i))",
                    (color.R * 255) + 0.5, (color.G * 255) + 0.5, (color.B * 255) + 0.5
                )
            else
                local color1, color2 = keypoints[1].Value, keypoints[2].Value
                return string.format(
                    "ColorSequence.new(Color3.fromRGB(%i,%i,%i),Color3.fromRGB(%i,%i,%i))",
                    (color1.R * 255) + 0.5, (color1.G * 255) + 0.5, (color1.B * 255) + 0.5,
                    (color2.R * 255) + 0.5, (color2.G * 255) + 0.5, (color2.B * 255) + 0.5
                )
            end
        else
            local sequences = table.create(#keypoints)
            for i, keypoint in ipairs(keypoints) do
                local color = keypoint.Value
                sequences[i] = string.format(
                    "ColorSequence.new(%.14g, Color3.fromRGB(%i,%i,%i)",
                    keypoint.Time, (color.R * 255) + 0.5, (color.G * 255) + 0.5, (color.B * 255) + 0.5
                )
            end
            return string.format("ColorSequence.new({%s})", table.concat(keypoints, ","))
        end
    elseif dataType == "EnumItem" then
        return string.format("%i", v.Value)
    elseif dataType == "Faces" then
        return string.format(
            "Faces.new(%s%s%s%s%s%s)",
            v.Front and "Enum.NormalId.Front," or "",
            v.Right and "Enum.NormalId.Right," or "",
            v.Top and "Enum.NormalId.Top," or "",
            v.Back and "Enum.NormalId.Back," or "",
            v.Left and "Enum.NormalId.Left," or "",
            v.Bottom and "Enum.NormalId.Bottom" or ""
        )
    elseif dataType == "NumberRange" then
        return string.format("NumberRange.new(%.14g,%.14g)", round(v.Min), round(v.Max))
    elseif dataType == "NumberSequence" then
        local keypoints = v.Keypoints
        if #keypoints == 2 then
            if keypoints[1].Value == keypoints[2].Value then
                return string.format("NumberSequence.new(%.14g)", keypoints[1].Value)
            else
                return string.format("NumberSequence.new(%.14g,%.14g)", keypoints[1].Value, keypoints[2].Value)
            end
        else
            local sequences = table.create(#keypoints)
            for i, keypoint in ipairs(keypoints) do
                sequences[i] = string.format(
                    "NumberSequenceKeypoint.new(%.14g,%.14g,%.14g",
                    keypoint.Time, keypoint.Value, keypoint.Envelope
                )
            end
            return string.format("NumberSequence.new({%s})", table.concat(keypoints, ","))
        end
    elseif dataType == "PhysicalProperties" then
        local fWeight, eWeight = v.FrictionWeight, v.ElasticityWeight
        if fWeight == 1 and eWeight == 1 then
            return string.format(
                "PhysicalProperties.new(%.14g,%.14g,%.14g)",
                round(v.Density), round(v.Friction), round(v.Elasticity)
            )
        else
            return string.format(
                "PhysicalProperties.new(%.14g, %.14g,%.14g,%.14g,%.14g)",
                round(v.Density), round(v.Friction), round(v.Elasticity), round(fWeight), round(eWeight)
            )
        end
    elseif dataType == "Ray" then
        local origin, dir = v.Origin, v.Direction
        return string.format(
            "Ray.new(Vector3.new(%.14g,%.14g,%.14g), Vector3.new(%.14g,%.14g,%.14g))",
            round(origin.X), round(origin.Y), round(origin.Z),
            round(dir.X), round(dir.Y), round(dir.Z)
        )
    elseif dataType == "Rect" then
        return string.format(
            "Rect.new(%.14g,%.14g,%.14g,%.14g)",
            v.Min.X, v.Min.Y, v.Max.X, v.Max.Y
        )
    elseif dataType == "UDim" then
        --Offset doesn't currently support non-integers, but one day Roblox might support subpixels.
        --One day... :-(
        return string.format("UDim.new(%.14g,%.14g)", round(v.Scale), round(v.Offset))
    elseif dataType == "UDim2" then
        return string.format(
            "UDim2.new(%.14g,%.14g,%.14g,%.14g)",
            round(v.X.Scale), round(v.X.Offset), round(v.Y.Scale), round(v.Y.Offset)
        )
    elseif dataType == "Vector2" then
        return string.format("Vector2.new(%.14g,%.14g)", v.X, v.Y)
    elseif dataType == "Vector3" then
        return string.format("Vector3.new(%.14g,%.14g,%.14g)", v.X, v.Y, v.Z)
    else
        error(string.format(
            "unknown datatype '%s' passed to Serializer - contact Dekkonot", dataType
        ), 2)
    end
end

return {
    toStringVerbose = toStringVerbose,
    toStringMinified = toStringMinified,
}