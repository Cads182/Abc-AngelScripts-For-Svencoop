#include "dm_weapons/trigger_hitbox"

class CHitBox
{
	void MapInit()
	{
		g_CustomEntityFuncs.RegisterCustomEntity( "trigger_hitbox", "trigger_hitbox" );
		g_Game.PrecacheOther("trigger_hitbox");
	}

	void PutInServer( CBasePlayer@ pPlayer )
	{
		CBaseEntity@ pEntity;
		@pEntity = g_EntityFuncs.Create( "trigger_hitbox", pPlayer.pev.origin, pPlayer.pev.angles, true );
		@pEntity.pev.owner = @pPlayer.edict();
		g_EntityFuncs.DispatchKeyValue( pEntity.edict(), "targetname",  TargetName(pPlayer) );
		g_EntityFuncs.DispatchSpawn( pEntity.edict() );
		
	}
	
	void DestroyHitBox( CBasePlayer@ pPlayer )
	{
	
		CBaseEntity@ pEntity = null;
		while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, g_EngineFuncs.GetPlayerAuthId(pPlayer.edict()))) !is null)
		{
			g_EntityFuncs.Remove(pEntity);
		}
	}
	
	string TargetName( CBasePlayer@ pPlayer )
	{
		return g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
	}
}

CHitBox g_HitBox;