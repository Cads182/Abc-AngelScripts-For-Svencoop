/***				Easy Barrel - Dr.Abc
							 - Dr.Abc@foxmail.com ****/

enum BARRELhuAnimation
{
	BARREL_IDLE = 0,
	BARREL_FIDGET,
	BARREL_DRAW,
	BARREL_ATTACK1HIT,
	BARREL_HOLSTER
	
};

class weapon_zmbarrel : ScriptBasePlayerWeaponEntity
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
		
		g_Game.PrecacheGeneric( "sprites/" + "dm_weapons/weapon_zmbarrel.txt" );
		
		g_Game.PrecacheOther( "monster_zmbarrel" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= -1;
		info.iMaxAmmo2		= -1;
		info.iSlot			= 7;
		info.iPosition		= 6;
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
			bResult = self.DefaultDeploy( self.GetV_Model( "models/v_satchel_radio.mdl" ), self.GetP_Model( "models/p_satchel_radio.mdl" ), BARREL_DRAW, "saw" );
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
			self.SendWeaponAnim( BARREL_ATTACK1HIT, 0, 0 );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "ambience/loader_step1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
			Vector vecReal = m_pPlayer.pev.angles + vecAangle;
			vecReal.x = 0;
			CBaseEntity@ pSentry = g_EntityFuncs.Create( "monster_zmbarrel" , vecSentry , vecReal , false , self.edict() );
			@pSentry.pev.owner = m_pPlayer.edict();
			g_EntityFuncs.DispatchSpawn(pSentry.edict());
			g_EntityFuncs.DispatchKeyValue(pSentry.edict(), "displayname", string(m_pPlayer.pev.netname) + "'s barrel" );
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
		 if (g_EngineFuncs.PointContents(tr.vecEndPos) == CONTENTS_SKY || pHit is null || !pHit.IsBSPModel() || pHit.pev.classname == "holobarrel")
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
		self.SendWeaponAnim( BARREL_IDLE );
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
			pSprite.pev.classname == "holobarrel";
			pSprite.AnimateAndDie(2);
			
			self.pev.nextthink = g_Engine.time + 0.2f;
		}
		else
			self.pev.nextthink = g_Engine.time + 20.0f;
		BaseClass.Think();
	}
}


class monster_zmbarrel: ScriptBaseMonsterEntity
{
	void Spawn()
	{ 
		pev.movetype	= MOVETYPE_FLY;
		pev.solid	= SOLID_BBOX;
		pev.takedamage	= DAMAGE_YES;
		pev.flags	|= FL_MONSTER;
		self.m_bloodColor	= DONT_BLEED;
		pev.health	= 200;
		g_EntityFuncs.SetModel(self, "models/dm_weapons/zm_barrel.mdl");
		Precache();
		BaseClass.Spawn();
		g_EntityFuncs.SetSize(self.pev, Vector( -32, -32, -64 ), Vector( 32, 32, 64 ));
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( "models/dm_weapons/zm_barrel.mdl" );
		g_Game.PrecacheGeneric( "models/dm_weapons/zm_barrel.mdl" );
		
		g_Game.PrecacheModel( "models/metalplategibs.mdl" );
		
		g_SoundSystem.PrecacheSound("debris/metal1.wav");
		g_SoundSystem.PrecacheSound("debris/metal3.wav");
		g_SoundSystem.PrecacheSound("debris/metal4.wav");
		g_SoundSystem.PrecacheSound("debris/metal7.wav");
	}
	
	int TakeDamage(entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
	{
		if( flDamage > 0 )
		{
			switch(Math.RandomLong(0,2))
			{
				case 0:g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "debris/metal1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );break;
				case 1:g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "debris/metal3.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );break;
				case 2:g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "debris/metal4.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );break;
			}
			BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
			return 1;
		}
		return 0;
	}
	
	void Killed(entvars_t@pevAtttacker, int iGibbed)
	{
		if(pev.health <= 0 )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_ITEM, "debris/metal7.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			te_breakmodel( self.pev.origin, Vector(4,4,4), self.pev.velocity );
			g_EntityFuncs.Remove(self);
		}
		BaseClass.Killed( pevAtttacker, iGibbed );
	}
	
	void te_breakmodel(Vector pos, Vector size, Vector velocity)
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
			m.WriteByte(TE_BREAKMODEL);
			m.WriteCoord(pos.x);
			m.WriteCoord(pos.y);
			m.WriteCoord(pos.z);
			m.WriteCoord(size.x);
			m.WriteCoord(size.y);
			m.WriteCoord(size.z);
			m.WriteCoord(velocity.x);
			m.WriteCoord(velocity.y);
			m.WriteCoord(velocity.z);
			m.WriteByte(16);
			m.WriteShort(g_EngineFuncs.ModelIndex("models/metalplategibs.mdl"));
			m.WriteByte(8);
			m.WriteByte(0);
			m.WriteByte(20);
		m.End();
	}
}

void RegisterZMBarrel()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_zmbarrel", "monster_zmbarrel" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_zmbarrel", "weapon_zmbarrel" );
	g_ItemRegistry.RegisterWeapon( "weapon_zmbarrel", "dm_weapons","barrel" );
	g_DMEntityList.insertLast("weapon_zmbarrel");
	g_DMEntityList.insertLast("monster_zmbarrel");
}
