local util = require(script.Parent.Util)

local pluginError = util.pluginError
local escapeString = util.escapeString

local powers_of_10 = {}
for i = 0, 10 do
	powers_of_10[i] = 10 ^ i
end

local function round(n, prec)
	local pow = powers_of_10[prec]
	return math.floor(n * pow + 0.5) / pow
end

local function genEnumList(data, enum, concatSep)
	local on = {}
	for _, item in ipairs(enum:GetEnumItems()) do
		if data[item] then
			on[#on + 1] = string.format("Enum.%s.%s", tostring(enum), item.Name)
		end
	end
	return table.concat(on, concatSep)
end

-- Now I know what you're thinking... Why not just use `tostring` for this function where I can?
-- While I don't expect Roblox to change any of the results for `tostring`, they could without announcement.
-- Casting them to strings isn't explicitly defined anywhere, so I'm not relying upon it.

local function toString(...)
	local results = table.create(select("#", ...))
	local data = { ... }
	for i, v in ipairs(data) do
		local dataType = typeof(v)
		if dataType == "string" then
			results[i] = '"' .. escapeString(v) .. '"' -- In a twist of fate, tostring(string) does something!
		elseif dataType == "boolean" or dataType == "nil" then
			results[i] = tostring(v)
		elseif dataType == "number" then
			results[i] = tostring(round(v, 7))
		elseif dataType == "Axes" then
			results[i] = string.format(
				"Axes.new(%s)",
				genEnumList(v, Enum.Axis, ",")
			)
		elseif dataType == "BrickColor" then
			results[i] = string.format("BrickColor.new(%q)", v.Name)
		elseif dataType == "CFrame" then
			--stylua: ignore start
			-- This is kind of a nightmare if it's formatted so let's not
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
            if r00 == 1 and r01 == 0 and r02 == 0 and r10 == 0 and r11 == 1 and r12 == 0 and r20 == 0 and r21 == 0 and r22 == 1 then
                results[i] = string.format("CFrame.new(%s,%s,%s)", tostring(x), tostring(y), tostring(z))
            else
                results[i] = string.format("CFrame.new(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)",
                    tostring(x), tostring(y), tostring(z), tostring(r00), tostring(r01), tostring(r02),
                    tostring(r10), tostring(r11), tostring(r12), tostring(r20), tostring(r21), tostring(r22)
                )
            end
		elseif dataType == "Color3" then
			results[i] = string.format(
				"Color3.fromRGB(%u,%u,%u)",
				(v.R * 255) + 0.5,
				(v.G * 255) + 0.5,
				(v.B * 255) + 0.5
			)
		elseif dataType == "ColorSequence" then
			local keypoints = v.Keypoints
			if #keypoints == 2 and keypoints[1].Value == keypoints[2].Value then
				local c = keypoints[1].Value
				results[i] = string.format(
					"ColorSequence.new(Color3.fromRGB(%u,%u,%u))",
					(c.R * 255) + 0.5,
					(c.G * 255) + 0.5,
					(c.B * 255) + 0.5
				)
			elseif #keypoints == 2 then
				local c1 = keypoints[1].Value
				local c2 = keypoints[2].Value
				results[i] = string.format(
					"ColorSequence.new(Color3.fromRGB(%u,%u,%u),Color3.fromRGB(%u,%u,%u))",
					(c1.R * 255) + 0.5,
					(c1.G * 255) + 0.5,
					(c1.B * 255) + 0.5,
					(c2.R * 255) + 0.5,
					(c2.G * 255) + 0.5,
					(c2.B * 255) + 0.5
				)
			else
				results[i] = string.format(
					"ColorSequence.new({%s})",
					toString(unpack(keypoints))
				)
			end
		elseif dataType == "ColorSequenceKeypoint" then
			local c = v.Value
			results[i] = string.format(
				"ColorSequenceKeypoint.new(%s,Color3.fromRGB(%u,%u,%u))",
				tostring(round(v.Time, 7)),
				(c.R * 255) + 0.5,
				(c.G * 255) + 0.5,
				(c.B * 255) + 0.5
			)
		elseif dataType == "EnumItem" then
			results[i] = tostring(v.Value)
		elseif dataType == "Faces" then
			results[i] = string.format(
				"Faces.new(%s)",
				genEnumList(v, Enum.NormalId, ",")
			)
		elseif dataType == "NumberRange" then
			results[i] = string.format(
				"NumberRange.new(%s,%s)",
				tostring(round(v.Min, 7)),
				tostring(round(v.Max, 7))
			)
		elseif dataType == "NumberSequence" then
			local keypoints = v.Keypoints
			if #keypoints == 2 and keypoints[1].Value == keypoints[2].Value then
				results[i] = string.format(
					"NumberSequence.new(%s)",
					toString(keypoints[1].Value)
				)
			elseif #keypoints == 2 then
				results[i] = string.format(
					"NumberSequence.new(%s)",
					toString(keypoints[1].Value, keypoints[2].Value)
				)
			else
				results[i] = string.format(
					"NumberSequence.new({%s})",
					toString(unpack(keypoints))
				)
			end
		elseif dataType == "NumberSequenceKeypoint" then
			if v.Envelope == 0 then
				results[i] = string.format(
					"NumberSequenceKeypoint.new(%s,%s)",
					tostring(round(v.Time, 7)),
					tostring(round(v.Value, 7))
				)
			else
				results[i] = string.format(
					"NumberSequenceKeypoint.new(%s,%s,%s)",
					tostring(round(v.Time, 7)),
					tostring(round(v.Value, 7)),
					tostring(round(v.Envelope, 7))
				)
			end
		elseif dataType == "PhysicalProperties" then
			local fWeight, eWeight = v.FrictionWeight, v.ElasticityWeight
			if fWeight == 1 and eWeight == 1 then
				results[i] = string.format(
					"PhysicalProperties.new(%s,%s,%s)",
					tostring(round(v.Density, 7)),
					tostring(round(v.Friction, 7)),
					tostring(round(v.Elasticity, 7))
				)
			else
				results[i] = string.format(
					"PhysicalProperties.new(%s,%s,%s,%s,%s)",
					tostring(round(v.Density, 7)),
					tostring(round(v.Friction, 7)),
					tostring(round(v.Elasticity, 7)),
					tostring(round(fWeight, 7)),
					tostring(round(eWeight, 7))
				)
			end
		elseif dataType == "Ray" then
			local origin, dir = v.Origin, v.Direction
			results[i] = string.format(
				"Ray.new(Vector3.new(%s,%s,%s),Vector3.new(%s,%s,%s))",
				tostring(origin.X),
				tostring(origin.Y),
				tostring(origin.Z),
				tostring(dir.X),
				tostring(dir.Y),
				tostring(dir.Z)
			)
		elseif dataType == "Rect" then
			results[i] = string.format(
				"Rect.new(%s,%s,%s,%s)",
				tostring(v.Min.X),
				tostring(v.Min.Y),
				tostring(v.Max.X),
				tostring(v.Max.Y)
			)
		elseif dataType == "UDim" then
			results[i] = string.format(
				"UDim.new(%s,%s)",
				tostring(round(v.Scale, 7)),
				tostring(round(v.Offset, 7))
			)
		elseif dataType == "UDim2" then
			results[i] = string.format(
				"UDim2.new(%s,%s,%s,%s)",
				tostring(round(v.X.Scale, 7)),
				tostring(round(v.X.Offset, 7)),
				tostring(round(v.Y.Scale, 7)),
				tostring(round(v.Y.Offset, 7))
			)
		elseif dataType == "Vector2" then
			results[i] = string.format(
				"Vector2.new(%s,%s)",
				tostring(v.X),
				tostring(v.Y)
			)
		elseif dataType == "Vector3" then
			results[i] = string.format(
				"Vector3.new(%s,%s,%s)",
				tostring(v.X),
				tostring(v.Y),
				tostring(v.Z)
			)
		else
			pluginError("Attempted to serialize value of type '%s'", dataType)
		end
	end

	return table.concat(results, ",")
end

local function toStringVerbose(...)
	local results = table.create(select("#", ...))
	local data = { ... }
	for i, v in ipairs(data) do
		local dataType = typeof(v)
		if dataType == "string" then
			results[i] = '"' .. escapeString(v) .. '"'
		elseif dataType == "boolean" or dataType == "nil" then
			results[i] = tostring(v)
		elseif dataType == "number" then
			results[i] = tostring(round(v, 7))
		elseif dataType == "Axes" then
			results[i] = string.format(
				"Axes.new(%s)",
				genEnumList(v, Enum.Axis, ",")
			)
		elseif dataType == "BrickColor" then
			results[i] = string.format('BrickColor.new("%s")', v.Name)
		elseif dataType == "CFrame" then
			-- stylua: ignore start
            local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = v:GetComponents()
            if r00 == 1 and r01 == 0 and r02 == 0 and r10 == 0 and r11 == 1 and r12 == 0 and r20 == 0 and r21 == 0 and r22 == 1 then
                results[i] = string.format("CFrame.new(%s, %s, %s)", tostring(x), tostring(y), tostring(z))
            else
                results[i] = string.format("CFrame.new(%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                    tostring(x), tostring(y), tostring(z), tostring(r00), tostring(r01), tostring(r02),
                    tostring(r10), tostring(r11), tostring(r12), tostring(r20), tostring(r21), tostring(r22)
                )
            end
		elseif dataType == "Color3" then
			results[i] = string.format(
				"Color3.fromRGB(%u, %u, %u)",
				(v.R * 255) + 0.5,
				(v.G * 255) + 0.5,
				(v.B * 255) + 0.5
			)
		elseif dataType == "ColorSequence" then
			local keypoints = v.Keypoints
			if #keypoints == 2 and keypoints[1].Value == keypoints[2].Value then
				local c = keypoints[1].Value
				results[i] = string.format(
					"ColorSequence.new(Color3.fromRGB(%u, %u, %u))",
					(c.R * 255) + 0.5,
					(c.G * 255) + 0.5,
					(c.B * 255) + 0.5
				)
			elseif #keypoints == 2 then
				local c1 = keypoints[1].Value
				local c2 = keypoints[2].Value
				results[i] = string.format(
					"ColorSequence.new(Color3.fromRGB(%u, %u, %u), Color3.fromRGB(%u, %u, %u))",
					(c1.R * 255) + 0.5,
					(c1.G * 255) + 0.5,
					(c1.B * 255) + 0.5,
					(c2.R * 255) + 0.5,
					(c2.G * 255) + 0.5,
					(c2.B * 255) + 0.5
				)
			else
				results[i] = string.format(
					"ColorSequence.new({%s})",
					toStringVerbose(unpack(keypoints))
				)
			end
		elseif dataType == "ColorSequenceKeypoint" then
			local c = v.Value
			results[i] = string.format(
				"ColorSequenceKeypoint.new(%s, Color3.fromRGB(%u, %u, %u))",
				tostring(round(v.Time, 7)),
				(c.R * 255) + 0.5,
				(c.G * 255) + 0.5,
				(c.B * 255) + 0.5
			)
		elseif dataType == "EnumItem" then
			results[i] = string.format(
				"Enum.%s.%s",
				tostring(v.EnumType),
				v.Name
			) --verbose
		elseif dataType == "Faces" then
			results[i] = string.format(
				"Faces.new(%s)",
				genEnumList(v, Enum.NormalId, ", ")
			)
		elseif dataType == "NumberRange" then
			results[i] = string.format(
				"NumberRange.new(%s, %s)",
				tostring(round(v.Min, 7)),
				tostring(round(v.Max, 7))
			)
		elseif dataType == "NumberSequence" then
			local keypoints = v.Keypoints
			if #keypoints == 2 and keypoints[1].Value == keypoints[2].Value then
				results[i] = string.format(
					"NumberSequence.new(%s)",
					toStringVerbose(keypoints[1].Value)
				)
			elseif #keypoints == 2 then
				results[i] = string.format(
					"NumberSequence.new(%s)",
					toStringVerbose(keypoints[1].Value, keypoints[2].Value)
				)
			else
				results[i] = string.format(
					"NumberSequence.new({%s})",
					toStringVerbose(unpack(keypoints))
				)
			end
		elseif dataType == "NumberSequenceKeypoint" then
			if v.Envelope == 0 then
				results[i] = string.format(
					"NumberSequenceKeypoint.new(%s, %s)",
					tostring(round(v.Time, 7)),
					tostring(round(v.Value, 7))
				)
			else
				results[i] = string.format(
					"NumberSequenceKeypoint.new(%s, %s, %s)",
					tostring(round(v.Time, 7)),
					tostring(round(v.Value, 7)),
					tostring(round(v.Envelope, 7))
				)
			end
		elseif dataType == "PhysicalProperties" then
			local fWeight, eWeight = v.FrictionWeight, v.ElasticityWeight
			if fWeight == 1 and eWeight == 1 then
				results[i] = string.format(
					"PhysicalProperties.new(%s, %s, %s)",
					tostring(round(v.Density, 7)),
					tostring(round(v.Friction, 7)),
					tostring(round(v.Elasticity, 7))
				)
			else
				results[i] = string.format(
					"PhysicalProperties.new(%s, %s, %s, %s, %s)",
					tostring(round(v.Density, 7)),
					tostring(round(v.Friction, 7)),
					tostring(round(v.Elasticity, 7)),
					tostring(round(fWeight, 7)),
					tostring(round(eWeight, 7))
				)
			end
		elseif dataType == "Ray" then
			local origin, dir = v.Origin, v.Direction
			results[i] = string.format(
				"Ray.new(Vector3.new(%s, %s, %s),Vector3.new(%s, %s, %s))",
				tostring(origin.X),
				tostring(origin.Y),
				tostring(origin.Z),
				tostring(dir.X),
				tostring(dir.Y),
				tostring(dir.Z)
			)
		elseif dataType == "Rect" then
			results[i] = string.format(
				"Rect.new(%s, %s, %s, %s)",
				tostring(v.Min.X),
				tostring(v.Min.Y),
				tostring(v.Max.X),
				tostring(v.Max.Y)
			)
		elseif dataType == "UDim" then
			results[i] = string.format(
				"UDim.new(%s, %s)",
				tostring(round(v.Scale, 7)),
				tostring(round(v.Offset, 7))
			)
		elseif dataType == "UDim2" then
			results[i] = string.format(
				"UDim2.new(%s, %s, %s, %s)",
				tostring(round(v.X.Scale, 7)),
				tostring(round(v.X.Offset, 7)),
				tostring(round(v.Y.Scale, 7)),
				tostring(round(v.Y.Offset, 7))
			)
		elseif dataType == "Vector2" then
			results[i] = string.format(
				"Vector2.new(%s, %s)",
				tostring(v.X),
				tostring(v.Y)
			)
		elseif dataType == "Vector3" then
			results[i] = string.format(
				"Vector3.new(%s, %s, %s)",
				tostring(v.X),
				tostring(v.Y),
				tostring(v.Z)
			)
		else
			pluginError("Attempted to serialize value of type '%s'", dataType)
		end
	end

	return table.concat(results, ", ")
end

return {
	toString = toString,
	toStringVerbose = toStringVerbose,
}
