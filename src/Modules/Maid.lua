local ALLOWED_TASK_TYPES = {
	["function"] = true,
	["RBXScriptConnection"] = true,
	["Instance"] = true,
}

local Maid = {}
Maid.__index = Maid

function Maid.new()
	local self = {
		_tasks = {},
	}

	setmetatable(self, Maid)

	return self
end

function Maid:Give(task)
	if not self then
		error("tried to call Maid::Give as a static function: use `:` instead of `.`", 2)
	elseif self == Maid then
		error("tried to call Maid::Give on the module instead of a Maid instance", 2)
	end

	if ALLOWED_TASK_TYPES[typeof(task)] or getmetatable(task) == Maid then
		local tasks = self._tasks
		tasks[#tasks + 1] = task
	else
		error(string.format("invalid task type `%s` given to Maid::Give", typeof(task), 2))
	end
end

function Maid:CleanUp(task)
	if not self then
		error("tried to call Maid::CleanUp as a static function: use `:` instead of `.`", 2)
	elseif self == Maid then
		error("tried to call Maid::CleanUp on the module instead of a Maid instance", 2)
	end

	local taskType = typeof(task)

	if taskType == "RBXScriptConnection" then
		task:Disconnect()
	elseif taskType == "Instance" then
		task:Destroy()
	elseif taskType == "function" then
		task()
	elseif getmetatable(self) == Maid then
		task:Sweep()
	end
end

function Maid:Sweep()
	print("Sweeping uwu")
	local tasks = self._tasks
	for k, v in pairs(tasks) do
		if typeof(v) == "RBXScriptConnection" then
			v:Disconnect()
			tasks[k] = nil
		end
	end

	for k, v in pairs(tasks) do
		self:CleanUp(v)
		tasks[k] = nil
	end
end

return Maid