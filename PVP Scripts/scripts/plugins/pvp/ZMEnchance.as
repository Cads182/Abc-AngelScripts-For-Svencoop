/***				Zombie Mode Enchance - Dr.Abc
							 - Dr.Abc@foxmail.com ****/

#include "dm_weapons/ZM/weapon_flaregun"
#include "dm_weapons/ZM/weapon_zmsentry"
#include "dm_weapons/ZM/weapon_zmbarrel"
#include "dm_weapons/ZM/weapon_zmfreeznade"
#include "dm_weapons/ZM/item_nvsight"

namespace CZMEnchance
{
	const int HUD_CHAN_DAMA = 9;
	const string PlayerSpeakPharse = "buy";
	const array<array<string>> HumanItemKeys = {
		{"AmmoSupply", "null", "50" },
		{"ExplodeSupply", "null", "200" },
		{"C4", "weapon_satchel" , "250" },
		{"NVSight", "item_nvsight" , "750" },
		{"Tripmine", "weapon_tripmine", "100" },
		{"Handgrenade", "weapon_handgrenade", "100" },
		{"Flare", "weapon_flaregun", "50" },
		{"H.E.V Battery", "item_battery", "200" },
		{"Freeznade", "weapon_zmfreeznade", "200" },
		{"Barrel", "weapon_zmbarrel", "500" },
		{"Sentry", "weapon_zmsentry", "2000" },
		{"Gauss", "null", "1000" },
		{"Egon", "weapon_egon", "1000" },
		{"Hornet Gun", "null", "1000"} };
		
	const array<string> AmmoList = {
		"buckshot",
		"556",
		"m40a1",
		"357",
		"9mm",
		"bolts",
		"monster_flarelight",
		"snarks",
		"Hornet",
		"shock"
	};
		
	const array<string>ExpList = {
		"argrenades",
		"sporeclip",
		"rockets",
		"hand grenade",
		"uranium"
	};
		
	dictionary pPlayerData;
	dictionary g_HumanItem;
	
	CTextMenu@ hMenu = null;
	
	class CPlayerEncData{ float DoneDamage; float LastDamageTime; }
	class CZMBuyStuff{ string classname; int cost; }
	
	bool DecuntCoin( CBasePlayer@ pPlayer, const CZMBuyStuff@&in stuff )
	{
		if( stuff is null )
			return false;
		
		const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		if( pPlayerData.exists(steamId) )
		{
			CPlayerEncData@ data = cast<CPlayerEncData@>(pPlayerData[steamId]);
			if( data.DoneDamage - stuff.cost >= 0 )
			{
				data.DoneDamage -= stuff.cost;
				data.LastDamageTime = data.LastDamageTime;
				pPlayerData[steamId] = data;
				return true;
			}
			else
			{
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTTALK, "[Vending Machine] Poor Guy, RIP.\n" );
				return false;
			}
		}
		return false;
	}
	
	bool AddBuyStuff( CBasePlayer@ pPlayer, const CZMBuyStuff@&in data  )
	{
		if( data is null )
			return false;
			
		pPlayer.GiveNamedItem( data.classname , 0, 0 );
		return true;
	}
	
	void ZMEnchanceResetvariable()
	{
		pPlayerData.deleteAll();
		g_HumanItem.deleteAll();
	}
	
	void ZMEnchanceInitialized()
	{
		pPlayerData.deleteAll();
		
		g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
		
		g_Scheduler.SetInterval( "HealthRegen", 1.0f, g_Scheduler.REPEAT_INFINITE_TIMES );
		
		@ hMenu = CTextMenu(hMenuRespond);
		hMenu.SetTitle("[Vending Machine]\nChose weapons 4 your life.\n");
		AddBuyStuffItem();
		
		hMenu.Register();
		RegisterSentrygun();
		RegisterZMBarrel();
		RegisterFreeznade();
		RegisterHumanNV();
		
		g_SoundSystem.PrecacheSound( "player/heartbeat1.wav" );
	}
	
	void AddBuyStuffItem()
	{
		for (uint i = 0; i < HumanItemKeys.length(); i++) 
		{
			CZMBuyStuff data;
			data.classname						= HumanItemKeys[i][1];
			data.cost	  						= atoi(HumanItemKeys[i][2]);
	
			string szItemName = HumanItemKeys[i][0] + " - " + HumanItemKeys[i][2] + " coins";
			g_HumanItem[szItemName]    = data;
			
			hMenu.AddItem( szItemName , null);
		}
	}
	
	void ClientSayHook( CBasePlayer@ pPlayer )
	{
		if(!m_bIsStart || !CSvenZM::m_bSelected )
		{
			g_DMUtility.SayToYou( pPlayer , "Game hasn't started." );
			return;
		}
			
		if( pPlayer.pev.targetname == "human" )
			hMenu.Open(0, 0, pPlayer);
		else
			g_DMUtility.SayToYou( pPlayer , "Wut, zombie? No sell No sell." );
	}
	
	void hMenuRespond(CTextMenu@ mMenu, CBasePlayer@ pPlayer, int iPage, const CTextMenuItem@ mItem)
	{
		if(pPlayer.pev.targetname != "human")
			return;
			
		const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());	
		if(mItem !is null && pPlayer !is null)
		{
			const CZMBuyStuff@ data = cast<CZMBuyStuff@>(g_HumanItem[mItem.m_szName]);
			
			if(!g_HumanItem.exists(mItem.m_szName) || !DecuntCoin(pPlayer,data))
				return;
			if(mItem.m_szName == "AmmoSupply - 50 coins")
				AmmoResupply( pPlayer , AmmoList);
			else if (mItem.m_szName == "ExplodeSupply - 200 coins")
				AmmoResupply( pPlayer , ExpList);
			else if (mItem.m_szName == "Gauss - 1000 coins")
			{
				if(!IsClassMode)
					pPlayer.GiveNamedItem( "weapon_gauss" , 0, 0);
				else
				{
					pPlayer.GiveNamedItem( "weapon_dmgauss" , 0, 0);
				}	
			}
			else if (mItem.m_szName == "Hornet Gun - 1000 coins")
			{
				if(!IsClassMode)
					pPlayer.GiveNamedItem( "weapon_hornetgun" , 0, 0);
				else
					pPlayer.GiveNamedItem( "weapon_dmhornetgun" , 0, 0);
			}
			else if (g_HumanItem.exists(mItem.m_szName))
				AddBuyStuff(pPlayer,data);
			
			pPlayer.SetItemPickupTimes(0);
		}
	}
	
	void AmmoResupply( CBasePlayer@ pPlayer , array<string> ary )
	{
		for (uint u = 0; u < ary.length(); u++) 
		{
			int m_iAmmoIndex = g_PlayerFuncs.GetAmmoIndex(ary[u]);
			pPlayer.m_rgAmmo(m_iAmmoIndex , pPlayer.GetMaxAmmo(m_iAmmoIndex));
		}
	}
	
	void HealthRegen()
	{
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				SendHUD(pPlayer);
				if(  pPlayer.IsAlive() && pPlayer.pev.targetname == "zombie" )
				{
					const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
					if(!pPlayerData.exists(steamId))
						continue;
					else
					{
						const CPlayerEncData@ data = cast<CPlayerEncData@>(pPlayerData[steamId]);
						if( data.LastDamageTime + 7 <= g_Engine.time )
						{
							if( pPlayer.pev.health < pPlayer.pev.max_health)
							{
								if( pPlayer.pev.health + 100 < pPlayer.pev.max_health )
									pPlayer.pev.health += 100;
								else
									pPlayer.pev.health = pPlayer.pev.max_health;
								g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_VOICE, "player/heartbeat1.wav", 0.5, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );
							}
						}
						if( pPlayer.pev.health >= pPlayer.pev.max_health )
							g_SoundSystem.StopSound( pPlayer.edict(), CHAN_VOICE, "player/heartbeat1.wav" );
					}
				}
			}
		}
		
		/*CBaseEntity@ pEntity = null;
		while( ( @pEntity = g_EntityFuncs.FindEntityByClassname( pEntity, "monster_zmbarrel") ) !is null )
		{
			if(pEntity.pev.health <= 0 )
				g_EntityFuncs.Remove(pEntity);
		}*/
	}
	
	void SendHUD(CBasePlayer@ pPlayer)
	{
		HUDNumDisplayParams params;
		params.channel = HUD_CHAN_DAMA;
		params.flags = HUD_ELEM_DEFAULT_ALPHA |HUD_NUM_NEGATIVE_NUMBERS | HUD_NUM_PLUS_SIGN;
		params.x = 0.5;
		params.y = 0.97;
		params.defdigits = 2;
		params.maxdigits = 6;
		params.color1 =  RGBA_SVENCOOP;
		const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		const CPlayerEncData@ data = cast<CPlayerEncData@>(pPlayerData[szSteamId]);
		params.value = int(data.DoneDamage);
		g_PlayerFuncs.HudNumDisplay( pPlayer, params );
	}
	
	void DoneDamage(  CBasePlayer@ pPlayer, float flDamage , CBasePlayer@ pAttacker )
	{
		DamageAmount( pAttacker , flDamage );
		DamageTime( pPlayer );
	}
	
	void DamageAmount(  CBasePlayer@ pPlayer, float flDamage ) 
	{
		if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsNetClient() || pPlayer.pev.targetname == "zombie" )
			return;
			
		const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		if(pPlayerData.exists(szSteamId))
		{
			CPlayerEncData@ data = cast<CPlayerEncData@>(pPlayerData[szSteamId]);
			data.DoneDamage += flDamage;
			data.LastDamageTime = data.LastDamageTime;
			pPlayerData[szSteamId] = data;
			//g_Game.AlertMessage( at_console, flDamage );
		}
	}
	
	void DamageTime(  CBasePlayer@ pPlayer )
	{
		if( pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsNetClient() )
			return;
			
		const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		if(pPlayerData.exists(szSteamId))
		{
			CPlayerEncData@ data = cast<CPlayerEncData@>(pPlayerData[szSteamId]);
			data.DoneDamage = data.DoneDamage;
			data.LastDamageTime = g_Engine.time;
			pPlayerData[szSteamId] = data;
			//g_Game.AlertMessage( at_console, data.LastDamageTime );
		}
	}
	
	void BuildDic( string&in szSteamID )
	{
		CPlayerEncData data;
		data.DoneDamage = 0;
		data.LastDamageTime = g_Engine.time;
		pPlayerData[szSteamID] = data;
	}
}

class CZMEnchance
{
	void EnchanceInit()
	{
		if(CSvenZM::IsZM())
		{
			CZMEnchance::ZMEnchanceInitialized();
			g_pGameRules.IsMultiplayer = false;
		}
	}
	
	void ClientDis( CBasePlayer@ pPlayer )
	{
		const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
		if(CZMEnchance::pPlayerData.exists(szSteamId))
			CZMEnchance::pPlayerData.delete(szSteamId);
	}
	
	void ClientSay( CBasePlayer@ pPlayer ,const CCommand@ pArguments )
	{
		if(pArguments[0].ToLowercase() == "!" + PlayerSpeakPharse || pArguments[0] == "/" + PlayerSpeakPharse)
				CZMEnchance::ClientSayHook(pPlayer);
	}
}

CZMEnchance g_ZMEnchance;
