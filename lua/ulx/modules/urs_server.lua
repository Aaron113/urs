AddCSLuaFile( "ulx/modules/sh/urs_cmds.lua" )
local Pickups = ulx.convar( "urs_weaponpickups", 0 )
local restrictiontypes = { "tool","vehicle","effect","swep", "npc","ragdoll","prop","sent", "all", "advdupe", "pickup" }
local limittypes = { "vehicle","effect", "npc","ragdoll","prop","sent" }
restrictions = {}
limits = {}
loadouts = {}

local shoulddebug = false
local function Debug( msg ) if shoulddebug then ULib.console( nil, "[URS DEBUG] ".. msg ) Msg( "[URS DEBUG] ".. msg .."\n" ) end end

if file.Exists( "ulx/limits.txt", "DATA" ) then limits = util.JSONToTable( file.Read( "ulx/limits.txt", "DATA" ) ) end
if file.Exists( "ulx/restrictions.txt", "DATA" ) then restrictions = util.JSONToTable( file.Read( "ulx/restrictions.txt", "DATA" ) ) end
if file.Exists( "ulx/loadouts.txt", "DATA" ) then loadouts = util.JSONToTable( file.Read( "ulx/loadouts.txt", "DATA" ) ) end

for type, types in pairs( limittypes ) do if not limits[types] then limits[types] = {} end end
for type, types in pairs( restrictiontypes ) do if not restrictions[types] then restrictions[types] = {} end end

function URSSave()
	if limits then file.Write( "ulx/limits.txt", util.TableToJSON( limits ) ) end
	if restrictions then file.Write( "ulx/restrictions.txt", util.TableToJSON( restrictions ) ) end
	if loadouts then file.Write( "ulx/loadouts.txt", util.TableToJSON( loadouts ) ) end
end

function URSCheck( ply, type, what, noecho )
	what = string.lower( what )
	local group = ply:GetUserGroup() 
	if restrictions[type][what] and (table.HasValue(restrictions[type][what], group) or table.HasValue(restrictions[type][what], "*") or table.HasValue(restrictions[type][what], ply:SteamID())) then
		if !table.HasValue(restrictions[type][what], "*") and (!table.HasValue( restrictions[type][what], ply:SteamID()) and table.HasValue(restrictions[type][what], group)) then
			if !noecho then
				ulx.logSpawn( ply:Nick() .."<".. ply:SteamID() .."> spawned/used ".. type .." ".. what .." -=RESTRICTED=-" )
				ULib.tsayError( ply, "\"".. what .."\" is a restricted ".. type .." from your rank." )
			end
			return false
		end
	elseif restrictions["all"][type] and table.HasValue(restrictions["all"][type], group) then
		if !noecho then
			ULib.tsayError( ply, "Your rank is restricted from all ".. type .."s" )
		end
		return false
	elseif table.HasValue( limittypes, type ) and limits[type][ply:SteamID()] then
		if ply:GetCount( type .."s" ) >= limits[type][ply:SteamID()] then
			ply:LimitHit( type .."s" )
			return false
		else
			return true
		end
	elseif table.HasValue( limittypes, type ) and limits[type][group] then
		if ply:GetCount( type .."s" ) >= limits[type][group] then
			ply:LimitHit( type .."s" )
			return false
		else
			return true
		end
	end
end

timer.Simple(0.1, function() 

	--  Wiremod's Advanced Duplicator
	if AdvDupe then 
		AdvDupe.AdminSettings.AddEntCheckHook( "URSDupeCheck", function(ply, Ent, EntTable) 
			return URSCheck( ply, "advdupe", EntTable.Class )
		end, function(Hook) 
			ULib.tsayColor( nil, false, Color( 255, 0, 0 ), "URSDupeCheck has failed.  Please contact Aaron113 @\nhttp://forums.ulyssesmod.net/index.php/topic,5269.0.html" )
		end )
	end

	-- Advanced Duplicator 2 (http://facepunch.com/showthread.php?t=1136597)
	if AdvDupe2 then 
		hook.Add("PlayerSpawnEntity", "URSCheckRestrictedEntity", function(ply, EntTable) 
			if URSCheck(ply, "advdupe", EntTable.Class) == false or URSCheck(ply, "advdupe", EntTable.Model) == false then 
				return false 
			end 
		end) 
	end 

end )

function URSCheckRestrictedSENT( ply, sent )
	return URSCheck( ply, "sent", sent )
end
hook.Add( "PlayerSpawnSENT", "URSCheckRestrictedSENT", URSCheckRestrictedSENT, -10 )

function URSCheckRestrictedProp( ply, mdl )
	return URSCheck( ply, "prop", mdl )
end
hook.Add( "PlayerSpawnProp", "URSCheckRestrictedProp", URSCheckRestrictedProp, -10 )

function URSCheckRestrictedTool( ply, tr, tool )
	if URSCheck( ply, "tool", tool ) == false then return false end
	if tool != "inflator" then
		ulx.logSpawn( ply:Nick().."<".. ply:SteamID() .."> used the tool ".. tool .." on ".. tr.Entity:GetModel() )
	end
end
hook.Add( "CanTool", "URSCheckRestrictedTool", URSCheckRestrictedTool, -10 )

function URSCheckRestrictedEffect( ply, mdl )
	return URSCheck( ply, "effect", mdl )
end
hook.Add( "PlayerSpawnEffect", "URSCheckRestrictedEffect", URSCheckRestrictedEffect, -10 )

function URSCheckRestrictedNPC( ply, npc, weapon )
	return URSCheck( ply, "npc", npc )
end
hook.Add( "PlayerSpawnNPC", "URSCheckRestrictedNPC", URSCheckRestrictedNPC, -10 )

function URSCheckRestrictedRagdoll( ply, mdl )
	return URSCheck( ply, "ragdoll", mdl )
end
hook.Add( "PlayerSpawnRagdoll", "URSCheckRestrictedRagdoll", URSCheckRestrictedRagdoll, -10 )

function URSCheckRestrictedSWEP( ply, class, weapon )
	if URSCheck( ply, "swep", class ) == false then return false end
	ulx.logSpawn( ply:Nick().."<".. ply:SteamID() .."> spawned/gave himself swep ".. class )
end
hook.Add( "PlayerSpawnSWEP", "URSCheckRestrictedSWEP", URSCheckRestrictedSWEP, -10 )
hook.Add( "PlayerGiveSWEP", "URSCheckRestrictedSWEP2", URSCheckRestrictedSWEP, -10 )

function URSCheckRestrictedPickUp( ply, weapon )
	if Pickups:GetInt() == 2 then
		return URSCheck( ply, "pickup", weapon:GetClass(), true )
	elseif Pickups:GetInt() == 1 then
		return URSCheck( ply, "swep", weapon:GetClass(), true )
	end
end
hook.Add( "PlayerCanPickupWeapon", "URSCheckRestrictedPickUp", URSCheckRestrictedPickUp, -10 )

function URSCheckRestrictedVehicle( ply, mdl, name, vehicle_table )
	return URSCheck( ply, "vehicle", mdl ) and URSCheck( ply, "vehicle", name )
end
hook.Add( "PlayerSpawnVehicle", "URSCheckRestrictedVehicle", URSCheckRestrictedVehicle, -10 )

function URSCustomLoadouts( ply )
	if loadouts[ply:SteamID()] then
		ply:StripWeapons()
		for k, v in pairs( loadouts[ply:SteamID()] ) do
			ply:Give( v )
		end
		return true
	elseif loadouts[ply:GetUserGroup()] then
		ply:StripWeapons()
		for k, v in pairs( loadouts[ply:GetUserGroup()] ) do
			ply:Give( v )
		end
		return true
	end
end
hook.Add( "PlayerLoadout", "URSCustomLoadouts", URSCustomLoadouts, -10 )