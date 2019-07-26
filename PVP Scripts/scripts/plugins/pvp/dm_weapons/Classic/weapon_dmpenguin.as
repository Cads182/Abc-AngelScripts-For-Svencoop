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

#include "monster_penguin"

enum PenguinNestAnim
{
	PENGUINNEST_WALK = 0,
	PENGUINNEST_IDLE
};

enum PenguinAnim
{
	PENGUIN_IDLE1 = 0,
	PENGUIN_FIDGETFIT,
	PENGUIN_FIDGETNIP,
	PENGUIN_DOWN,
	PENGUIN_UP,
	PENGUIN_THROW
};

class weapon_dmpenguin : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private bool m_bJustThrown;
	
	void Precache()
	{
		BaseClass.Precache();

		g_Game.PrecacheModel( "models/opfor/w_penguinnest.mdl" );
		g_Game.PrecacheModel( "models/opfor/v_penguin.mdl" );
		g_Game.PrecacheModel( "models/opfor/p_penguin.mdl" );
		
		g_Game.PrecacheModel( "sprites/dm_weapons/640hud7.spr" );
		g_Game.PrecacheModel( "sprites/dm_weapons/640hudof03.spr" );
		g_Game.PrecacheModel( "sprites/dm_weapons/640hudof04.spr" );
		
		g_Game.PrecacheGeneric( "sprites/dm_weapons/640hud7.spr" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/640hudof03.spr" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/640hudof04.spr" );
		
		g_Game.PrecacheGeneric( "sprites/dm_weapons/weapon_dmpenguin.txt" );
		
		g_SoundSystem.PrecacheSound( "squeek/sqk_hunt2.wav" );
		g_SoundSystem.PrecacheSound( "squeek/sqk_hunt3.wav" );

		g_Game.PrecacheOther( "monster_penguin" );
	}

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/opfor/w_penguinnest.mdl" );
		
		self.m_iDefaultAmmo = 1;
		self.FallInit();

		pev.sequence = PENGUINNEST_IDLE;
		pev.animtime = g_Engine.time ;
		pev.framerate = 1 ;
	}
		
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 10;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= -1;
		info.iSlot 		= 7;
		info.iPosition 	= 7;
		info.iFlags 	= 0;
		info.iWeight 	= 5;

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
		// play hunt sound
		const float flRndSound = Math.RandomFloat( 0, 1 );

		if( flRndSound <= 0.5 )
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		else
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );

		m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;

		//Opposing Force uses the penguin animation set, which doesn't exist. - Solokiller
		return self.DefaultDeploy( self.GetV_Model( "models/opfor/v_penguin.mdl" ), self.GetP_Model( "models/opfor/p_penguin.mdl" ), PENGUIN_UP, "squeak" );
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
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

		if( pPlayer.HasNamedPlayerItem( "weapon_dmpenguin" ) !is null ) 
		{
			if( pPlayer.GiveAmmo( 1, "weapon_dmpenguin", 10 ) != -1 )
			{
				//self.CheckRespawn();
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
				//g_EntityFuncs.Remove( self );
			}
			return;
		}
		else if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
			self.AttachToPlayer( pPlayer );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );
		}
	}

	void Holster()
	{
		m_pPlayer.m_flNextAttack = WeaponTimeBase() + 0.5;

		self.SendWeaponAnim( PENGUIN_DOWN, 0, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "common/null.wav", VOL_NORM, ATTN_NORM );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if( m_bJustThrown )
		{
			m_bJustThrown = false;

			if( m_pPlayer.m_rgAmmo(self.PrimaryAmmoIndex()) <= 0) 
			{
				self.DestroyItem();
				return;
			}

			self.SendWeaponAnim( PENGUIN_UP, 0, 0 );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			return;
		}

		int iAnim;
		float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
		if( flRand <= 0.75 )
		{
			iAnim = PENGUIN_IDLE1;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 30.0 / 16 * ( 2 );
		}
		else if( flRand <= 0.875 )
		{
			iAnim = PENGUIN_FIDGETFIT;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 70.0 / 16.0;
		}
		else
		{
			iAnim = PENGUIN_FIDGETNIP;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 80.0 / 16.0;
		}
		self.SendWeaponAnim( iAnim, 0, 0 );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo( self.PrimaryAmmoIndex()) > 0 ) 
		{
			Math.MakeVectors( m_pPlayer.pev.v_angle );
			TraceResult tr;

			// HACK HACK:  Ugly hacks to handle change in origin based on new physics code for players
			// Move origin up if crouched and start trace a bit outside of body ( 20 units instead of 16 )
			
			Vector trace_origin = m_pPlayer.GetOrigin();
			if ( m_pPlayer.pev.flags & FL_DUCKING == 0 )
				trace_origin = trace_origin - ( VEC_HULL_MIN - VEC_DUCK_HULL_MIN );
				
			// find place to toss monster
			g_Utility.TraceLine( trace_origin + g_Engine.v_forward * 20, trace_origin + g_Engine.v_forward * 64, dont_ignore_monsters, m_pPlayer.edict(), tr );

			if( tr.fAllSolid == 0 && tr.fStartSolid == 0 && tr.flFraction > 0.25 )
			{
				// player "shoot" animation
				m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
				self.SendWeaponAnim( SQUEAK_THROW, 0, 0 );
				
				CBaseEntity@ pSqueak = g_EntityFuncs.Create( "monster_penguin", tr.vecEndPos, m_pPlayer.pev.v_angle, false, m_pPlayer.edict() );
				pSqueak.pev.velocity = g_Engine.v_forward * 200 + m_pPlayer.pev.velocity;

				// play hunt sound
				pSqueak.SetClassification(m_pPlayer.Classify());
				switch(Math.RandomLong(0,1))
				{
					case 0 :g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt2.wav", 1.0, ATTN_NORM, 0, 100 );break;
					case 1 :g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt3.wav", 1.0, ATTN_NORM, 0, 100 );break;
				}
				m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
				m_bJustThrown = true;

				self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.9f;
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.8f;
			}
		}
	}

	void SecondaryAttack()
	{
		//Nothing.
	}
}

class weapon_penguin : ScriptBaseEntity
{	
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "" );
		CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity( "weapon_dmpenguin", null, false );
		
		pEntity.pev.targetname = self.pev.targetname;
		pEntity.pev.maxs = self.pev.maxs;
		pEntity.pev.mins = self.pev.mins;
		pEntity.pev.origin = self.pev.origin;
		pEntity.pev.angles = self.pev.angles;
		pEntity.pev.target = self.pev.target;
		pEntity.pev.scale = self.pev.scale ;

		g_EntityFuncs.DispatchSpawn( pEntity.edict() );
		
		g_EntityFuncs.Remove(self);
	}
}

string GetWeaponNameDMPenguinNade()
{
	return "weapon_dmpenguin";
}
void RegisterDMPenguinNade()
{
	RegisterDMPenguin();
	g_CustomEntityFuncs.RegisterCustomEntity( GetWeaponNameDMPenguinNade(), GetWeaponNameDMPenguinNade() );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_penguin", "weapon_penguin" );
	g_ItemRegistry.RegisterWeapon( GetWeaponNameDMPenguinNade(), "dm_weapons", "penguin" );
	g_ItemRegistry.RegisterItem( GetWeaponNameDMPenguinNade(), "dm_weapons", "weapon_penguin" );
	g_DMEntityList.insertLast("weapon_dmpenguin");
}