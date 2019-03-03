/***
*
*	Copyright (c) 1996-2001, Valve LLC. All rights reserved.
*	
*	This product contains software technology licensed from Id 
*	Software, Inc. ("Id Technology").  Id Technology (c) 1996 Id Software, Inc. 
*	All Rights Reserved.
*
*   Use, distribution, and modification of this source code and/or resulting
*   object code is restricted to non-commercial enhancements to products from
*   Valve LLC.  All other use, distribution, or modification is prohibited
*   without written permission from Valve LLC.
*
****/

/***
	Conversion by Dr.Abc
***/

enum squeak_e
{
	SQUEAK_IDLE1 = 0,
	SQUEAK_FIDGETFIT,
	SQUEAK_FIDGETNIP,
	SQUEAK_DOWN,
	SQUEAK_UP,
	SQUEAK_THROW
};

class weapon_dmsnark : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private bool m_fJustThrown;
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_sqknest.mdl" );
		self.m_iDefaultAmmo = 5;
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/hlclassic/v_squeak.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_sqknest.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_squeak.mdl" );
		g_SoundSystem.PrecacheSound("squeek/sqk_hunt2.wav" );	
		g_SoundSystem.PrecacheSound("squeek/sqk_hunt3.wav" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/weapon_dmsnark.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 10;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= -1;
		info.iSlot 		= 4;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= 8;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) == true )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				message.WriteLong( self.m_iId );
			message.End();
			@m_pPlayer = pPlayer;
			return true;
		}	
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			switch(Math.RandomLong(0,1))
			{
				case 0 :g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt2.wav", 1.0, ATTN_NORM, 0, 100 );break;
				case 1 :g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt3.wav", 1.0, ATTN_NORM, 0, 100 );break;
			}
			bResult = self.DefaultDeploy( self.GetV_Model( "models/hlclassic/v_squeak.mdl" ), self.GetP_Model( "models/hlclassic/p_squeak.mdl" ), SQUEAK_UP, "squeak" );
			float deployTime = 0.3f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	bool CanDeploy()
	{
		return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) != 0;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void Holster( int skipLocal = 0 )
	{
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
		{
			m_pPlayer.pev.weapons &= ~( 0 << g_ItemRegistry.GetIdForName("weapon_dmsnark") );
			SetThink( ThinkFunction( DestroyThink ) );
			self.pev.nextthink = g_Engine.time + 0.1;
			return;
		}
		self.SendWeaponAnim( SQUEAK_DOWN, 0, 0 );
		BaseClass.Holster( skipLocal );
	}	
	
	void Materialize()
	{
		BaseClass.Materialize();
		
		SetTouch( TouchFunction( CustomTouch ) );
	}
	
	void CustomTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@> (pOther);

		if( pPlayer.HasNamedPlayerItem( "weapon_dmsnark" ) !is null ) 
		{
			if( pPlayer.GiveAmmo( self.m_iDefaultAmmo, "weapon_dmsnark", 10 ) != -1 )
			{
				self.CheckRespawn();
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
				g_EntityFuncs.Remove( self );
			}
			return;
		}
		else if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
			self.AttachToPlayer( pPlayer );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );
		}
	}
	
	void DestroyThink()
	{
		self.DestroyItem();
	}
	
	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo ( self.m_iPrimaryAmmoType ) > 0 )
		{
			Math.MakeVectors(m_pPlayer.pev.v_angle);
			TraceResult tr;
			Vector trace_origin = m_pPlayer.GetOrigin();
			
			// HACK HACK:  Ugly hacks to handle change in origin based on new physics code for players
			// Move origin up if crouched and start trace a bit outside of body ( 20 units instead of 16 )
			if ( m_pPlayer.pev.flags & FL_DUCKING == 0 )
				trace_origin = trace_origin - ( VEC_HULL_MIN - VEC_DUCK_HULL_MIN );
			// find place to toss monster
			g_Utility.TraceLine( trace_origin + g_Engine.v_forward * 20, trace_origin + g_Engine.v_forward * 64, dont_ignore_monsters, m_pPlayer.edict(), tr );
			
			if ( tr.fAllSolid == 0 && tr.fStartSolid == 0 && tr.flFraction > 0.25 )
			{
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
				self.SendWeaponAnim( SQUEAK_THROW, 0, 0 );
				CBaseEntity@ pSqueak = g_EntityFuncs.Create( "monster_snark", tr.vecEndPos, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
				pSqueak.pev.velocity = g_Engine.v_forward * 200 + m_pPlayer.pev.velocity;
				pSqueak.SetClassification(m_pPlayer.Classify());
				switch(Math.RandomLong(0,1))
				{
					case 0 :g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt2.wav", 1.0, ATTN_NORM, 0, 100 );break;
					case 1 :g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt3.wav", 1.0, ATTN_NORM, 0, 100 );break;
				}
				m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
				m_fJustThrown = true;
				self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.3f;
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 1.0f;
			}
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
	
		if (m_fJustThrown)
		{
			m_fJustThrown = false;

			if ( m_pPlayer.m_rgAmmo ( self.m_iPrimaryAmmoType ) < 0 )
			{
				self.RetireWeapon();
				return;
			}
			self.SendWeaponAnim( SQUEAK_UP, 0, 0 );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
			return;
		}
		
		int iAnim;
		float flRand = Math.RandomFloat(0,1);
		if (flRand <= 0.75)
		{
			iAnim = SQUEAK_IDLE1;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 30.0 / 16 * (2);
		}
		else if (flRand <= 0.875)
		{
			iAnim = SQUEAK_FIDGETFIT;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 70.0 / 16.0;
		}
		else
		{
			iAnim = SQUEAK_FIDGETNIP;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 80.0 / 16.0;
		}
		self.SendWeaponAnim( iAnim, 0, 0 );
	}	
}

string GetWeaponNameDMSnark()
{
	return "weapon_dmsnark";
}
void RegisterDMSnark()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetWeaponNameDMSnark(), GetWeaponNameDMSnark() );
	g_ItemRegistry.RegisterWeapon( GetWeaponNameDMSnark(), "dm_weapons", "snarks" );
}