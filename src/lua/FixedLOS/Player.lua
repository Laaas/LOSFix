if not Server then return end

local kCommanderLOSCheckInterval = 0.5 -- also present in LOSMixin.lua
local kCommanderLOSRadius        = 8
local function CheckIsVisibleToCommander(self)
	local entities = Shared.GetEntitiesWithTagInRange("LOS", self:GetOrigin(), kCommanderLOSRadius)
	local time = Shared.GetTime()

	for i = 1, #entities do
		local ent = entities[i]
		if ent:GetTeamNumber() ~= self:GetTeamNumber() then
			ent.commanderSighted = time
			ent:SetExcludeRelevancyMask(0x1F)
		end
	end

	return true
end

local old = Player.OnCreate
function Player:OnCreate()
	old(self)

	self:AddTimedCallback(CheckIsVisibleToCommander, kCommanderLOSCheckInterval)
end
