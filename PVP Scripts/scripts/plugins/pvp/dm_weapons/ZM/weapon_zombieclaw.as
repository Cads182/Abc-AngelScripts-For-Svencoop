/***				Easy ZomClaw - Dr.Abc
							 - Dr.Abc@foxmail.com ****/

enum zombieclaw_e
{
	ZOMBIECLAW_IDLE = 0,
	ZOMBIECLAW_DRAW,
	ZOMBIECLAW_HOLSTER,
	ZOMBIECLAW_ATTACK1HIT,
	ZOMBIECLAW_ATTACK1MISS,
	ZOMBIECLAW_ATTACK2MISS,
	ZOMBIECLAW_ATTACK2HIT,
	ZOMBIECLAW_ATTACK3MISS,
	ZOMBIECLAW_ATTACK3HIT,
	ZOMBIECLAW_IDLE2,
	ZOMBIECLAW_IDLE3,
	ZOMBIECLAW_EAT,
	ZOMBIECLAW_ATKR
};

class weapon_zombieclaw : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	int m_iSwing;
	TraceResult m_trHit;
	
	void Spawn()
	{
		self.Precache();
		g_EntityFuncs.SetModel( self, self.GetW_Model( "models/w_crowbar.mdl") );
		self.m_iClip			= -1;
		self.m_iDefaultAmmo = 1;
		self.m_flCustomDmg		= self.pev.dmg;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( "models/dm_weapons/v_zclaws.mdl" );
		g_Game.PrecacheModel( "models/w_crowbar.mdl" );
		g_Game.PrecacheModel( "models/p_headcrab_face.mdl" );
		
		g_Game.PrecacheModel( "sprites/dm_weapons/640hud01.spr" );
		g_Game.PrecacheModel( "sprites/dm_weapons/640hud04.spr" );
		g_Game.PrecacheModel( "sprites/640hud7.spr" );
		g_Game.PrecacheModel( "sprites/crosshairs.spr" );
		
		g_Game.PrecacheGeneric( "sprites/dm_weapons/640hud01.spr" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/640hud04.spr" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/weapon_zombieclaw.txt" );

		g_SoundSystem.PrecacheSound( "zombie/zo_attack1.wav" );
		g_SoundSystem.PrecacheSound( "zombie/zo_attack2.wav" );
		g_SoundSystem.PrecacheSound( "zombie/claw_strike1.wav" );
		g_SoundSystem.PrecacheSound( "zombie/claw_strike2.wav" );
		g_SoundSystem.PrecacheSound( "zombie/claw_strike3.wav.wav" );
		g_SoundSystem.PrecacheSound( "zombie/claw_miss1.wav" );
		
		g_Game.PrecacheOther( "item_zmbrain" );
		g_Game.PrecacheOther( "item_zmgrenade" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1		= 5;
		info.iMaxAmmo2		= -1;
		info.iMaxClip		= WEAPON_NOCLIP;
		info.iSlot			= 0;
		info.iPosition		= 5;
		info.iWeight		= 0;
		info.iFlags  	= 0;
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;		
		@m_pPlayer = pPlayer;
		return true;
	}

	bool Deploy()
	{
		return self.DefaultDeploy( self.GetV_Model( "models/dm_weapons/v_zclaws.mdl" ), self.GetP_Model( "models/p_headcrab_face.mdl" ), ZOMBIECLAW_DRAW, "crowbar" );
	}

	void Holster( int skiplocal /* = 0 */ )
	{
		self.m_fInReload = false;

		m_pPlayer.m_flNextAttack = g_WeaponFuncs.WeaponTimeBase() + 0.5; 

		m_pPlayer.pev.viewmodel = 0;
	}
	
	void Materialize()
	{
		BaseClass.Materialize();
		
		g_EntityFuncs.Remove(self);
	}
	
	void PrimaryAttack()
	{
		if( !Swing( 1 ) )
		{
			SetThink( ThinkFunction( this.SwingAgain ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}
	}
	
	void TertiaryAttack()
	{
		bool fDidHit = false;
		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 64;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		
		CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );
		if( pEntity.pev.classname == "item_zmbrain")
		{
			self.SendWeaponAnim( ZOMBIECLAW_EAT );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) + 1 );	
			m_pPlayer.pev.health = m_pPlayer.pev.health + 500 >= m_pPlayer.pev.max_health ? m_pPlayer.pev.max_health : m_pPlayer.pev.health + 500;
			g_EntityFuncs.Remove(pEntity);
		}
		
		self.m_flNextTertiaryAttack = g_Engine.time + 1.0f;
	}
	
	void SecondaryAttack()
	{		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "zombie/zo_attack1.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 5 ) ); 
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 1 )
		{
			self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.5;
			self.SendWeaponAnim( ZOMBIECLAW_IDLE2 );
			return;
		}
		self.SendWeaponAnim( ZOMBIECLAW_ATKR );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle);
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );	
		ShootGrenade(m_pPlayer.pev,m_pPlayer.GetGunPosition() + g_Engine.v_forward * 32 + g_Engine.v_up * -8 + g_Engine.v_right * 4.5,g_Engine.v_forward * 800 + g_Engine.v_up * 64);
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 1.5;
	}
	
	private void ShootGrenade(entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity) 
	{
        
        CBaseEntity@ cbeGrenade = g_EntityFuncs.CreateEntity( "item_zmgrenade", null,  false);
        item_zmgrenade@ pGrenade = cast<item_zmgrenade@>(CastToScriptClass(cbeGrenade));
        
        g_EntityFuncs.SetOrigin( pGrenade.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );
        
        pGrenade.pev.velocity = vecVelocity ;
        @pGrenade.pev.owner = pevOwner.pContainingEntity;
        pGrenade.pev.angles = Math.VecToAngles( pGrenade.pev.velocity );
        pGrenade.SetTouch( TouchFunction( pGrenade.Touch ) );
	}
	
	void Smack()
	{
		g_WeaponFuncs.DecalGunshot( m_trHit, BULLET_PLAYER_CROWBAR );
	}


	void SwingAgain()
	{
		Swing( 0 );
	}

	bool Swing( int fFirst )
	{
		bool fDidHit = false;
		TraceResult tr;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecSrc	= m_pPlayer.GetGunPosition();
		Vector vecEnd	= vecSrc + g_Engine.v_forward * 48;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if ( tr.flFraction >= 1.0 )
		{
			g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, m_pPlayer.edict(), tr );
			if ( tr.flFraction < 1.0 )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if ( pHit is null || pHit.IsBSPModel() )
					g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, m_pPlayer.edict() );
				vecEnd = tr.vecEndPos;
			}
		}

		if ( tr.flFraction >= 1.0 )
		{
			if( fFirst != 0 )
			{
				// miss
				switch( ( m_iSwing++ ) % 3 )
				{
				case 0:
					self.SendWeaponAnim( ZOMBIECLAW_ATTACK1MISS ); break;
				case 1:
					self.SendWeaponAnim( ZOMBIECLAW_ATTACK2MISS ); break;
				case 2:
					self.SendWeaponAnim( ZOMBIECLAW_ATTACK3MISS ); break;
				}
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "zombie/claw_miss1.wav", 1, ATTN_NORM, 0, 94 + Math.RandomLong( 0,0xF ) );

				m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			}
		}
		else
		{
			fDidHit = true;
			
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			switch( ( ( m_iSwing++ ) % 2 ) + 1 )
			{
			case 0:
				self.SendWeaponAnim( ZOMBIECLAW_ATTACK1HIT ); break;
			case 1:
				self.SendWeaponAnim( ZOMBIECLAW_ATTACK2HIT ); break;
			case 2:
				self.SendWeaponAnim( ZOMBIECLAW_ATTACK3HIT ); break;
			}

			m_pPlayer.SetAnimation( PLAYER_ATTACK1 ); 
			
			
			float flDamage = 25;
			
			if( pEntity.pev.targetname == "human")
			{
				if(pEntity.pev.armorvalue <= 0)
				{
					CSvenZM::BecomeZombie(cast<CBasePlayer@>(pEntity) , false );
					g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string(pEntity.pev.netname) + " was bite by " + string(m_pPlayer.pev.netname) + "!.\n" );
					m_pPlayer.pev.frags++;
					const string steamId = g_EngineFuncs.GetPlayerAuthId(m_pPlayer.edict());
					CZMEnchance::CPlayerEncData@ data = cast<CZMEnchance::CPlayerEncData@>(CZMEnchance::pPlayerData[steamId]);		
					data.DoneDamage += 500;
					CZMEnchance::pPlayerData[steamId] = data;
				}
				else if (pEntity.pev.armorvalue - flDamage <= 0)
					pEntity.pev.armorvalue = 0;
				else
					pEntity.pev.armorvalue -= flDamage;
			}
			else
			{
				if(pEntity.pev.targetname == "monster_"  + "*")
					m_pPlayer.pev.frags++;
					
				if ( self.m_flCustomDmg > 0 )
					flDamage = self.m_flCustomDmg;

				g_WeaponFuncs.ClearMultiDamage();
				if ( self.m_flNextPrimaryAttack + 1 < g_Engine.time )
				{
					pEntity.TraceAttack( m_pPlayer.pev, flDamage, g_Engine.v_forward, tr, DMG_CLUB );  
				}
				else
				{
					pEntity.TraceAttack( m_pPlayer.pev, flDamage * 0.5, g_Engine.v_forward, tr, DMG_CLUB );  
				}	
				g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );
			}
			
			float flVol = 1.0;
			bool fHitWorld = true;

			if( pEntity !is null )
			{
				self.m_flNextPrimaryAttack = g_Engine.time + 0.30; //0.25
				if( pEntity.Classify() != CLASS_NONE && pEntity.Classify() != CLASS_MACHINE && pEntity.BloodColor() != DONT_BLEED )
				{
					if( pEntity.IsPlayer() )
					{
						pEntity.pev.velocity = pEntity.pev.velocity + ( self.pev.origin - pEntity.pev.origin ).Normalize() * 120;
					}
					switch( Math.RandomLong( 0, 2 ) )
					{
					case 0:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "zombie/claw_strike1.wav", 1, ATTN_NORM ); break;
					case 1:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "zombie/claw_strike2.wav", 1, ATTN_NORM ); break;
					case 2:
						g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "zombie/claw_strike3.wav.wav", 1, ATTN_NORM ); break;
					}
					m_pPlayer.m_iWeaponVolume = 128; 
					if( !pEntity.IsAlive() )
						return true;
					else
						flVol = 0.1;

					fHitWorld = false;
				}
			}

			if( fHitWorld == true )
			{
				float fvolbar = g_SoundSystem.PlayHitSound( tr, vecSrc, vecSrc + ( vecEnd - vecSrc ) * 2, BULLET_PLAYER_CROWBAR );
				self.m_flNextPrimaryAttack = g_Engine.time + 0.25; //0.25
				fvolbar = 1;
				switch( Math.RandomLong( 0, 1 ) )
				{
				case 0:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "zombie/zo_attack1.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				case 1:
					g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "zombie/zo_attack2.wav", fvolbar, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
					break;
				}
			}
			m_trHit = tr;
			SetThink( ThinkFunction( this.Smack ) );
			self.pev.nextthink = g_Engine.time + 0.2;

			m_pPlayer.m_iWeaponVolume = int( flVol * 512 ); 
		}
		return fDidHit;
	}
}

class item_zmgrenade : ScriptBaseMonsterEntity 
{
    void Spawn() 
	{
		Precache();
        pev.solid = SOLID_SLIDEBOX;
        pev.movetype = MOVETYPE_TOSS;
        pev.scale = 1.5;
        g_EntityFuncs.SetModel( self, "models/gib_b_gib.mdl");
		g_EntityFuncs.SetSize(self.pev, Vector( -1, -3, -3 ), Vector( 1, 3, 3 ));
    }
	
	void Precache()
	{
		g_Game.PrecacheModel( "sprites/eexplo.spr" );
		g_Game.PrecacheModel( "models/gib_b_gib.mdl" );
		g_SoundSystem.PrecacheSound( "weapons/splauncher_impact.wav" );
	}

    void Touch ( CBaseEntity@ pOther ) 
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		while( (@pOther = g_EntityFuncs.FindEntityInSphere(pOther, self.pev.origin, 128, "*", "classname")) !is null )
		{
			if ((pOther.pev.targetname == "human" && pOther.IsPlayer() && pOther.IsBSPModel() == false) || pOther.pev is pevOwner )
			{
				Math.MakeVectors(pevOwner.v_angle);
				pOther.pev.velocity = pOther.pev.velocity - (self.pev.origin - pOther.pev.origin).Normalize() * (pOther.pev is pevOwner ? 240 : 360) + g_Engine.v_up * 120;
				pevOwner.frags += 0.5;
			}
		}
		
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_AUTO, "weapons/splauncher_impact.wav", 1, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) ); 
		
		NetworkMessage exp1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);//调用spr
			exp1.WriteByte ( TE_EXPLOSION );
			exp1.WriteCoord( self.pev.origin.x );
			exp1.WriteCoord( self.pev.origin.y );
			exp1.WriteCoord( self.pev.origin.z );
			exp1.WriteShort( g_EngineFuncs.ModelIndex("sprites/eexplo.spr") );
			exp1.WriteByte ( 10 );//spr缩放大小
			exp1.WriteByte ( 30 );//spr播放速率
			exp1.WriteByte ( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		exp1.End();
		
		
		g_EntityFuncs.Remove( self ); 
	}
}


class item_zmbrain: ScriptBaseMonsterEntity
{
	void Spawn()
	{ 
		pev.solid = SOLID_BBOX;
        pev.movetype = MOVETYPE_TOSS;
		g_EntityFuncs.SetModel(self, "models/gib_skull.mdl");
		g_EntityFuncs.SetSize(pev, Vector( -12, -12, -8 ), Vector( 12, 12, 8 ));
		pev.rendermode = kRenderNormal;
		pev.renderfx = kRenderFxGlowShell;
		pev.renderamt = 0;
		pev.rendercolor = Vector(128,0,255);
		Precache();
		BaseClass.Spawn();
	}
	
	void Touch( CBaseEntity@ pOther )
	{
		if(IsStuck(pOther))
		{
			g_EntityFuncs.SetOrigin( self, pOther.pev.origin +  pOther.pev.maxs + Vector (1,1,0) );
		}
		BaseClass.Touch( @pOther );
	}
	
	bool IsStuck( CBaseEntity@ pOther )
	{
		Vector vecMax = pOther.pev.origin + pOther.pev.maxs;
		Vector vecMin = pOther.pev.origin + pOther.pev.mins;
		if( pev.origin.x <  vecMax.x && pev.origin.x > vecMin.x)
			if( pev.origin.y <  vecMax.y && pev.origin.y > vecMin.y)
				if( pev.origin.z <  vecMax.z && pev.origin.z > vecMin.z)
					return true;
		return false;
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( "models/gib_skull.mdl" );
	}
}

string GetClawName()
{
	return "weapon_zombieclaw";
}

void RegisterZMClaw()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "item_zmbrain", "item_zmbrain" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_zmgrenade", "item_zmgrenade" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_zombieclaw", GetClawName() );
	g_ItemRegistry.RegisterWeapon( GetClawName(), "dm_weapons" , "zombieshoot");
	g_DMEntityList.insertLast("item_zmgrenade");
	g_DMEntityList.insertLast("item_zmbrain");
	g_DMEntityList.insertLast("weapon_zombieclaw");
}