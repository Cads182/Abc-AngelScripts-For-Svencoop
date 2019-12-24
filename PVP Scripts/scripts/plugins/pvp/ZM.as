/***				Zombie Mode - Dr.Abc
							 - Dr.Abc@foxmail.com ****/
							 
#include "ZMEnchance"

#include "dm_weapons/ZM/weapon_zombieclaw"

namespace CSvenZM
{
	const float m_flGatherMaxTime  = 20.0f;
	const float g_ZMTiemLeft = 200.0f;
	const float IntitalZombieGrav = 0.8;
	const float ZombieGrav = 0.9;
	const Vector ZombieEyeColor = Vector(191,42,42);
	const int MultiShock = 9;
	const int ZombieSpeed = 300;
	const int HumanSpeed = 270;
	const int IntitalZombieHP = 500;
	const int ZombieHP = 200;
	const int BHopLimit = 400;
	const bool CanWeBHop = false;
	const string MapLight = "d";
	const string NVpharse = "nvsight";
	const string ZMSkyName = "carnival";
	const array<array<string>> g_ZMSkill = {{"mp_weapon_droprules", "0"},
											{"mp_dropweapons", "0"},
											{"mp_ammo_droprules", "0"},
											{"sk_suitcharger", "0"},
											{"sk_healthcharger", "0"},
											{"mp_npckill", "2"},
											{"sv_maxspeed", "300"}};
	
	int  m_iGatherTime, m_iRoundTime;
	uint8 winnercounter = 1;
	bool m_bIsZM, m_bIsWarining,m_bSelected,m_bOpenMenu,m_bCoundRespwan,IsBGM;
	bool b_IsWin = false;
	dictionary d_Playermodel,pPlayerData,pZombieData;
	CTextMenu@ pMenu = null;
	CTextMenu@ sMenu = null;
	CScheduledFunction@ pSchedu = null;
	CScheduledFunction@ nSchedu = null;
	HUDNumDisplayParams params;
	
	
	class CHumanData{ Vector Pos; EHandle thisHandle; }
	class CZombieData{ bool IsNVSight; bool CanWeRespwan; }
	
	array<string>@pPlayerDataKey;
	array<string>pZombieName;
	
	array<string> pWeaponList = {
		"weapon_crossbow",
		"weapon_shotgun",
		"weapon_rpg",
		"weapon_sniperrifle",
		"weapon_m249",
		"weapon_m16",
		"weapon_sporelauncher",
		"weapon_displacer"};
		
	array<string> pWeaponCLList = {
		"weapon_dmbow",
		"weapon_rpg",
		"weapon_hlmp5",
		"weapon_sniperrifle",
		"weapon_m249",
		"weapon_m16",
		"weapon_sporelauncher",
		"weapon_displacer"};
	
	array<string> sWeaponList = {
		"weapon_satchel",
		"weapon_snark",
		"weapon_uziakimbo",
		"weapon_eagle"};
		
	array<string> sWeaponCLList = {
		"weapon_dm357",
		"weapon_satchel",
		"weapon_dmsnark",
		"weapon_uziakimbo",
		"weapon_eagle"};
		
	array<string> AllAmmoList = {
		"buckshot",
		"556",
		"m40a1",
		"argrenades",
		"357",
		"9mm",
		"sporeclip",
		"rockets",
		"bolts",
		"uranium",
		"monster_flarelight",
		"trip mine", 
		"satchel charge",
		"hand grenade", 
		"snarks",
		"Hornet",
		"shock"};
	
	bool IsZM()
	{
		if(!m_bIsTDM && !m_bIsScore)
		{
			const string szMapName = string(g_Engine.mapname).ToLowercase();
			const CMapData@ data = cast<CMapData@>(g_ReadFiles.g_PVPMapList[szMapName]);
			if(data is null)
				return false;
			if(data.MapMode == 3)
				return true;
			return false;
		}
		return false;
	}
	
	bool OnlyZombie()
	{
		if(g_PlayerFuncs.GetNumPlayers() <= 1)
			return false;
		
		uint8 human = 0;
		CBaseEntity@ pEntity = null;
		while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "human")) !is null)
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEntity);
			if( pPlayer.IsConnected() && pPlayer.IsAlive() )
				human++;
		}
		if( human == 0 )
			return true;
		return false;
	}
	
	bool OnlyHuman()
	{
		uint8 zombie = 0;
		CBaseEntity@ pEntity = null;
		while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "zombie")) !is null)
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEntity);
			if(pPlayer.IsPlayer() && pPlayer.IsConnected() && pPlayer.IsAlive())
				zombie++;
		}
		if(zombie != 0)
			return false;		
		return true;
	}
	
	bool CountAlive()
	{
		uint8 alive = 0;
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
				alive++;
		}
		if( alive <= 0)
			return false;
		return true;
	}
	
	bool InNVOList( CBasePlayer@ pPlayer )
	{
		const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		if(pZombieData.exists(szSteamId))
		{
			const CZombieData@ data = cast<CZombieData@>(pZombieData[szSteamId]);
			if( data is null )
				return true;
			else if(data.IsNVSight)
				return true;
			else
				return false;
		}
		return true;
	}
	
	bool IsHumanWin()
	{
		if( m_iGatherTime >= m_flGatherMaxTime )
		{
			if(g_ZMTiemLeft + m_flGatherMaxTime - m_iRoundTime <= 0 || OnlyHuman())
				return true;
		}
		return false;
	}
	
	bool CheakRespwan( CBasePlayer@ pPlayer )
	{
		const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		if(m_bCoundRespwan && !pPlayer.IsAlive())
		{
			if(pZombieData.exists(szSteamId))
			{
				const CZombieData@ data = cast<CZombieData@>(pZombieData[szSteamId]);
				if( data !is null )
					return data.CanWeRespwan;
				else
					return false;
			}
			return true;
		}
		return false;
	}
	
	void ZMModeResetvariable()
	{
		CSvenZM::m_bIsZM = false;
		
		CSvenZM::m_iRoundTime = 0;
		CSvenZM::m_iGatherTime = 0;
		CSvenZM::winnercounter = 0;
		
		CSvenZM::m_bIsWarining = false;
		CSvenZM::m_bSelected = false;
		CSvenZM::m_bOpenMenu = false;
		CSvenZM::IsBGM = false;
		CSvenZM::b_IsWin = false;
		CSvenZM::m_bCoundRespwan = true;
		
		CSvenZM::d_Playermodel.deleteAll();
		CSvenZM::pPlayerData.deleteAll();
		CSvenZM::pZombieData.deleteAll();
		
		CZMEnchance::ZMEnchanceResetvariable();
	}
	
	
	void ZMModeInitialized()
	{
		m_bIsZM = false;
		
		m_iRoundTime = 0;
		m_iGatherTime = 0;
		winnercounter = 1;
		m_bIsWarining = false;
		m_bSelected = false;
		m_bOpenMenu = true;
		IsBGM = true;
		m_bCoundRespwan = true;
		d_Playermodel.deleteAll();
		
		@pMenu = CTextMenu(pMenuRespond);
		@sMenu = CTextMenu(sMenuRespond);
		pMenu.SetTitle("[Vending Machine]\nChose weapons 4 your life.\n");
		sMenu.SetTitle("[Vending Machine]\nChose weapons 4 your life.\n");
		
		for (uint i = 0; i < (IsClassMode ? pWeaponCLList : pWeaponList).length(); i++) 
		{
			array<string> gargs = { IsClassMode ? pWeaponCLList[i] : pWeaponList[i]};
			pMenu.AddItem(gargs[0], null);
		}
		
		for (uint i = 0; i < (IsClassMode ? sWeaponCLList : sWeaponList).length(); i++) 
		{
			array<string> gargs = { IsClassMode ? sWeaponCLList[i] : sWeaponList[i]};
			sMenu.AddItem(gargs[0], null);
		}
		
		pMenu.Register();
		sMenu.Register();
	}
	
	void pMenuRespond(CTextMenu@ mMenu, CBasePlayer@ pPlayer, int iPage, const CTextMenuItem@ mItem)
	{
		if(mItem !is null && pPlayer !is null)
		{
			if(pPlayer.pev.targetname == "human")
			{
				pPlayer.GiveNamedItem(mItem.m_szName, 0, 0);
				sMenu.Open(0, 0, pPlayer);
			}
		}
	}
	
	void sMenuRespond(CTextMenu@ mMenu, CBasePlayer@ pPlayer, int iPage, const CTextMenuItem@ mItem)
	{
		if(mItem !is null && pPlayer !is null)
		{
			if(pPlayer.pev.targetname == "human")
			{
				pPlayer.GiveNamedItem(mItem.m_szName, 0, 0);
				AmmoResupply(pPlayer);
			}
		}
	}
	
	void AmmoResupply( CBasePlayer@ pPlayer )
	{
		for (uint u = 0; u < AllAmmoList.length(); u++) 
		{
			int m_iAmmoIndex = g_PlayerFuncs.GetAmmoIndex(AllAmmoList[u]);
			pPlayer.m_rgAmmo(m_iAmmoIndex , pPlayer.GetMaxAmmo(m_iAmmoIndex));
		}
	}
	
	void ZMSchedulerCall()
	{
		if(IsZM())
		{
			@pSchedu = g_Scheduler.SetInterval( "GatheringTime", 1.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
			@nSchedu = g_Scheduler.SetInterval( "NVOSight", 0.1f, g_Scheduler.REPEAT_INFINITE_TIMES );
		}
	}
	
	void NVOSight()
	{
		CBaseEntity@ pEntity = null;
		while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "zombie")) !is null)
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEntity);
			if( pPlayer.IsConnected() && pPlayer.IsAlive() )
			{
				if(InNVOList(pPlayer))
				{
					Vector vecSrc = pPlayer.EyePosition();
					g_DMUtility.te_NVSight( pPlayer, vecSrc );
				}
			}
		}
	}
	
	void GatheringTime()
	{
		if(!m_bIsStart)
			return;
			
		if(!CountAlive())
			ZombieWin();
		
		m_iRoundTime++;
		
		if( m_iRoundTime >= g_ZMTiemLeft/5*4 )
			m_bIsWarining = true;
			
		if(m_bOpenMenu)
		{
			OpenMenu();
			m_bOpenMenu = false;
		}
			
		if( m_iGatherTime < m_flGatherMaxTime)
		{
			if(IsBGM)
				Music();
			m_iGatherTime++;
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Initial zombies will appeared in " + (m_flGatherMaxTime - m_iGatherTime) + "s.\n" );
		}
		else
		{
			if(!m_bSelected )
			{
				g_SurvivalMode.Activate(true);
				SelecteZombie();
			}
			else
			{
				SendTime();	
				HumanTimer();
				if(int(g_Engine.time % 2) == 0)
					Revive();
				
				if(!b_IsWin)
				{
					if(g_PlayerFuncs.GetNumPlayers() > 1)
					{
						if(OnlyZombie())
							ZombieWin();
						
						else if(IsHumanWin())
							HumanWin();
					}
					ZombieEquip();
				}
				else
				{
					winnercounter++;
					if( winnercounter == 10)
						RespawnPlayers();
				}
			}
		}
	}
	
	void Music()
	{
		g_SoundSystem.EmitSound( g_EntityFuncs.IndexEnt(0), CHAN_MUSIC, "pvp_zm/ambience.wav", 1.0, ATTN_NONE );
		IsBGM = false;
	}
	
	void ZombieEquip()
	{
		CBaseEntity@ pEntity = null;
		while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "zombie")) !is null)
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEntity);
			if( pPlayer.IsConnected() && pPlayer.IsAlive() )
				pPlayer.SetItemPickupTimes(-1);
		}
	}
	
	void HumanTimer()
	{
		CBaseEntity@ pPlayer = null;
		while((@pPlayer = g_EntityFuncs.FindEntityByTargetname(pPlayer, "human")) !is null)
		{
			if( pPlayer.IsAlive() && pPlayer.IsPlayer() && pPlayer.IsNetClient() )
			{
				const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
				EHandle thisHandle = pPlayer;
				
				if(pPlayerData.exists(szSteamId))
				{
					CHumanData@ data = cast<CHumanData@>(pPlayerData[szSteamId]);
					data.thisHandle = thisHandle;
					data.Pos = pPlayer.pev.origin + g_Engine.v_up * 64;
					pPlayerData[szSteamId] = data;
				}
				else
				{
					CHumanData data;
					data.thisHandle = thisHandle;
					data.Pos = pPlayer.pev.origin + g_Engine.v_up * 64;
					pPlayerData[szSteamId] = data;
				}
			}
		}
		
		@pPlayerDataKey = pPlayerData.getKeys();
		for(uint i=0; i<uint(pPlayerDataKey.length()); i++)
		{
			CHumanData data = cast<CHumanData@>(pPlayerData[pPlayerDataKey[i]]);
			CBaseEntity@ pEntity = data.thisHandle;
			if( pEntity is null || !pEntity.IsAlive() || pEntity.pev.targetname != "human" )
			{
				CBaseEntity@ pAmmo = g_EntityFuncs.Create("item_zmbrain", data.Pos ,Vector(Math.RandomLong (-25,25),Math.RandomLong (-25,25),Math.RandomLong (-25,25)), false);
				pPlayerData.delete(pPlayerDataKey[i]);
			}
		}
	}
	
	void OpenMenu()
	{			
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
			{
				if(pPlayer.pev.targetname == "human")
					pMenu.Open(0, 0, pPlayer);
			}
		}
	}
	
	void SelecteZombie()
	{
		if (uint8(g_PlayerFuncs.GetNumPlayers()) <= 0)
			return;
		
		int8 ShouldZombie = Math.max(int(g_PlayerFuncs.GetNumPlayers()/4),1);
		
		array<EHandle>arrayHandle = {};
		array<int8>arrayint = {};
		
		for (int8 i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected() && pPlayer.IsAlive() )
			{
				EHandle Handled = pPlayer;
				arrayHandle.insertLast(Handled);
			}
		}
		
		for(int8 j = 1; j <= ShouldZombie; j++)
		{
			arrayint.insertLast(Math.RandomLong( 0, g_PlayerFuncs.GetNumPlayers() - 1 ));
		}
		
		if(arrayint.length() > 1)
			for(uint8 c = 0; c < arrayint.length(); c++)
			{
				for(uint8 b = 0; b < arrayint.length(); b++)
				{
					if(arrayint[c] == arrayint[b])
					{
						if(arrayint[c] != g_PlayerFuncs.GetNumPlayers() - 1 )
							arrayint[c] = Math.RandomLong( arrayint[c] + 1, g_PlayerFuncs.GetNumPlayers() - 1 );
						else
							arrayint[c] = Math.RandomLong( 0, arrayint[c] - 1 );
					}
				}
			}
		
		for(uint8 f = 0; f < arrayint.length(); f++)
		{
			CBaseEntity@ pEntity = arrayHandle[arrayint[f]];
			pZombieName.insertLast(string(pEntity.pev.netname));
			BecomeZombie( cast<CBasePlayer@> ( pEntity ) );
		}
		
		WarnHUD();
		
		arrayHandle = {};
		arrayint = {};
		
		m_bSelected = true;
	}
	
	void WarnHUD()
	{
		HUDTextParams params1;
		
		params1.x = -1;
		params1.y = 0.4 - ((pZombieName.length()) * 0.005);
			
		params1.r1 = 200;
		params1.g1 = 122;
		params1.b1 = 100;
		params1.a1 = 0;

		params1.fadeinTime = 0.1;
		params1.holdTime = 3;
		params1.channel = 11;
		
		string szName = "";
		for(uint i = 0; i <= pZombieName.length() - 1; i++)
		{
			szName = szName + pZombieName[i] + "\n";
		}
		g_PlayerFuncs.HudMessageAll( params1, szName + " became the zombie!.\n" );
		pZombieName = {};

	}
	
	void BecomeZombie( CBasePlayer@ pPlayer , bool IsIntial = true , bool IsRevive = false )
	{
		pPlayer.pev.targetname = "zombie";
		g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", 14 );
		g_DMUtility.CCommandApplyer(pPlayer,"setinfo model " + (IsIntial ? "Gonome" : "zombie_HD") );
		
		pPlayer.RemoveAllItems(false);
		if(!b_IsWin)
			pPlayer.GiveNamedItem("weapon_zombieclaw", 0, 0);
		
		if(!IsRevive)
		{
			switch(Math.RandomLong(0,1))
			{
				case 0 :g_SoundSystem.EmitSound( g_EntityFuncs.IndexEnt(0), CHAN_MUSIC, "pvp_zm/human_pain1.wav", 0.5, ATTN_NONE );break;
				case 1 :g_SoundSystem.EmitSound( g_EntityFuncs.IndexEnt(0), CHAN_MUSIC, "pvp_zm/human_pain2.wav", 1.0, ATTN_NONE );break;
			}
		}
		
		pPlayer.pev.max_health = g_PlayerFuncs.GetNumPlayers() * (IsIntial ? IntitalZombieHP : ZombieHP );
		pPlayer.pev.health = pPlayer.pev.max_health;
		pPlayer.pev.maxspeed = ZombieSpeed;
		pPlayer.pev.gravity = (IsIntial ? IntitalZombieGrav : ZombieGrav );
		pPlayer.pev.armorvalue = 100;
		pPlayer.SetItemPickupTimes(-1);
		
		if(InNVOList(pPlayer))
			g_PlayerFuncs.ScreenFade( pPlayer, ZombieEyeColor, 0.01, 0.5, 64, FFADE_OUT | FFADE_STAYOUT);
	}
	
	void BecomeHuman ( CBasePlayer@ pPlayer )
	{
		pPlayer.pev.targetname = "human";
		g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", 2 );
		
		pPlayer.pev.max_health = 100;
		pPlayer.pev.health = pPlayer.pev.max_health;
		pPlayer.pev.armorvalue = 0;
		pPlayer.pev.maxspeed = HumanSpeed;
		pPlayer.m_flEffectSpeed = 100.0f;
		pPlayer.pev.gravity = 1;
		pPlayer.SetItemPickupTimes(0);
		
		g_PlayerFuncs.ScreenFade( pPlayer, ZombieEyeColor, 0.01, 0.1, 32, FFADE_IN);
		
		g_SoundSystem.StopSound( pPlayer.edict(), CHAN_VOICE, "player/heartbeat1.wav" );
		
		KeyValueBuffer@ pInfo = g_EngineFuncs.GetInfoKeyBuffer(pPlayer.edict());
		const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		string szpModel = pInfo.GetValue("model");
		if(!d_Playermodel.exists(szSteamId))
		{
			if( szpModel == "Gonome" || szpModel == "zombie_HD")
				d_Playermodel[szSteamId] = "barney";
			else
				d_Playermodel[szSteamId] = szpModel;
		}
		g_DMUtility.CCommandApplyer(pPlayer,"setinfo model " + string(d_Playermodel[szSteamId]) );
	}
	
	void SendTime ()
	{
		params.channel = 7;
		params.flags = HUD_ELEM_DEFAULT_ALPHA | HUD_TIME_MINUTES | HUD_TIME_SECONDS | HUD_ELEM_SCR_CENTER_X | HUD_TIME_COUNT_DOWN;
		if(m_bIsWarining)
		{
			params.flags +=  HUD_TIME_MILLISECONDS ;
		}
		params.x = 0;
		params.y = 0.06;
		params.value = g_ZMTiemLeft + m_flGatherMaxTime - m_iRoundTime;
		params.color1 = m_bIsWarining ? RGBA_RED : RGBA_SVENCOOP;
		params.spritename = "stopwatch";
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				g_PlayerFuncs.HudTimeDisplay( pPlayer, params );
				if(pPlayer.IsAlive())
					BHopTimer(pPlayer);
			}
		}
	}
	
	void BHopTimer( CBasePlayer@ pPlayer )
	{
		if(!CanWeBHop)
		{
			Vector vecSpeed = pPlayer.pev.velocity;
			vecSpeed.z = 0;
			if(vecSpeed.Length() >= BHopLimit )
				pPlayer.pev.velocity = pPlayer.pev.velocity.opDiv(2);
		}
	}
	
	void Revive()
	{
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				if(CheakRespwan(pPlayer))
				{
					g_PlayerFuncs.RespawnPlayer( pPlayer , true , true );
					BecomeZombie( pPlayer , false , true );
				}
			}
		}
	}
	
	void ZombieWin()
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Zombies ate everyone's brain.\n" );
		EndGame( "zombie" );
		b_IsWin = true;
	}
	
	void HumanWin()
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "Human just survived and kept thier brain.\n" );
		EndGame( "human" );
		b_IsWin = true;
	}
	
	void EndGame( string&in szTeam )
	{
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				if( pPlayer.pev.targetname == szTeam )
					pPlayer.pev.frags += 20;
				if( pPlayer.pev.targetname == "zombie" )
					pPlayer.RemoveAllItems(false);
			}
		}
		m_bCoundRespwan = false;
	}
	
	void RespawnPlayers()
	{
		m_iRoundTime = 0;
		m_iGatherTime = 0;
		winnercounter = 1;
		
		m_bIsWarining = false;
		m_bSelected = false;
		m_bOpenMenu = true;
		m_bCoundRespwan = true;
		IsBGM = true;
		b_IsWin = false;
		
		//BreakbleReset();
		
		pPlayerData.deleteAll();
		for (int i = 0; i <= g_Engine.maxClients + 1; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
				if(pZombieData.exists(szSteamId))
				{
					CZombieData@ data = cast<CZombieData@>(pZombieData[szSteamId]);
					data.CanWeRespwan = true;
					pZombieData[szSteamId] = data;
				}
				
				GiveWeapon(pPlayer);
				BecomeHuman(pPlayer);
			}
		}
		CBaseEntity@ pEntity = null;
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "item_zmbrain") ) !is null )
		{
				g_EntityFuncs.Remove(pEntity);
		}
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_"  + "*" ) ) !is null )
		{
				g_EntityFuncs.Remove(pEntity);
		}
		g_PlayerFuncs.RespawnAllPlayers(true, true);
	}
	
	void GiveWeapon( CBasePlayer@ pPlayer )
	{
		pPlayer.RemoveAllItems(false);
		pPlayer.SetItemPickupTimes(0);
		pPlayer.GiveNamedItem("weapon_9mmhandgun" , 1 , 34 );
		pPlayer.GiveNamedItem("weapon_357" , 1 , 34 );
		pPlayer.GiveNamedItem("weapon_shotgun" , 1 , 34 );
		pPlayer.GiveNamedItem("weapon_9mmAR" , 1 , 34 );
		pPlayer.GiveNamedItem("weapon_crowbar" , 0 , 0 );
		pPlayer.pev.health = 100;
		pPlayer.pev.armorvalue = 0;
	}
	
	void BreakbleReset()
	{
		CBaseEntity@ pEntity = null;
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_breakble") ) !is null )
		{
			pEntity.pev.health = pEntity.pev.max_health;
			pEntity.pev.deadflag = DEAD_NO;
		}
	}
}

class CSvenZM
{
	void ZMMapInit()
	{
		if( CSvenZM::IsZM() || CSvenZM::m_bIsZM )
		{
			CSvenZM::ZMModeInitialized();
			
			CSvenZM::pPlayerData.deleteAll();
			CSvenZM::d_Playermodel.deleteAll();
			
			for(uint i = 0; i < CSvenZM::g_ZMSkill.length() - 1 ; i ++ )
			{
				g_DMUtility.CServerCommand( CSvenZM::g_ZMSkill[i][0], atof(CSvenZM::g_ZMSkill[i][1]) );
			}
			
			RegisterZMClaw();
			RegisterFlaregun();
			
			g_EngineFuncs.LightStyle(0, CSvenZM::MapLight);
			
			m_bSendTime = false;
			
			g_SurvivalMode.SetStartOn( false );
			g_SurvivalMode.Enable();
			g_SurvivalMode.SetDelayBeforeStart( 0.1 );
			
			CSvenZM::ZMSchedulerCall();

			g_Game.PrecacheModel( "models/player/Gonome/Gonome.mdl" );
			g_Game.PrecacheModel( "models/player/zombie_HD/zombie_HD.mdl" );
			
			g_SoundSystem.PrecacheSound( "zombie/zo_pain1.wav" );
			g_SoundSystem.PrecacheSound( "zombie/zo_pain2.wav" );
			g_SoundSystem.PrecacheSound( "pvp_zm/ambience.wav" );
			g_SoundSystem.PrecacheSound( "pvp_zm/human_pain1.wav" );
			g_SoundSystem.PrecacheSound( "pvp_zm/human_pain2.wav" );
			
			g_Game.PrecacheGeneric( "sound/pvp_zm/ambience.wav" );
			g_Game.PrecacheGeneric( "sound/pvp_zm/human_pain1.wav" );
			g_Game.PrecacheGeneric( "sound/pvp_zm/human_pain2.wav" );
			
			g_ZMEnchance.EnchanceInit();
		}
		else
		{
			CSvenZM::ZMModeResetvariable();
		}
	}
	
	void ZMItemRemover()
	{
		if( CSvenZM::IsZM() || CSvenZM::m_bIsZM )
		{
			CBaseEntity@ pEntity = null;
			while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "weapon_" + "*") ) !is null )
			{
				g_EntityFuncs.Remove(pEntity);
			}
			while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "ammo_" + "*") ) !is null )
			{
				g_EntityFuncs.Remove(pEntity);
			}
			while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "item_" + "*") ) !is null )
			{
				g_EntityFuncs.Remove(pEntity);
			}
			while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "func_tank" + "*") ) !is null )
			{
				g_EntityFuncs.Remove(pEntity);
			}
			while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "info_player_start") ) !is null )
			{
				CBaseEntity@ cEntity = g_EntityFuncs.CreateEntity( "info_player_deathmatch", null, false );
				cEntity.pev.maxs = pEntity.pev.maxs;
				cEntity.pev.mins = pEntity.pev.mins;
				cEntity.pev.origin = pEntity.pev.origin;
				cEntity.pev.angles = pEntity.pev.angles;
				cEntity.pev.target = pEntity.pev.target;
				g_EntityFuncs.DispatchSpawn( cEntity.edict() );
				g_EntityFuncs.Remove(pEntity);
			}
			
			g_EntityFuncs.DispatchKeyValue(g_EntityFuncs.IndexEnt(0), "skyname", ZMSkyName );
			//g_Game.AlertMessage( at_console, "foundit\nfoundit\nfoundit\nfoundit\n" );
		}
	}

	
	void WeaponShock(  CBasePlayer@ pPlayer, float flDamage , CBasePlayer@ pAttacker )
	{
		if(pPlayer.pev.targetname == "zombie" && CSvenZM::IsZM())
		{
			pPlayer.pev.velocity = Vector(0,0,0) + g_Engine.v_forward * flDamage * CSvenZM::MultiShock + g_Engine.v_up * 80;
			switch( Math.RandomLong( 0, 2 ) )
			{
				case 0:g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, "zombie/zo_pain1.wav", 0.45, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ));	break;
				case 1:g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_VOICE, "zombie/zo_pain2.wav", 0.45, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF )); break;
			}
			CZMEnchance::DoneDamage( pPlayer , flDamage , pAttacker );
		}
	}
	
	void CritKill( CBasePlayer@ pPlayer , int bitsDamageType )
	{
		if(!CSvenZM::IsZM())
			return;
		
		if(bitsDamageType & DMG_BLAST != 0 || bitsDamageType & DMG_ALWAYSGIB != 0)
		{
			const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
			if(CSvenZM::pZombieData.exists(szSteamId))
			{
				CSvenZM::CZombieData@ data = cast<CSvenZM::CZombieData@>(CSvenZM::pZombieData[szSteamId]);
				data.CanWeRespwan = false;
				data.IsNVSight = data.IsNVSight;
				CSvenZM::pZombieData[szSteamId] = data;
			}
		}
	}
	
	void PlayerDis( CBasePlayer@ pPlayer )
	{
		if(CSvenZM::IsZM())
		{
			const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
			if(CSvenZM::pPlayerData.exists(szSteamId))
				CSvenZM::pPlayerData.delete(szSteamId);
			if(CSvenZM::pZombieData.exists(szSteamId))
				CSvenZM::pZombieData.delete(szSteamId);
			
			g_ZMEnchance.ClientDis( pPlayer );
		}
	}
	
	void BuildDic( CBasePlayer@ pPlayer )
	{
		CSvenZM::BecomeHuman(pPlayer);
		
		const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		CSvenZM::CZombieData data;
		data.IsNVSight = true;
		data.CanWeRespwan = true;
		g_PlayerFuncs.ScreenFade( pPlayer, CSvenZM::ZombieEyeColor, 0, 0, 0, FFADE_IN );
		CSvenZM::pZombieData[szSteamId] = data;
		
		CZMEnchance::BuildDic(szSteamId);
	}
	
	void ClientSay( SayParameters@ pParams )
	{
		if(CSvenZM::IsZM())
		{
			const CCommand@ pArguments = pParams.GetArguments();
			CBasePlayer@ pPlayer = pParams.GetPlayer();
			if(pPlayer !is null)
			{
				if((pArguments[0].ToLowercase() == "!" + NVpharse || pArguments[0] == "/" + NVpharse))
				{
					if(pPlayer.pev.targetname == "zombie")
					{
						const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
						if(CSvenZM::pZombieData.exists(szSteamId))
						{
							CSvenZM::CZombieData@ data = cast<CSvenZM::CZombieData@>(CSvenZM::pZombieData[szSteamId]);
							if(data is null)
								return;
							if(!data.IsNVSight)
								g_PlayerFuncs.ScreenFade( pPlayer, CSvenZM::ZombieEyeColor, 0.01, 0.5, 64, FFADE_OUT | FFADE_STAYOUT );
							else
								g_PlayerFuncs.ScreenFade( pPlayer, CSvenZM::ZombieEyeColor, 0, 0, 0, FFADE_IN );
							data.IsNVSight = !data.IsNVSight;
							data.CanWeRespwan = data.CanWeRespwan;
							CSvenZM::pZombieData[szSteamId] = data;
						}
					}
					else
						g_DMUtility.SayToYou( pPlayer , "You don't have super power, human." );
				}
				g_ZMEnchance.ClientSay( pPlayer , pArguments );
			}
		}
	}
}

CSvenZM g_SvenZM;
