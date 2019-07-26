/***
	From Default Angelscripts sample
***/

class weapon_hlmp5 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private float m_flNextAnimTime;
	private int m_iShell,m_iSecondaryAmmo;
	void Spawn()
	{
		if(IsClassMode)
			Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_9mmAR.mdl" );
		self.m_iDefaultAmmo = 100;
		self.m_iClip = 25;
		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/hlclassic/v_9mmAR.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_9mmAR.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_9mmAR.mdl" );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );
		g_Game.PrecacheModel( "models/grenade.mdl" );
		g_Game.PrecacheModel( "models/w_9mmARclip.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );              
		g_SoundSystem.PrecacheSound( "hlclassic/items/clipinsert1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/items/cliprelease1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/items/guncock1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks3.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/glauncher.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/glauncher2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
	}
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 250;
		info.iMaxAmmo2 	= 10;
		info.iMaxClip 	= 50;
		info.iSlot 		= 2;
		info.iPosition 	= 4;
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
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/357_cock1.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		}
		return false;
	}
	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/hlclassic/v_9mmAR.mdl" ), self.GetP_Model( "models/hlclassic/p_9mmAR.mdl" ), 4, "mp5" );
	}
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD ){
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;}
		if( self.m_iClip <= 0 ){
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;}
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		--self.m_iClip;
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) ){
			case 0: self.SendWeaponAnim( 5, 0, 0 ); break;
			case 1: self.SendWeaponAnim( 6, 0, 0 ); break;
			case 2: self.SendWeaponAnim( 7, 0, 0 ); break;}
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/hks1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		g_DMUtility.DMTraceDamage( m_pPlayer, self.pev, 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_MP5 );
		g_DMUtility.DMBulletEjection( m_pPlayer.GetGunPosition(), Vector(7,17,-8), m_pPlayer.pev.angles[1], m_iShell, TE_BOUNCE_SHELL ,m_pPlayer.pev.velocity);
		
		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );
		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.1;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}
	void SecondaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD ){
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;}
		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 ){
			self.PlayEmptySound();
			return;}
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
		m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );
		m_pPlayer.pev.punchangle.x = -10.0;
		self.SendWeaponAnim( 2 );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		if ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/glauncher.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		else
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/glauncher2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		if( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
			g_EntityFuncs.ShootContact( m_pPlayer.pev, m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 800 );
		else
			g_EntityFuncs.ShootContact( m_pPlayer.pev, m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 800 );
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 1;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 5;
		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	}
	void Reload()
	{
		self.DefaultReload( 50, 3, 1.5, 0 );
		BaseClass.Reload();
	}
	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) ){
			case 0:	iAnim = 0;break;
			case 1:iAnim = 1;break;
			default:iAnim = 1;break;}
		self.SendWeaponAnim( iAnim );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}
}

void RegisterDMMP5()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_hlmp5", "weapon_hlmp5" );
	g_ItemRegistry.RegisterWeapon( "weapon_hlmp5", "hl_weapons", "9mm", "ARgrenades" );
	g_DMEntityList.insertLast("weapon_hlmp5");
}