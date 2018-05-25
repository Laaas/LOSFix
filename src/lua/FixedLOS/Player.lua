if not Server then return end

local max = math.max

local kMaxViewDistance = kMaxRelevancyDistance * 0.75

local function filter(ent)
    return not ent:isa "Door"
end

local function Iterate(entities, time, dir, origin, team)
	for i = 1, #entities do
		local ent = entities[i]
		if ent.teamNumber ~= team and time - ent.timeSighted > 1 and not ent.fullyCloaked and ent:GetIsVisible() then
			local ent_origin = ent:GetModelOrigin()
			local trace = Shared.TraceRay(origin, ent_origin, CollisionRep.LOS, 0xFFFFFFFF, filter)
			if trace.fraction == 1 then
				ent:SetIsSighted(true)
			end
		end
	end
end

local function Check(self)
	if not self:GetIsAlive() then return end

	local time   = Shared.GetTime()
	local coords = self:GetViewCoords()
	local dir    = coords.zAxis
	local origin = coords.origin
	local team   = self:GetTeamNumber()

	-- Filter is not used here, since it is not possible
	-- for this trace to stop earlier than the ones in Iterate,
	-- so we save performance by not using a trivial filter here
	local trace = Shared.TraceRay(origin, origin + dir * kMaxViewDistance, CollisionRep.LOS, 0xFFFFFFFF)
	local view_distance = max(kMaxViewDistance * trace.fraction - 5, 5)

	for i = 5, view_distance, 5 do
		Iterate(
			Shared.GetEntitiesWithTagInRange("LOS", origin + dir * i, 5),
			time,
			dir,
			origin,
			team
		)
	end

	return true
end

local old = assert(Player.OnInitialized)
function Player:OnInitialized()
	old(self)

	if
		not self:isa "Spectator" and not self:isa "Commander" and
		(self:GetTeamNumber() == 1 or self:GetTeamNumber() == 2)
	then -- other teams can't cause others to be sighted
		self:AddTimedCallback(Check, 0.5)
	end
end
