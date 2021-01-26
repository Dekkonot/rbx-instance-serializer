local ALLOWED_TASK_TYPES = {
	["function"] = true,
	["RBXScriptConnection"] = true,
	["Instance"] = true,
	["table"] = true,
	["userdata"] = true,
}

local function tryDestroy(thing)
	thing:Destroy()
end

---@class Maid
local Maid = {}
Maid.__index = Maid

---Creates a new Maid and returns it.
---@return Maid
function Maid.new()
	local self = {
		_tasks = {},
	}

	setmetatable(self, Maid)

	return self
end

---Accepts a `task` and adds it to the Maid, to be cleaned up with `Maid:Sweep`.
---@param task function | RBXScriptConnection | Instance | Maid | table | userdata
---@return any
function Maid:Give(task)
	if not self then
		error("tried to call Maid::Give as a static function: use `:` instead of `.`", 2)
	elseif self == Maid then
		error("tried to call Maid::Give on the module instead of a Maid instance", 2)
	end

	if ALLOWED_TASK_TYPES[typeof(task)] or getmetatable(task) == Maid then
		local tasks = self._tasks
		tasks[#tasks + 1] = task
		return task
	else
		error(string.format("invalid task type `%s` given to Maid::Give", typeof(task)), 2)
	end

end

---Cleans up a given `task`, and returns whether it was cleaned up successfully.
---Useful for cases where the type of `task` is not known.
---
---This function:
---- Calls `functions`
---- Disconnects `RBXScriptConnections`
---- Destroys `Instances`
---- Sweeps other `Maids`
---- Attempts to call `Destroy` on any `tables` or `userdata`
---- Iterates through and removes all of the indicies for `tables` that don't have `Destroy`
---- Sets the metatable of `tables` to `nil`
---@param task function | RBXScriptConnection | Instance | Maid | table | userdata
---@return boolean cleaned
function Maid:CleanUp(task)
	if not self then
		error("tried to call Maid::CleanUp as a static function: use `:` instead of `.`", 2)
	elseif self == Maid then
		error("tried to call Maid::CleanUp on the module instead of a Maid instance", 2)
	end

	local taskType = typeof(task)

	if taskType == "RBXScriptConnection" then
		task:Disconnect()
		return true
	elseif taskType == "Instance" then
		task:Destroy()
		return true
	elseif taskType == "function" then
		task()
		return true
	elseif getmetatable(self) == Maid then
		task:Sweep()
		return true
	elseif taskType == "table" then
		local success = pcall(tryDestroy, task)
		setmetatable(task, nil)
		if not success then
			for k in pairs(task) do
				task[k] = nil
			end
			return true
		end
		return true
	elseif taskType == "userdata" then
		local success = pcall(tryDestroy, task)
		return success
	else
		return false
	end
end

---Cleans up all of the tasks stored inside the Maid. If the task is cleaned up successfully, it is removed.
---Whether all tasks succeeded is returned.
---
---This function calls `Maid:CleanUp` internally, so if you need implementation details, see that function.
---@return boolean cleaned
function Maid:Sweep()
	local tasks = self._tasks
	for i, v in ipairs(tasks) do
		if typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
			tasks[i] = nil
		end
	end

	local success = true
	for i, v in ipairs(tasks) do
		local cleaned = self:CleanUp(v)
		if not cleaned then
			success = false
		end
		tasks[i] = nil
	end

	return success
end

function Maid:Destroy()
	local tasks = self._tasks
	for i in ipairs(self._tasks) do
		tasks[i] = nil
	end
	setmetatable(self, nil)
end

return Maid
