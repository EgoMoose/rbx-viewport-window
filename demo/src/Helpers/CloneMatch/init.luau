--!strict

-- This is kind of messy, but it gets the job done
-- Allows for cloning of instance hierarchies in the data model and matching their properties
-- Useful for having a matching world in viewport frames

local Trove = require(game.ReplicatedStorage.Packages.Trove)
local MatchHandlers = require(script.MatchHandlers)
local Copy = require(script.Copy)

local SUPPORTED = { "BasePart", "Folder", "Model", "Decal", "Texture", "SurfaceAppearance" }
local UNSUPPORTED = { "Terrain", "Status" }

-- Class

local CloneMatchClass = {}
CloneMatchClass.__index = CloneMatchClass
CloneMatchClass.ClassName = "CloneMatch"

export type CloneMatch = typeof(setmetatable(
	{} :: {
		trove: Trove.Trove,
		root: Instance,
		handlers: typeof(MatchHandlers),
		copyMap: { [Instance]: Instance },
		cleanMap: { [Instance]: Trove.Trove },
	},
	CloneMatchClass
))

-- Constructors

function CloneMatchClass.raw(root: Instance, rootCopy: Instance, handlers: typeof(MatchHandlers))
	local self = setmetatable({}, CloneMatchClass) :: CloneMatch

	self.trove = Trove.new()

	self.root = root
	self.copyMap = {}
	self.cleanMap = {}

	self.handlers = table.clone(MatchHandlers)
	for key, handler in handlers do
		self.handlers[key] = handler
	end

	self:_track(root, rootCopy)

	for _, descendant in root:GetDescendants() do
		if self:_isSupported(descendant) then
			self:_add(descendant)
		end
	end

	self.trove:Add(root.DescendantAdded:Connect(function(descendant)
		if self:_isSupported(descendant) then
			self:_add(descendant)
		end
	end))

	self.trove:Add(root.DescendantRemoving:Connect(function(descendant)
		self:_remove(descendant)
	end))

	self.trove:Add(function()
		for instance, _ in self.cleanMap do
			self:_remove(instance)
		end
	end)

	return self
end

function CloneMatchClass.workspace(handlers: typeof(MatchHandlers)?)
	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "Workspace"
	return CloneMatchClass.raw(workspace, worldModel, handlers or {})
end

function CloneMatchClass.new(root: Instance, handlers: typeof(MatchHandlers)?)
	return CloneMatchClass.raw(root, Copy.instance(root), handlers or {})
end

-- Private

function CloneMatchClass._isSupported(_self: CloneMatch, instance: Instance)
	for _, className in UNSUPPORTED do
		if instance:IsA(className) then
			return false
		end
	end

	for _, className in SUPPORTED do
		if instance:IsA(className) then
			return true
		end
	end

	return false
end

function CloneMatchClass._findNearestAncestor(self: CloneMatch, instance: Instance)
	local parent = instance.Parent
	while parent and parent:IsDescendantOf(self.root) do
		if self.copyMap[parent] then
			return parent
		end
		parent = parent.Parent
	end
	return self.root
end

function CloneMatchClass._track(self: CloneMatch, instance: Instance, copy: Instance)
	local trove = Trove.new()

	for _, handler in self.handlers do
		handler(instance, copy, trove)
	end

	trove:Add(function()
		copy:Destroy()
		self.copyMap[instance] = nil
	end)

	self.copyMap[instance] = copy
	self.cleanMap[instance] = trove
end

function CloneMatchClass._add(self: CloneMatch, instance: Instance)
	local ancestor = self:_findNearestAncestor(instance)
	local copy = Copy.instance(instance)
	copy.Parent = self.copyMap[ancestor]
	self:_track(instance, copy)
end

function CloneMatchClass._remove(self: CloneMatch, instance: Instance)
	local trove = self.cleanMap[instance]
	self.cleanMap[instance] = nil
	if trove then
		trove:Destroy()
	end
end

-- Public

function CloneMatchClass.Get(self: CloneMatch)
	return self.copyMap[self.root]
end

function CloneMatchClass.Destroy(self: CloneMatch)
	self.trove:Destroy()
end

--

return CloneMatchClass
