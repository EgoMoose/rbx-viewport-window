--!strict

local RunService = game:GetService("RunService") :: RunService

local Trove = require(game.ReplicatedStorage.Packages.Trove)

local MatchHandlers: { [string]: (Instance, Instance, Trove.Trove) -> () } = {}

function MatchHandlers.Default(real, copy, trove)
	-- this will cause issues if not using deferred signaling
	trove:Add(real.Changed:Connect(function(property)
		pcall(function()
			local copyAny = copy :: any
			local realAny = real :: any
			copyAny[property] = realAny[property]
		end)
	end))
end

function MatchHandlers.BasePart(real, copy, trove)
	if not (real:IsA("BasePart") and copy:IsA("BasePart")) then
		return
	end

	trove:Add(RunService.Heartbeat:Connect(function()
		if not real.Anchored then
			copy.CFrame = real.CFrame
		end
	end))
end

return MatchHandlers
