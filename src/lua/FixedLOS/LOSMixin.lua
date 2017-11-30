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

function LOSMixin:GetIsSighted()
	return self.sighted
end

if Server then
	local function LateInit(self)
		local team = self:GetTeamNumber()

		self.exclude_relevancy_mask_not_sighted = bit.bor(
			kRelevantToTeam1Unit,
			kRelevantToTeam2Unit,
			kRelevantToReadyRoom,

			team == 1 and kRelevantToTeam1Commander or
			team == 2 and kRelevantToTeam2Commander or
			0
		)
		self:SetExcludeRelevancyMask(self.exclude_relevancy_mask_not_sighted)
	end

	local function CheckIsVisibleToCommander(self)
		if Shared.GetTime() - self.commanderSighted > 0.55 then
			self:SetExcludeRelevancyMask(self.exclude_relevancy_mask_not_sighted)
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
		self.commanderSighted = -1000
		self.drifterScanned   = -1000
		self.timeSighted      = -1000
		self.originSighted    = Vector()

		self:SetExcludeRelevancyMask(bit.bor(
			kRelevantToTeam1Unit,
			kRelevantToTeam2Unit,
			kRelevantToReadyRoom
		))

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

		if target.sighted == false then
			Sighted(target)
		end
	end

	function LOSMixin:SetIsSighted(sighted)
		local old = self.sighted

		if old ~= sighted then
			if sighted then
				Sighted(self)
			else
				NotSighted(self)
			end
		end
	end

	function LOSMixin:OnKill()
		if self.sighted then
			NotSighted(self)
		end
	end

	LOSMixin.OnUseGorgeTunnel     = LOSMixin.OnKill
	LOSMixin.OnPhaseGateEntry     = LOSMixin.OnKill
	LOSMixin.TriggerBeaconEffects = LOSMixin.OnKill
	LOSMixin.OnTeamChange         = LOSMixin.OnKill

else
	function LOSMixin:__initmixin()
	end
end
