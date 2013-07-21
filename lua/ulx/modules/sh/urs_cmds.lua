local restrictiontypes = { "tool","vehicle","effect","swep", "npc","ragdoll","prop","sent", "all", "advdupe", "pickup" }
local limittypes = { "vehicle","effect", "npc","ragdoll","prop","sent" }
local Echo
if SERVER then
	Echo = ulx.convar( "echours", 0 )
	util.AddNetworkString("URS-Loadouts")
	util.AddNetworkString("URS-Restrictions")
	util.AddNetworkString("URS-All")
end

function ulx.restrict( ply, type, what, ... )
	local groups = {...}
	local removers = {}
	what = string.lower( what )
	if type == "all" and !table.HasValue( {"tool","vehicle","effect","swep", "npc","ragdoll","prop","sent"}, what ) then
		ULib.tsayError( ply, "Global Restrictions are limited to:\ntool, vehicle, effect, swep, npc, ragdoll, prop, sent " )
		return
	end
	if !restrictions[type][what] then
		restrictions[type][what] = groups
	else
		for group, groups in pairs( groups ) do
			if table.HasValue( restrictions[type][what], groups ) then
				table.insert( removers, group )
				ULib.tsayError( ply, groups .." is already restricted from this rank." )
			else
				if groups == "*" then
					table.insert( restrictions[type][what], 1, groups )
				else
					table.insert( restrictions[type][what], groups )
				end
			end
		end
	end
	xgui.sendDataTable( {}, "URSRestrictions" )
	URSSave()
	table.sort( removers, function(a, b) return a > b end )
	if removers[1] then for num, nums in pairs( removers ) do table.remove( groups, nums ) end end
	if groups[1] then
		ulx.fancyLogAdmin( ply, Echo:GetBool(), "#A restricted #s #s from #s", type, what, table.concat( groups, ", " ) )
	end
end
local restrict = ulx.command( "URS", "ulx restrict", ulx.restrict, "!restrict" )
restrict:addParam{ type=ULib.cmds.StringArg, hint="Type", completes=restrictiontypes, ULib.cmds.restrictToCompletes }
restrict:addParam{ type=ULib.cmds.StringArg, hint="Target Name/Model Path" }
restrict:addParam{ type=ULib.cmds.StringArg, hint="Groups", ULib.cmds.takeRestOfLine, repeat_min=1 }
restrict:defaultAccess( ULib.ACCESS_SUPERADMIN )
restrict:help( "Add a restriction to a group." )

function ulx.unrestrict( ply, type, what, ... )
	local groups = {...}
	local removers = {}
	local removers2 = {}
	what = string.lower( what )
	if not restrictions[type][what] then ULib.tsayError( ply, what .." is not a restricted ".. type ) return
	elseif groups[1] == "*" then
		if restrictions[type][what][1] == "*" then
			if not restrictions[type][what][2] then
				restrictions[type][what] = nil
			else
				table.remove( restrictions[type][what], 1 )
			end
		else
			restrictions[type][what] = nil
		end
	else
		for k,v in pairs( groups ) do
			if table.HasValue( restrictions[type][what], v ) then
				for k2,v2 in pairs( restrictions[type][what] ) do
					if v2 == v then
						table.insert( removers, k2 )
						if not restrictions[type][what][1] then restrictions[type][what] = nil end
					end
				end
			else
				ULib.tsayError( ply, v .." is not restricted from ".. what )
				table.insert( removers2, k )
			end
		end
	end
	table.sort( removers, function(a, b) return a > b end )
	for i=1,#removers do table.remove( restrictions[type][what], removers[i] ) end
	URSSave()
	xgui.sendDataTable( {}, "URSRestrictions" )
	if groups[1] then
		table.sort( removers2, function(a, b) return a > b end )
		for i=1,#removers2 do table.remove( groups, removers2[i] ) end
		if groups[1] == "*" and not restrictions[type][what] then
			ulx.fancyLogAdmin( ply, Echo:GetBool(), "#A removed all restrictions from #s", what )
		else
			ulx.fancyLogAdmin( ply, Echo:GetBool(), "#A unrestricted #s from #s", what, table.concat(groups,", ") )
		end
	end
end
local unrestrict = ulx.command( "URS", "ulx unrestrict", ulx.unrestrict, "!unrestrict")
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Type", completes=restrictiontypes, ULib.cmds.restrictToCompletes }
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Target Name/Model Path" }
unrestrict:addParam{ type=ULib.cmds.StringArg, hint="Groups", ULib.cmds.takeRestOfLine, repeat_min=1 }
unrestrict:defaultAccess( ULib.ACCESS_SUPERADMIN )
unrestrict:help( "Remove a restrictions from a group." )

function ulx.setlimit( ply, type, group, limit )
	if limit == -1 then limits[type][group] = nil else limits[type][group] = limit end
	xgui.sendDataTable( {}, "URSLimits" )
	URSSave()
	ulx.fancyLogAdmin( ply, Echo:GetBool(), "#A set the #s limit for #s to #i", type, group, limit )
end
local limit = ulx.command( "URS", "ulx setlimit", ulx.setlimit, "!setlimit" )
limit:addParam{ type=ULib.cmds.StringArg, ULib.cmds.restrictToCompletes, completes=limittypes, hint="Type" }
limit:addParam{ type=ULib.cmds.StringArg, hint="Group" }
limit:addParam{ type=ULib.cmds.NumArg, min=-1, default=-1, hint="Amount (-1 is default)" }
limit:defaultAccess( ULib.ACCESS_SUPERADMIN )
limit:help( "Set limits for specific groups." )

local weaponlist = { "manhack_welder", "weapon_ak47", "weapon_deagle", "weapon_fiveseven", "weapon_glock", "weapon_m4", "weapon_mac10","weapon_tmp","weapon_pumpshotgun","weapon_para","weapon_mp5","harpooncannon","flechette_gun","weapon_crowbar","weapon_stunstick","weapon_physcannon","weapon_physgun","weapon_pistol","weapon_357","weapon_smg1","weapon_ar2","weapon_shotgun","weapon_crossbow",  "weapon_frag", "weapon_rpg", "weapon_slam", "weapon_bugbait", "item_ml_grenade", "item_ar2_grenade", "item_ammo_ar2_altfire", "gmod_camera", "gmod_tool"}

function ulx.loadoutadd( ply, group, ... )
	local weapons = {...}
	local removers = {}
	for i=1, #weapons do
		if loadouts[group] and not table.HasValue( loadouts[group], weapons[i] ) then
			table.insert( loadouts[group], weapons[i] )
		elseif loadouts[group] and table.HasValue( loadouts[group], weapons[i] ) then
			ULib.tsayError( ply, weapons[i] .." is already in the loadout for ".. group )
			table.insert( removers, i )
		end
	end
	if not loadouts[group] then
		loadouts[group] = weapons
	end
	URSSave()
	xgui.sendDataTable( {}, "URSLoadouts" )
	table.sort( removers, function(a, b) return a > b end )
	for i=1,#removers do table.remove( weapons, removers[i] ) end
	if weapons[1] then
		ulx.fancyLogAdmin( ply, Echo:GetBool(), "#A added #s to the loadout for #s", table.concat( weapons, ", " ), group )
	end
end
local loadout = ulx.command( "URS", "ulx loadoutadd", ulx.loadoutadd, "!loadoutadd" )
loadout:addParam{ type=ULib.cmds.StringArg, hint="Group" }
loadout:addParam{ type=ULib.cmds.StringArg, hint="Weapons", ULib.cmds.takeRestOfLine, repeat_min=1, completes=weaponlist }
loadout:defaultAccess( ULib.ACCESS_SUPERADMIN )
loadout:help( "Create or update a loudout for a specific group." )

function ulx.loadoutremove( ply, group, ... )
	if not loadouts[group] then ULib.tsayError( ply, group .." does not have a loadout" ) return end
	local weapons = {...}
	local removers = {}
	local removers2 = {}
	if weapons[1] == "*" then
		loadouts[group] = nil
		weapons = {}
		URSSave()
		xgui.sendDataTable( {}, "URSLoadouts" )
		ulx.fancyLogAdmin( ply, Echo:GetBool(), "#A removed the loadout from #s", group )
		return
	else
		for k,v in pairs( weapons ) do
			if table.HasValue( loadouts[group], v ) then
				for k2,v2 in pairs( loadouts[group] ) do
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
	for i=1,#removers do table.remove( loadouts[group], removers[i] ) end
	if not loadouts[group][1] then loadouts[group] = nil end
	URSSave()
	xgui.sendDataTable( {}, "URSLoadouts" )
	table.sort( removers2, function(a, b) return a > b end )
	for i=1,#removers2 do table.remove( weapons, removers2[i] ) end
	if weapons and not weapons[1] then return end
	ulx.fancyLogAdmin( ply, Echo:GetBool(), "#A removed #s from the loadout of #s", table.concat( weapons, ", " ), group )
end
local loadout = ulx.command( "URS", "ulx loadoutremove", ulx.loadoutremove, "!loadoutremove" )
loadout:addParam{ type=ULib.cmds.StringArg, hint="Group" }
loadout:addParam{ type=ULib.cmds.StringArg, hint="Weapons", ULib.cmds.takeRestOfLine, repeat_min=1 }
loadout:defaultAccess( ULib.ACCESS_SUPERADMIN )
loadout:help( "Remove weapons from a loadout for a specific group." )

function ulx.print( ply, type )
	if type == "loadouts" then
		net.Start("URS-Loadouts")
		net.WriteTable(loadouts)
		net.Send(ply)
	elseif type == "restrictions" then
		net.Start("URS-Restrictions")
		net.WriteTable(restrictions)
		net.Send(ply)
	elseif type == "limits" then
		net.Start("URS-Limits")
		net.WriteTable(limits)
		net.Send(ply)
	else
		net.Start("URS-All")
		net.WriteTable(limits)
		net.WriteTable(restrictions)
		net.WriteTable(loadouts)
		net.Send(ply)
	end
end
local loadout = ulx.command( "URS", "ulx print", ulx.print, "!print" )
loadout:addParam{ type=ULib.cmds.StringArg, hint="Type", completes={"restrictions","loadouts","limits","all" }, ULib.cmds.restrictToCompletes }
loadout:defaultAccess( ULib.ACCESS_SUPERADMIN )
loadout:help( "Print Restrictions, Loadouts, or Limits from URS into your console." )
