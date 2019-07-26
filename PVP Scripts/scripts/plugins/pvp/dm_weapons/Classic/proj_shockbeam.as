/***
	Conversion by Dr.Abc
***/

const float fl_plrShock		= g_EngineFuncs.CVarGetFloat( "sk_plr_shockrifle" );

class dm_shockbeam : ScriptBaseMonsterEntity
{
	private CBeam@ m_pBeam1;
	private CBeam@ m_pBeam2;

	private CSprite@ m_pSprite;

	private int m_iBeams;
	private bool bIsMultiplayer = false;
	void Spawn()
	{
		Precache();
		
		pev.movetype	= MOVETYPE_FLY;
		pev.solid	= SOLID_BBOX;
			
		g_EntityFuncs.SetModel( self, "models/shock_effect.mdl" );
		
		self.SetOrigin(self.GetOrigin());
		
		g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, -4 ), Vector( 4, 4, 4 ) );
		
		SetTouch( TouchFunction( BallTouch ) );
		SetThink( ThinkFunction( FlyThink ) );
		
		@m_pSprite = g_EntityFuncs.CreateSprite( "sprites/flare3.spr", self.pev.origin, false ); 
		m_pSprite.SetTransparency( kRenderTransAdd, 255, 255, 255, 255, kRenderFxDistort );
		m_pSprite.SetScale( 0.35 );
		m_pSprite.SetAttachment( self.edict(), 0 );
		
		@m_pBeam1 = g_EntityFuncs.CreateBeam( "sprites/lgtning.spr", 60 );
		
		if( m_pBeam1 !is null )
		{
			m_pBeam1.SetOrigin( m_pBeam1.GetOrigin() );
			m_pBeam1.EntsInit( m_pBeam1.entindex(), m_pBeam1.entindex() );
			m_pBeam1.SetStartAttachment( 1 );
			m_pBeam1.SetEndAttachment( 2 );
			m_pBeam1.SetColor( 0, 253, 253 );
			m_pBeam1.SetFlags( BEAM_FSHADEOUT );
			m_pBeam1.SetBrightness( 180 );
			m_pBeam1.SetNoise( 0 );
			m_pBeam1.SetScrollRate( 10 );
			if( bIsMultiplayer )
			{
				pev.nextthink = g_Engine.time + 0.1;
				return;
			}
			@m_pBeam2 = g_EntityFuncs.CreateBeam( "sprites/lgtning.spr", 20 );
			if( m_pBeam2 !is null )
			{
				m_pBeam2.SetOrigin( m_pBeam2.GetOrigin() );
				m_pBeam2.EntsInit( m_pBeam2.entindex(), m_pBeam2.entindex() );
				m_pBeam2.SetStartAttachment( 1 );
				m_pBeam2.SetEndAttachment( 2 );
				m_pBeam2.SetColor( 255, 255, 157 );
				m_pBeam2.SetFlags( BEAM_FSHADEOUT );
				m_pBeam2.SetBrightness( 180 );
				m_pBeam2.SetNoise( 30 );
				m_pBeam2.SetScrollRate( 30 );
				
				pev.nextthink = g_Engine.time + 0.1;
			}
		}
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( "sprites/flare3.spr" );
		g_Game.PrecacheModel( "sprites/lgtning.spr" );
		g_Game.PrecacheModel( "sprites/glow01.spr" );
		g_Game.PrecacheModel( "models/shock_effect.mdl" );
		g_SoundSystem.PrecacheSound("weapons/shock_impact.wav" );	
	}
	
	void FlyThink()
	{
		if( self.pev.waterlevel == WATERLEVEL_HEAD )
		{
			SetThink( ThinkFunction( WaterExplodeThink ) );
		}
		pev.nextthink = g_Engine.time + 0.01;
	}
	
	void ExplodeThink()
	{
		Explode();
		g_EntityFuncs.Remove( self );
	}
	
	void WaterExplodeThink()
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		Explode();
		g_WeaponFuncs.RadiusDamage( self.GetOrigin(), self.pev, pevOwner, 100, 150.0f, CLASS_NONE,  DMG_ALWAYSGIB | DMG_BLAST );
		g_EntityFuncs.Remove( self );
	}
	
	void BallTouch( CBaseEntity@ pOther )
	{
		if( pOther.pev.takedamage != DAMAGE_NO )
		{
			TraceResult tr = g_Utility.GetGlobalTrace();
			
			entvars_t@ pevOwner = self.pev.owner.vars;
			
			g_WeaponFuncs.ClearMultiDamage();
			
			int bitsDamageTypes = DMG_ALWAYSGIB | DMG_SHOCK;
			if( pOther.IsMonster() )
			{
				CBaseMonster@ pMonster = cast<CBaseMonster@>( pOther );
				bitsDamageTypes = 64;
				/*if( pMonster.m_flShockDuration > 1.0 )
				{
					bitsDamageTypes = 8192;
				}*/
				pMonster.ShockGlowEffect( true );
			}
			pOther.TraceAttack( pevOwner, bIsMultiplayer ? 15 : int(fl_plrShock), self.pev.velocity.Normalize(), tr, bitsDamageTypes );  
			g_WeaponFuncs.ApplyMultiDamage(self.pev, pevOwner);
			self.pev.velocity = g_vecZero;
		}
		SetThink( ThinkFunction( ExplodeThink ) );
		pev.nextthink = g_Engine.time + 0.01;
		
		if( pOther.pev.takedamage == DAMAGE_NO )
		{
			TraceResult tr ;
			g_Utility.TraceLine( self.GetOrigin(), self.GetOrigin() + self.pev.velocity * 10, dont_ignore_monsters, self.edict(), tr );
			g_Utility.DecalTrace( tr, DECAL_OFSCORCH1 + Math.RandomLong( 0, 2 ));
			g_Utility.Sparks( self.GetOrigin() );
		}
	}
	
	void Explode()
	{
		entvars_t@ pevOwner = self.pev.owner.vars;
		if( m_pSprite !is null )
		{
			g_EntityFuncs.Remove( m_pSprite );
			@m_pSprite = null;
		}
		
		if( m_pBeam1 !is null )
		{
			g_EntityFuncs.Remove( m_pBeam1 );
			@m_pBeam1 = null;
		}
		
		if( m_pBeam2 !is null )
		{
			g_EntityFuncs.Remove( m_pBeam2 );
			@m_pBeam2 = null;
		}
		
		g_WeaponFuncs.RadiusDamage( self.pev.origin,self.pev, pevOwner, pev.dmg, 5 ,CLASS_NONE, DMG_SHOCK );
		
		NetworkMessage m( MSG_PVS , NetworkMessages::SVC_TEMPENTITY, null );
			m.WriteByte(TE_DLIGHT);
			m.WriteCoord(self.pev.origin.x);
			m.WriteCoord(self.pev.origin.y);
			m.WriteCoord(self.pev.origin.z);
			m.WriteByte(8);
			m.WriteByte(0);
			m.WriteByte(253);
			m.WriteByte(253);
			m.WriteByte(5);
			m.WriteByte(10);
		m.End();
		
		@self.pev.owner = null;
		
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "weapons/shock_impact.wav", Math.RandomFloat(0.8,0.9), ATTN_NORM, 0, PITCH_NORM );
	}
}

string GetNameProjShockBeam()
{
	return "dm_shockbeam";
}

void RegisterPJshockbeam()
{
	g_CustomEntityFuncs.RegisterCustomEntity( GetNameProjShockBeam(), GetNameProjShockBeam() );
	g_DMEntityList.insertLast(GetNameProjShockBeam());
}