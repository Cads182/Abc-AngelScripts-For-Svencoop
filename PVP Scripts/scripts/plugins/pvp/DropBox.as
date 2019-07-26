/***
	Made by Dr.Abc
***/

#include "dm_weapons/item_dmweaponpack"

bool g_HLDMDropRule = false;


namespace CDropWeaponBoxVote
{
	void StartDropModeVote( const CCommand@ pArgs )
	{
		float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
		
		if( flVoteTime <= 0 )
			flVoteTime = 16;
			
		float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_voteclassicmoderequired" );
		
		if( flPercentage <= 0 )
			flPercentage = 51;

		Vote vote( "WeaponBox Drop Mode vote", ( g_HLDMDropRule ? "Disable" : "Enable" ) + " HLDM drop Mode?", flVoteTime, flPercentage );
		
		vote.SetVoteBlockedCallback( @DropModeVoteBlocked );
		vote.SetVoteEndCallback( @DropModeVoteEnd );
		vote.Start();
	}

	void DropModeVoteBlocked( Vote@ pVote, float flTime )
	{
		g_Scheduler.SetTimeout( "StartDropModeVote", flTime, false );
	}

	void DropModeVoteEnd( Vote@ pVote, bool bResult, int iVoters )
	{
		if( !bResult )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for HLDM drop Mode failed" );
			return;
		}
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( !g_HLDMDropRule ? "Enable" : "Disable" ) + " HLDM drop mode passed\n" );
		g_DMDropRule.ChangeDropRule();
	}
}

class CDropWeaponBox
{
	bool IsDrop()
	{
		return g_HLDMDropRule;
	}
	void DropIt( CBasePlayer@ pPlayer )
	{
		if(!g_HLDMDropRule)
			return;
		CBaseEntity@ cbePack = g_EntityFuncs.CreateEntity( "item_dmweaponpack", null,  false);
		item_dmweaponpack@ pPack = cast<item_dmweaponpack@>(CastToScriptClass(cbePack));
		g_EntityFuncs.SetOrigin( pPack.self, pPlayer.pev.origin );
		g_EntityFuncs.DispatchSpawn( pPack.self.edict() );  
		pPack.pev.velocity = pPlayer.pev.velocity ;
		pPack.pev.angles = pPlayer.pev.angles ;
		
		CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.m_hActiveItem.GetEntity());
		@pPack.pWeapon = pWeapon;
		
		if( pWeapon !is null )
		{
			if( pWeapon.PrimaryAmmoIndex() != -1 )
			{
				pPack.m_iAmmo1 = pPlayer.m_rgAmmo( pWeapon.PrimaryAmmoIndex());
				pPlayer.m_rgAmmo(pWeapon.PrimaryAmmoIndex(), 0);
			}
			if( pWeapon.SecondaryAmmoIndex() != -1 )
			{
				pPack.m_iAmmo2 = pPlayer.m_rgAmmo( pWeapon.SecondaryAmmoIndex());
				pPlayer.m_rgAmmo(pWeapon.SecondaryAmmoIndex(), 0);
			}
			pPack.m_strpWeapon = string( pWeapon.pev.classname );
			CBasePlayerItem@ pItem = cast<CBasePlayerItem@>(pWeapon);
			pPlayer.RemovePlayerItem(pItem);
		}
	}
	
	void ApplyDropRule()
	{
		if(g_HLDMDropRule)
		{
			g_DMUtility.CServerCommand( "mp_weapon_droprules", 0 );
			g_DMUtility.CServerCommand( "mp_ammo_droprules", 0 );
		}
		else
		{
			g_DMUtility.CServerCommand( "mp_weapon_droprules", 2 );
			g_DMUtility.CServerCommand( "mp_ammo_droprules", 2 );
		}
	}
	
	void ChangeDropRule()
	{
		g_HLDMDropRule = !g_HLDMDropRule;
		ApplyDropRule();
	}
}
CDropWeaponBox g_DMDropRule;