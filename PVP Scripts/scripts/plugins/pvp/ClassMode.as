/***
	Made by Dr.Abc
***/

#include "dm_weapons/info_ctfspawn"
#include "dm_weapons/weapon_dmgauss"
#include "dm_weapons/weapon_dmbow"
#include "dm_weapons/weapon_dm357"
#include "dm_weapons/weapon_dmsqueak"
#include "dm_weapons/weapon_dmshockrifle"
#include "dm_weapons/weapon_dmhornetgun"
#include "dm_weapons/weapon_hlmp5"

class CDMClassMode
{
	bool EnableClassMode ( bool bInput )
	{
		if( bInput )
		{
			Register();
			return true;
		}
		else
		{
			Unregister();
			return false;
		}
	}

	void Register()
	{
		RegisterDMMP5();
		RegisterDMGauss();
		RegisterDMXBOW();
		RegisterDM357();
		RegisterDMSnark();
		RegisterDMShockRifle();
		RegisterDMHornetGun();
	}
	
	void Unregister()
	{
		g_CustomEntityFuncs.UnRegisterCustomEntity( "weapon_hlmp5" );
		g_CustomEntityFuncs.UnRegisterCustomEntity( "weapon_dmgauss" );
		g_CustomEntityFuncs.UnRegisterCustomEntity( "weapon_dmbow" );
		g_CustomEntityFuncs.UnRegisterCustomEntity( "weapon_dm357" );
		g_CustomEntityFuncs.UnRegisterCustomEntity( "weapon_dmsnark" );
		g_CustomEntityFuncs.UnRegisterCustomEntity( "weapon_dmshockrifle" );
		g_CustomEntityFuncs.UnRegisterCustomEntity( "weapon_dmhornetgun" );
		g_CustomEntityFuncs.UnRegisterCustomEntity( "dmhornet" );
		g_CustomEntityFuncs.UnRegisterCustomEntity( "dm_shockbeam" );
	}
	
	void WeaponReplace()
	{
		WeaponReplacer( "weapon_9mmAR" , "weapon_hlmp5" );
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
}

CDMClassMode g_DMClassMode;