/***				Easy Freeznade - Dr.Abc
							 - Dr.Abc@foxmail.com ****/

const int FREEZNADE_DEFAULT_GIVE	= 2;
const int FREEZNADE_WEIGHT			= 5;
const int FREEZNADE_MAX_CARRY		= 5;

enum FREEZNADEAnimation 
{
	FREEZNADE_IDLE = 0,
	FREEZNADE_IDLE2,
	FREEZNADE_PULLPIN,
	FREEZNADE_THROW,
	FREEZNADE_THROW2,
	FREEZNADE_THROW3,
	FREEZNADE_HOLSTER,
	FREEZNADE_DEPLOY
};

class weapon_zmfreeznade : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	float m_flStartThrow;
	float m_flReleaseThrow;
	float time;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/dm_weapons/w_freeznade.mdl" );
		self.m_iDefaultAmmo = FREEZNADE_DEFAULT_GIVE;

		self.KeyValue( "m_flCustomRespawnTime", 1 ); //fgsfds

		m_flReleaseThrow = -1.0f;
		time = 0;
		m_flStartThrow = 0;
		
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/dm_weapons/w_freeznade.mdl" );
		g_Game.PrecacheModel( "models/dm_weapons/v_freeznade.mdl" );
		g_Game.PrecacheModel( "models/dm_weapons/p_freeznade.mdl" );
		g_Game.PrecacheModel( "sprites/laserbeam.spr" );
		
		g_SoundSystem.PrecacheSound( "weapons/grenade_hit1.wav" );

		g_Game.PrecacheGeneric( "sound/" + "weapons/hydra/activate.wav" );
		g_Game.PrecacheGeneric( "sound/" + "weapons/hydra/deploy.wav" );
		
		g_Game.PrecacheGeneric( "sprites/" + "dm_weapons/weapon_zmfreeznade.txt" );
		
		g_Game.PrecacheOther("item_freezenade");
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) )
		{
			@m_pPlayer = pPlayer;
			NetworkMessage freeznade( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				freeznade.WriteLong( g_ItemRegistry.GetIdForName("weapon_zmfreeznade") );
			freeznade.End();
			return true;
		}

		return false;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= FREEZNADE_MAX_CARRY;
		info.iMaxAmmo2	= -1;
		info.iMaxClip	= WEAPON_NOCLIP;
		info.iSlot  	= 4;
		info.iPosition	= 10;
		info.iWeight	= FREEZNADE_WEIGHT;
		info.iFlags 	= ITEM_FLAG_LIMITINWORLD | ITEM_FLAG_EXHAUSTIBLE | ITEM_FLAG_ESSENTIAL;

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
			m_flReleaseThrow = -1;
			bResult = self.DefaultDeploy( self.GetV_Model( "models/dm_weapons/v_freeznade.mdl" ), self.GetP_Model( "models/dm_weapons/p_freeznade.mdl" ), FREEZNADE_DEPLOY, "crowbar" );

			float deployTime = 0.7;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + deployTime;
			return bResult;
		}
	}

	//fgsfds
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

		if( pPlayer.HasNamedPlayerItem( "weapon_zmfreeznade" ) !is null ) 
		{
			if( pPlayer.GiveAmmo( FREEZNADE_DEFAULT_GIVE, "weapon_zmfreeznade", FREEZNADE_MAX_CARRY ) != -1 )
			{
				self.CheckRespawn();
				g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1, ATTN_NORM );
				g_EntityFuncs.Remove( self );
			}
			return;
		}
		else if( pPlayer.AddPlayerItem( self ) != APIR_NotAdded )
		{
			self.AttachToPlayer( pPlayer );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "items/gunpickup2.wav", 1, ATTN_NORM );
		}
	}
	//fgsfds

	bool CanHolster()
	{
		// can only holster hand grenades when not primed!
		return m_flStartThrow == 0;
	}

	bool CanDeploy()
	{
		return m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType) != 0;
	}

	void DestroyThink()
	{
		self.DestroyItem();
	}

	void Holster( int skiplocal )
	{
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.5f;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 0.5f;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.5f;

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
		{
			m_pPlayer.pev.weapons &= ~( 0 << g_ItemRegistry.GetIdForName("weapon_zmfreeznade") );
			SetThink( ThinkFunction( DestroyThink ) );
			self.pev.nextthink = g_Engine.time + 0.1;
		}

		m_flStartThrow = 0;
		m_flReleaseThrow = -1.0f;
		BaseClass.Holster( skiplocal );
	}

	void PrimaryAttack()
	{
		if( m_flStartThrow == 0 && m_pPlayer.m_rgAmmo ( self.m_iPrimaryAmmoType ) > 0 )
		{
			m_flReleaseThrow = 0;
			m_flStartThrow = g_Engine.time;
		
			self.SendWeaponAnim( FREEZNADE_PULLPIN );
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.75;
		}
	}	


	void WeaponIdle()
	{
		if ( m_flReleaseThrow == 0 && m_flStartThrow > 0.0 )
			m_flReleaseThrow = g_Engine.time;

		if ( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;

		if ( m_flStartThrow > 0.0 )
		{
			Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

			if ( angThrow.x < 0 )
				angThrow.x = -10 + angThrow.x * ( ( 90 - 10 ) / 90.0 );
			else
				angThrow.x = -10 + angThrow.x * ( ( 90 + 10 ) / 90.0 );

			float flVel = ( 90.0f - angThrow.x ) * 6;

			if ( flVel > 750.0f )
				flVel = 750.0f;

			Math.MakeVectors ( angThrow );

			Vector vecSrc = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 24;
			Vector vecThrow = g_Engine.v_forward * flVel + m_pPlayer.pev.velocity;

			// always explode 2 seconds after the grenade was thrown
			time = m_flStartThrow - g_Engine.time + 2.0;
			if( time < 2.0 )
				time = 2.0;
			
			ShootGrenade( m_pPlayer.pev, vecSrc, vecThrow );

			self.SendWeaponAnim( FREEZNADE_THROW );
					
			// player "shoot" animation
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			m_flReleaseThrow = g_Engine.time;
			m_flStartThrow = 0;
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 1.31;
			self.m_flTimeWeaponIdle = WeaponTimeBase() + 0.75;

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );

			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 )
			{
				self.m_flTimeWeaponIdle = self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.75;
			}
			return;
		}
		else if( m_flReleaseThrow > 0 )
		{
			m_flStartThrow = 0;

			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
			{
				self.SendWeaponAnim( FREEZNADE_DEPLOY );
			}
			else
			{
				self.RetireWeapon();
				return;
			}

			self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			m_flReleaseThrow = -1;
			return;
		}

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
		{
			int iAnim;
			float flRand = g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 0, 1 );
			if( flRand <= 1.0 )
			{
				iAnim = FREEZNADE_IDLE;
				self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			}
			else
			{
				iAnim = FREEZNADE_IDLE;
				self.m_flTimeWeaponIdle = WeaponTimeBase() + 2.5;
			}

			self.SendWeaponAnim( iAnim );
		}
	}
	
	private void ShootGrenade(entvars_t@ pevOwner, Vector vecStart, Vector vecVelocity) 
	{
        CBaseEntity@ cbeGrenade = g_EntityFuncs.CreateEntity( "item_freezenade", null,  false);
        item_freezenade@ pGrenade = cast<item_freezenade@>(CastToScriptClass(cbeGrenade));
        
        g_EntityFuncs.SetOrigin( pGrenade.self, vecStart );
        g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );
        
        pGrenade.pev.velocity = vecVelocity ;
        pGrenade.pev.angles = Math.VecToAngles( pGrenade.pev.velocity );
        pGrenade.SetTouch( TouchFunction( pGrenade.Touch ) );
	}
	
}

class item_freezenade : ScriptBaseEntity
{
	float freezetime = 3.0f;
	float m_fExplodeTime = 2.0f;
	float FreezRadius = 512.0f;
	private bool isboomed = false;
	private array<EHandle> Handled;

	void Spawn()
	{
		g_EntityFuncs.SetModel(self, "models/dm_weapons/w_freeznade.mdl");
		g_EntityFuncs.SetSize(self.pev, Vector(-0.5, -0.5, -0.5), Vector(0.5, 0.5, 0.5));
		g_EntityFuncs.SetOrigin(self, self.pev.origin);
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.solid = SOLID_BBOX;
		self.pev.avelocity = Vector(300, 300, 300);
		SetThink(ThinkFunction(Explode));
		self.pev.nextthink = g_Engine.time + m_fExplodeTime;
	}

	void Explode() 
	{
		if(isboomed)
		{
			if( Handled.length() > 0 )
			{
				CBaseEntity@ pEntity = null;
				for (uint8 i = 0; i <= Handled.length() - 1; i++)
				{
					@pEntity = Handled[i];
					pEntity.pev.maxspeed = CSvenZM::ZombieSpeed;
					pEntity.pev.rendermode = kRenderNormal;
					pEntity.pev.renderfx = kRenderFxNone;
					pEntity.pev.renderamt = 0;
				}
			}
			g_EntityFuncs.Remove(self);
		}
		else
		{
			g_DMUtility.te_beamcylinder(pev.origin, int(FreezRadius), 16, Vector(0,207,240), 32);
			CBaseEntity@ pEntity = null;
			while((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, "zombie")) !is null)
			{
				if((pEntity.pev.origin - pev.origin).Length() < FreezRadius)
				{
					pEntity.pev.velocity = Vector(0,0,0);
					pEntity.pev.maxspeed = 0.0001;
					pEntity.pev.rendermode = kRenderNormal;
					pEntity.pev.renderfx = kRenderFxGlowShell;
					pEntity.pev.renderamt = 0;
					pEntity.pev.rendercolor = Vector(0,255,255);
					
					EHandle eEntity = pEntity;
					Handled.insertLast(eEntity);
				}
			}
			pev.rendermode = 1;
			pev.renderamt = 0;
			self.pev.solid = SOLID_NOT;
			isboomed = true;
			self.pev.nextthink = g_Engine.time + freezetime;
		}
	}

	void Touch(CBaseEntity@ pOther)
	{
		if (self.pev.velocity.Length() > 15.0)
		{
			g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_AUTO, "weapons/grenade_hit1.wav", 1.0, ATTN_NORM, 0, 100);
		}
		else
		{
			self.pev.angles.x = 0.0;
			self.pev.avelocity = Vector(0.0, 0.0, 0.0);
		}
		self.pev.velocity = self.pev.velocity * 0.5;
	}

}

void RegisterFreeznade()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "item_freezenade", "item_freezenade" );
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_zmfreeznade", "weapon_zmfreeznade" );
	g_ItemRegistry.RegisterWeapon( "weapon_zmfreeznade", "dm_weapons", "weapon_zmfreeznade" );
	g_ItemRegistry.RegisterItem( "weapon_zmfreeznade", "dm_weapons", "weapon_zmfreeznade" );
	
	g_DMEntityList.insertLast("item_freezenade");
	g_DMEntityList.insertLast("weapon_zmfreeznade");
}