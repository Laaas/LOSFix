if not Server then return end

local kInterval = 0.5
local kRadius   = 10
local function Check(self)
	local entities = Shared.GetEntitiesWithTagInRange("LOS", self:GetOrigin(), kRadius)
	local time = Shared.GetTime()

	for i = 1, #entities do
		local ent = entities[i]
		if ent:GetTeamNumber() ~= self:GetTeamNumber() then
			ent:SetIsSighted(true)
		end
	end

	return true
end

local old = Drifter.OnCreate
function Drifter:OnCreate()
	old(self)

	self:AddTimedCallback(Check, kInterval)
end
