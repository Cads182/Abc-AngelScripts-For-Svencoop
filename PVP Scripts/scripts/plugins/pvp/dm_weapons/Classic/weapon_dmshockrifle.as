/***
	Conversion by Dr.Abc
***/

#include "proj_shockbeam"

enum ShockRifleAnim
{
	SHOCKRIFLE_IDLE1 = 0,
	SHOCKRIFLE_FIRE,
	SHOCKRIFLE_DRAW,
	SHOCKRIFLE_HOLSTER,
	SHOCKRIFLE_IDLE3
};

class weapon_dmshockrifle : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private int m_iSpriteTexture;
	private float m_flRechargeTime;
	private float m_flSoundDelay;
	private int iMaxAmmo = 10;
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/w_shock_rifle.mdl" );
		self.m_iDefaultAmmo = iMaxAmmo;
		pev.nextthink = g_Engine.time + 0.28;
		self.FallInit();
	}
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/v_shock.mdl" );
		g_Game.PrecacheModel( "models/w_shock_rifle.mdl" );
		g_Game.PrecacheModel( "models/p_shock.mdl" );
		m_iSpriteTexture = g_Game.PrecacheModel( "sprites/shockwave.spr" );
		g_Game.PrecacheModel( "sprites/lgtning.spr" );
		g_SoundSystem.PrecacheSound("weapons/shock_fire.wav" );	
		g_SoundSystem.PrecacheSound("weapons/shock_draw.wav" );
		g_SoundSystem.PrecacheSound("weapons/shock_recharge.wav" );
		g_SoundSystem.PrecacheSound("weapons/shock_discharge.wav" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/weapon_dmshockrifle.txt" );
		g_Game.PrecacheOther( "dm_shockbeam" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= iMaxAmmo;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= -1;
		info.iSlot 		= 6;
		info.iPosition 	= 5;
		info.iFlags 	= ITEM_FLAG_NOAUTOSWITCHEMPTY;
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
			bResult = self.DefaultDeploy( self.GetV_Model( "models/v_shock.mdl" ), self.GetP_Model( "models/p_shock.mdl" ), SHOCKRIFLE_DRAW, "bow" );
			float deployTime = 0.3f;
			if( g_pGameRules.IsMultiplayer )
				m_flRechargeTime = WeaponTimeBase() + 0.25;
			else
				m_flRechargeTime = WeaponTimeBase() + 0.5;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/shock_draw.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	bool CanDeploy()
	{
		return true;
	}

	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	
	void Holster( int skipLocal = 0 )
	{
		RechargeAmmo( false );
		SetThink( null );
		self.pev.nextthink = g_Engine.time + 1.0;
		self.SendWeaponAnim( SHOCKRIFLE_HOLSTER, 0, 0 );
		if ( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 1 );
		BaseClass.Holster( skipLocal );
	}	
	
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			const float flVolume = Math.RandomFloat( 0.8, 0.9 );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "weapons/shock_discharge.wav", flVolume, ATTN_NORM, 0, PITCH_NORM );
			g_WeaponFuncs.RadiusDamage( self.GetOrigin(), self.pev, m_pPlayer.pev, (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType )) * 100, (m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType )) * 150.0f, CLASS_NONE,  DMG_ALWAYSGIB | DMG_BLAST );
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, 0 );
			return;
		}
		
		if((m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType )) <= 0 )
		{
			return;
		}
		
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/shock_fire.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
		
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
	
		m_flRechargeTime = WeaponTimeBase() + 1.0;
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.SendWeaponAnim( SHOCKRIFLE_FIRE, 0, 0 );
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		
		Vector vecSrc = m_pPlayer.GetGunPosition() + 
						g_Engine.v_forward * 16 + 
						g_Engine.v_right * 9 + 
						g_Engine.v_up * -7;
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		ShootShockBeam(m_pPlayer.pev,vecSrc,g_Engine.v_forward * 2000.0f);
		
		if( g_pGameRules.IsMultiplayer )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1;
		else
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.2;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.33;
	}
	
	void ShootShockBeam(entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity) 
	{
        
        CBaseEntity@ cbeBeam = g_EntityFuncs.CreateEntity( "dm_shockbeam", null,  false);
        dm_shockbeam@ pBeam = cast<dm_shockbeam@>(CastToScriptClass(cbeBeam));
        
        g_EntityFuncs.SetOrigin( pBeam.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pBeam.self.edict() );
        pBeam.pev.velocity = vecVelocity ;
        @pBeam.pev.owner = pevOwner.pContainingEntity;
        pBeam.pev.angles = Math.VecToAngles( pBeam.pev.velocity );
	}
	
	void ItemPostFrame()
	{
		RechargeAmmo( true );
		BaseClass.ItemPostFrame();
	}
	
	void RechargeAmmo( bool bLoud )
	{
		const int iMax = iMaxAmmo;

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) >= iMax )
		{
			return;
		}

		while( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < iMax )
		{
			if( m_flRechargeTime >= WeaponTimeBase() )
				break;

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + 1 );

			if( bLoud )
			{
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/shock_recharge.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
			}

			if( g_pGameRules.IsMultiplayer )
			{
				m_flRechargeTime += 0.25;
			}
			else
			{
				m_flRechargeTime += 0.5;
			}
		}
	}

	void WeaponIdle()
	{
		if( m_flSoundDelay != 0 && WeaponTimeBase() >= m_flSoundDelay )
		{
			m_flSoundDelay = 0;
		}
		//This used to be completely broken. It used the current game time instead of the weapon time base, which froze the idle animation.
		//It also never handled IDLE3, so it only ever played IDLE1, and then only animated it when you held down secondary fire.
		//This is now fixed. - Solokiller
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		
		int iAnim;
		float flRand = Math.RandomFloat(0,1);
		if (flRand <= 0.75)
		{
			iAnim = SHOCKRIFLE_IDLE3;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 51.0 / 15.0;
		}
		else
		{
			iAnim =  SHOCKRIFLE_IDLE1;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 101.0 / 30.0;
		}
		self.SendWeaponAnim( iAnim, 0, 0 );
	}	
}

string GetWeaponNameDMShockRifle()
{
	return "weapon_dmshockrifle";
}
void RegisterDMShockRifle()
{
	RegisterPJshockbeam();
	g_CustomEntityFuncs.RegisterCustomEntity( GetWeaponNameDMShockRifle(), GetWeaponNameDMShockRifle() );
	g_ItemRegistry.RegisterWeapon( GetWeaponNameDMShockRifle(), "dm_weapons", "shock" );
	g_DMEntityList.insertLast("weapon_dmshockrifle");
}