--!strict

local RunService = game:GetService("RunService") :: RunService
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Demo = ReplicatedStorage.Demo
local ViewportWindow = require(ReplicatedStorage.Packages.ViewportWindow)

local sky = game.Lighting:FindFirstChildWhichIsA("Sky")

local function setupPortal()
	local windowA = ViewportWindow.fromPart(workspace.World.PortalA, Enum.NormalId.Front)
	local windowB = ViewportWindow.fromPart(workspace.World.PortalB, Enum.NormalId.Front)

	windowA:GetSurfaceGui().ResetOnSpawn = false
	windowB:GetSurfaceGui().ResetOnSpawn = false
	windowA:SetSky(sky)
	windowB:SetSky(sky)

	local Portal = require(Demo.Portal)
	local portal = Portal.new(windowA, windowB)

	RunService.RenderStepped:Connect(function()
		portal:Render()
	end)
end

local function setupMirror()
	local window = ViewportWindow.fromPart(workspace.World.Mirror, Enum.NormalId.Front)

	window:GetSurfaceGui().ResetOnSpawn = false
	window:SetSky(sky)

	local Mirror = require(Demo.Mirror)
	local mirror = Mirror.new(window)

	RunService.RenderStepped:Connect(function()
		mirror:Render()
	end)
end

local function setupSeeThrough()
	local surface = workspace.World.SeeThrough
	local window = ViewportWindow.fromPart(surface, Enum.NormalId.Front)

	window:GetSurfaceGui().ResetOnSpawn = false
	--window:SetSky(sky)

	for _, child in surface:GetChildren() do
		child.Parent = window:GetViewportFrame()
	end

	RunService.RenderStepped:Connect(function()
		window:Render()
	end)
end

setupPortal()
setupMirror()
setupSeeThrough()
