--!strict

local Copy = {}

function Copy.instance<T>(instance: T & Instance)
	local archivableMap = {}
	for _, child in instance:GetChildren() do
		archivableMap[child] = child.Archivable
		child.Archivable = false
	end

	local archivable = instance.Archivable
	instance.Archivable = true
	local copy = instance:Clone()
	instance.Archivable = archivable

	for child, prevArchivable in archivableMap do
		child.Archivable = prevArchivable
	end

	return copy :: T
end

function Copy.hierarchy(root: Instance)
	local copyMap = {}
	local stack = { root }
	while #stack > 0 do
		local popped = table.remove(stack) :: Instance
		copyMap[popped] = Copy.instance(popped)
		for _, child in popped:GetChildren() do
			table.insert(stack, child)
		end
	end
	return copyMap[root], copyMap
end

return Copy
