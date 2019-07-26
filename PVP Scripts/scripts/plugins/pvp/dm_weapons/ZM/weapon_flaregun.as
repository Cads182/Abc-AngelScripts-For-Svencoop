/***				Easy flareGun - Dr.Abc
							 - Dr.Abc@foxmail.com ****/

enum flareAnimation //动作顺序
{
	flare_IDLE = 0,
	flare_SHOOT1,
	flare_RELOAD,
	flare_DRAW
};


const int flaregun_MAX_CLIP			= 1;

class weapon_flaregun : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	
	void Spawn()
	{
		Precache();
		self.m_iDefaultAmmo = 5;//默认给予
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/dm_weapons/w_flaregun.mdl") ); //掉落模型
		self.FallInit();	//重力
	}

	void Precache() //预加载资源
	{
		self.PrecacheCustomModels();
		
		g_Game.PrecacheModel( "models/dm_weapons/flarelight.mdl" ); 
		
		g_Game.PrecacheModel( "models/dm_weapons/v_flaregun.mdl" );
		g_Game.PrecacheModel( "models/dm_weapons/w_flaregun.mdl" );
		g_Game.PrecacheModel( "models/dm_weapons/p_flaregun.mdl" );
		
		g_SoundSystem.PrecacheSound( "weapons/dm_weapons/flare/firegun_draw.wav" );
		g_SoundSystem.PrecacheSound( "weapons/dm_weapons/flare/flaregun_shoot.wav" );
		g_SoundSystem.PrecacheSound( "weapons/dm_weapons/flare/grenadelauncher_reload.wav" );
		g_SoundSystem.PrecacheSound( "weapons/dm_weapons/minicrit_hit2.wav" );
		
		g_Game.PrecacheModel( "sprites/dm_weapons/flaregun.spr" );
		g_Game.PrecacheModel( "sprites/dm_weapons/flareguns.spr" );
		g_Game.PrecacheModel( "sprites/hotglow.spr" );
		g_Game.PrecacheModel( "sprites/glow01.spr" );
		
		g_Game.PrecacheGeneric( "sound/" + "weapons/dm_weapons/flare/firegun_draw.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/dm_weapons/flare/flaregun_shoot.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/dm_weapons/flare/grenadelauncher_reload.wav" );
		g_Game.PrecacheGeneric( "sound/"   + "weapons/dm_weapons/minicrit_hit2.wav" );

		g_Game.PrecacheGeneric( "sprites/" + "dm_weapons/weapon_flaregun.txt" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= 20;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= flaregun_MAX_CLIP;
		info.iSlot			= 1;
		info.iPosition		= 11;
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
		return self.DefaultDeploy( self.GetV_Model( "models/dm_weapons/v_flaregun.mdl" ), self.GetP_Model( "models/dm_weapons/p_flaregun.mdl" ), flare_DRAW, "onehanded" );
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;// 取消上弹
		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 
	}
	
	void PrimaryAttack()
	{
		if( self.m_iClip <= 0 )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.9f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		
		
		self.SendWeaponAnim( flare_SHOOT1, 0, 0 );
	
		--self.m_iClip;

		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/dm_weapons/flare/flaregun_shoot.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		
        Shootflare(m_pPlayer.pev,
                     m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -5.5 +g_Engine.v_right * 9 ,
                     g_Engine.v_forward * 1300	+ g_Engine.v_up * -6.5);
					 
		m_pPlayer.pev.punchangle.x += Math.RandomFloat( -5, -1 );
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 2.12f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );	
	}
	
	void Reload()
	{
		if( self.m_iClip == flaregun_MAX_CLIP ) 
			return;
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			return;
		BaseClass.Reload();

		self.DefaultReload( flaregun_MAX_CLIP, flare_RELOAD, 1.33, 0 );
	}
	
	void WeaponIdle()
	{

		self.ResetEmptySound();

		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		self.SendWeaponAnim( flare_IDLE );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.2f;
	}
	

	private void Shootflare(entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity) 
	{
        
        CBaseEntity@ cbeflare = g_EntityFuncs.CreateEntity( "monster_flarelight", null,  false);
        monster_flarelight@ pflare = cast<monster_flarelight@>(CastToScriptClass(cbeflare));
        
        g_EntityFuncs.SetOrigin( pflare.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pflare.self.edict() );
        
        pflare.pev.velocity = vecVelocity ;
        @pflare.pev.owner = pevOwner.pContainingEntity;
        pflare.pev.angles = Math.VecToAngles( pflare.pev.velocity );
		pflare.SetThink( ThinkFunction( pflare.BulletThink ) );
        pflare.pev.nextthink = g_Engine.time + 0.1f;
		pflare.SetTouch( TouchFunction( pflare.Touch ) );
	}     
}

	
class monster_flarelight : ScriptBaseEntity 
{
	private Vector lastPos;		//上一位置
    private float mLifeTime;    // 寿命
	private int wallcheacker = 0; //墙壁检查
    void Spawn() 
	{
        pev.solid = SOLID_SLIDEBOX;
        pev.movetype = MOVETYPE_TOSS;
        pev.scale = 1;
        pev.movetype = MOVETYPE_FLY;
        g_EntityFuncs.SetModel( self, "models/dm_weapons/flarelight.mdl");
        SetThink( ThinkFunction( this.BulletThink ) );
        this.mLifeTime = g_Engine.time + 60.0f;	
    }
    
	 void Touch ( CBaseEntity@ pOther )
	{    
		entvars_t@ pevOwner = self.pev.owner.vars;
        if ( ( pOther.TakeDamage ( pev, pev, 0, DMG_SLASH ) ) != 1 )
		{
            pev.solid = SOLID_NOT;
            pev.movetype = MOVETYPE_TOSS;
            pev.velocity = Vector( 0, 0, 0 );
			wallcheacker = 1;
        }
		else if (pOther.IsAlive())
		{
				pOther.TakeDamage ( pev, self.pev.owner.vars, 10, DMG_TIMEBASED );
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_AUTO, "weapons/dm_weapons/minicrit_hit2.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
				SpriteTrail(pOther.pev.origin,pOther.pev.origin + g_Engine.v_up *1 +g_Engine.v_forward *-1);
				g_EntityFuncs.Remove( self );
		}
    }
	
	void BulletThink() 
	{
		
		switch (wallcheacker)
		{
			case 0 :pev.velocity = pev.velocity + g_Engine.v_up * -80;break;
			case 1 :pev.velocity = pev.velocity + g_Engine.v_up * -160;break;
		}
		
		
		if(!lastPos.opEquals(self.pev.origin))
		{
			Delight(self.pev.origin,40,25,5,5,9,255);
			lastPos = self.pev.origin;
			self.pev.nextthink = g_Engine.time + 0.5f;
		}
		else
		{
			Delight(self.pev.origin,40,55,20,20,31,0);	
			lastPos = self.pev.origin;
			SpriteTrail(self.pev.origin,lastPos + g_Engine.v_up *1 +g_Engine.v_forward *-1);
			GlowSprite(self.pev.origin,"sprites/glow01.spr",1,10,160);
			self.pev.nextthink = g_Engine.time + 3.0f;
		}
        // 移除自身
        if ((this.mLifeTime > 0) && (g_Engine.time  >= this.mLifeTime))
            g_EntityFuncs.Remove( self );

	}
	
	void Delight(Vector pos, uint8 radius=25, uint8 r =255,uint8 g = 0, uint8 b = 0,uint8 life=255, uint8 decayRate=50)//通用发光
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
		m.WriteByte(TE_DLIGHT);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteByte(radius);
		m.WriteByte(r);
		m.WriteByte(g);
		m.WriteByte(b);
		m.WriteByte(life);
		m.WriteByte(decayRate);
		m.End();
	}
	
	void SpriteTrail(Vector start, Vector end, string sprite="sprites/hotglow.spr", uint8 count=5, uint8 life=0, uint8 scale=1, uint8 speed=16, uint8 speedNoise=8)//通用喷射SPR
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
			m.WriteByte(TE_SPRITETRAIL);
			m.WriteCoord(start.x);
			m.WriteCoord(start.y);
			m.WriteCoord(start.z);
			m.WriteCoord(end.x);
			m.WriteCoord(end.y);
			m.WriteCoord(end.z);
			m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
			m.WriteByte(count);
			m.WriteByte(life);
			m.WriteByte(scale);
			m.WriteByte(speedNoise);
			m.WriteByte(speed);
		m.End();
	}
	
	void GlowSprite(Vector pos, string sprite="sprites/redflare2.spr", uint8 life=1, uint8 scale=10, uint8 alpha=255)//通用发光SPR
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
		m.WriteByte(TE_GLOWSPRITE);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteShort(g_EngineFuncs.ModelIndex(sprite));
		m.WriteByte(life);
		m.WriteByte(scale);
		m.WriteByte(alpha);
		m.End();
	}
}
	
void RegisterFlaregun()
{
    g_CustomEntityFuncs.RegisterCustomEntity( "monster_flarelight", "monster_flarelight" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_flaregun", "weapon_flaregun" );
	g_ItemRegistry.RegisterWeapon( "weapon_flaregun", "dm_weapons","monster_flarelight" );
	g_DMEntityList.insertLast("weapon_flaregun");
	g_DMEntityList.insertLast("monster_flarelight");
}
