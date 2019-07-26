/***				Easy Sentry - Dr.Abc
							 - Dr.Abc@foxmail.com ****/

enum REMOTEhuAnimation
{
	REMOTE_IDLE = 0,
	REMOTE_FIDGET,
	REMOTE_DRAW,
	REMOTE_ATTACK1HIT,
	REMOTE_HOLSTER
	
};

class weapon_zmsentry : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	private Vector vecSentry;
	private Vector vecAangle = Vector(0, 0, 0);
	private bool Visible;
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/w_isotopebox.mdl") ); //掉落模型
		self.FallInit();	//重力
	}

	void Precache() //预加载资源
	{
		self.PrecacheCustomModels();
		
        g_SoundSystem.PrecacheSound("ambience/loader_step1.wav");

		g_Game.PrecacheModel( "models/v_satchel_radio.mdl" );
		g_Game.PrecacheModel( "models/w_isotopebox.mdl" );
		g_Game.PrecacheModel( "models/p_satchel_radio.mdl" );
		
		g_Game.PrecacheModel( "sprites/640wrhudsc.spr" );
		g_Game.PrecacheModel( "sprites/iplayer.spr" );
		g_Game.PrecacheModel( "sprites/laserbeam.spr" );

		g_Game.PrecacheGeneric( "sprites/" + "dm_weapons/weapon_zmsentry.txt" );
		
		g_Game.PrecacheOther( "monster_sentry" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iSlot			= 7;
		info.iPosition		= 8;
		info.iWeight		= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
			
		@m_pPlayer = pPlayer;
		NetworkMessage  message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );//获得时播放SPR
						message.WriteLong( self.m_iId );
						message.End();
		return true;
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}

	bool Deploy()
	{
		bool bResult;
		{
			Visible = true;
			self.pev.nextthink = g_Engine.time + 0.2f;
			bResult = self.DefaultDeploy( self.GetV_Model( "models/v_satchel_radio.mdl" ), self.GetP_Model( "models/p_satchel_radio.mdl" ), REMOTE_DRAW, "saw" );
			return bResult;
		}
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		Visible = false;
		self.m_fInReload = false;// 取消上弹
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 
	}
	
	void PrimaryAttack()
	{
		if(CanDeploy())
		{
			self.SendWeaponAnim( REMOTE_ATTACK1HIT, 0, 0 );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "ambience/loader_step1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
			Vector vecReal = m_pPlayer.pev.angles + vecAangle;
			vecReal.x = 0;
			CBaseEntity@ pSentry = g_EntityFuncs.Create( "monster_sentry" , vecSentry , vecReal , false , self.edict() );
			@pSentry.pev.owner = m_pPlayer.edict();
			g_EntityFuncs.DispatchSpawn(pSentry.edict());
			g_EntityFuncs.DispatchKeyValue(pSentry.edict(), "displayname", string(m_pPlayer.pev.netname) + "'s sentry" );
			g_EntityFuncs.SetSize(pSentry.pev, Vector( -16, -16, -64 ), Vector( 16, 16, 64 ));
			pSentry.SetClassification(m_pPlayer.Classify());
			SetThink( null );
			g_EntityFuncs.Remove(self);
		}
	}
	
	void SecondaryAttack()
	{
		vecAangle.y += 5;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.1f;
	}
	
	bool CanDeploy()
	{
		TraceResult tr;
        Vector vecSrc = m_pPlayer.GetGunPosition();
		Vector vecEnd = vecSrc + g_Engine.v_forward * 128;
        // 获取注视点坐标
        Math.MakeVectors( m_pPlayer.pev.v_angle );
        g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		 CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
		 if (g_EngineFuncs.PointContents(tr.vecEndPos) == CONTENTS_SKY || pHit is null || !pHit.IsBSPModel() || pHit.pev.classname == "holosentry")
			return false;
		
		vecSrc = tr.vecEndPos;
		vecEnd = vecEnd + g_Engine.v_up * -8092;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		if( (tr.vecEndPos - vecSrc).Length() > 0 )
			return false;
		else
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( pHit is null || pHit.IsBSPModel() )
				g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
			vecSentry = tr.vecEndPos;
			return true;
		}
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		self.SendWeaponAnim( REMOTE_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}
	
	void Think()
	{
		if(Visible)
		{
			TraceResult tr;
			Vector vecSrc = m_pPlayer.GetGunPosition();
			Vector vecEnd = vecSrc + g_Engine.v_forward * 128;

			Math.MakeVectors( m_pPlayer.pev.v_angle );
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
			
			g_DMUtility.te_beampoints( vecSrc - g_Engine.v_up * 24, tr.vecEndPos );

			CSprite@ pSprite = g_EntityFuncs.CreateSprite( "sprites/iplayer.spr", tr.vecEndPos, false ); 
			pSprite.SetTransparency( kRenderTransAdd, 0, 0, 0, 255, 14 );
			pSprite.SetScale( 1 );
			pSprite.pev.classname == "holosentry";
			pSprite.AnimateAndDie(2);
			
			self.pev.nextthink = g_Engine.time + 0.2f;
		}
		else
			self.pev.nextthink = g_Engine.time + 20.0f;
		BaseClass.Think();
	}
}


void RegisterSentrygun()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_zmsentry", "weapon_zmsentry" );
	g_ItemRegistry.RegisterWeapon( "weapon_zmsentry", "dm_weapons","sentry" );
	g_DMEntityList.insertLast("weapon_zmsentry");
}
