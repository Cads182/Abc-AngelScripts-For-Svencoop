/***
	Made by Dr.Abc
***/

const float flSkPlrXbow		= g_EngineFuncs.CVarGetFloat( "sk_plr_xbow_bolt_monster" );

enum DMXBOWAnimation
{
	XBOW_IDLE = 0,
	XBOW_IDLE2,
	XBOW_FIDGET1,
	XBOW_FIDGET2,
	XBOW_SHOOT1,
	XBOW_SHOOT2,
	XBOW_SHOOT3,
	XBOW_RELOAD,
	XBOW_DRAW1,
	XBOW_DRAW2,
	XBOW_HOLSTER1,
	XBOW_HOLSTER2
};

class weapon_dmbow : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private bool bInZoom = false;
	private bool bCanZoom = true;
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_crossbow.mdl" );
		self.m_iDefaultAmmo = 5;
		self.FallInit();
	}
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/hlclassic/v_crossbow.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_crossbow.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_crossbow.mdl" );
		g_SoundSystem.PrecacheSound("hl/weapons/357_cock1.wav" );	
		g_SoundSystem.PrecacheSound("weapons/xbow_fire1.wav" );
		g_SoundSystem.PrecacheSound("weapons/xbow_hit1.wav" );
		g_SoundSystem.PrecacheSound("weapons/xbow_reload1.wav" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/weapon_dmbow.txt" );
	}
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 50;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= 5;
		info.iSlot 		= 2;
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
	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;			
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hl/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}	
		return false;
	}
	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model( "models/hlclassic/v_crossbow.mdl" ), self.GetP_Model( "models/hlclassic/p_crossbow.mdl" ), XBOW_DRAW1, "bow" );
			float deployTime = 0.3f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75;
			return;
		}
		if( self.m_iClip <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75;
			return;
		}
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		--self.m_iClip;
		if( self.m_iClip == 0 )
			self.SendWeaponAnim( XBOW_SHOOT3, 0, 0 );
		else
			self.SendWeaponAnim( XBOW_SHOOT1, 0, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/xbow_fire1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		int m_iBulletDamage = int(flSkPlrXbow);
		
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		Vector vecDir = g_Engine.v_forward;
		Vector vecSpeed;
		
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
			vecSpeed = vecDir * 500;
		else
			vecSpeed = vecDir * 1000;
		
		if(!bInZoom)
		{
			CBaseEntity@ pBolt = g_EntityFuncs.Create("crossbow_bolt", vecSrc, m_pPlayer.pev.v_angle, false, m_pPlayer.edict());
			pBolt.pev.dmg = m_iBulletDamage;
			pBolt.pev.velocity = vecSpeed;
			pBolt.pev.angles = Math.VecToAngles( pBolt.pev.velocity );
		}
		else
		{
			m_pPlayer.FireBullets( 1, vecSrc, vecAiming, g_vecZero, 8192, BULLET_PLAYER_CUSTOMDAMAGE, 2, m_iBulletDamage );
			TraceResult tr;	
			float x, y;	
			g_Utility.GetCircularGaussianSpread( x, y );
			Vector vectrDir = vecAiming ;
			Vector vecEnd	= vecSrc + vectrDir * 4096;
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			if( tr.flFraction < 1.0 )
			{
				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					if( pHit is null || pHit.IsBSPModel() == true )
					{
						g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );
						CBaseEntity@ pBolt = g_EntityFuncs.Create("crossbow_bolt", tr.vecEndPos, m_pPlayer.pev.v_angle, false, m_pPlayer.edict());
						pBolt.pev.velocity = vecSpeed;
						pBolt.pev.angles = Math.VecToAngles( pBolt.pev.velocity );
					}
				}
			}
		}
		
		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );	
		
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + Math.RandomFloat( 10, 15 );	
	}
	
	void SecondaryAttack()
	{
		if (!bCanZoom)
			return;
		if(!bInZoom)
		{
			bInZoom = true;
			ToggleZoom( 20 );
			m_pPlayer.m_szAnimExtension = "sniperscope";
		}
		else
		{
			bInZoom = false;
			ToggleZoom( 0 );
			m_pPlayer.m_szAnimExtension = "bow";
		}
		bCanZoom = false;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.75f;
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
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 || self.m_iClip >= 5 )
			return;
		
		if(bInZoom)
		{
			SecondaryAttack();
		}
		self.DefaultReload( 5, XBOW_RELOAD, 4.53, 0 );
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "weapons/xbow_reload1.wav", 1.0, ATTN_NORM, 0, 93 + Math.RandomLong (0,0xF) );
		BaseClass.Reload();
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		bCanZoom = true;
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		switch (Math.RandomLong(0,1))
		{
			case 0:	self.SendWeaponAnim( XBOW_IDLE );break;
			case 1:	self.SendWeaponAnim( XBOW_FIDGET1 );break;
		}
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10, 15 );
	}
	
	void Holster( int skipLocal = 0 )
	{
		if(bInZoom)
		{
			bInZoom = false;
			m_pPlayer.pev.maxspeed = 0;
			ToggleZoom( 0 );
			m_pPlayer.m_szAnimExtension = "bow";
		}
		BaseClass.Holster( skipLocal );
	}		
}
string GetWeaponNameDMXBOW()
{
	return "weapon_dmbow";
}
void RegisterDMXBOW()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dmbow", GetWeaponNameDMXBOW() );
	g_ItemRegistry.RegisterWeapon( GetWeaponNameDMXBOW(), "dm_weapons", "bolts" );
}