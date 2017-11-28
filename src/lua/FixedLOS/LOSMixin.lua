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
local kCommanderLOSCheckInterval = 0.5
local kLOSStructureRange         = 8

local kNotRelevantToTeam1Commander = bit.bnot(kRelevantToTeam1Commander)
local kNotRelevantToTeam2Commander = bit.bnot(kRelevantToTeam2Commander)

function LOSMixin:GetIsSighted()
	return self.sighted
end

if Server then
	local function LateInit(self)
		local team = self:GetTeamNumber()

		self.kRelevantToEnemyCommander =
			team == 1 and kRelevantToTeam2Commander or
			team == 2 and kRelevantToTeam1Commander or
			0
		self.kNotRelevantToEnemyCommander = bit.bnot(self.kRelevantToEnemyCommander)

		local mask = self:GetExcludeRelevancyMask()

		self:SetExcludeRelevancyMask(bit.bor(mask,
			team == 1 and kRelevantToTeam1Commander or
			team == 2 and kRelevantToTeam2Commander or
			0
		))
	end

	local function EnemyNear(self)
		return
			#GetEntitiesForTeamWithinRange("Player",  GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kLOSStructureRange) > 0 or
			#GetEntitiesForTeamWithinRange("Drifter", GetEnemyTeamNumber(self:GetTeamNumber()), self:GetOrigin(), kLOSStructureRange) > 0

	end

	local function Sighted(self)
		self.sighted       = true
		self.timeSighted   = Shared.GetTime()
		self.originSighted = self:GetOrigin()

		local mask = self:GetExcludeRelevancyMask()
		self:SetExcludeRelevancyMask(bit.bor(mask, self.kRelevantToEnemyCommander))

		self:OnSighted(true)
	end

	local function NotSighted(self)
		self.sighted = false

		if not EnemyNear(self) then
			local mask = self:GetExcludeRelevancyMask()
			self:SetExcludeRelevancyMask(bit.band(mask, self.kNotRelevantToEnemyCommander))
		end

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

	local function CheckIsVisibleToCommander(self)
		if self.sighted then return true end

		if not (self.GetIsCloaked and self:GetIsCloaked()) and EnemyNear(self) then
			local mask = self:GetExcludeRelevancyMask()
			self:SetExcludeRelevancyMask(bit.bor(mask,  self.kRelevantToEnemyCommander))
		else
			local mask = self:GetExcludeRelevancyMask()
			self:SetExcludeRelevancyMask(bit.band(mask, self.kNotRelevantToEnemyCommander))
		end

		return true
	end

	function LOSMixin:__initmixin()
		self.sighted       = false
		self.timeSighted   = -1000
		self.originSighted = Vector()

		self.kRelevantToEnemyCommander    = 0
		self.kNotRelevantToEnemyCommander = bit.bnot(0)

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
	end

	function LOSMixin:OnDamageDone(_, target)
		if not HasMixin(target, "LOS") then return end
		if target.GetIsAlive and not target:GetIsAlive() then return end
		if target:GetTeamNumber() == self:GetTeamNumber() then return end

		if not target.sighted then
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

	function LOSMixin:OnTeamChange()
		if self.sighted then
			NotSighted(self)
		end
		LateInit(self)
	end

	function LOSMixin:OnKill()
		if self.sighted then
			NotSighted(self)
		end
	end

	LOSMixin.OnUseGorgeTunnel     = LOSMixin.OnKill
	LOSMixin.OnPhaseGateEntry     = LOSMixin.OnKill
	LOSMixin.TriggerBeaconEffects = LOSMixin.OnKill

else
	function LOSMixin:__initmixin()
	end
end
