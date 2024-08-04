--!strict

local ViewportWindow = require(game.ReplicatedStorage.Packages.ViewportWindow)
local CloneMatch = require(script.Parent.Helpers.CloneMatch)

local PortalClass = {}
PortalClass.__index = PortalClass
PortalClass.ClassName = "Portal"

type ViewportWindow = ViewportWindow.ViewportWindow

export type Portal = typeof(setmetatable(
	{} :: {
		windowA: ViewportWindow,
		windowB: ViewportWindow,
	},
	PortalClass
))

function PortalClass.new(windowA: ViewportWindow, windowB: ViewportWindow)
	local self = setmetatable({}, PortalClass) :: Portal

	self.windowA = windowA
	self.windowB = windowB

	CloneMatch.workspace():Get().Parent = self.windowA:GetViewportFrame()
	CloneMatch.workspace():Get().Parent = self.windowB:GetViewportFrame()

	return self
end

function PortalClass.Render(self: Portal)
	local camera = workspace.CurrentCamera
	local cameraCFrame = camera.CFrame

	local surfaceACF, surfaceASize = self.windowA:GetSurfaceCFrameSize()
	local surfaceBCF, surfaceBSize = self.windowB:GetSurfaceCFrameSize()

	local rotatedSurfaceBCF = surfaceBCF * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)
	local rotatedSurfaceACF = surfaceACF * CFrame.fromEulerAnglesYXZ(0, math.pi, 0)

	local renderACF = rotatedSurfaceBCF * surfaceACF:ToObjectSpace(cameraCFrame)
	local renderBCF = rotatedSurfaceACF * surfaceBCF:ToObjectSpace(cameraCFrame)

	self.windowA:RenderManual(renderACF, rotatedSurfaceBCF, surfaceBSize)
	self.windowB:RenderManual(renderBCF, rotatedSurfaceACF, surfaceASize)

	return cameraCFrame
end

return PortalClass
