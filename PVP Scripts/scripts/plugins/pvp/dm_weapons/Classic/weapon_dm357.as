/***
	Made by Dr.Abc
***/

enum DM357Animation
{
	DM357_IDLE = 0,
	DM357_FIDGET,
	DM357_SHOOT1,
	DM357_RELOAD,
	DM357_HOLSTER,
	DM357_DRAW,
	DM357_IDLE2,
	DM357_IDLE3
};

const int DM357_DEFAULT_GIVE	= 6;
const int DM357_MAX_CARRY		= 36;
const int DM357_MAX_CLIP		= 6;
const int DM357_WEIGHT			= 7;

class weapon_dm357 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private int m_iShotsFired;
	private bool bInZoom = false;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_357.mdl" );
		self.m_iDefaultAmmo = DM357_DEFAULT_GIVE;
		m_iShotsFired = 0;
		self.FallInit();
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/hlclassic/w_357.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_357.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/v_357.mdl" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_reload1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_shot1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_shot2.wav" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/weapon_dm357.txt" );
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= DM357_MAX_CARRY;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= DM357_MAX_CLIP;
		info.iSlot 		= 1;
		info.iPosition 	= 6;
		info.iFlags 	= 0;
		info.iWeight 	= DM357_WEIGHT;

		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) == true )
		{
			@m_pPlayer = pPlayer;
			NetworkMessage DM357( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				DM357.WriteLong( g_ItemRegistry.GetIdForName("weapon_dm357") );
			DM357.End();
			return true;
		}
		
		return false;
	}
	
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, "weapons/357_cock1.wav", 0.9, ATTN_NORM, 0, PITCH_NORM );
		}
		
		return false;
	}
	
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/hlclassic/v_357.mdl" ), self.GetP_Model( "models/hlclassic/p_357.mdl" ), DM357_DRAW, "onehanded" );
		
			float deployTime = 0.12f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	void Holster( int skipLocal = 0 )
	{
		self.m_fInReload = false;
		if(bInZoom)
		{
			bInZoom = false;
			ToggleZoom( 0 );
		}
		BaseClass.Holster( skipLocal );
	}
	
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD || self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15f;
			self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.45f;
			return;
		}

		m_iShotsFired++;
		if( m_iShotsFired > 1 )
		{
			return;
		}
		
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75f;	
		m_pPlayer.m_iWeaponVolume = BIG_EXPLOSION_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--self.m_iClip;
		
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( DM357_SHOOT1, 0, 0 );
		
		string str_FireSound;
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) )
		{
			case 0: str_FireSound = "hlclassic/weapons/357_shot1.wav"; break;
			case 1: str_FireSound = "hlclassic/weapons/357_shot2.wav"; break;
		}
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, str_FireSound, 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
	
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		g_DMUtility.DMTraceDamage(m_pPlayer, self.pev, 1, vecSrc, vecAiming, bInZoom ? g_vecZero : VECTOR_CONE_1DEGREES, 8192, BULLET_PLAYER_357);

		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -6, -5 );

		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75f;
	}
	
	void SecondaryAttack()
	{
		if(!bInZoom)
		{
			bInZoom = true;
			ToggleZoom( 40 );
		}
		else
		{
			bInZoom = false;
			ToggleZoom( 0 );
		}
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
	}
	
	void SetFOV( int fov )
	{
		m_pPlayer.pev.fov = m_pPlayer.m_iFOV = fov;
	}
	
	void ToggleZoom( int zoomedFOV )
	{		
		SetFOV( zoomedFOV );
	}
	
	void Reload()
	{
		if( self.m_iClip == DM357_MAX_CLIP || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			return;
		m_iShotsFired = 0;
		if(bInZoom)
		{
			SecondaryAttack();
		}
		self.DefaultReload( DM357_MAX_CLIP, DM357_RELOAD, 3.3f, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "hlclassic/weapons/357_reload1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		BaseClass.Reload();
	}
	
	void WeaponIdle()
	{
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
		{
			if( !( ( m_pPlayer.pev.button & IN_ATTACK ) != 0 ) )
			{
				m_iShotsFired = 0;
			}
		}
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_10DEGREES );
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		switch (Math.RandomLong(0,3))
		{
			case 0:	self.SendWeaponAnim( DM357_IDLE );break;
			case 1:	self.SendWeaponAnim( DM357_FIDGET );break;
			case 2:	self.SendWeaponAnim( DM357_IDLE2 );break;
			case 3:	self.SendWeaponAnim( DM357_IDLE3 );break;
		}
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );
	}
}

string GetDM357Name()
{
	return "weapon_dm357";
}

void RegisterDM357()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetDM357Name(), GetDM357Name() );
	g_ItemRegistry.RegisterWeapon( GetDM357Name(), "dm_weapons", "357" );
	g_DMEntityList.insertLast(GetDM357Name());
}