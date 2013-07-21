--========================================================================
--========================Used for debugging purposes.=============================
--========================================================================

function URSLoadouts( len )
	Msg( "=============================================================\n" )
	Msg( "URS - Loadouts:\n" )
	PrintTable( net.ReadTable() )
	Msg( "=============================================================\n" )
	LocalPlayer():ChatPrint( "* Check console for a list of your Loadouts *" )
end
net.Receive( "URS-Loadouts", URSLoadouts )

function URSRestrictions( len )
	Msg( "=============================================================\n" )
	Msg( "URS - Restrictions:\n" )
	PrintTable( net.ReadTable() )
	Msg( "=============================================================\n" )
	LocalPlayer():ChatPrint( "* Check console for a list of your Restrictions *" )
end
net.Receive( "URS-Restrictions", URSRestrictions )

function URSLimits( len )
	Msg( "=============================================================\n" )
	Msg( "URS - Limits:\n" )
	PrintTable( net.ReadTable() )
	Msg( "=============================================================\n" )
	LocalPlayer():ChatPrint( "* Check console for a list of your Limits *" )
end
net.Receive( "URS-Limits", URSLimits )

function URSAll( len )
	Msg( "=============================================================\n" )
	Msg( "URS - Limits:\n" )
	PrintTable( net.ReadTable() )
	Msg( "=============================================================\n" )
	Msg( "URS - Restrictions:\n" )
	PrintTable( net.ReadTable() )
	Msg( "=============================================================\n" )
	Msg( "URS - Loadouts:\n" )
	PrintTable( net.ReadTable() )
	Msg( "=============================================================\n" )
	LocalPlayer():ChatPrint( "* Check console for a list of your Limits, Restrictions, and Loadouts *" )
end
net.Receive( "URS-All", URSAll )

--========================================================================
--========================================================================
--[[ local ply = LocalPlayer()
local trace = ply:GetEyeTraceNoCursor()
function URSHelper()
	-- draw.RoundedBox( 6, 2, 7, 178, 203, Color( 50, 50, 200, 200 ) )
	-- draw.RoundedBox( 6, 5, 10, 175, 200, Color( 50, 50, 50, 200 ) )
	surface.SetDrawColor( Color( 0, 0, 0, 255 ) )
	surface.DrawOutlinedRect( 5, 10, 175, 200 )
	surface.SetDrawColor( Color( 50, 50, 50, 200 ) )
	surface.DrawRect( 5, 10, 175, 200 )
	
	surface.CreateFont ("DefaultBold", 20, 700, true, false, "URSHeader")
	surface.SetFont( "DefaultBold" )
	surface.SetTextColor( 200, 200, 200, 255 )
	surface.SetTextPos( 10, 12 ) 
	surface.DrawText( "Target:  ".. trace.Entity:GetModel() )
	
end
hook.Add("PostDrawHUD", "URSHelper", URSHelper) ]]