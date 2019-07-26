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


enum glock_e
{
	GLOCK_IDLE1 = 0,
	GLOCK_IDLE2,
	GLOCK_IDLE3,
	GLOCK_SHOOT,
	GLOCK_SHOOT_EMPTY,
	GLOCK_RELOAD,
	GLOCK_RELOAD_NOT_EMPTY,
	GLOCK_DRAW,
	GLOCK_HOLSTER,
	GLOCK_ADD_SILENCER
};

class weapon_dmglock : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private int m_iShell;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_9mmhandgun.mdl" );

		self.m_iDefaultAmmo = 34;

		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		
		g_Game.PrecacheModel("models/hlclassic/v_9mmhandgun.mdl");
		g_Game.PrecacheModel("models/hlclassic/w_9mmhandgun.mdl");
		g_Game.PrecacheModel("models/hlclassic/p_9mmhandgun.mdl");

		m_iShell = g_Game.PrecacheModel ("models/shell.mdl");// brass shell

		g_SoundSystem.PrecacheSound("hlclassic/items/9mmclip1.wav");
		g_SoundSystem.PrecacheSound("hlclassic/items/9mmclip2.wav");

		g_SoundSystem.PrecacheSound ("hlclassic/weapons/pl_gun1.wav");//silenced handgun
		g_SoundSystem.PrecacheSound ("hlclassic/weapons/pl_gun2.wav");//silenced handgun
		g_SoundSystem.PrecacheSound ("hlclassic/weapons/pl_gun3.wav");//handgun
		
		g_Game.PrecacheModel( "sprites/640hud1.spr" );
		g_Game.PrecacheModel( "sprites/640hud4.spr" );
		g_Game.PrecacheModel( "sprites/640hud7.spr" );
		g_Game.PrecacheModel( "sprites/crosshairs.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "dm_weapons/weapon_dmglock.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 250;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= 17;
		info.iSlot 		= 1;
		info.iPosition 	= 5;
		info.iFlags 	= 0;
		info.iWeight 	= 5;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;
			
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();

		return true;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/hlclassic/v_9mmhandgun.mdl" ), self.GetP_Model( "models/hlclassic/p_9mmhandgun.mdl" ), GLOCK_DRAW, "onehanded" );
		
			float deployTime = 0.3;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}

	void PrimaryAttack()
	{
		GlockFire( 0.01, 0.3, true );
	}

	void SecondaryAttack()
	{
		GlockFire( 0.1, 0.2, false );
	}
	
	void GlockFire( float flSpread , float flCycleTime, const bool fUseAutoAim )
	{
		if (self.m_iClip <= 0)
		{
			PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.2f;
			return;
		}

		self.m_iClip--;

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		// player "shoot" animation
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		// silenced
		if (self.GetBodygroup(0) == 1)
		{
			m_pPlayer.m_iWeaponVolume = QUIET_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = DIM_GUN_FLASH;
		}
		else
		{
			// non-silenced
			m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
			m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		}
		
		self.SendWeaponAnim( self.m_iClip <= 0 ? GLOCK_SHOOT_EMPTY : GLOCK_SHOOT );
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/pl_gun3.wav", 1, ATTN_NORM, 0, PITCH_NORM );
		g_DMUtility.DMBulletEjection( m_pPlayer.GetGunPosition(), Vector(7,19,-8), m_pPlayer.pev.angles[1], m_iShell, TE_BOUNCE_SHELL ,m_pPlayer.pev.velocity );
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition( );
		Vector vecAiming;
		
		if ( fUseAutoAim )
		{
			vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		}
		else
		{
			vecAiming = g_Engine.v_forward;
		}

		g_DMUtility.DMTraceDamage( m_pPlayer, self.pev, 1, vecSrc, vecAiming, Vector( flSpread, flSpread, flSpread ),8192, BULLET_PLAYER_9MM );
		
		m_pPlayer.pev.punchangle.x = -1.0;

		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = WeaponTimeBase() + flCycleTime;

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
	}

	void Reload()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip == 17 )
			return;
		bool bResult;
		if (self.m_iClip == 0)
			bResult = self.DefaultReload( 17, GLOCK_RELOAD, 1.5 );
		else
			bResult = self.DefaultReload( 17, GLOCK_RELOAD_NOT_EMPTY, 1.5 );

		if ( bResult )
		{
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
		}
		
		BaseClass.Reload();
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );

		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		// only idle if the slid isn't back
		if (self.m_iClip != 0)
		{
			int iAnim;
			float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0.0, 1.0 );

			if (flRand <= 0.3 + 0 * 0.75)
			{
				iAnim = GLOCK_IDLE3;
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 49.0 / 16;
			}
			else if (flRand <= 0.6 + 0 * 0.875)
			{
				iAnim = GLOCK_IDLE1;
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 60.0 / 16.0;
			}
			else
			{
				iAnim = GLOCK_IDLE2;
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 40.0 / 16.0;
			}
			self.SendWeaponAnim( iAnim );
		}
	}
}

void RegisterDMGlock()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dmglock", "weapon_dmglock" );
	g_ItemRegistry.RegisterWeapon( "weapon_dmglock", "dm_weapons", "9mm" );
	g_DMEntityList.insertLast("weapon_dmglock");
}