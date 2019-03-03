/***
	Made by Dr.Abc
***/

CClientCommand g_ArcadeModeVote( "votedmarcade", "starts the arcade Mode vote", @CVoteArcade::DMArcadeVoteCallback );
namespace CVoteArcade
{
	const float m_fArcadeVoteTime  = 60.0f;	
	bool g_IsArcade = false;
	
	array<string> giveAllList = {
		"weapon_crowbar",
		"weapon_9mmhandgun",
		"weapon_357",
		"weapon_9mmAR",
		"weapon_crossbow",
		"weapon_shotgun",
		"weapon_rpg",
		"weapon_gauss",
		"weapon_egon",
		"weapon_hornetgun",
		"weapon_handgrenade",
		"weapon_tripmine",
		"weapon_satchel",
		"weapon_snark",
		"weapon_uziakimbo",
		"weapon_pipewrench",
		"weapon_grapple",
		"weapon_sniperrifle",
		"weapon_m249",
		"weapon_m16",
		"weapon_sporelauncher",
		"weapon_eagle",
		"weapon_displacer"};

	array<string> giveClassicAllList = {
		"weapon_crowbar",
		"weapon_9mmhandgun",
		"weapon_dm357",
		"weapon_hlmp5",
		"weapon_dmbow",
		"weapon_shotgun",
		"weapon_rpg",
		"weapon_dmgauss",
		"weapon_egon",
		"weapon_dmhornetgun",
		"weapon_handgrenade",
		"weapon_tripmine",
		"weapon_satchel",
		"weapon_dmsnark",
		"weapon_uziakimbo",
		"weapon_pipewrench",
		"weapon_grapple",
		"weapon_sniperrifle",
		"weapon_m249",
		"weapon_m16",
		"weapon_sporelauncher",
		"weapon_eagle",
		"weapon_dmshockrifle",
		"weapon_displacer"};

	array<string> giveAmmoList = {
		"buckshot",
		"556",
		"m40a1",
		"argrenades",
		"357",
		"9mm",
		"sporeclip",
		"uranium",
		"rockets",
		"bolts",
		"trip mine", 
		"satchel charge",
		"hand grenade", 
		"snarks",
		"Hornet",
		"shock"};
	
	void StartArcadeVote()
	{
		float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
		
		if( flVoteTime <= 0 )
			flVoteTime = 16;
			
		float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_voteclassicmoderequired" );
		
		if( flPercentage <= 0 )
			flPercentage = 51;

		Vote vote( "Arcade rule vote ", ( !g_IsArcade ? "Enable" : "Disable" ) + " Arcade Play ?", flVoteTime, flPercentage );
		
		vote.SetVoteBlockedCallback( @ArcadeVoteBlocked );
		vote.SetVoteEndCallback( @ArcadeVoteEnd );
		vote.Start();
	}

	void ArcadeVoteBlocked( Vote@ pVote, float flTime )
	{
		g_Scheduler.SetTimeout( "StartArcadeVote", flTime, false );
	}

	void ArcadeVoteEnd( Vote@ pVote, bool bResult, int iVoters )
	{
		if( !bResult )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for Arcade play failed" );
			return;
		}
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( g_IsArcade ? "Disable" : "Enable" ) + " Arcade play passed\n" );
		
		if(!g_IsArcade)
		{
			g_IsArcade = true;
			for (int i = 1; i <= g_Engine.maxClients; i++)
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
				if(pPlayer !is null && pPlayer.IsConnected())
					ApplyArcade( pPlayer );
			}
		}
		else
			g_IsArcade = false;
	}
	
	void DMArcadeVoteCallback( const CCommand@ pArgs )
	{
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		if (g_Engine.time >= m_fArcadeVoteTime)
			g_PlayerFuncs.SayText( pPlayer, "Game has been started for a while"+"(>"+m_fArcadeVoteTime+"s)" +", you can't change rule any more!" );
		else
			StartArcadeVote();
	}
	
	void ApplyArcade( CBasePlayer@ pPlayer )
	{
		CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.m_hActiveItem.GetEntity());
		if(pWeapon.m_iClip != -1)
			pWeapon.m_iClip = pWeapon.iMaxClip();
		
		string m_stractiveItem;
		if (pPlayer.m_hActiveItem.GetEntity() !is null)
			m_stractiveItem = pWeapon.pev.classname;
		
		pPlayer.SetItemPickupTimes(0);
	
		for (uint i = 0; i < (IsClassMode ? giveClassicAllList : giveAllList).length(); i++) 
		{
			array<string> gargs = { IsClassMode ? giveClassicAllList[i] : giveAllList[i]};
			if (@pPlayer.HasNamedPlayerItem(gargs[0]) == @null)
				pPlayer.GiveNamedItem(gargs[0], 0, 0);
		}

		for (uint u = 0; u < giveAmmoList.length(); u++) 
		{
			int m_iAmmoIndex = g_PlayerFuncs.GetAmmoIndex(giveAmmoList[u]);
			pPlayer.m_rgAmmo(m_iAmmoIndex , pPlayer.GetMaxAmmo(m_iAmmoIndex));
		}
		
		//CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem("item_longjump");
		//if( pItem is null)
		//	pPlayer.GiveNamedItem("item_longjump", 0, 0);
		
		if (m_stractiveItem.Length() > 0)
			pPlayer.SelectItem(m_stractiveItem);
		pPlayer.pev.health = 100;
		pPlayer.pev.armorvalue = 100;
	}
}