require("physics")
require("util")
TPLocation = nil
cdummy = nil

function PotInstantHeal(keys)
	local caster = keys.caster
	caster:Heal(500, caster)
	caster:GiveMana(300) 

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification_g.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin()) -- target effect location

end

function TPScroll(keys)
	local caster = keys.caster
	local targetPoint = keys.target_points[1]
	local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint, nil, 1500
            , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
		if v:GetName() == "npc_dota_ward_base" then
			TPLocation = v 
		end
		return
	end
end

function TPSuccess(keys)
	local caster = keys.caster
	caster:SetAbsOrigin(TPLocation:GetAbsOrigin())
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end

function MassTPSuccess(keys)
	local caster = keys.caster
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1000
            , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)	
	for k,v in pairs(targets) do
		v:SetAbsOrigin(TPLocation:GetAbsOrigin())
		FindClearSpaceForUnit(v, v:GetAbsOrigin(), true)
	end

end

function TPFail(keys)
end

function WardFam(keys)
	local caster = keys.caster
	local targetPoint = keys.target_points[1]
	local ward = CreateUnitByName("ward_familiar", targetPoint, true, caster, caster, caster:GetTeamNumber())
	ward:AddNewModifier(caster, caster, "modifier_invisible", {}) 
	ward:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 1600}) 
	Timers:CreateTimer({
		endTime = 105,
		callback = function()
		if ward:IsAlive() then ward:RemoveSelf() return end
	end
	})
end

function ScoutFam(keys)
	local caster = keys.caster
	local pid = caster:GetPlayerID()
	local scout = CreateUnitByName("scout_familiar", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
	scout:SetControllableByPlayer(pid, true)
	keys.ability:ApplyDataDrivenModifier(caster, scout, "modifier_banished", {}) 
	Timers:CreateTimer({
		endTime = 40,
		callback = function()
		if scout:IsAlive() then scout:RemoveSelf() return end
	end
	})
end

function BecomeWard(keys)
	local caster = keys.caster
	local transform = CreateUnitByName("ward_familiar", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())

	transform:AddNewModifier(caster, caster, "modifier_invisible", {}) 
	transform:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 1600}) 
	
	Timers:CreateTimer({
		endTime = 0.1,
		callback = function()
		caster:RemoveSelf() 
		return
	end
	})
	Timers:CreateTimer({
		endTime = 105,
		callback = function()
		if transform:IsAlive() then transform:RemoveSelf() return end
	end
	})
end

function SpiritLink(keys)
	local caster = keys.caster
	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 1000
            , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, 0, FIND_CLOSEST, false)
	local linkTargets = {}
	-- set up table for link
	for i=1,5 do
		if targets[i] == nil then 
			break
		end
		linkTargets[i] = targets[i]
	end
	-- add list of linked targets to hero table
	for i=1,5 do
		if targets[i] == nil then 
			break
		end		
		targets[i].linkTable = linkTargets
		print(targets[i]:GetName())
		keys.ability:ApplyDataDrivenModifier(caster, targets[i], "modifier_share_damage", {}) 
	end
end

function OnLinkDamageTaken(keys)

end

function GemOfResonance(keys)
	-- body
end

function Blink(keys)
	local caster = keys.caster
	local targetPoint = keys.target_points[1]
	local diff = targetPoint - caster:GetAbsOrigin()
	local particle = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 1, caster:GetAbsOrigin()) -- target effect location
	caster:EmitSound("DOTA_Item.BlinkDagger.Activate")

	if diff:Length() <= 1000 then caster:SetAbsOrigin(targetPoint)
	else  caster:SetAbsOrigin(caster:GetAbsOrigin() + diff:Normalized() * 1000) end

	local particle2 = ParticleManager:CreateParticle("particles/items_fx/blink_dagger_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle2, 1, caster:GetAbsOrigin()) -- target effect location
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
end


function CScroll(keys)
	local caster = keys.caster
	local pid = caster:GetPlayerID()
	cdummy = CreateUnitByName("dummy_unit", caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
	ccaster = caster
	local dummy_passive = cdummy:FindAbilityByName("dummy_unit_passive")
	dummy_passive:SetLevel(1)
	local fire = cdummy:FindAbilityByName("dummy_c_scroll")
	fire:SetLevel(1)
	if fire:IsFullyCastable() then 
		cdummy:CastAbilityOnTarget(keys.target, fire, pid)
	end

	caster:RemoveItem(keys.ability)
end

function CScrollHit(keys)
	keys.target:AddNewModifier(keys.caster:GetPlayerOwner():GetAssignedHero(), keys.target, "modifier_stunned", {Duration = 1.0}) 
	--keys.caster:RemoveSelf()
end


function BScroll(keys)
	local caster = keys.caster
	caster.BShieldAmount = keys.ShieldAmount
	

end

function AScroll(keys)
	local caster = keys.caster
	local particle = ParticleManager:CreateParticle("particles/prototype_fx/item_linkens_buff_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end

function SScroll(keys)
	local caster = keys.caster
	local target = keys.target
	local lightning = {
		attacker = caster,
		victim = target,
		damage = 400,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = 0,
		ability = keys.ability
	}
	ApplyDamage(lightning) 
	ApplyPurge(target)
	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_slow_tier1", {Duration = 0.5}) 
	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_slow_tier2", {Duration = 1.0}) 
	local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_OVERHEAD_FOLLOW, caster) -- a bit bad right now
	ParticleManager:SetParticleControl(bolt, 1, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z+((target:GetBoundingMaxs().z - target:GetBoundingMins().z)/2)))
end

function EXScroll(keys)
	local caster = keys.caster
	local target = keys.target
	local lightning = {
		attacker = caster,
		victim = target,
		damage = 600,
		damage_type = DAMAGE_TYPE_MAGICAL,
		damage_flags = 0,
		ability = keys.ability
	}
	ApplyPurge(target)
	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_slow_tier1", {Duration = 1.0}) 
	keys.ability:ApplyDataDrivenModifier(caster, target, "modifier_slow_tier2", {Duration = 2.0}) 

	local bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_OVERHEAD_FOLLOW, caster) -- a bit bad right now
	ParticleManager:SetParticleControl(bolt, 1, Vector(target:GetAbsOrigin().x,target:GetAbsOrigin().y,target:GetAbsOrigin().z+((target:GetBoundingMaxs().z - target:GetBoundingMins().z)/2)))
	local forkCount = 0
	local dist = target:GetAbsOrigin() - caster:GetAbsOrigin()
	ApplyDamage(lightning)

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin() + dist:Normalized() * dist:Length2D() + 350 , nil, 700
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
		if forkCount == 4 then return end
		if v ~= target then 
	        lightning.victim = v
	        ApplyDamage(lightning) 
	        bolt = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_OVERHEAD_FOLLOW, caster) 
	        ParticleManager:SetParticleControl(bolt, 1, Vector(v:GetAbsOrigin().x,v:GetAbsOrigin().y,v:GetAbsOrigin().z+((v:GetBoundingMaxs().z - v:GetBoundingMins().z)/2)))
	        forkCount = forkCount + 1
    	end
    end
end



function HealingScroll(keys)
	local caster = keys.caster
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification_g.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, 600
            , DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
		print("heal")
		ParticleManager:SetParticleControl(particle, 1, v:GetAbsOrigin()) -- target effect location
         v:Heal(500, caster) 
    end
end

function satyr_purge(caster, target)
	caster:AddAbility("satyr_trickster_purge")
	local ability = caster:FindAbilityByName("satyr_trickster_purge")
	ability:SetLevel(1)
	caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
	caster:RemoveAbility("satyr_trickster_purge")
end