LOSMixin = {
	type = "LOS",
	expectedMixins = {
		Team = "Needed for calls to GetTeamNumber().",
	},
	optionalCallbacks = {
		OverrideCheckVision = "Return true if this entity can see, false otherwise"
	},
	networkVars = {
		sighted = "boolean"
	}
}

local kLOSTimeout = 4
local kLOSDistanceTimeoutSquared = 7^2

function LOSMixin:GetIsSighted()
	return self.sighted
end

if Server then
	local function UpdateLOS(self)
		local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit, kRelevantToReadyRoom)

		local team = self:GetTeamNumber()
		if self.sighted then
			mask = bit.bor(mask, kRelevantToTeam1Commander, kRelevantToTeam2Commander)
		elseif team == 1 then
			mask = bit.bor(mask, kRelevantToTeam1Commander)
		elseif team == 2 then
			mask = bit.bor(mask, kRelevantToTeam2Commander)
		end

		self:SetExcludeRelevancyMask(mask)

		if self.OnSighted then
			self:OnSighted(self.sighted)
		end
	end

	function LOSMixin:__initmixin()
		self.sighted       = false
		self.timeSighted   = 0
		self.originSighted = Vector()

		UpdateLOS(self)
	end

	function LOSMixin:DoDamage(damage, target)
		if not HasMixin(target, "LOS") then return end
		if target.GetIsAlive and not target:GetIsAlive() then return end

		target:SetIsSighted(true)
	end

	function LOSMixin:SetIsSighted() -- Always sets sighted to true
		self.sighted       = true
		self.timeSighted   = Shared.GetTime()
		self.originSighted = self:GetOrigin()

		UpdateLOS(self)
	end

	function LOSMixin:OnUpdate()
		if sighted and (
			Shared.GetTime() - self.timeSighted > kLOSTimeout or
			(self:GetOrigin() - self.originSighted):GetLengthSquared() > kLOSDistanceTimeoutSquared
		) then
			self.sighted = false
			UpdateLOS(self)
		end
	end

	function LOSMixin:OnTeamChange()
		self.sighted = false
		UpdateLOS(self)
	end
else
	function LOSMixin:__initmixin()
	end
end
