

namespace CLMSVote
{
	const int m_iLMSMaxTime = 60;
	const float m_flDMVoteTime  = 60.0f;
	const float m_flLMSMaxRadius  = 8092.0f;
	
	const array<string> WeaponList = {
		"weapon_uziakimbo",
		"weapon_tripmine",
		"weapon_snark",
		"weapon_shotgun",
		"weapon_shockrifle",
		"weapon_satchel",
		"weapon_pipewrench",
		"weapon_m16",
		"weapon_handgrenade",
		"weapon_grapple",
		"weapon_eagle",
		"weapon_crossbow",
		"weapon_9mmhandgun",
		"weapon_9mmAR",
		"weapon_uzi"};
	
	const array<string> CLWeaponList = {
		"weapon_uziakimbo",
		"weapon_tripmine",
		"weapon_snark",
		"weapon_shotgun",
		"weapon_shockrifle",
		"weapon_satchel",
		"weapon_pipewrench",
		"weapon_m16",
		"weapon_handgrenade",
		"weapon_grapple",
		"weapon_eagle",
		"weapon_crossbow",
		"weapon_9mmhandgun",
		"weapon_9mmAR",
		"weapon_dm357",
		"weapon_dmhornetgun",
		"weapon_dmshockrifle",
		"weapon_dmsnark",
		"weapon_hlmp5",
		"weapon_uzi"};
		
	const array<string> DropWeaponList = {
		"weapon_displacer",
		"weapon_minigun",
		"weapon_rpg",
		"weapon_m249",
		"weapon_sporelauncher",
		"weapon_dmgauss",
		"weapon_dmbow",
		"weapon_sniperrifle",
		"weapon_gauss",
		"weapon_hornetgun",
		"weapon_egon"};
	
	const array<string> AmmoList = {
		"ammo_uziclip",
		"ammo_sporeclip",
		"ammo_rpgclip",
		"ammo_gaussclip",
		"ammo_crossbow",
		"ammo_buckshot",
		"ammo_ARgrenades",
		"ammo_9mmclip",
		"ammo_9mmbox",
		"ammo_9mmAR",
		"ammo_762",
		"ammo_556",
		"ammo_357"};
	
	const array<string> ItemList = {
		"item_longjump",
		"item_healthkit",
		"item_battery",
		"item_armorvest",
		"item_helmet"};
			
	CScheduledFunction@ LMSCheacker;
	HUDTextParams Param;
	Vector vecRnd,vecRnd2;
	float m_flLMSRadius;
	int m_iRoundCounter;
	int m_iLMSRoundTime;
	bool m_bLMSActive = false , IsDrop = false ;
	array<Vector> RandomVector;
	array<Vector> vecWeapons;
	
	bool IsLMS()
	{
		if(	g_SurvivalMode.IsActive() && m_bLMSActive && g_PlayerFuncs.GetNumPlayers() > 1 )
			return true;
		return false;
	}
	
	bool CanWeLMS()
	{
		string szMapName = string(g_Engine.mapname).ToLowercase();
		const CMapData@ data = cast<CMapData@>(g_ReadFiles.g_PVPMapList[szMapName]);
		if( data is null )
			return false;
		if ( data.MapMode <= 2  )
			return true;
		return false;
	}
	
	bool IsTDM()
	{
		string szMapName = string(g_Engine.mapname).ToLowercase();
		const CMapData@ data = cast<CMapData@>(g_ReadFiles.g_PVPMapList[szMapName]);
		if ( data.MapMode == 1 || data.MapMode == 2 )
			return true;
		return false;
	}
	
	bool IsScore()
	{
		string szMapName = string(g_Engine.mapname).ToLowercase();
		const CMapData@ data = cast<CMapData@>(g_ReadFiles.g_PVPMapList[szMapName]);
		if ( data.MapMode == 2 )
			return true;
		return false;
	}
	
	void Precache()
	{
		for (uint8 i = 0; i <= ( IsClassMode ? CLWeaponList : WeaponList ).length() - 1; i++)
		{
			g_Game.PrecacheOther(( IsClassMode ? CLWeaponList : WeaponList )[i]);
		}
		for (uint8 f = 0; f <= DropWeaponList.length() - 1; f++)
		{
			g_Game.PrecacheOther(DropWeaponList[f]);
		}
		for (uint8 e = 0; e <= AmmoList.length() - 1; e++)
		{
			g_Game.PrecacheOther(AmmoList[e]);
		}
		for (uint8 d = 0; d <= ItemList.length() - 1; d++)
		{
			g_Game.PrecacheOther(ItemList[d]);
		}
	}

	void StartLMSModeVote( const CCommand@ pArgs )
	{
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		if (g_Engine.time >= m_flDMVoteTime)
		{
			g_DMUtility.SayToYou( pPlayer, "Game has been started for a while"+"(>"+m_flDMVoteTime+"s)" +", you can't change rule any more!" );
			return;
		}
		if (!g_SurvivalMode.IsEnabled())
		{
			g_DMUtility.SayToYou( pPlayer, "You guys just trun off the survival mode! enable it again!" );
			return;
		}
		if(!CanWeLMS())
		{
			g_DMUtility.SayToYou( pPlayer, "You can't play LMS in this map!" );
			return;
		}
		if( !m_bIsStart )
		{
			g_DMUtility.SayToYou( pPlayer , "Game hasn't started." );
			return;
		}
		
		uint8 u = 0;
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ cPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(cPlayer !is null && cPlayer.IsConnected())
			{
				if(cPlayer.IsAlive())
					u++;
			}
		}
		
		if( u > 1)
		{
			float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
			
			if( flVoteTime <= 0 )
				flVoteTime = 16;
				
			float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_voteclassicmoderequired" );
			
			if( flPercentage <= 0 )
				flPercentage = 51;
			
			Vote vote( "LMS Mode vote", ( IsLMS() ? "Disable" : "Enable" ) + " LMS Mode?", flVoteTime, flPercentage );
			
			vote.SetVoteBlockedCallback( @LMSModeVoteBlocked );
			vote.SetVoteEndCallback( @LMSModeVoteEnd );
			vote.Start();
		}
		else
			g_DMUtility.SayToYou( pPlayer , "Man, There's only you in the server." );
	}

	void LMSModeVoteBlocked( Vote@ pVote, float flTime )
	{
		g_Scheduler.SetTimeout( "StartLMSModeVote", flTime, false );
	}

	void LMSModeVoteEnd( Vote@ pVote, bool bResult, int iVoters )
	{
		if( !bResult )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for LMS Mode failed" );
			return;
		}
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( !IsLMS() ? "Enable" : "Disable" ) + " LMS mode passed\n" );
		EnableLMS();
	}
	
	void EnableLMS()
	{
		if(IsScore())
		{
			m_iScoreTeam2 = m_iScoreTeam1 = 0;
			PVPHUD::RefreshScore();
		}
		
		//移除玩家身上的武器，不然也算
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				pPlayer.RemoveAllItems(false);
			}
		}
		
		//寻找随机出生点
		FoundRndSpwan();
		
		//寻找随机武器
		CBaseEntity@ pWeapon = null;
		while((@pWeapon = g_EntityFuncs.FindEntityByClassname(pWeapon, "weapon_*")) !is null)
		{
			vecWeapons.insertLast(pWeapon.pev.origin);	//插入数组
			g_EntityFuncs.Remove(pWeapon);
		}
		while((@pWeapon = g_EntityFuncs.FindEntityByClassname(pWeapon, "item_*")) !is null)
		{
			vecWeapons.insertLast(pWeapon.pev.origin);
			g_EntityFuncs.Remove(pWeapon);
		}
		while((@pWeapon = g_EntityFuncs.FindEntityByClassname(pWeapon, "ammo_*")) !is null)
		{
			vecWeapons.insertLast(pWeapon.pev.origin);
			g_EntityFuncs.Remove(pWeapon);
		}
		
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "LMS Mode Started." );
		RespawnPlayers();
		m_bLMSActive = true;
		g_SurvivalMode.Activate();
		@LMSCheacker = g_Scheduler.SetInterval( "AlivePlayerCounter", 1, g_Scheduler.REPEAT_INFINITE_TIMES );
	}
	
	void RndWeapons()
	{
		CBaseEntity@ pWeapon = null;
		while((@pWeapon = g_EntityFuncs.FindEntityByClassname(pWeapon, "weapon_*")) !is null)
		{
			g_EntityFuncs.Remove(pWeapon);
		}
		while((@pWeapon = g_EntityFuncs.FindEntityByClassname(pWeapon, "item_*")) !is null)
		{
			g_EntityFuncs.Remove(pWeapon);
		}
		while((@pWeapon = g_EntityFuncs.FindEntityByClassname(pWeapon, "ammo_*")) !is null)
		{
			g_EntityFuncs.Remove(pWeapon);
		}
		
		array<string> aryEntity;
		for (uint8 f = 0; f <= ItemList.length() - 1; f++)
		{
			aryEntity.insertLast(ItemList[f]);
		}
		for (uint8 e = 0; e <= AmmoList.length() - 1; e++)
		{
			aryEntity.insertLast(AmmoList[e]);
		}
		
		for (uint8 d = 0; d <= vecWeapons.length() - 1; d++)
		{
			if(Math.RandomLong(0,1) == 0)
				g_EntityFuncs.Create( aryEntity[Math.RandomLong(0,aryEntity.length() - 1)], vecWeapons[d], g_vecZero, false , null );
			else
				CreatWeapon(( IsClassMode ? CLWeaponList : WeaponList )[Math.RandomLong(0,( IsClassMode ? CLWeaponList : WeaponList ).length() - 1)],vecWeapons[d]);
		}
		
		
	}
	
	CBasePlayerWeapon@ CreatWeapon( string&in EntityType , Vector vecOrigin )
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Create( EntityType, vecOrigin, g_vecZero ,  false , null );
		CBasePlayerWeapon@ cWeapon = cast<CBasePlayerWeapon@>(pEntity);
		if(cWeapon !is null)
		{
			if(cWeapon.m_iClip != -1)
			{
					cWeapon.m_iDefaultAmmo += cWeapon.m_iClip;
					cWeapon.m_iClip = 0;
			}
			if(cWeapon.m_iClip2 != -1)
			{
				cWeapon.m_iDefaultSecAmmo += cWeapon.m_iClip2;
				cWeapon.m_iClip2 = 0;
			}
		}
		g_EntityFuncs.DispatchSpawn(cWeapon.edict());
		return cWeapon;
	}

	void DisableLMS()
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "LMS Mode Disabled." );
		RespawnPlayers();
		m_bLMSActive = false;
		g_SurvivalMode.Disable();
		@LMSCheacker = null;
	}
	
	void RoundEnd( CBasePlayer@ pPlayer , int Survival )
	{
		if(pPlayer is null)
			return;
		m_iRoundCounter++;
		RespawnPlayers();
		pPlayer.pev.frags += 100;
		g_SoundSystem.EmitSound( g_EntityFuncs.Instance(0).edict(), CHAN_MUSIC, "barney/ba_bring.wav", 1.0, ATTN_NONE );
		if( Survival == 1)
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, the winner is " + pPlayer.pev.netname + "!\n" );
		else
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, nobody is winner!\n" );
	}
	
	void TeamRoundEnd( int Survival1 , int Survival2 )
	{
		m_iRoundCounter++;
		RespawnPlayers();
		g_SoundSystem.EmitSound( g_EntityFuncs.Instance(0).edict(), CHAN_MUSIC, "barney/ba_bring.wav", 1.0, ATTN_NONE );
		if( Survival1 == 0 && Survival2 != 0 )
		{
			if(IsScore())
				m_iScoreTeam2 += 5;
			else
				TeamAddFrags ("team2");
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, the winner is Team HECU!\n" );
		}
		else if( Survival1 != 0 && Survival2 == 0 )
		{
			if(IsScore())
				m_iScoreTeam1 += 5;
			else
				TeamAddFrags ("team1");
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, the winner is Team Lambda!\n" );
		}
		else if( Survival1 == 0 && Survival2 == 0 )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, nobody is winner!\n" );
		if(IsScore())
			PVPHUD::RefreshScore();
	}
	
	void TeamAddFrags( string Str_Teamname )
	{
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				if(pPlayer.pev.targetname == Str_Teamname )
					pPlayer.pev.frags += 100;
			}
		}
	}
	
	void RespawnPlayers()
	{
		FoundRndSpwan();
		RndWeapons();
		m_iLMSRoundTime = 0;
		m_flLMSRadius = 0;
		IsDrop = false;
		g_PlayerFuncs.RespawnAllPlayers(true, true);
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				pPlayer.RemoveAllItems(false);
				pPlayer.SetItemPickupTimes(0);
				pPlayer.GiveNamedItem("weapon_9mmhandgun" , 1 , 34 );
				pPlayer.GiveNamedItem("weapon_crowbar" , 0 , 0 );
				pPlayer.pev.health = 100;
				pPlayer.pev.armorvalue = 0;
			}
		}
	}
	
	void AlivePlayerCounter()
	{
		if( !m_bLMSActive )
			return;
		if(IsLMS())
		{
			if( g_Engine.maxClients > 1 )
			{
				if(!IsTDM())
				{
					CBasePlayer@ cPlayer;
					int8 m_shortAlivePlayer = 0;
					for (int i = 1; i <= g_Engine.maxClients; i++)
					{
						CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
						if(pPlayer !is null && pPlayer.IsConnected())
						{
							if(pPlayer.IsAlive())
							{
								m_shortAlivePlayer++;
								@cPlayer = @pPlayer;
							}
						}
					}
					if( m_shortAlivePlayer <= 1 && !IsTDM() )
						RoundEnd( cPlayer , m_shortAlivePlayer );
				}
				else
				{
					int8 m_iTeam1Player = 0, m_iTeam2Player = 0;
					bool m_bHaveTeam = false;
					for (int i = 1; i <= g_Engine.maxClients; i++)
					{
						CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
						if(pPlayer !is null && pPlayer.IsConnected())
						{
							if(pPlayer.IsAlive())
							{
								if(pPlayer.pev.targetname == "team1")
								{
									m_iTeam1Player++;
									m_bHaveTeam = true;
								}
								else if (pPlayer.pev.targetname == "team2")
								{
									m_iTeam2Player++;
									m_bHaveTeam = true;
								}
								else
								{	
									if( m_iTeam2 >= m_iTeam1 )
										PVPTeam::AddToTeam1(pPlayer);
									else
										PVPTeam::AddToTeam2(pPlayer);
								}
							}
						}
					}
					if(( m_iTeam1Player == 0 || m_iTeam2Player == 0 ) && m_bHaveTeam )
						TeamRoundEnd ( m_iTeam1Player, m_iTeam2Player );
				}
				SendMessage();
			}
		}
		else
			DisableLMS();
	}
	
	void SendMessage()
	{
		Param.x = -1;
		Param.y = 0.97;
			
		Param.r1 = 200;
		Param.g1 = 122;
		Param.b1 = 100;
		Param.a1 = 0;

		Param.fadeinTime = 0.1;
		Param.holdTime = 1;
		Param.channel = 11;
		
		m_iLMSRoundTime++;
		
		if( m_iLMSRoundTime >= m_iLMSMaxTime )
			TimeOut();
		else
			g_PlayerFuncs.HudMessageAll( Param, "Round time left: " + (m_iLMSMaxTime - m_iLMSRoundTime) + "s." );
			
		if( m_iLMSRoundTime >= m_iLMSMaxTime/2 && !IsDrop )
			SupplyIt();
	}
	
	void SupplyIt()
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Watch out, a supply case is landing!\n" );
		IsDrop = true;
		Vector vecOrigin;
		if(RandomVector.length() > 0)
			vecOrigin = RandomVector[Math.RandomLong(0,RandomVector.length() - 1)];
		else
			vecOrigin = vecRnd2;
		CBaseEntity@ aSupply = g_EntityFuncs.Create( "item_lmssupply",vecOrigin,Vector(0,0,0),false, null);
		g_DMUtility.te_beampoints ( vecOrigin, vecOrigin + Vector(0,0,4096), Vector(205,15,32),196, "sprites/laserbeam.spr", 0, 100, 64, 96, 0 );
	}
	
	void TimeOut()
	{
		m_flLMSRadius += 64;
		float BattleRadius = Math.max(m_flLMSMaxRadius - m_flLMSRadius, 512);
		CBasePlayer@ pPlayer = null;
		while((@pPlayer = cast<CBasePlayer@>(g_EntityFuncs.FindEntityByClassname(pPlayer, "player"))) !is null)
		{
			if(pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive())
			{
				SendEscapeHUD( pPlayer, vecRnd );
				float le = (pPlayer.pev.origin - vecRnd).Length();
				if( le >= BattleRadius )
				{
					g_PlayerFuncs.ScreenFade(pPlayer, Vector(137,207,240), 0.2, 0.1, 25, FFADE_OUT);
					pPlayer.TakeDamage(g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, 5.0f, DMG_SHOCK);
					g_PlayerFuncs.ClientPrint( cast<CBasePlayer@>(pPlayer), HUD_PRINTCENTER, "You are in the shock zone!\n" );
				}
			}
		}
		g_DMUtility.te_beamcylinder( vecRnd, BattleRadius, uint(BattleRadius) ,Vector(137,207,240));
		g_DMUtility.te_beampoints ( vecRnd, vecRnd + Vector(0,0,4096), Vector(128,0,128),196, "sprites/laserbeam.spr", 0, 100, 10, 96, 0 );
		
		g_PlayerFuncs.HudMessageAll( Param, "Time out, Reducing playable zone." );
		//g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, all you guys are losers!\n" );
	}
	
	void FoundRndSpwan()
	{
		CBaseEntity@ pWeapon = null;
		while((@pWeapon = g_EntityFuncs.FindEntityByClassname(pWeapon, "weaponbox")) !is null)
		{
			g_EntityFuncs.Remove(pWeapon);
		}
		
		array<Vector> vecOrigin = {};
		CBaseEntity@ pSpawn = null;
		while((@pSpawn = g_EntityFuncs.FindEntityByClassname(pSpawn, "info_player_*")) !is null)
		{
			vecOrigin.insertLast(pSpawn.pev.origin);
		}
		uint8 index = Math.RandomLong( 0, vecOrigin.length() - 1 );
		vecRnd = vecOrigin[ index ];
		vecRnd2 = vecOrigin[ Math.clamp(0, vecOrigin.length() - 1, index) ];
	}
	
	void SendEscapeHUD( CBasePlayer@ pPlayer, Vector&in vecIn , float hold = 0.2 )
	{
		Vector vecLengh = pPlayer.pev.origin - vecIn;
		HUDSpriteParams params;

		Vector vecAngle = vecLengh/vecLengh.Length();
		vecAngle = Vector(vecAngle.x + 1, vecAngle.y + 1, vecAngle.z + 1).opDiv(2);
				
		Vector vecAim = pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES )/pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES ).Length();
		vecAim = Vector(vecAim.x + 1, vecAim.y + 1, vecAim.z + 1 ).opDiv(2);
				
		Vector2D vecHUD = ((vecAngle + vecAim)/2).Make2D();
				
		params.channel = 6;
		params.spritename = "misc/escape.spr";
		params.fadeinTime = 0.1;
		params.fadeoutTime = 0.4;
		params.x = vecHUD.x ;
		params.y = vecHUD.y ;
		params.holdTime = hold;
		params.color1 = RGBA_SVENCOOP;
		g_PlayerFuncs.HudCustomSprite( pPlayer, params );
	}
}

class CLMSMode
{
	void LMSModeInitialized()
	{
		ReadVector();
		InfoRegister();
		CLMSVote::Precache();
		CLMSVote::vecWeapons = {};
		CLMSVote::m_iRoundCounter = CLMSVote::m_iLMSRoundTime = 0;
		CLMSVote::m_flLMSRadius = 0;
		g_SurvivalMode.SetStartOn( false );
		g_SurvivalMode.Disable();
		g_SurvivalMode.SetDelayBeforeStart( 0.1 );
		CLMSVote::m_bLMSActive = false;
		g_SoundSystem.PrecacheSound("barney/ba_bring.wav");
		g_Game.PrecacheModel( "sprites/laserbeam.spr" );
		g_Game.PrecacheModel( "sprites/misc/escape.spr" );
		g_Game.PrecacheModel( "models/dm_weapons/lms_supply.mdl" );
		
		g_Game.PrecacheGeneric("sprites/misc/escape.spr");
		g_Game.PrecacheGeneric("models/dm_weapons/lms_supply.mdl");
	}
	
	void InfoRegister()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "item_lmssupply", "item_lmssupply" );
		g_DMEntityList.insertLast("item_lmssupply");
	}
	
	void ReadVector()
	{
		const string g_LMSVecFile = "scripts/plugins/pvp/config/LMSVector/" + string(g_Engine.mapname).ToLowercase() + ".ini";
		File@ file = g_FileSystem.OpenFile(g_LMSVecFile, OpenFile::READ);
		if (file !is null && file.IsOpen()) 
		{
			while(!file.EOFReached()) 
			{
				string sLine;
				file.ReadLine(sLine);
				if (sLine.SubString(0,1) == "//" || sLine.IsEmpty())
					continue;

				array<string> parseds = sLine.Split(" ");
				if (parseds.length() < 3)
					continue;
				
				Vector vecRnd;
				vecRnd.x = atoi(parseds[0]);
				vecRnd.y = atoi(parseds[1]);
				vecRnd.z = atoi(parseds[2]);
				CLMSVote::RandomVector.insertLast(vecRnd);
			}
			file.Close();
		}
	}
}
CLMSMode g_LMSMode;

class item_lmssupply : ScriptBaseEntity
{	
	private int SupplyAmonut = 3 ;
	void Spawn()
	{ 
		pev.solid = SOLID_SLIDEBOX;
        pev.movetype = MOVETYPE_FLY;
		pev.velocity = Vector( 0, 0, -32 );
		BaseClass.Spawn();
		g_EntityFuncs.SetModel( self, "models/dm_weapons/lms_supply.mdl" );
		SetTouch( TouchFunction( this.Touch ) );
	}
	
	void Touch ( CBaseEntity@ pOther ) 
	{
		pev.velocity = Vector( 0, 0, 0 );
		pev.solid = SOLID_NOT;
		
		for (int i = 1; i <= 3; i++)
		{
			TraceResult tr;
			Vector vecSrc = pev.origin + g_Engine.v_up * 16;
			Vector vecEnd = (vecSrc + g_Engine.v_right * i * 4 + g_Engine.v_forward * i * 4) * 48;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
			Vector vecSupOrigin = tr.vecEndPos;
			CBaseEntity@ aSupply = g_EntityFuncs.Create( CLMSVote::DropWeaponList[Math.RandomLong(0,CLMSVote::DropWeaponList.length()-1)],vecSupOrigin,Vector(0,0,0),false, self.edict());
			aSupply.KeyValue("m_flCustomRespawnTime", "-1");
		}
		
		g_EntityFuncs.Remove( self ); 
	}
}