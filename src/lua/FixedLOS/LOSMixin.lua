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

local kLOSTimeout                = 4
local kLOSMaxDistanceSquared     = 7^2
local kLOSCheckInterval          = 0.5

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

		self:SetExcludeRelevancyMask(bit.bor(
			kRelevantToTeam1Unit,
			kRelevantToTeam2Unit,
			kRelevantToReadyRoom
		))

		self:AddTimedCallback(UpdateLOS, 0)
		self:AddTimedCallback(self.CheckIsSighted, kLOSCheckInterval)
	end

	function LOSMixin:OnDamageDone(_, target)
		if not HasMixin(target, "LOS") then return end
		if target.GetIsAlive and not target:GetIsAlive() then return end
		if target:GetTeamNumber() == self:GetTeamNumber() then return end

		target:SetIsSighted()
	end

	function LOSMixin:SetIsSighted(sighted)
		if not sighted then return end

		local old = self.sighted

		self.sighted       = true
		self.timeSighted   = Shared.GetTime()
		self.originSighted = self:GetOrigin()

		if not old then
			UpdateLOS(self)
		end
	end

	function LOSMixin:CheckIsSighted()
		if self.sighted and not (self.GetIsParasited and self:GetIsParasited()) and (
			Shared.GetTime() - self.timeSighted > kLOSTimeout or
			(self:GetOrigin() - self.originSighted):GetLengthSquared() > kLOSMaxDistanceSquared
		) then
			self.sighted = false
			UpdateLOS(self)
		end

		return true
	end

	function LOSMixin:OnKill()
		if self.sighted then
			self.sighted = false
			UpdateLOS(self)
		end
	end

	LOSMixin.OnTeamChange         = LOSMixin.OnKill
	LOSMixin.OnUseGorgeTunnel     = LOSMixin.OnKill
	LOSMixin.OnPhaseGateEntry     = LOSMixin.OnKill
	LOSMixin.TriggerBeaconEffects = LOSMixin.OnKill

else
	function LOSMixin:__initmixin()
	end
end
