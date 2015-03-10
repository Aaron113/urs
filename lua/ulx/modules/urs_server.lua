AddCSLuaFile( "ulx/modules/sh/urs_cmds.lua" )

if !URS then URS = {} end 

function URS.Load() 
	if file.Exists( "ulx/restrictions.txt", "DATA" ) then URS.restrictions = util.JSONToTable( file.Read( "ulx/restrictions.txt", "DATA" ) ) end
	if file.Exists( "ulx/limits.txt", "DATA" ) then URS.limits = util.JSONToTable( file.Read( "ulx/limits.txt", "DATA" ) ) end
	if file.Exists( "ulx/loadouts.txt", "DATA" ) then URS.loadouts = util.JSONToTable( file.Read( "ulx/loadouts.txt", "DATA" ) ) end

	-- Initiallize all tables to prevent errors
	for type, types in pairs(URS.types) do 
		if !URS[type] then 
			URS[type] = {} 
			for k, v in pairs(types) do 
				URS[type][v] = {} 
			end 
		end 
	end 
end

function URS.Save()
	if URS.restrictions then file.Write("ulx/restrictions.txt", util.TableToJSON(URS.restrictions)) end
	if URS.limits then file.Write("ulx/limits.txt", util.TableToJSON(URS.limits)) end
	if URS.loadouts then file.Write("ulx/loadouts.txt", util.TableToJSON(URS.loadouts)) end
end

function URS.PrintRestricted(ply, type, what) 
	if URS.cfg.echoSpawns then 
		ulx.logSpawn(ply:Nick() .."<".. ply:SteamID() .."> spawned/used ".. type .." ".. what .." -=RESTRICTED=-")
	end 
	ULib.tsayError(ply, "\"".. what .."\" is a restricted ".. type .." from your rank.")
end 

function URS.Check(ply, type, what)
	what = string.lower(what) 
	local group = ply:GetUserGroup() 
	local restriction = URS.restrictions[type][what] 

	if restriction then 
		if table.HasValue(restriction, "*") then 
			if !(table.HasValue(restriction, group) or table.HasValue(restriction, ply:SteamID())) then 
				URS.PrintRestricted(ply, type, what)
				return false
			end 
		elseif table.HasValue(restriction, group) or table.HasValue(restriction, ply:SteamID()) then 
			URS.PrintRestricted(ply, type, what) 
			return false 
		end 

	elseif URS.restrictions["all"][type] and table.HasValue(URS.restrictions["all"][type], group) then 
		ULib.tsayError(ply, "Your rank is restricted from all ".. type .."s") 
		return false 

	elseif table.HasValue(URS.types.limits, type) and (URS.limits[type][ply:SteamID()] or URS.limits[type][group]) then 
		if URS.limits[type][ply:SteamID()] then 
			if ply:GetCount(type.."s") >= URS.limits[type][ply:SteamID()] then 
				ply:LimitHit( type .."s" )
				return false 
			end 
		elseif URS.limits[type][group] then 
			if ply:GetCount(type.."s") >= URS.limits[type][group] then 
				ply:LimitHit( type .."s" )
				return false 
			end 
		end 
		return true -- Overwrite sbox limit (ours is greater)
	end 
end

timer.Simple(0.1, function() 

	--  Wiremod's Advanced Duplicator
	if AdvDupe then 
		AdvDupe.AdminSettings.AddEntCheckHook( "URSDupeCheck", 
		function(ply, Ent, EntTable) 
			return URS.Check( ply, "advdupe", EntTable.Class )
		end, 
		function(Hook) 
			ULib.tsayColor( nil, false, Color( 255, 0, 0 ), "URSDupeCheck has failed.  Please contact Aaron113 @\nhttp://forums.ulyssesmod.net/index.php/topic,5269.0.html" )
		end )
	end

	-- Advanced Duplicator 2 (http://facepunch.com/showthread.php?t=1136597)
	if AdvDupe2 then 
		hook.Add("PlayerSpawnEntity", "URSCheckRestrictedEntity", function(ply, EntTable) 
			if URSCheck(ply, "advdupe", EntTable.Class) == false or URS.Check(ply, "advdupe", EntTable.Model) == false then 
				return false 
			end 
		end) 
	end 

end )

function URS.CheckRestrictedSENT(ply, sent)
	return URS.Check( ply, "sent", sent )
end
hook.Add( "PlayerSpawnSENT", "URSCheckRestrictedSENT", URS.CheckRestrictedSENT, -10 )

function URS.CheckRestrictedProp(ply, mdl)
	return URS.Check( ply, "prop", mdl )
end
hook.Add( "PlayerSpawnProp", "URSCheckRestrictedProp", URS.CheckRestrictedProp, -10 )

function URS.CheckRestrictedTool(ply, tr, tool)
	if !URS.Check( ply, "tool", tool ) then return false end
	if URS.cfg.echoSpawns and tool != "inflator" then
		ulx.logSpawn( ply:Nick().."<".. ply:SteamID() .."> used the tool ".. tool .." on ".. tr.Entity:GetModel() )
	end
end
hook.Add( "CanTool", "URSCheckRestrictedTool", URS.CheckRestrictedTool, -10 )

function URS.CheckRestrictedEffect(ply, mdl)
	return URS.Check( ply, "effect", mdl )
end
hook.Add( "PlayerSpawnEffect", "URSCheckRestrictedEffect", URS.CheckRestrictedEffect, -10 )

function URS.CheckRestrictedNPC(ply, npc, weapon)
	return URS.Check( ply, "npc", npc )
end
hook.Add( "PlayerSpawnNPC", "URSCheckRestrictedNPC", URS.CheckRestrictedNPC, -10 )

function URS.CheckRestrictedRagdoll(ply, mdl)
	return URS.Check( ply, "ragdoll", mdl )
end
hook.Add( "PlayerSpawnRagdoll", "URSCheckRestrictedRagdoll", URS.CheckRestrictedRagdoll, -10 )

function URS.CheckRestrictedSWEP(ply, class, weapon)
	if !URS.Check( ply, "swep", class ) then return false end
	if URS.cfg.echoSpawns then 
		ulx.logSpawn( ply:Nick().."<".. ply:SteamID() .."> spawned/gave himself swep ".. class ) 
	end 
end
hook.Add( "PlayerSpawnSWEP", "URSCheckRestrictedSWEP", URS.CheckRestrictedSWEP, -10 )
hook.Add( "PlayerGiveSWEP", "URSCheckRestrictedSWEP2", URS.CheckRestrictedSWEP, -10 )

function URS.CheckRestrictedPickUp(ply, weapon)
	if URS.cfg.weaponPickups:GetInt() == 2 then
		if !URS.Check( ply, "pickup", weapon:GetClass()) then 
			return false 
		end 
	elseif URS.cfg.weaponPickups:GetInt() == 1 then
		if !URS.Check( ply, "swep", weapon:GetClass()) then 
			return false 
		end 
	end
end
hook.Add( "PlayerCanPickupWeapon", "URSCheckRestrictedPickUp", URS.CheckRestrictedPickUp, -10 )

function URS.CheckRestrictedVehicle(ply, mdl, name, vehicle_table)
	return URS.Check( ply, "vehicle", mdl ) and URS.Check( ply, "vehicle", name )
end
hook.Add( "PlayerSpawnVehicle", "URSCheckRestrictedVehicle", URS.CheckRestrictedVehicle, -10 )

function URS.CustomLoadouts(ply)
	if URS.loadouts[ply:SteamID()] then
		ply:StripWeapons()
		for k, v in pairs( URS.loadouts[ply:SteamID()] ) do
			ply:Give( v )
		end
		return true
	elseif URS.loadouts[ply:GetUserGroup()] then
		ply:StripWeapons()
		for k, v in pairs( URS.loadouts[ply:GetUserGroup()] ) do
			ply:Give( v )
		end
		return true
	end
end
hook.Add( "PlayerLoadout", "URSCustomLoadouts", URS.CustomLoadouts, -10 )