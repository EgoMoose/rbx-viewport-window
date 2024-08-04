--!strict

local SKYBOX_MAP: { [string]: CFrame } = {
	["Bk"] = CFrame.fromEulerAnglesYXZ(0, math.rad(180), 0),
	["Dn"] = CFrame.fromEulerAnglesYXZ(-math.rad(90), math.rad(90), 0),
	["Ft"] = CFrame.fromEulerAnglesYXZ(0, 0, 0),
	["Lf"] = CFrame.fromEulerAnglesYXZ(0, -math.rad(90), 0),
	["Rt"] = CFrame.fromEulerAnglesYXZ(0, math.rad(90), 0),
	["Up"] = CFrame.fromEulerAnglesYXZ(math.rad(90), math.rad(90), 0),
}

local SkyboxHelper = {}

function SkyboxHelper.skySphere(sky: Sky)
	local model = Instance.new("Model")
	model.Name = "SkyboxModel"

	for property, rotationCF in SKYBOX_MAP do
		local side = Instance.new("Part")
		side.Anchored = true
		side.Name = property
		side.CFrame = rotationCF
		side.Size = Vector3.one
		side.Parent = model

		local mesh = Instance.new("SpecialMesh")
		mesh.MeshId = "rbxassetid://3083991485"
		mesh.Offset = Vector3.new(0, 0, -0.683)
		mesh.Parent = side

		local decal = Instance.new("Decal")
		decal.Texture = (sky :: any)["Skybox" .. property]
		decal.Parent = side
	end

	return model
end

return SkyboxHelper
