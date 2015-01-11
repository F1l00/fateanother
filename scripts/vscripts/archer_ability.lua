require("physics")
require("util")

chainTargetsTable = nil
ubwTargets = nil
ubwTargetLoc = nil
ubwCasterPos = nil
ubwCenter = Vector(5600, -4398, 200)

function FarSightVision(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()

	visiondummy = CreateUnitByName("sight_dummy_unit", keys.target_points[1], false, keys.caster, keys.caster, keys.caster:GetTeamNumber())
	if ply.IsEagleEyeAcquired then 
		visiondummy:SetDayTimeVisionRange(1400)
		visiondummy:SetNightTimeVisionRange(1400)
		visiondummy:AddNewModifier(caster, caster, "modifier_item_ward_true_sight", {true_sight_range = 1400}) 
	end

	local unseen = visiondummy:FindAbilityByName("dummy_unit_passive")
	unseen:SetLevel(1)

	if ply.IsHruntingAcquired then
		caster:SwapAbilities("archer_5th_clairvoyance", "archer_5th_hrunting", true, true) 
		Timers:CreateTimer(8, function() return caster:SwapAbilities("archer_5th_clairvoyance", "archer_5th_hrunting", true, false)  end)
	end

	Timers:CreateTimer(8, function() return FarSightEnd(visiondummy) end)
end

function FarSightEnd(dummy)
	dummy:RemoveSelf()
	return nil
end

function KBStart(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ply = caster:GetPlayerOwner()

	local info = {
		Target = target, -- chainTarget
		Source = caster, -- chainSource
		Ability = ability,
		EffectName = "particles/units/heroes/hero_queenofpain/queen_shadow_strike.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 1000
	}
	ProjectileManager:CreateTrackingProjectile(info) 
	
	if ply.IsOveredgeAcquired and caster.OveredgeCount < 3 then
		caster.OveredgeCount = caster.OveredgeCount + 1
	elseif hero.OveredgeCount == 3 then 
		if caster:GetAbilityByIndex(3):GetName() ~= "archer_5th_overedge" then
			hero:SwapAbilities("rubick_empty1", "archer_5th_overedge", true, true) 
		end
	end

	if ply.IsProjectionImproved and caster:HasModifier("modifier_ubw_death_checker") then
		keys.ability:StartCooldown(2.0)
	end
end

function KBHit(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local KBCount = 0

	Timers:CreateTimer(function() 
		if KBCount == 4 then return end
		DoDamage(keys.caster, keys.target, keys.DamagePerTick , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)

		caster:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
		KBCount = KBCount + 1
		return 0.25
	end)
end


function BPHit(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	DoDamage(caster, target, keys.TargetDamage, DAMAGE_TYPE_MAGICAL, 0, ability, false)

	local targets = FindUnitsInRadius(caster:GetTeam(), target:GetOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
         DoDamage(caster, v, keys.SplashDamage, DAMAGE_TYPE_MAGICAL, 0, ability, false)
    end


    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
    ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin())
	--ParticleManager:SetParticleControl(particle, 3, target:GetAbsOrigin()) -- target location

	target:AddNewModifier(caster, target, "modifier_stunned", {Duration = keys.StunDuration})
end

rhoTarget = nil

function OnRhoStart(keys)
	local target = keys.target
	rhoTarget = target 
	target.rhoShieldAmount = keys.ShieldAmount
	EmitGlobalSound("Archer.RhoAias" ) --[[Returns:void
	Play named sound for all players
	]]
end

function OnRhoDamaged(keys)
	local currentHealth = rhoTarget:GetHealth() 


	rhoTarget.rhoShieldAmount = rhoTarget.rhoShieldAmount - keys.DamageTaken
	if rhoTarget.rhoShieldAmount <= 0 then
		if currentHealth + rhoTarget.rhoShieldAmount <= 0 then
			print("lethal")
		else
			print("rho broken, but not lethal")
			rhoTarget:RemoveModifierByName("modifier_rho_aias_shield")
			rhoTarget:SetHealth(currentHealth + keys.DamageTaken + rhoTarget.rhoShieldAmount)
			rhoTarget.rhoShieldAmount = 0
		end
	else
		print("rho not broken, remaining shield : " .. rhoTarget.rhoShieldAmount)
		rhoTarget:SetHealth(currentHealth + keys.DamageTaken)
	end
end

function OnUBWCastStart(keys)
	EmitGlobalSound("Archer.UBW")
	Timers:CreateTimer({
		endTime = 2,
		callback = function()
		if keys.caster:IsAlive() then 
			OnUBWStart(keys)
			keys.ability:ApplyDataDrivenModifier(keys.caster, keys.caster, "modifier_ubw_death_checker",{})
		end
	end
	})
	ArcherCheckCombo(keys.caster, keys.ability)
end

function OnUBWStart(keys)
	local caster = keys.caster
	local ability = keys.ability
	ubwTargets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	ubwTargetLoc = {}
	local diff = nil
	local ubwTargetPos = nil
	ubwCasterPos = caster:GetAbsOrigin()
	
	local info = {
		Target = nil,
		Source = nil, 
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf",
		vSpawnOrigin = ubwCenter + Vector(RandomFloat(-800,800),RandomFloat(-800,800), 500),
		iMoveSpeed = 1000
	}
	-- record location of units and move them into UBW(center location : 6000, -4000, 200)
	for i=1, #ubwTargets do
		ubwTargetPos = ubwTargets[i]:GetAbsOrigin()
        ubwTargetLoc[i] = ubwTargetPos
        diff = (ubwCasterPos - ubwTargetPos) -- rescale difference to UBW size(1200)
        ubwTargets[i]:SetAbsOrigin(ubwCenter - diff)
		FindClearSpaceForUnit(ubwTargets[i], ubwTargets[i]:GetAbsOrigin(), true)
    end

    -- swap Archer's skillset with UBW ones
    caster:SwapAbilities("archer_5th_clairvoyance", "archer_5th_sword_barrage", true, true) 
    caster:SwapAbilities("archer_5th_broken_phantasm", "archer_5th_rule_breaker", true, true) 
    caster:SwapAbilities("archer_5th_ubw", "archer_5th_nine_lives", true, true) 

    -- DUN DUN DUN DUN
	Timers:CreateTimer(function() 
		if caster:IsAlive() and caster:HasModifier("modifier_ubw_death_checker") then
			EmitGlobalSound("Archer.UBWAmbient")
		else return end 
		return 3.0 
	end)


	local ubwdummy1 = CreateUnitByName("dummy_unit", Vector(5500,-3500,500), false, caster, caster, caster:GetTeamNumber())
	local ubwdummy2 = CreateUnitByName("dummy_unit", Vector(5500,-4500, 500), false, caster, caster, caster:GetTeamNumber())
	local ubwdummy3 = CreateUnitByName("dummy_unit", Vector(6500,-3500, 500), false, caster, caster, caster:GetTeamNumber())
	local ubwdummy4 = CreateUnitByName("dummy_unit", Vector(6500,-4500, 500), false, caster, caster, caster:GetTeamNumber())
	local ubwdummies = {ubwdummy1, ubwdummy2, ubwdummy3, ubwdummy4}
	for i=1, #ubwdummies do
		ubwdummies[i]:FindAbilityByName("dummy_unit_passive"):SetLevel(1)
	end

	Timers:CreateTimer(function() 
		if caster:IsAlive() and caster:HasModifier("modifier_ubw_death_checker") then
			local weaponTargets = FindUnitsInRadius(caster:GetTeam(), ubwCenter, nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
            for i=1, #weaponTargets do
            	if weaponTargets[i]:GetTeam() ~= caster:GetTeam() then
            		info.Target = weaponTargets[i]
            		info.Source = ubwdummies[RandomInt(1,4)]
            		break
            	end
            end
            ProjectileManager:CreateTrackingProjectile(info) 
		else return end 
		return 0.1
	end)

	Timers:CreateTimer("ubw_timer", {
	    endTime = 12,
	    callback = function()
		if caster:IsAlive() and caster:HasModifier("modifier_ubw_death_checker")  then 
			EndUBW(caster)
		end
	end
	})
end

function EndUBW(caster)
    caster:SwapAbilities("archer_5th_clairvoyance", "archer_5th_sword_barrage", true, true) 
    caster:SwapAbilities("archer_5th_broken_phantasm", "archer_5th_rule_breaker", true, true) 
    caster:SwapAbilities("archer_5th_ubw", "archer_5th_nine_lives", true, true) 


    local units = FindUnitsInRadius(caster:GetTeam(), ubwCenter, nil, 1300
    , DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)

    for i=1, #units do
    	local IsUnitGeneratedInUBW = true
    	for j=1, #ubwTargets do
    		if units[i] == ubwTargets[j] then
    			units[i]:SetAbsOrigin(ubwTargetLoc[j]) 
    			FindClearSpaceForUnit(units[i], units[i]:GetAbsOrigin(), true)
    			IsUnitGeneratedInUBW = false
    			break 
    		end
    	end 
    	if IsUnitGeneratedInUBW then
    		diff = ubwCenter - units[i]:GetAbsOrigin()
    		units[i]:SetAbsOrigin(ubwCasterPos - diff)
    		FindClearSpaceForUnit(units[i], units[i]:GetAbsOrigin(), true) 
    	end 
    end

    ubwTargets = nil
    ubwTargetLoc = nil

    Timers:RemoveTimer("ubw_timer")
end
-- combo
function OnRainStart(keys)
	local caster = keys.caster
	local ascendCount = 0
	local descendCount = 0
	local radius = 1200

	local info = {
		Target = nil,
		Source = caster, 
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_clinkz/clinkz_searing_arrow.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 3000
	}

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 4.0)

	Timers:CreateTimer('rain_ascend', {
		endTime = 0,
		callback = function()
	   	if ascendCount == 30 then return end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z+22))
		ascendCount = ascendCount + 1;
		return 0.01
	end
	})

	local barrageCount = 0
	Timers:CreateTimer(0.3, function()
		if barrageCount == 30 then return end
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_luna/luna_lucent_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		
		arrowVector = Vector(RandomFloat(-radius, radius), RandomFloat(-radius, radius), 0)

		ParticleManager:SetParticleControl(particle, 0, ubwCenter + arrowVector)
		ParticleManager:SetParticleControl(particle, 1, ubwCenter + arrowVector)
		ParticleManager:SetParticleControl(particle, 5, ubwCenter + arrowVector)
		ParticleManager:SetParticleControl(particle, 6, ubwCenter + arrowVector)
		local targets = FindUnitsInRadius(caster:GetTeam(), ubwCenter + arrowVector, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
		for k,v in pairs(targets) do
        	DoDamage(caster, v, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
		end
	    barrageCount = barrageCount + 1
		return 0.1
    end)

	local bpCount = 0 
	Timers:CreateTimer(3.3, function()
		if bpCount == 5 then return end
		local units = FindUnitsInRadius(caster:GetTeam(), ubwCenter, nil, 1300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		info.Target = units[math.random(#units)]
		if info.Target ~= nil then 
			ProjectileManager:CreateTrackingProjectile(info) 
		end
		bpCount = bpCount + 1
		return 0.1
    end)

	Timers:CreateTimer('rain_descend', {
		endTime = 3.7,
		callback = function()
	   	if descendCount == 30 then return end
		caster:SetAbsOrigin(Vector(caster:GetAbsOrigin().x,caster:GetAbsOrigin().y,caster:GetAbsOrigin().z-22))
		descendCount = descendCount + 1;
		return 0.01
	end
	})
end

function OnArrowRainBPHit(keys)
	local caster = keys.caster
	local ability = caster:FindAbilityByName("archer_5th_broken_phantasm")
	local targetdmg = ability:GetLevelSpecialValueFor("target_damage", ability:GetLevel())
	local splashdmg = ability:GetLevelSpecialValueFor("splash_damage", ability:GetLevel())
	local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel())
	local stunDuration = ability:GetLevelSpecialValueFor("stun_duration", ability:GetLevel())

	DoDamage(caster, keys.target, targetdmg , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	local targets = FindUnitsInRadius(caster:GetTeam(), keys.target:GetOrigin(), nil, radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
	for k,v in pairs(targets) do
         DoDamage(caster, v, splashdmg, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
    end
    local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_sven/sven_storm_bolt_projectile_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, keys.target)
    ParticleManager:SetParticleControl(particle, 3, keys.target:GetAbsOrigin())
	keys.target:AddNewModifier(caster, keys.target, "modifier_stunned", {Duration = stunDuration})
end

function OnUBWWeaponHit(keys)
	if keys.caster:GetPlayerOwner().IsProjectionImproved then 
		keys.Damage = keys.Damage + 10
	end	
	DoDamage(keys.caster, keys.target, keys.Damage , DAMAGE_TYPE_PHYSICAL, 0, keys.ability, false)
end

function OnUBWDeath(keys)
	local caster = keys.caster
	EndUBW(caster)
end

function OnUBWBarrageStart(keys)
	local caster = keys.caster
	local targetPoint = keys.target_points[1]
	local radius = keys.Radius
	local ply = caster:GetPlayerOwner()
	if ply.IsProjectionImproved then 
		keys.Damage = keys.Damage + 100
	end	

	local barrageCount = 0
	Timers:CreateTimer(function()
		if barrageCount == 25 then return end
		if caster:HasModifier("modifier_sword_barrage") then
			local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_luna/luna_lucent_beam.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			
			swordVector = Vector(RandomFloat(-radius, radius), RandomFloat(-radius, radius), 0)

			ParticleManager:SetParticleControl(particle, 0, targetPoint + swordVector)
			ParticleManager:SetParticleControl(particle, 1, targetPoint + swordVector)
			ParticleManager:SetParticleControl(particle, 5, targetPoint + swordVector)
			ParticleManager:SetParticleControl(particle, 6, targetPoint + swordVector)
			local targets = FindUnitsInRadius(caster:GetTeam(), targetPoint + swordVector, nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false) 
			for k,v in pairs(targets) do
	        	DoDamage(caster, v, keys.Damage , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	        	v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 0.1})
			end
		    barrageCount = barrageCount + 1
			return 0.08
		end
    end)
end

function OnBarrageCanceled(keys)
	keys.caster:RemoveModifierByName("modifier_sword_barrage")
end

function OnUBWRBStart(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	if ply.IsProjectionImproved then 
		keys.StunDuration = keys.StunDuration + 0.2
		giveUnitDataDrivenModifier(caster, keys.target, "rb_sealdisabled", 2.0)
	end
	keys.target:AddNewModifier(caster, target, "modifier_stunned", {duration = keys.StunDuration})
	EmitGlobalSound("Caster.RuleBreaker") 
end

function OnUBWNineStart(keys)
	local caster = keys.caster
	local travelCounter = 0
	local targetPoint = keys.target_points[1]
	local ply = caster:GetPlayerOwner()

	local archer = Physics:Unit(caster)
	local origin = caster:GetAbsOrigin()
	local distance = (targetPoint - origin):Length2D()
	local forward = (targetPoint - origin):Normalized() * distance
	EmitGlobalSound("Archer.NineLives" )

	caster:SetPhysicsFriction(0)
	caster:SetPhysicsVelocity(forward)
	caster:SetNavCollisionType(PHYSICS_NAV_BOUNCE)

	giveUnitDataDrivenModifier(caster, caster, "nine_pause", 2.0)
	Timers:CreateTimer(1.00, function() 
		if caster:HasModifier("modifier_ubw_nine_anim") == false then
			OnUBWNineLanded(caster, keys.ability) 
		end
	return end)

	caster:OnPhysicsFrame(function(unit)
		local diff = unit:GetAbsOrigin() - origin
		print(distance .. " and " .. diff:Length2D())
		if diff:Length2D() > distance then
			unit:PreventDI(false)
			unit:OnPhysicsFrame(nil)
			unit:SetPhysicsVelocity(Vector(0,0,0))
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			unit:OnPhysicsFrame(nil)
		end
	end)

	caster:OnPreBounce(function(unit, normal) -- stop the pushback when unit hits wall
		OnUBWNineLanded(caster, keys.ability)
		unit:OnPreBounce(nil)
		unit:SetBounceMultiplier(0)
		unit:PreventDI(false)
		unit:SetPhysicsVelocity(Vector(0,0,0))
		FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		unit:OnPreBounce(nil)
	end)
end

function OnUBWNineLanded(caster, ability)
	local tickdmg = ability:GetLevelSpecialValueFor("damage", ability:GetLevel() - 1)
	local lasthitdmg = ability:GetLevelSpecialValueFor("damage_lasthit", ability:GetLevel() - 1)
	local radius = ability:GetSpecialValueFor("radius")
	local lasthitradius = ability:GetSpecialValueFor("radius_lasthit")
	local stun = ability:GetSpecialValueFor("stun_duration")
	local nineCounter = 0

	local ply = caster:GetPlayerOwner()
	if ply.IsProjectionImproved then 
		tickdmg = tickdmg + 15
		lasthitdmg = lasthitdmg + 200
	end

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_nine_anim", {})
	Timers:CreateTimer(function()
		if caster:IsAlive() then -- only perform actions while caster stays alive
			if nineCounter == 8 then -- if nine is finished
				EmitGlobalSound("Berserker.Roar") 
				caster:RemoveModifierByName("nine_pause") 
				local lasthitTargets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, lasthitradius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 1, false)
				for k,v in pairs(lasthitTargets) do
					DoDamage(caster, v, lasthitdmg , DAMAGE_TYPE_MAGICAL, 0, ability, false)
					v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.0})
				end
				local lasthitparticle1 = ParticleManager:CreateParticle("particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_magma_low_egset.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	   			ParticleManager:SetParticleControl(lasthitparticle1, 1, caster:GetAbsOrigin())
	   			local lasthitparticle2 = ParticleManager:CreateParticle("particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_aftershock_warp_egset.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	   			ParticleManager:SetParticleControl(lasthitparticle2, 1, caster:GetAbsOrigin())
				return 
			end
			
			local targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 1, false)
			for k,v in pairs(targets) do
				DoDamage(caster, v, tickdmg , DAMAGE_TYPE_MAGICAL, 0, ability, false)
				v:AddNewModifier(caster, v, "modifier_stunned", {Duration = 1.0})
			end

			local particle1 = ParticleManager:CreateParticle("particles/econ/items/earthshaker/egteam_set/hero_earthshaker_egset/earthshaker_echoslam_start_magma_cracks_egset.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle1, 1, caster:GetAbsOrigin())
			local particle2 = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start_f_fallback_low.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(particle2, 1, caster:GetAbsOrigin())
			nineCounter = nineCounter + 1
			print(nineCounter)
			return 0.12
		end 
	end)
end

function OnHruntStart(keys)
	local caster = keys.caster
	caster.HruntDamage =  250 + caster:FindAbilityByName("archer_5th_broken_phantasm"):GetLevel() * 100  + caster:GetMana()
	caster:SetMana(0) 
	local info = {
		Target = keys.target,
		Source = keys.caster, 
		Ability = keys.ability,
		EffectName = "particles/units/heroes/hero_chaos_knight/chaos_knight_chaos_bolt.vpcf",
		vSpawnOrigin = caster:GetAbsOrigin(),
		iMoveSpeed = 3000
	}
	ProjectileManager:CreateTrackingProjectile(info) 
end

function OnHruntHit(keys)
	local caster = keys.caster
	DoDamage(keys.caster, keys.target, keys.caster.HruntDamage, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	local targets = FindUnitsInRadius(caster:GetTeam(), keys.target:GetAbsOrigin(), nil, 1000
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_CLOSEST, false)
	for k,v in pairs(targets) do
		DoDamage(keys.caster, v, keys.caster.HruntDamage/2, DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	end
end

function OnOveredgeStart(keys)
	local caster = keys.caster 
	local targetPoint = keys.target_points[1]
	local dist = (caster:GetAbsOrigin() - targetPoint):Length2D() * 10/6

	giveUnitDataDrivenModifier(caster, caster, "jump_pause", 0.59)
	caster:SwapAbilities("rubick_empty1", "archer_5th_overedge", true, true) 
    local archer = Physics:Unit(caster)
    caster:PreventDI()
    caster:SetPhysicsFriction(0)
    caster:SetPhysicsVelocity(Vector(caster:GetForwardVector().x * dist, caster:GetForwardVector().y * dist, 400))
    caster:SetNavCollisionType(PHYSICS_NAV_NOTHING)
    caster:FollowNavMesh(false)	
    caster:SetAutoUnstuck(false)

	Timers:CreateTimer({
		endTime = 0.3,
		callback = function()
		print("ascend")
		caster:SetPhysicsVelocity(Vector(caster:GetForwardVector().x * dist, caster:GetForwardVector().y * dist, -400))
	end
	})

	Timers:CreateTimer({
		endTime = 0.6,
		callback = function()
		print("descend")
		caster:PreventDI(false)
		caster:SetPhysicsVelocity(Vector(0,0,0))
		caster:SetAutoUnstuck(true)
        FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)

        local targets = FindUnitsInRadius(caster:GetTeam(), caster:GetOrigin(), nil, keys.Radius
            , DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, FIND_ANY_ORDER, false)
		for k,v in pairs(targets) do
	         DoDamage(caster, v, 700 + 20 * caster:GetIntellect() , DAMAGE_TYPE_MAGICAL, 0, keys.ability, false)
	    end
	end
	})
end


function ArcherCheckCombo(caster, ability)
	if ability == caster:FindAbilityByName("archer_5th_ubw") then
		caster:SwapAbilities("archer_5th_rho_aias", "archer_5th_arrow_rain", true, true) 
	end
	Timers:CreateTimer({
		endTime = 5,
		callback = function()
		caster:SwapAbilities("archer_5th_rho_aias", "archer_5th_arrow_rain", true, true) 
	end
	})
end

function OnEagleEyeAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:SetDayTimeVisionRange(hero:GetDayTimeVisionRange() + 200)
	hero:SetNightTimeVisionRange(hero:GetNightTimeVisionRange() + 200) 
	ply.IsEagleEyeAcquired = true
end

function OnHruntingAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	ply.IsHruntingAcquired = true
end

function OnShroudOfMartinAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	hero:SetPhysicalArmorBaseValue(hero:GetPhysicalArmorBaseValue() + 10) 
	hero:SetBaseMagicalResistanceValue(0.15)
	ply.IsMartinAcquired = true
end

function OnImproveProjectionAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	ply.IsProjectionImproved = true
end

function OnOveredgeAcquired(keys)
	local caster = keys.caster
	local ply = caster:GetPlayerOwner()
	local hero = caster:GetPlayerOwner():GetAssignedHero()
	ply.IsOveredgeAcquired = true
	hero.OveredgeCount = 0

	Timers:CreateTimer(function()  
		if ply.IsOveredgeAcquired and hero.OveredgeCount < 3 then
			caster.OveredgeCount = caster.OveredgeCount + 1
		elseif hero.OveredgeCount == 3 then 
			if caster:GetAbilityByIndex(3):GetName() ~= "archer_5th_overedge" then
				hero:SwapAbilities("rubick_empty1", "archer_5th_overedge", true, true) 
			end
		end
		return 20
	end)

end