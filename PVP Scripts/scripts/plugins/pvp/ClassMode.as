/***
	Made by Dr.Abc
***/

#include "dm_weapons/Classic/info_ctfspawn"
#include "dm_weapons/Classic/weapon_dmgauss"
#include "dm_weapons/Classic/weapon_dmbow"
#include "dm_weapons/Classic/weapon_dm357"
#include "dm_weapons/Classic/weapon_dmsqueak"
#include "dm_weapons/Classic/weapon_dmshockrifle"
#include "dm_weapons/Classic/weapon_dmhornetgun"
#include "dm_weapons/Classic/weapon_dmglock"
#include "dm_weapons/Classic/weapon_hlmp5"
#include "dm_weapons/Classic/weapon_hlcrowbar"
#include "dm_weapons/Classic/weapon_hlshotgun"
#include "dm_weapons/Classic/weapon_dmpenguin"

namespace CGameRules
{
	void MultiCallBack(const CCommand@ pArgs)
	{
		g_pGameRules.IsMultiplayer = !g_pGameRules.IsMultiplayer;
	}
}

class CGameRules
{
	private bool bMultiP = true;
	bool IsMultiplayer
	{
		get const{ return bMultiP;}
		set{ bMultiP = value;}
	}
}

CGameRules g_pGameRules;

class CDMClassMode
{
	bool EnableClassMode ( bool&in bInput )
	{
		if( bInput )
		{
			Register();
			return true;
		}
		else
		{
			return false;
		}
	}

	void Register()
	{
		RegisterDMPenguinNade();
		RegisterDMMP5();
		RegisterDMGauss();
		RegisterDMXBOW();
		RegisterDM357();
		RegisterDMSnark();
		RegisterDMShockRifle();
		RegisterDMHornetGun();
		RegisterHLCrowbar();
		RegisterHLShotgun();
		RegisterDMGlock();
	}
	
	void WeaponReplace()
	{
		g_DMUtility.CServerCommand( "sv_aim", 1);
		g_pGameRules.IsMultiplayer = true;
		
		WeaponReplacer( "weapon_9mmhandgun" , "weapon_dmglock" );
		WeaponReplacer( "weapon_9mmAR" , "weapon_hlmp5" );
		WeaponReplacer( "weapon_shotgun" , "weapon_hlshotgun" );
		WeaponReplacer( "weapon_crowbar" , "weapon_hlcrowbar" );
		WeaponReplacer( "weapon_gauss" , "weapon_dmgauss" );
		WeaponReplacer( "weapon_crossbow" , "weapon_dmbow" );
		WeaponReplacer( "weapon_357" , "weapon_dm357" );
		WeaponReplacer( "weapon_snark" , "weapon_dmsnark" );
		WeaponReplacer( "weapon_shockrifle" , "weapon_dmshockrifle" );
		WeaponReplacer( "weapon_hornetgun" , "weapon_dmhornetgun" );
	}
	
	void WeaponReplacer( string str_Replacee , string str_Replacer )
	{
		CBaseEntity@ entWeapon = null;
		while( ( @entWeapon = g_EntityFuncs.FindEntityByClassname( entWeapon, str_Replacee ) ) !is null )
		{
			if ( BeApply( entWeapon, str_Replacer ) )
				continue;
		}
	}

	bool BeApply( CBaseEntity@ ent, const string& in strReplacement )
	{
		CBaseEntity@ pEntity = g_EntityFuncs.Create( strReplacement, ent.pev.origin, ent.pev.angles ,  false , null );
		if ( pEntity is null )
			return false;

		pEntity.pev.targetname = ent.pev.targetname;
		pEntity.pev.maxs = ent.pev.maxs;
		pEntity.pev.mins = ent.pev.mins;
		pEntity.pev.target = ent.pev.target;
		pEntity.pev.scale = ent.pev.scale;
		
		g_EntityFuncs.Remove(ent);
		return true;
	}
	
	void PlayerSpwanHook( CBasePlayer@ pPlayer )		//Spwan hook
	{
		SpwanReplace( pPlayer, "weapon_9mmhandgun" , "weapon_dmglock" );
		SpwanReplace( pPlayer, "weapon_9mmAR" , "weapon_hlmp5" );
		SpwanReplace( pPlayer, "weapon_shotgun" , "weapon_hlshotgun" );
		SpwanReplace( pPlayer, "weapon_crowbar" , "weapon_hlcrowbar" );
		SpwanReplace( pPlayer, "weapon_gauss" , "weapon_dmgauss" );
		SpwanReplace( pPlayer, "weapon_crossbow" , "weapon_dmbow" );
		SpwanReplace( pPlayer, "weapon_357" , "weapon_dm357" );
		SpwanReplace( pPlayer, "weapon_snark" , "weapon_dmsnark" );
		SpwanReplace( pPlayer, "weapon_shockrifle" , "weapon_dmshockrifle" );
		SpwanReplace( pPlayer, "weapon_hornetgun" , "weapon_dmhornetgun" );
	}
	
	void SpwanReplace( CBasePlayer@ pPlayer, string str_Replacee , string str_Replacer )	//出生的时候取代cfg.....
	{
		g_EntityFuncs.SetSize(pPlayer.pev, Vector(-32,-32,-48), Vector(32,32,48));
		pPlayer.pev.solid	= SOLID_SLIDEBOX;
		CBasePlayerItem@ pItem = pPlayer.HasNamedPlayerItem(str_Replacee);
		if( pItem !is null )
		{
			if(pPlayer.RemovePlayerItem(pItem))
				pPlayer.GiveNamedItem(str_Replacer);
		}
	}
}

CDMClassMode g_DMClassMode;