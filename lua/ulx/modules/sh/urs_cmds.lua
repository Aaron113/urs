if !URS then URS = {} end 

URS.types = {} 
URS.types.restrictions = {"tool","vehicle","effect","swep", "npc","ragdoll","prop","sent", "all", "advdupe", "pickup"}
URS.types.limits = {"vehicle","effect", "npc","ragdoll","prop","sent"}
URS.types.loadouts = {}

URS.restrictions = {}
URS.limits = {}
URS.loadouts = {}

URS.cfg = {}

if SERVER then 
	URS.cfg.weaponPickups = ulx.convar("urs_weaponpickups", 2)
	URS.cfg.echoSpawns = ulx.convar("urs_echo_spawns", 1)
	URS.cfg.echoCommands = ulx.convar("urs_echo_commands", 1)
	URS.cfg.overwriteSbox = ulx.convar("urs_overwrite_sbox", 1)

	URS.Load()
end 


function ulx.restrict( ply, type, what, ... )
	local groups = {...}
	local removers = {}
	what = string.lower(what)
	if type == "all" and !table.HasValue({"tool","vehicle","effect","swep", "npc","ragdoll","prop","sent"}, what) then
		ULib.tsayError(ply, "Global Restrictions are limited to:\ntool, vehicle, effect, swep, npc, ragdoll, prop, sent")
		return
	end
	if !URS.restrictions[type][what] then
		URS.restrictions[type][what] = groups
	else
		for group, groups in pairs( groups ) do
			if table.HasValue(URS.restrictions[type][what], groups) then
				table.insert(removers, group)
				ULib.tsayError(ply, groups .." is already restricted from this rank.")
			else
				if groups == "*" then
					table.insert(URS.restrictions[type][what], 1, groups)
				else
					table.insert(URS.restrictions[type][what], groups)
				end
			end
		end
	end
	xgui.sendDataTable({}, "URSRestrictions")
	URS.Save(URS_SAVE_RESTRICTIONS)
	table.sort(removers, function(a, b) return a > b end)
	if removers[1] then for num, nums in pairs(removers) do table.remove(groups, nums) end end
	if groups[1] then
		ulx.fancyLogAdmin(ply, URS.cfg.echoCommands:GetBool(), "#A restricted #s #s from #s", type, what, table.concat(groups, ", "))
	end
end
local restrict = ulx.command( "URS", "ulx restrict", ulx.restrict, "!restrict" )
restrict:addParam{ type=ULib.cmds.StringArg, hint="Type", completes=URS.types.restrictions, ULib.cmds.restrictToCompletes }
restrict:addParam{ type=ULib.cmds.StringArg, hint="Target Name/Model Path" }
restrict:addParam{ type=ULib.cmds.StringArg, hint="Groups", ULib.cmds.takeRestOfLine, repeat_min=1 }
restrict:defaultAccess( ULib.ACCESS_SUPERADMIN )
restrict:help( "Add a restriction to a group." )

function ulx.unrestrict( ply, type, what, ... )
	local groups = {...}
	local removers = {}
	local removers2 = {}
	what = string.lower( what )
	if not URS.restrictions[type][what] then ULib.tsayError( ply, what .." is not a restricted ".. type ) return
	elseif groups[1] == "*" then
		if URS.restrictions[type][what][1] == "*" then
			if not URS.restrictions[type][what][2] then
				URS.restrictions[type][what] = nil
			else
				table.remove( URS.restrictions[type][what], 1 )
			end
		else
			URS.restrictions[type][what] = nil
		end
	else
		for k,v in pairs( groups ) do
			if table.HasValue( URS.restrictions[type][what], v ) then
				for k2,v2 in pairs( URS.restrictions[type][what] ) do
					if v2 == v then
						table.insert( removers, k2 )
						if not URS.restrictions[type][what][1] then URS.restrictions[type][what] = nil end
					end
				end
			else
				ULib.tsayError( ply, v .." is not restricted from ".. what )
				table.insert( removers2, k )
			end
		end
	end
	table.sort( removers, function(a, b) return a > b end )
	for i=1,#removers do table.remove( URS.restrictions[type][what], removers[i] ) end
	URS.Save(URS_SAVE_RESTRICTIONS)
	xgui.sendDataTable( {}, "URSRestrictions" )
	if groups[1] then
		table.sort( removers2, function(a, b) return a > b end )
		for i=1,#removers2 do table.remove( groups, removers2[i] ) end
		if groups[1] == "*" and not URS.restrictions[type][what] then
			ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A removed all restrictions from #s", what )
		else
			ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A unrestricted #s from #s", what, table.concat(groups,", ") )
		end
	end
end
local unrestrict = ulx.command( "URS", "ulx unrestrict", ulx.unrestrict, "!unrestrict")
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Type", completes=URS.types.restrictions, ULib.cmds.restrictToCompletes }
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Target Name/Model Path" }
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Groups", ULib.cmds.takeRestOfLine, repeat_min=1 }
unrestrict:defaultAccess( ULib.ACCESS_SUPERADMIN )
unrestrict:help( "Remove a restrictions from a group." )

function ulx.setlimit( ply, type, group, limit )
	if limit == -1 then URS.limits[type][group] = nil else URS.limits[type][group] = limit end
	xgui.sendDataTable( {}, "URSLimits" )
	URS.Save(URS_SAVE_LIMITS)
	ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A set the #s limit for #s to #i", type, group, limit )
end
local limit = ulx.command( "URS", "ulx setlimit", ulx.setlimit, "!setlimit" )
limit:addParam{ type=ULib.cmds.StringArg, ULib.cmds.restrictToCompletes, completes=URS.types.limits, hint="Type" }
limit:addParam{ type=ULib.cmds.StringArg, hint="Group" }
limit:addParam{ type=ULib.cmds.NumArg, min=-1, default=-1, hint="Amount (-1 is default)" }
limit:defaultAccess( ULib.ACCESS_SUPERADMIN )
limit:help( "Set limits for specific groups." )

local weaponlist = { "manhack_welder", "weapon_ak47", "weapon_deagle", "weapon_fiveseven", "weapon_glock", "weapon_m4", "weapon_mac10","weapon_tmp","weapon_pumpshotgun","weapon_para","weapon_mp5","harpooncannon","flechette_gun","weapon_crowbar","weapon_stunstick","weapon_physcannon","weapon_physgun","weapon_pistol","weapon_357","weapon_smg1","weapon_ar2","weapon_shotgun","weapon_crossbow",  "weapon_frag", "weapon_rpg", "weapon_slam", "weapon_bugbait", "item_ml_grenade", "item_ar2_grenade", "item_ammo_ar2_altfire", "gmod_camera", "gmod_tool"}

function ulx.loadoutadd( ply, group, ... )
	local weapons = {...}
	local removers = {}
	for i=1, #weapons do
		if URS.loadouts[group] and not table.HasValue( URS.loadouts[group], weapons[i] ) then
			table.insert( URS.loadouts[group], weapons[i] )
		elseif URS.loadouts[group] and table.HasValue( URS.loadouts[group], weapons[i] ) then
			ULib.tsayError( ply, weapons[i] .." is already in the loadout for ".. group )
			table.insert( removers, i )
		end
	end
	if not URS.loadouts[group] then
		URS.loadouts[group] = weapons
	end
	URS.Save(URS_SAVE_LOADOUTS)
	xgui.sendDataTable( {}, "URSLoadouts" )
	table.sort( removers, function(a, b) return a > b end )
	for i=1,#removers do table.remove( weapons, removers[i] ) end
	if weapons[1] then
		ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A added #s to the loadout for #s", table.concat( weapons, ", " ), group )
	end
end
local loadout = ulx.command( "URS", "ulx loadoutadd", ulx.loadoutadd, "!loadoutadd" )
loadout:addParam{ type=ULib.cmds.StringArg, hint="Group" }
loadout:addParam{ type=ULib.cmds.StringArg, hint="Weapons", ULib.cmds.takeRestOfLine, repeat_min=1, completes=weaponlist }
loadout:defaultAccess( ULib.ACCESS_SUPERADMIN )
loadout:help( "Create or update a loudout for a specific group." )

function ulx.loadoutremove( ply, group, ... )
	if not URS.loadouts[group] then ULib.tsayError( ply, group .." does not have a loadout" ) return end
	local weapons = {...}
	local removers = {}
	local removers2 = {}
	if weapons[1] == "*" then
		URS.loadouts[group] = nil
		weapons = {}
		URS.Save(SAVE_LOADOUTS)
		xgui.sendDataTable( {}, "URSLoadouts" )
		ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A removed the loadout from #s", group )
		return
	else
		for k,v in pairs( weapons ) do
			if table.HasValue( URS.loadouts[group], v ) then
				for k2,v2 in pairs( URS.loadouts[group] ) do
					if v2 == v then
						table.insert( removers, k2 )
					end
				end
			else
				ULib.tsayError( ply, v .." is not a loadout of this group" )
				table.insert( removers2, k )
			end
		end
	end
	table.sort( removers, function(a, b) return a > b end )
	for i=1,#removers do table.remove( URS.loadouts[group], removers[i] ) end
	if not URS.loadouts[group][1] then URS.loadouts[group] = nil end
	URS.Save(URS_SAVE_LOADOUTS)
	xgui.sendDataTable( {}, "URSLoadouts" )
	table.sort( removers2, function(a, b) return a > b end )
	for i=1,#removers2 do table.remove( weapons, removers2[i] ) end
	if weapons and not weapons[1] then return end
	ulx.fancyLogAdmin( ply, URS.cfg.echoCommands:GetBool(), "#A removed #s from the loadout of #s", table.concat( weapons, ", " ), group )
end
local loadout = ulx.command( "URS", "ulx loadoutremove", ulx.loadoutremove, "!loadoutremove" )
loadout:addParam{ type=ULib.cmds.StringArg, hint="Group" }
loadout:addParam{ type=ULib.cmds.StringArg, hint="Weapons", ULib.cmds.takeRestOfLine, repeat_min=1 }
loadout:defaultAccess( ULib.ACCESS_SUPERADMIN )
loadout:help( "Remove weapons from a loadout for a specific group." )
