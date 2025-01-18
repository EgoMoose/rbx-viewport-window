--!strict

local Players = game:GetService("Players") :: Players
local Lighting = game:GetService("Lighting") :: Lighting

local Trove = require(script.Parent.Trove)
local SkyboxHelper = require(script.SkyboxHelper)

local VEC_XZ = Vector3.new(1, 0, 1)
local VEC_YZ = Vector3.new(0, 1, 1)

local ViewportWindowClass = {}
ViewportWindowClass.__index = ViewportWindowClass
ViewportWindowClass.ClassName = "ViewportWindow"

export type ViewportWindow = typeof(setmetatable(
	{} :: {
		trove: Trove.Trove,
		surfaceGui: SurfaceGui,

		nearPlaneZ: number?,

		worldCamera: Camera,
		worldViewportFrame: ViewportFrame,

		skyTrove: Trove.Trove,
		skyboxCamera: Camera,
		skyboxViewportFrame: ViewportFrame,
	},
	ViewportWindowClass
))

function ViewportWindowClass.fromPart(part: BasePart, face: Enum.NormalId)
	local self = setmetatable({}, ViewportWindowClass) :: ViewportWindow

	local player = assert(Players.LocalPlayer, "No local player found.")
	local playerGui = assert(player.PlayerGui, "Player has no PlayerGui.")

	self.trove = Trove.new()

	self.surfaceGui = Instance.new("SurfaceGui")
	self.surfaceGui.Name = "ViewportWindow"
	self.surfaceGui.Face = face
	self.surfaceGui.Adornee = part
	self.surfaceGui.ClipsDescendants = true
	self.surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	self.surfaceGui.CanvasSize = Vector2.new(1024, 1024)
	self.surfaceGui.ZOffset = 2 -- Fixes an issue viewing the surface gui closely on semi-transparent parts
	self.surfaceGui.Parent = playerGui
	self.trove:Add(self.surfaceGui)

	self.nearPlaneZ = 0

	self.worldCamera = Instance.new("Camera")
	self.worldCamera.Name = "WorldCamera"
	self.worldCamera.Parent = self.surfaceGui
	self.trove:Add(self.worldCamera)

	self.worldViewportFrame = Instance.new("ViewportFrame")
	self.worldViewportFrame.BackgroundTransparency = 1
	self.worldViewportFrame.Size = UDim2.fromScale(1, 1)
	self.worldViewportFrame.Name = "World"
	self.worldViewportFrame.ZIndex = 2
	self.worldViewportFrame.Ambient = Lighting.Ambient
	self.worldViewportFrame.LightColor = Color3.new(1, 1, 1)
	self.worldViewportFrame.LightDirection = -Lighting:GetSunDirection()
	self.worldViewportFrame.CurrentCamera = self.worldCamera
	self.worldViewportFrame.Parent = self.surfaceGui
	self.trove:Add(self.worldViewportFrame)

	self.skyTrove = Trove.new()

	self.skyboxCamera = Instance.new("Camera")
	self.skyboxCamera.Name = "SkyboxCamera"
	self.skyboxCamera.Parent = self.surfaceGui
	self.trove:Add(self.skyboxCamera)

	self.skyboxViewportFrame = Instance.new("ViewportFrame")
	self.skyboxViewportFrame.BackgroundTransparency = 1
	self.skyboxViewportFrame.Size = UDim2.fromScale(1, 1)
	self.skyboxViewportFrame.Name = "Skybox"
	self.skyboxViewportFrame.ZIndex = 1
	self.skyboxViewportFrame.Ambient = Color3.new(1, 1, 1)
	self.skyboxViewportFrame.LightColor = Color3.new(1, 1, 1)
	self.skyboxViewportFrame.LightDirection = -Lighting:GetSunDirection()
	self.skyboxViewportFrame.CurrentCamera = self.skyboxCamera
	self.skyboxViewportFrame.Parent = self.surfaceGui
	self.trove:Add(self.skyboxViewportFrame)

	return self
end

-- Public Methods

function ViewportWindowClass.SetSky(self: ViewportWindow, sky: Sky?)
	self.skyTrove:Clean()

	if sky and sky:IsA("Sky") then
		local skyCopyA = sky:Clone()
		skyCopyA.Name = "Sky"
		skyCopyA.Parent = self.worldViewportFrame
		self.skyTrove:Add(skyCopyA)

		local skyCopyB = sky:Clone()
		skyCopyB.Name = "Sky"
		skyCopyB.Parent = self.skyboxViewportFrame
		self.skyTrove:Add(skyCopyB)

		-- we can't do a small sphere b/c then the near clipping plane
		-- can cut-off some skybox when close to the surface
		local skyModel = SkyboxHelper.skySphere(sky)
		skyModel:ScaleTo(10)
		skyModel.Parent = self.skyboxViewportFrame
		self.skyTrove:Add(skyModel)
	end
end

function ViewportWindowClass.SetNearPlaneZ(self: ViewportWindow, nearPlaneZ: number?)
	self.nearPlaneZ = nearPlaneZ
end

function ViewportWindowClass.GetNearPlaneZ(self: ViewportWindow)
	return self.nearPlaneZ
end

function ViewportWindowClass.GetSurfaceGui(self: ViewportWindow)
	return self.surfaceGui
end

function ViewportWindowClass.GetViewportFrame(self: ViewportWindow)
	return self.worldViewportFrame
end

function ViewportWindowClass.GetSurfacePart(self: ViewportWindow)
	local surfacePart = self.surfaceGui.Adornee
	assert(surfacePart and surfacePart:IsA("BasePart"), "No surface part found.")
	return surfacePart
end

function ViewportWindowClass.GetSurfaceCFrameSize(self: ViewportWindow)
	local surfacePart = self:GetSurfacePart()

	local v = -Vector3.FromNormalId(self.surfaceGui.Face)
	local u = Vector3.new(v.Y, math.abs(v.X + v.Z), 0)
	local relativeCF = CFrame.fromMatrix(Vector3.zero, u:Cross(v), u, v)
	local worldCF = surfacePart.CFrame * CFrame.new(-v * surfacePart.Size / 2) * relativeCF

	local size = Vector3.new(
		math.abs(relativeCF.XVector:Dot(surfacePart.Size)),
		math.abs(relativeCF.YVector:Dot(surfacePart.Size)),
		math.abs(relativeCF.ZVector:Dot(surfacePart.Size))
	)

	return worldCF, size
end

function ViewportWindowClass.RenderManual(
	self: ViewportWindow,
	cameraCFrame: CFrame,
	surfaceCFrame: CFrame,
	surfaceSize: Vector3
)
	local camera = workspace.CurrentCamera
	local cameraPosition = cameraCFrame.Position
	local distance = surfaceCFrame:PointToObjectSpace(cameraPosition).Z

	if distance > 0 then
		-- the camera cannot see the surface so there's no point in continuing the calculation
		return
	end

	-- please see EmilyBendsSpace's post/code on the devforum as it provides the foundation for what's being done here
	-- https://devforum.roblox.com/t/re-creating-a-portal-effect/337159/78
	local xCross = surfaceCFrame.YVector:Cross(cameraCFrame.ZVector)
	local xVector = xCross:Dot(xCross) > 0 and xCross.Unit or cameraCFrame.XVector
	local levelCameraCFrame = CFrame.fromMatrix(cameraPosition, xVector, surfaceCFrame.YVector)

	local topCenter = surfaceCFrame * Vector3.new(0, surfaceSize.Y / 2, 0)
	local bottomCenter = surfaceCFrame * Vector3.new(0, -surfaceSize.Y / 2, 0)
	local cameraSpaceTopCenter = levelCameraCFrame:PointToObjectSpace(topCenter)
	local cameraSpaceBottomCenter = levelCameraCFrame:PointToObjectSpace(bottomCenter)

	local topDirection = (cameraSpaceTopCenter * VEC_YZ).Unit
	local bottomDirection = (cameraSpaceBottomCenter * VEC_YZ).Unit
	local alpha = math.sign(topDirection.Y) * math.acos(-topDirection.Z)
	local beta = math.sign(bottomDirection.Y) * math.acos(-bottomDirection.Z)

	local fovHeight = 2 * math.tan(math.rad(camera.FieldOfView / 2))
	local surfaceFovHeight = math.tan(alpha) - math.tan(beta)
	local fovHeightRatio = surfaceFovHeight / fovHeight

	local dv = surfaceCFrame:VectorToObjectSpace(surfaceCFrame.Position - cameraCFrame.Position)
	local dvXZ = (dv * VEC_XZ).Unit
	local dvYZ = dv * VEC_YZ

	local dvZ = -dvXZ.Z
	local camXZ = (surfaceCFrame:VectorToObjectSpace(cameraCFrame.LookVector) * VEC_XZ).Unit
	local scale = camXZ:Dot(dvXZ) / dvZ
	local tanArcCos = math.sqrt(1 - dvZ * dvZ) / dvZ

	local w, h = 1, 1
	if self.surfaceGui.SizingMode == Enum.SurfaceGuiSizingMode.FixedSize then
		local canvasSize = self.surfaceGui.CanvasSize
		h = (canvasSize.Y / canvasSize.X) * (surfaceSize.X / surfaceSize.Y)
	end

	local dx = math.sign(dv.X * dv.Z) * tanArcCos
	local dy = dvYZ.Y / dvYZ.Z * h
	local dz = math.abs(scale * fovHeightRatio * h)

	-- alternatively:
	-- w, h = w / dz, h / dz
	-- dx, dy = dx / dz, dy / dz
	-- dz = 1

	local m = math.max(w, h, math.abs(dx), math.abs(dy), dz)

	local nearZCFrame = CFrame.identity
	if self.nearPlaneZ then
		local cameraNearPlaneZ = camera.NearPlaneZ
		local minNearPlaneZ = math.min(cameraNearPlaneZ, distance + self.nearPlaneZ)
		local nz = (minNearPlaneZ / cameraNearPlaneZ) * (dz / m)
		nearZCFrame = CFrame.new(0, 0, 0, 1 / nz, 0, 0, 0, 1 / nz, 0, 0, 0, 1 / nz)
	end

	local renderRotation = surfaceCFrame.Rotation
		* CFrame.fromEulerAnglesYXZ(0, math.pi, 0)
		* CFrame.new(0, 0, 0, w / m, 0, 0, 0, h / m, 0, dx / m, dy / m, dz / m)

	local renderCFrame = renderRotation + cameraPosition

	self.worldCamera.FieldOfView = camera.FieldOfView
	self.worldCamera.CFrame = renderCFrame * nearZCFrame

	self.skyboxCamera.FieldOfView = camera.FieldOfView
	self.skyboxCamera.CFrame = renderCFrame.Rotation
end

function ViewportWindowClass.Render(self: ViewportWindow)
	local camera = workspace.CurrentCamera
	local surfaceCFrame, surfaceSize = self:GetSurfaceCFrameSize()
	return self:RenderManual(camera.CFrame, surfaceCFrame, surfaceSize)
end

function ViewportWindowClass.Destroy(self: ViewportWindow)
	self.skyTrove:Destroy()
	self.trove:Destroy()
end

--

return ViewportWindowClass
