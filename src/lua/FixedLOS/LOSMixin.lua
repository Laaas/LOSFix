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

		UpdateLOS(self)

		self:AddTimedCallback(self.CheckIsSighted, kLOSCheckInterval)
	end

	function LOSMixin:OnDamageDone(_, target)
		Log("Did damage to %s", target)
		if not HasMixin(target, "LOS") then Log "Target did not have LOS mixin!"; return end
		if target.GetIsAlive and not target:GetIsAlive() then Log "Target is not alive!"; return end
		if target:GetTeamNumber() == self:GetTeamNumber() then Log "Same team!"; return end

		target:SetIsSighted()
	end

	function LOSMixin:SetIsSighted() -- Always sets sighted to true
		self.sighted       = true
		self.timeSighted   = Shared.GetTime()
		self.originSighted = self:GetOrigin()

		UpdateLOS(self)
	end

	function LOSMixin:CheckIsSighted()
		local parasited = self.GetIsParasited and self:GetIsParasited()
		local timeout   = Shared.GetTime() - self.timeSighted > kLOSTimeout
		local faraway   = (self:GetOrigin() - self.originSighted):GetLengthSquared() > kLOSMaxDistanceSquared
		if self.sighted and not parasited and (
			timeout or
			faraway
		) then
			Log("%s is not longer sighted!", self)
			self.sighted = false
			UpdateLOS(self)
		elseif self.sighted then
			Log("%s, %s, %s", parasited, timeout, faraway)
		end

		return true
	end

	function LOSMixin:OnTeamChange()
		self.sighted = false
		UpdateLOS(self)
	end
else
	function LOSMixin:__initmixin()
	end
end
