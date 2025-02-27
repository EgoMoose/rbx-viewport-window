--!strict

local RunService = game:GetService("RunService")

local ViewportWindow = require(game.ReplicatedStorage.Packages.ViewportWindow)
local Trove = require(game.ReplicatedStorage.Packages.Trove)
local CloneMatch = require(script.Parent.Helpers.CloneMatch)

local MirrorClass = {}
MirrorClass.__index = MirrorClass
MirrorClass.ClassName = "Mirror"

type ViewportWindow = ViewportWindow.ViewportWindow

export type Mirror = typeof(setmetatable(
	{} :: {
		window: ViewportWindow,
	},
	MirrorClass
))

function MirrorClass.new(window: ViewportWindow)
	local self = setmetatable({}, MirrorClass) :: Mirror

	self.window = window

	local copy = CloneMatch.workspace({
		["BasePart"] = function(...)
			return self:_handleBasePart(...)
		end,
	})
	copy:Get().Parent = self.window:GetViewportFrame()

	return self
end

function MirrorClass._handleBasePart(self: Mirror, real: Instance, copy: Instance, trove: Trove.Trove)
	if not (real:IsA("BasePart") and copy:IsA("BasePart")) then
		return
	end

	local function update()
		local surfaceCF = self.window:GetSurfaceCFrameSize()
		local offset = surfaceCF:ToObjectSpace(real.CFrame)
		local x, y, z, m11, m12, m13, m21, m22, m23, m31, m32, m33 = offset:GetComponents()

		-- stylua: ignore
		local rotatedOffset = CFrame.new(
			x, y, -z,
			-m11, m12, m13,
			-m21, m22, m23, 
			m31, -m32, -m33
		)

		copy.CFrame = surfaceCF * rotatedOffset
	end

	copy.Anchored = true

	update()
	trove:Add(RunService.Heartbeat:Connect(function()
		update()
	end))
end

function MirrorClass.Render(self: Mirror)
	self.window:Render()
end

return MirrorClass
