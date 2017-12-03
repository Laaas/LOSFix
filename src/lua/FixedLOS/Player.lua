if not Server then return end

local kPhysicsMask = 0 -- What can we not see through?
for _, v in ipairs {
	"Default",
	"BigStructures",
	"Whip",
	"CommanderProps",
	"CommanderUnit",
	"CommanderBuild",
} do
	kPhysicsMask = bit.bor(kPhysicsMask, PhysicsGroup[v .. "Group"])
end

local function Iterate(entities, time, dir, origin, team)
	for i = 1, #entities do
		local ent = entities[i]
		if ent:GetTeamNumber() ~= team and time - ent.timeSighted > 1 then
			local ent_origin = ent:GetOrigin()
			local diff       = ent_origin - origin
			local within = math.acos(dir:DotProduct(diff) / diff:GetLength()) < 45 -- length of dir is always 1, we hope
			if within and Shared.TraceRay(origin, ent_origin, CollisionRep.LOS, kPhysicsMask).entity == ent then
				ent:SetIsSighted(true)
			end
		end
	end
end

local function Check(self)
	local time = Shared.GetTime()
	local coords = self:GetViewCoords()
	local dir    = coords.zAxis
	local origin = coords.origin
	local team   = self:GetTeamNumber()

	Iterate(
		Shared.GetEntitiesWithTagInRange("LOS", origin + dir * 5, 10),
		time,
		dir,
		origin,
		team
	)

	Iterate(
		Shared.GetEntitiesWithTagInRange("LOS", origin + dir * 10, 10),
		time,
		dir,
		origin,
		team
	)

	return true
end

local old = Player.OnCreate
function Player:OnCreate()
	old(self)

	self:AddTimedCallback(Check, 0.5)
end
