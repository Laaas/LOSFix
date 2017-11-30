Script.Load "lua/Globals.lua"

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

local kLOSTimeout                = 2
local kLOSMaxDistanceSquared     = 7^2
local kLOSCheckInterval          = 0.2
local kCommanderLOSCheckInterval = 0.5 -- also present in Player.lua

local kNotRelevantToTeam1Commander = bit.bnot(kRelevantToTeam1Commander)
local kNotRelevantToTeam2Commander = bit.bnot(kRelevantToTeam2Commander)

local rel_mask = "exclude_relevancy_mask_not_sighted"

function LOSMixin:GetIsSighted()
	return self.sighted
end

if Server then
	local function LateInit(self)
		local team = self:GetTeamNumber()

		self[rel_mask] = bit.bor(
			kRelevantToTeam1Unit,
			kRelevantToTeam2Unit,
			kRelevantToReadyRoom,

			team == 1 and kRelevantToTeam1Commander or
			team == 2 and kRelevantToTeam2Commander or
			0
		)
		self:SetExcludeRelevancyMask(self[rel_mask])
	end

	local function CheckIsVisibleToCommander(self)
		if self.sighted == false and Shared.GetTime() - self.commanderSighted > 0.55 then
			self:SetExcludeRelevancyMask(self[rel_mask] or 0)
		end

		return true
	end

	local function Sighted(self)
		self.timeSighted   = Shared.GetTime()
		self.originSighted = self:GetOrigin()

		self:SetExcludeRelevancyMask(0x1F)

		self:OnSighted(true)
	end

	local function NotSighted(self)
		CheckIsVisibleToCommander(self)
		self:OnSighted(false)
	end

	local function CheckIsSighted(self)
		if self.sighted and not (self.GetIsParasited and self:GetIsParasited()) and (
			Shared.GetTime() - self.timeSighted > kLOSTimeout or
			(self:GetOrigin() - self.originSighted):GetLengthSquared() > kLOSMaxDistanceSquared
		) then
			NotSighted(self)
		end

		return true
	end

	function LOSMixin:__initmixin()
		self.commanderSighted = 0
		self.timeSighted      = 0
		self.originSighted    = Vector()

		LateInit(self)

		self:OnSighted(false)

		self:AddTimedCallback(LateInit, 0)
		self:AddTimedCallback(CheckIsSighted,            kLOSCheckInterval)
		self:AddTimedCallback(CheckIsVisibleToCommander, kCommanderLOSCheckInterval)
	end

	function LOSMixin:OnSighted(sighted)
		self.sighted = sighted
	end

	function LOSMixin:OnDamageDone(_, target)
		if not HasMixin(target, "LOS") then return end
		if target.GetIsAlive and not target:GetIsAlive() then return end
		if target:GetTeamNumber() == self:GetTeamNumber() then return end

		Sighted(target)
	end

	function LOSMixin:SetIsSighted(sighted)
		if sighted then
			Sighted(self)
		else
			NotSighted(self)
		end
	end

	function LOSMixin:OnKill()
		NotSighted(self)
	end

	LOSMixin.OnUseGorgeTunnel     = LOSMixin.OnKill
	LOSMixin.OnPhaseGateEntry     = LOSMixin.OnKill
	LOSMixin.TriggerBeaconEffects = LOSMixin.OnKill
	LOSMixin.OnTeamChange         = LOSMixin.OnKill

else
	function LOSMixin:__initmixin()
	end
end
