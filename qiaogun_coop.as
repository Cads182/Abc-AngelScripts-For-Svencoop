array<ItemMapping@> g_ItemMappings =
{ 
	ItemMapping( "weapon_9mmAR", "weapon_crowbar" ), 
	ItemMapping( "weapon_9mmhandgun", "weapon_crowbar" ),
	ItemMapping( "weapon_357", "weapon_crowbar" ),
	ItemMapping( "weapon_eagle", "weapon_crowbar" ),
	ItemMapping( "weapon_egon", "weapon_crowbar" ),
	ItemMapping( "weapon_gauss", "weapon_crowbar" ),
	ItemMapping( "weapon_grapple", "weapon_crowbar" ),
	ItemMapping( "weapon_handgrenade", "weapon_crowbar" ),
	ItemMapping( "weapon_hornetgun", "weapon_crowbar" ),
	ItemMapping( "weapon_m16", "weapon_crowbar" ),
	ItemMapping( "weapon_m249", "weapon_crowbar" ),
	ItemMapping( "weapon_medkit", "weapon_crowbar" ),
	ItemMapping( "weapon_minigun", "weapon_crowbar" ),
	ItemMapping( "weapon_pipewrench", "weapon_crowbar" ),
	ItemMapping( "weapon_rpg", "weapon_crowbar" ),
	ItemMapping( "weapon_satchel", "weapon_crowbar" ),
	ItemMapping( "weapon_shockrifle", "weapon_crowbar" ),
	ItemMapping( "weapon_shotgun", "weapon_crowbar" ),
	ItemMapping( "weapon_snark", "weapon_crowbar" ),
	ItemMapping( "weapon_sniperrifle", "weapon_crowbar" ),
	ItemMapping( "weapon_sporelauncher", "weapon_crowbar" ),
	ItemMapping( "weapon_tripmine", "weapon_crowbar" ),
	ItemMapping( "weapon_uzi", "weapon_crowbar" ),
	ItemMapping( "weapon_uziakimbo", "weapon_crowbar" ),
	ItemMapping( "weaponbox", "weapon_crowbar" ),
	ItemMapping( "weapon_displacer", "weapon_crowbar" ),
	ItemMapping( "weapon_crossbow", "weapon_crowbar" )
};

void MapInit()
{
	g_ClassicMode.SetItemMappings( @g_ItemMappings );
	g_ClassicMode.ForceItemRemap( true );
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor( "Dr.Abc" );
	g_Module.ScriptInfo.SetContactInfo( "Dr.Abc@foxmail.com" );
}