function OnIskanderCharismaStart(keys)
	local caster = keys.caster
	StartCharismaTimer(keys)
	print("charisma start")
end

function OnIskanderCharismaDeath(keys)
	local caster = keys.caster
	Timers:RemoveTimer("charisma_passive_timer")
	print("charisma end")
end

function OnIskanderCharismaRespawn(keys)
	local caster = keys.caster
	StartCharismaTimer(keys)
end

function StartCharismaTimer(keys)
	local caster = keys.caster
	Timers:CreateTimer('charisma_passive_timer', {
		endTime = 0,
		callback = function()
		local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.Radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
			if v ~= caster then 
				if IsFacingUnit(v, caster, 120) then
					keys.ability:ApplyDataDrivenModifier(caster,v, "modifier_charisma_movespeed", {})
				end
			end
			
	    end
	    return 0.25
	end})
end
function OnForwardStart(keys)
	local caster = keys.caster
	
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_press_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin() )

	
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.Radius
        , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

	for k,v in pairs(targets) do
		keys.ability:ApplyDataDrivenModifier(caster,v, "modifier_forward", {})
		v:EmitSound("Hero_LegionCommander.Overwhelming.Location")
    end
end

function OnPhalanxStart(keys)
	local caster = keys.caster
    local targetPoint = keys.target_points[1]
    local forwardVec = caster:GetForwardVector()


	local leftvec = Vector(-forwardVec.y, forwardVec.x, 0)
	local rightvec = Vector(forwardVec.y, -forwardVec.x, 0)

	-- Spawn soldiers from target point to left end
	for i=0,3 do
		local soldier = CreateUnitByName("iskander_phalanx_soldier", targetPoint + leftvec * 75 * i, true, nil, nil, caster:GetTeamNumber())
		soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = 3})
		soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
	end

	-- Spawn soldiers on right side
	for i=1,4 do
		local soldier = CreateUnitByName("iskander_phalanx_soldier", targetPoint + rightvec * 75 * i, true, nil, nil, caster:GetTeamNumber())
		soldier:AddNewModifier(caster, nil, "modifier_kill", {duration = 3})
		soldier:EmitSound("Hero_LegionCommander.Overwhelming.Location")
	end
end

function OnChariotStart(keys)
	local caster = keys.caster
	EmitGlobalSound("Iskander.Charge")
end

function OnChariotChargeStart(keys)
end

function OnAOTKStart(keys)
	local caster = keys.caster
	EmitGlobalSound("Iskander.AOTK")
end

function OnCavalrySummon(keys)
end

function OnMageSummon(keys)
end

function OnBattleHornStart(keys)
end

function OnHammerStart(keys)
end

function OnBrillianceStart(keys)
end 

function OnAnnihilateStart(keys)
end

function OnIskanderCharismaImproved(keys)
end

function OnThundergodAcquired(keys)
end

function OnChariotChargeAcquired(keys)
end

function OnBeyondTimeAcquired(keys)
end