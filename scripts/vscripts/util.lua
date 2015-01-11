purgable = {"modifier_aspd_increase",
        "modifier_courage_self_buff",
        "modifier_berserk_self_buff",
        "modifier_ta_self_mod",
        "modifier_berserk_scroll",
        "modifier_share_damage",
        "modifier_a_plus_armor",
        "modifier_speed_gem",
        "modifier_share_damage"}
goesthruB = {"saber_avalon",
            "archer_5th_hrunting",
            "avenger_berg_avesta",
            "gilgamesh_gate_of_babylon",
            "false_assassin_quickdraw",
            "saber_alter_max_mana_burst",
            "archer_5th_overedge"}

-- Calculates the angle from caster to target(in radian, multiply it by 180/math.pi for degree)
function CalculateAngle(u, v)
    local angle = 0
    local dotproduct = u.x * v.x + u.y * v.y
    local cosangle = dotproduct/(u:Length2D()*v:Length2D()) 
    return math.acos(cosangle)
end

-- Apply a modifier from item
function giveUnitDataDrivenModifier(source, target, modifier,dur)
    --source and target should be hscript-units. The same unit can be in both source and target
    local item = CreateItem( "item_apply_modifiers", source, source)
    item:ApplyDataDrivenModifier( source, target, modifier, {duration=dur} )
end


function DummyEnd(dummy)
    dummy:RemoveSelf()
    return nil
end

function DoDamage(source, target , dmg, dmg_type, dmg_flag, abil, isLoop)
    local IsAbsorbed = false
    local damageTaken = dmg
    local IsBScrollIgnored = false
    local targetMR = target:GetMagicalArmorValue()

    -- check if target has B scroll on
    if dmg_type == DAMAGE_TYPE_MAGICAL then
        for k,v in pairs(goesthruB) do
            if abil:GetAbilityName() == v then IsBScrollIgnored = true break end
        end
        if IsBScrollIgnored == false and target:HasModifier("modifier_b_scroll") then 
            MR = target:GetMagicalArmorValue() 
            target.BShieldAmount = target.BShieldAmount - damageTaken * (1-MR)
            if target.BShieldAmount <= 0 then
                damageTaken = -target.BShieldAmount
                target:RemoveModifierByName("modifier_b_scroll")

            end
        end
    end

    -- check if target has Rho Aias shield 
    if not IsAbsorbed and target:HasModifier("modifier_rho_aias_shield") then
        local MR = 0
        if dmg_type == DAMAGE_TYPE_MAGICAL then
            MR = target:GetMagicalArmorValue() 
        end 
        target.rhoShieldAmount = target.rhoShieldAmount - damageTaken * (1-MR)

        -- if damage is beyond the shield's block amount, update remaining damage
        if target.rhoShieldAmount <= 0 then
            print("Rho Aias has been broken through by " .. -target.rhoShieldAmount)
            damageTaken = -target.rhoShieldAmount
            target:RemoveModifierByName("modifier_rho_aias_shield")
            target.argosShieldAmount = 0
        -- if shield has enough durability, set a flag that the damage is fully absorbed
        else 
            print("Rho Aias absorbed full damage")
            damageTaken = 0
            IsAbsorbed = true
        end
    end

    -- check if target has Argos
    if not IsAbsorbed and target:HasModifier("modifier_argos_shield") then
        local MR = 0
        if dmg_type == DAMAGE_TYPE_MAGICAL then
            MR = target:GetMagicalArmorValue() 
        end 
        target.argosShieldAmount = target.argosShieldAmount - damageTaken * (1-MR)
        if target.argosShieldAmount <= 0 then
            print("Argos has been broken through by " .. -target.argosShieldAmount)
            damageTaken = -target.argosShieldAmount
            target:RemoveModifierByName("modifier_argos_shield") 
            target.argosShieldAmount = 0
        else
            print("Argos absorbed full damage")
            damageTaken = 0
            IsAbsorbed = true
        end
    end

    -- if damage was not fully absorbed by shield, deal residue damage 
    if IsAbsorbed == true then return else
        local dmgtable = {
            attacker = source,
            victim = target,
            damage = damageTaken,
            damage_type = dmg_type,
            damage_flags = dmg_flag,
            ability = abil
        }
        -- if target is linked, distribute damages 
        if target:HasModifier("modifier_share_damage") and not isLoop then
            dmgtable.damage = dmgtable.damage/#target.linkTable
            for i=1, #target.linkTable do
                -- do ApplyDamage if it's primary target since the shield processing is already done
                if target.linkTable[i] == target then
                    ApplyDamage(dmgtable)
                    print("Damage dealt to primary target : " .. dmgtable.damage)
                -- for other linked targets, we need DoDamage
                else
                    DoDamage(source, target.linkTable[i], dmgtable.damage,  DAMAGE_TYPE_MAGICAL, 0, abil, true) 
                    print("Damage dealt to " .. target.linkTable[i]:GetName() .. " by link : " .. dmgtable.damage) 
                end
            end
        else 
            dmgtable.victim = target
            ApplyDamage(dmgtable)
        end
        
    end

end

function ApplyPurge(target)
    for k,v in pairs(purgable) do
        target:RemoveModifierByName(v)
    end
end


function ProcessShield()
    for k,v in pairs(goesthruB) do
        if ability == v then return else 
            -- process shield here
        end
    end
end


function PrintTable(t, indent, done)
	--print ( string.format ('PrintTable type %s', type(keys)) )
    if type(t) ~= "table" then return end

    done = done or {}
    done[t] = true
    indent = indent or 0

    local l = {}
    for k, v in pairs(t) do
        table.insert(l, k)
    end

    table.sort(l)
    for k, v in ipairs(l) do
        -- Ignore FDesc
        if v ~= 'FDesc' then
            local value = t[v]

            if type(value) == "table" and not done[value] then
                done [value] = true
                print(string.rep ("\t", indent)..tostring(v)..":")
                PrintTable (value, indent + 2, done)
            elseif type(value) == "userdata" and not done[value] then
                done [value] = true
                print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
                PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
            else
                if t.FDesc and t.FDesc[v] then
                    print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
                else
                    print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
                end
            end
        end
    end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'


--============ Copyright (c) Valve Corporation, All rights reserved. ==========
--
--
--=============================================================================

--/////////////////////////////////////////////////////////////////////////////
-- Debug helpers
--
--  Things that are really for during development - you really should never call any of this
--  in final/real/workshop submitted code
--/////////////////////////////////////////////////////////////////////////////

-- if you want a table printed to console formatted like a table (dont we already have this somewhere?)
scripthelp_LogDeepPrintTable = "Print out a table (and subtables) to the console"
logFile = "log/log.txt"

function LogDeepSetLogFile( file )
	logFile = file
end

function LogEndLine ( line )
	AppendToLogFile(logFile, line .. "\n")
end

function _LogDeepPrintMetaTable( debugMetaTable, prefix )
	_LogDeepPrintTable( debugMetaTable, prefix, false, false )
	if getmetatable( debugMetaTable ) ~= nil and getmetatable( debugMetaTable ).__index ~= nil then
		_LogDeepPrintMetaTable( getmetatable( debugMetaTable ).__index, prefix )
	end
end

function _LogDeepPrintTable(debugInstance, prefix, isOuterScope, chaseMetaTables ) 
    prefix = prefix or ""
    local string_accum = ""
    if debugInstance == nil then 
		LogEndLine( prefix .. "<nil>" )
		return
    end
	local terminatescope = false
	local oldPrefix = ""
    if isOuterScope then  -- special case for outer call - so we dont end up iterating strings, basically
        if type(debugInstance) == "table" then 
            LogEndLine( prefix .. "{" )
			oldPrefix = prefix
            prefix = prefix .. "   "
			terminatescope = true
        else 
            LogEndLine( prefix .. " = " .. (type(debugInstance) == "string" and ("\"" .. debugInstance .. "\"") or debugInstance))
        end
    end
    local debugOver = debugInstance

	-- First deal with metatables
	if chaseMetaTables == true then
		if getmetatable( debugOver ) ~= nil and getmetatable( debugOver ).__index ~= nil then
			local thisMetaTable = getmetatable( debugOver ).__index 
			if vlua.find(_LogDeepprint_alreadyseen, thisMetaTable ) ~= nil then 
				LogEndLine( string.format( "%s%-32s\t= %s (table, already seen)", prefix, "metatable", tostring( thisMetaTable ) ) )
			else
				LogEndLine(prefix .. "metatable = " .. tostring( thisMetaTable ) )
				LogEndLine(prefix .. "{")
				table.insert( _LogDeepprint_alreadyseen, thisMetaTable )
				_LogDeepPrintMetaTable( thisMetaTable, prefix .. "   ", false )
				LogEndLine(prefix .. "}")
			end
		end
	end

	-- Now deal with the elements themselves
	-- debugOver sometimes a string??
    for idx, data_value in pairs(debugOver) do
        if type(data_value) == "table" then 
            if vlua.find(_LogDeepprint_alreadyseen, data_value) ~= nil then 
                LogEndLine( string.format( "%s%-32s\t= %s (table, already seen)", prefix, idx, tostring( data_value ) ) )
            else
                local is_array = #data_value > 0
				local test = 1
				for idx2, val2 in pairs(data_value) do
					if type( idx2 ) ~= "number" or idx2 ~= test then
						is_array = false
						break
					end
					test = test + 1
				end
				local valtype = type(data_value)
				if is_array == true then
					valtype = "array table"
				end
                LogEndLine( string.format( "%s%-32s\t= %s (%s)", prefix, idx, tostring(data_value), valtype ) )
                LogEndLine(prefix .. (is_array and "[" or "{"))
                table.insert(_LogDeepprint_alreadyseen, data_value)
                _LogDeepPrintTable(data_value, prefix .. "   ", false, true)
                LogEndLine(prefix .. (is_array and "]" or "}"))
            end
		elseif type(data_value) == "string" then 
            LogEndLine( string.format( "%s%-32s\t= \"%s\" (%s)", prefix, idx, data_value, type(data_value) ) )
		else 
            LogEndLine( string.format( "%s%-32s\t= %s (%s)", prefix, idx, tostring(data_value), type(data_value) ) )
        end
    end
	if terminatescope == true then
		LogEndLine( oldPrefix .. "}" )
	end
end


function LogDeepPrintTable( debugInstance, prefix, isPublicScriptScope ) 
    prefix = prefix or ""
    _LogDeepprint_alreadyseen = {}
    table.insert(_LogDeepprint_alreadyseen, debugInstance)
    _LogDeepPrintTable(debugInstance, prefix, true, isPublicScriptScope )
end


--/////////////////////////////////////////////////////////////////////////////
-- Fancy new LogDeepPrint - handles instances, and avoids cycles
--
--/////////////////////////////////////////////////////////////////////////////

-- @todo: this is hideous, there must be a "right way" to do this, im dumb!
-- outside the recursion table of seen recurses so we dont cycle into our components that refer back to ourselves
_LogDeepprint_alreadyseen = {}


-- the inner recursion for the LogDeep print
function _LogDeepToString(debugInstance, prefix) 
    local string_accum = ""
    if debugInstance == nil then 
        return "LogDeep Print of NULL" .. "\n"
    end
    if prefix == "" then  -- special case for outer call - so we dont end up iterating strings, basically
        if type(debugInstance) == "table" or type(debugInstance) == "table" or type(debugInstance) == "UNKNOWN" or type(debugInstance) == "table" then 
            string_accum = string_accum .. (type(debugInstance) == "table" and "[" or "{") .. "\n"
            prefix = "   "
        else 
            return " = " .. (type(debugInstance) == "string" and ("\"" .. debugInstance .. "\"") or debugInstance) .. "\n"
        end
    end
    local debugOver = type(debugInstance) == "UNKNOWN" and getclass(debugInstance) or debugInstance
    for idx, val in pairs(debugOver) do
        local data_value = debugInstance[idx]
        if type(data_value) == "table" or type(data_value) == "table" or type(data_value) == "UNKNOWN" or type(data_value) == "table" then 
            if vlua.find(_LogDeepprint_alreadyseen, data_value) ~= nil then 
                string_accum = string_accum .. prefix .. idx .. " ALREADY SEEN " .. "\n"
            else 
                local is_array = type(data_value) == "table"
                string_accum = string_accum .. prefix .. idx .. " = ( " .. type(data_value) .. " )" .. "\n"
                string_accum = string_accum .. prefix .. (is_array and "[" or "{") .. "\n"
                table.insert(_LogDeepprint_alreadyseen, data_value)
                string_accum = string_accum .. _LogDeepToString(data_value, prefix .. "   ")
                string_accum = string_accum .. prefix .. (is_array and "]" or "}") .. "\n"
            end
        else 
            --string_accum = string_accum .. prefix .. idx .. "\t= " .. (type(data_value) == "string" and ("\"" .. data_value .. "\"") or data_value) .. "\n"
			string_accum = string_accum .. prefix .. idx .. "\t= " .. "\"" .. tostring(data_value) .. "\"" .. "\n"
        end
    end
    if prefix == "   " then 
        string_accum = string_accum .. (type(debugInstance) == "table" and "]" or "}") .. "\n" -- hack for "proving" at end - this is DUMB!
    end
    return string_accum
end


scripthelp_LogDeepString = "Convert a class/array/instance/table to a string"

function LogDeepToString(debugInstance, prefix) 
    prefix = prefix or ""
    _LogDeepprint_alreadyseen = {}
    table.insert(_LogDeepprint_alreadyseen, debugInstance)
    return _LogDeepToString(debugInstance, prefix)
end


scripthelp_LogDeepPrint = "Print out a class/array/instance/table to the console"

function LogDeepPrint(debugInstance, prefix) 
    prefix = prefix or ""
    LogEndLine(LogDeepToString(debugInstance, prefix))
end
