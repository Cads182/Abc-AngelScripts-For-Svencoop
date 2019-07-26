/***
*
*	Copyright (c) 1996-2001, Valve LLC. All rights reserved.
*	
*	This product contains software technology licensed from Id 
*	Software, Inc. ("Id Technology").  Id Technology (c) 1996 Id Software, Inc. 
*	All Rights Reserved.
*
*   Use, distribution, and modification of this source code and/or resulting
*   object code is restricted to non-commercial enhancements to products from
*   Valve LLC.  All other use, distribution, or modification is prohibited
*   without written permission from Valve LLC.
*
****/

/***
	Conversion by Dr.Abc
***/


enum PenguinGrenadeAnim
{
	PENGUINGRENADE_IDLE = 0,
	PENGUINGRENADE_FIDGET,
	PENGUINGRENADE_JUMP,
	PENGUINGRENADE_RUN
};

const float PENGUIN_DETONATE_DELAY = 15.0f;
const float PENGUINRADIUS = 256.0f;
class monster_penguin :  ScriptBaseMonsterEntity
{
	
	private float m_flDie;
	private Vector m_vecTarget;
	private float m_flNextHunt;
	private float m_flNextHit;
	private Vector m_posPrev;
	private EHandle m_hOwner;
	private float m_flNextBounceSoundTime = 0;

	
	void Precache()
	{
		BaseClass.Precache();
		
		g_Game.PrecacheModel( "models/opfor/w_penguin.mdl" );
		g_Game.PrecacheModel( "sprites/steam1.spr" );
		g_Game.PrecacheModel( "sprites/zerogxplode.spr" );
		
		g_SoundSystem.PrecacheSound( "squeek/sqk_blast1.wav" );
		g_SoundSystem.PrecacheSound( "common/bodysplat.wav" );
		g_SoundSystem.PrecacheSound( "squeek/sqk_die1.wav" );
		g_SoundSystem.PrecacheSound( "squeek/sqk_hunt1.wav" );
		g_SoundSystem.PrecacheSound( "squeek/sqk_hunt2.wav" );
		g_SoundSystem.PrecacheSound( "squeek/sqk_hunt3.wav" );
		g_SoundSystem.PrecacheSound( "squeek/sqk_deploy1.wav" );
	}

	void Spawn()
	{
		Precache();

		if( !self.SetupModel() )
			g_EntityFuncs.SetModel( self, "models/opfor/w_penguin.mdl" );
			
		g_EntityFuncs.SetSize( self.pev, Vector( -4, -4, 0 ), Vector( 4, 4, 8 ) );
	
		// motor
		@pev.owner					=@pev.owner;
		pev.solid					= SOLID_BBOX;
		pev.movetype				= MOVETYPE_BOUNCE;
		pev.flags			       |= FL_MONSTER;
		pev.takedamage = DAMAGE_AIM;
		pev.sequence = PENGUINGRENADE_RUN;
		pev.health				= g_EngineFuncs.CVarGetFloat( "sk_snark_health" );
		pev.dmg =  g_EngineFuncs.CVarGetFloat( "sk_plr_hand_grenade" );
		pev.gravity = 0.5;
		pev.friction = 0.5;
		self.m_bloodColor	= BLOOD_COLOR_RED;
		self.m_flFieldOfView		= 0; // 180 degrees
		self.m_FormattedName		= "Penguin";
		
		SetTouch( TouchFunction(SuperBounceTouch) );
		SetThink( ThinkFunction(HuntThink) );
		pev.nextthink = g_Engine.time +  0.1;
		
		m_flNextHunt = g_Engine.time + 1E6;
		m_flDie = g_Engine.time + PENGUIN_DETONATE_DELAY;
		
		CBaseEntity@ pOwner = g_EntityFuncs.Instance(pev.owner);
		if( pOwner !is null )
			m_hOwner = pOwner;
		
		self.MonsterInit();
		self.ResetSequenceInfo();
	}

	int GetClassification(int cl)
	{
		//if( cl != self.GetNoneId() )
			//return cl; // protect against recursion
		
		CBaseEntity@ pEnemy = g_EntityFuncs.Instance(pev.enemy);
		if( @ pEnemy is self.m_hEnemy.GetEntity() )
		{
			cl = self.GetClassification( CLASS_INSECT ); // no one cares about it

			const int classId = pEnemy.Classify();

			if( classId == self.GetClassification( CLASS_PLAYER ) ||
				classId == self.GetClassification( CLASS_HUMAN_PASSIVE ) ||
				classId == self.GetClassification( CLASS_HUMAN_MILITARY ) )
			{
				return self.GetClassification( CLASS_ALIEN_MILITARY ); // barney's get mad, grunts get mad at it
			}
		}
		return self.GetClassification( CLASS_ALIEN_BIOWEAPON );
	}

	void Killed(entvars_t@ pevAttacker, int iGib)
	{
		BaseClass.Killed(pevAttacker, iGib);
		
		CBaseEntity@ pOwner = m_hOwner;

		//Set owner if it was changed. - Solokiller
		if( pOwner !is null )
		{
			@pev.owner =  pOwner.edict();
		}
		Detonate();

		g_Utility.BloodDrips( self.GetOrigin(), g_vecZero, self.BloodColor(), 80 );

		//Detonate clears the owner, so set it again. - Solokiller
		if( pOwner !is null  )
		{
			@pev.owner =  pOwner.edict();
		}
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "common/bodysplat.wav", 0.75, ATTN_NORM, 0, 200 );
	}

	void SuperBounceTouch( CBaseEntity @pOther )
	{
		TraceResult tr = g_Utility.GetGlobalTrace();

		CBaseEntity@ pRealOwner = m_hOwner;

		{
			CBaseEntity@ pOwner = g_EntityFuncs.Instance(pev.owner);
			// don't hit the guy that launched this grenade
			if( pOwner is pOwner && pOther is pOwner )
				return;
		}

		// at least until we've bounced once
		@pev.owner = null;

		{
			Vector vecAngles = pev.angles;

			vecAngles.x = 0;
			vecAngles.z = 0;

			pev.angles = vecAngles;
		}

		// avoid bouncing too much
		if( m_flNextHit > g_Engine.time )
			return;

		// higher pitch as squeeker gets closer to detonation time
		const float flpitch = 155.0 - 60.0 * ( ( m_flDie - g_Engine.time ) / PENGUIN_DETONATE_DELAY );

		if( pOther.pev.takedamage != DAMAGE_NO && self.m_flNextAttack < g_Engine.time )
		{
			// attack!

			bool bIsEnemy = true;

			//Check if this is an ally. Used for teamplay/CTF. - Solokiller
			if( g_pGameRules.IsMultiplayer )
			{
				CBaseEntity@ pOwner = pRealOwner;

				if( pOwner is null )
					@pOwner = g_EntityFuncs.Instance(0);

				if( pOwner.IsPlayer() && pOther.IsPlayer() )
				{
					bIsEnemy = true;
				}
			}
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

			// make sure it's me who has touched them
			if( pHit == pOther )
			{
				// and it's not another squeakgrenade
				if( pHit.pev.modelindex != pev.modelindex )
				{
					// ALERT( at_console, "hit enemy\n");
					g_WeaponFuncs.ClearMultiDamage();
					
					pOther.TraceAttack(  self.pev, g_EngineFuncs.CVarGetFloat( "sk_snark_dmg_bite" ), g_Engine.v_forward, tr, DMG_SLASH );
					if( pRealOwner !is null )
						g_WeaponFuncs.ApplyMultiDamage( self.pev, pRealOwner.pev );
					else
						g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );

					// add more explosion damage
					// m_flDie += 2.0; // add more life
					//Friendly players cause explosive damage to increase at a lower rate. - Solokiller
					pev.dmg =  Math.min (pev.dmg  + ( bIsEnemy ? pev.dmg : pev.dmg / 5.0 ), 500) ;

					// make bite sound
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, "squeek/sqk_deploy1.wav", VOL_NORM, ATTN_NORM, 0,  int  (flpitch) );
					self.m_flNextAttack = g_Engine.time + 0.5;
				}
			}
		}

		m_flNextHit = g_Engine.time + 0.1;
		m_flNextHunt = g_Engine.time;

		if( g_pGameRules.IsMultiplayer )
		{
			// in multiplayer, we limit how often snarks can make their bounce sounds to prevent overflows.
			if( g_Engine.time < m_flNextBounceSoundTime )
			{
				// too soon!
				return;
			}
		}

		if( pev.flags & FL_SWIM != 0 )
		{
			// play bounce sound
			float flRndSound = Math.RandomFloat( 0, 1 );

			if( flRndSound <= 0.33 )
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt1.wav", VOL_NORM, ATTN_NORM, 0, int  (flpitch) );
			else if( flRndSound <= 0.66 )
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt2.wav", VOL_NORM, ATTN_NORM, 0, int  (flpitch) );
			else
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_hunt3.wav", VOL_NORM, ATTN_NORM, 0, int  (flpitch) );
			//g_SoundEnt.InsertSound( bits_SOUND_COMBAT, self.GetOrigin(), 256, 0.25 );
		}
		else
		{
			// skittering sound
			//g_SoundEnt.InsertSound( bits_SOUND_COMBAT, self.GetOrigin(), 100, 0.1 );
		}

		m_flNextBounceSoundTime = g_Engine.time + 0.5;// half second.
	}

	void HuntThink()
	{
		// ALERT( at_console, "think\n" );

		if( !self.IsInWorld() )
		{
			SetTouch( null );
			g_EntityFuncs.Remove( self );
			return;
		}

		self.StudioFrameAdvance();
		pev.nextthink = g_Engine.time + 0.1;

		// explode when ready
		if( g_Engine.time >= m_flDie )
		{
			//g_vecAttackDir =  pev.velocity.Normalize();
			pev.health = -1;
			Killed( self.pev, GIB_NORMAL );
			return;
		}

		// float
		if( pev.waterlevel != WATERLEVEL_DRY )
		{
			if( pev.movetype == MOVETYPE_BOUNCE )
			{
				pev.movetype = MOVETYPE_FLY;
			}
			Vector vecVelocity = pev.velocity * 0.9;
			vecVelocity.z += 8.0;

			 pev.velocity = vecVelocity;
		}
		else if( pev.movetype == MOVETYPE_FLY )
		{
			pev.movetype = MOVETYPE_BOUNCE;
		}

		// return if not time to hunt
		if( m_flNextHunt > g_Engine.time )
			return;

		m_flNextHunt = g_Engine.time + 2.0;

		Vector vecFlat =  pev.velocity;
		vecFlat.z = 0;
		vecFlat = vecFlat.Normalize();

		Math.MakeVectors( pev.angles );

		CBaseEntity@ pEntity = self.m_hEnemy;
		if( pEntity is null || !pEntity.IsAlive() )
		{
			// find target, bounce a bit towards it.
			self.Look( 512 );
			self.m_hEnemy = EHandle(FindClosestEnemy(512));
			@pEntity = self.m_hEnemy;
		}

		// squeek if it's about time blow up
		if( ( m_flDie - g_Engine.time <= 0.5 ) && ( m_flDie - g_Engine.time >= 0.3 ) )
		{
			g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "squeek/sqk_die1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM + Math.RandomLong( 0, 0x3F ) );
			//g_SoundEnt.InsertSound( bits_SOUND_COMBAT, self.GetOrigin(), 256, 0.25 );
		}

		// higher pitch as squeeker gets closer to detonation time
		float flpitch = Math.min(155.0 - 60.0 * ( ( m_flDie - g_Engine.time ) / PENGUIN_DETONATE_DELAY ), 80);

		if( pEntity !is null )
		{
			Vector m_vecTarget;
			if( self.FVisible( pEntity , true ) )
			{
				Vector vecDir = pEntity.EyePosition() - self.GetOrigin();
				m_vecTarget = vecDir.Normalize();
			}

			float flVel =  pev.velocity.Length();
			float flAdj = Math.min(50.0 / ( flVel + 10.0 ), 1.2);


			// ALERT( at_console, "think : enemy\n");

			// ALERT( at_console, "%.0f %.2f %.2f %.2f\n", flVel, m_vecTarget.x, m_vecTarget.y, m_vecTarget.z );

			pev.velocity =  pev.velocity * flAdj + m_vecTarget * 300;
		}

		if( pev.flags & FL_SWIM == 0 )
		{
			pev.avelocity =  g_vecZero ;
		}
		else
		{
			if( pev.avelocity == g_vecZero )
			{
				Vector vecAVel;
				vecAVel.x = Math.RandomFloat( -100, 100 );
				vecAVel.y = pev.avelocity.y;
				vecAVel.z = Math.RandomFloat( -100, 100 );

				pev.avelocity =  vecAVel ;
			}
		}

		if( ( (self.GetOrigin() - self.m_vecLastOrigin).Length() < 1.0 ))
		{
			Vector vecVel;
			vecVel.x = Math.RandomFloat( -100, 100 );
			vecVel.y = Math.RandomFloat( -100, 100 );
			vecVel.z =  pev.velocity.z;

			pev.velocity = vecVel;
		}
		self.m_vecLastOrigin = self.GetOrigin();

		Vector vecAngles = Math.VecToAngles(  pev.velocity );

		vecAngles.x = 0;
		vecAngles.z = 0;

		pev.angles = vecAngles;
	}

	void Smoke()
	{
		if( g_EngineFuncs.PointContents( self.GetOrigin() ) == CONTENTS_WATER )
		{
			g_Utility.Bubbles( self.GetOrigin() - Vector( 64, 64, 64 ), self.GetOrigin() + Vector( 64, 64, 64 ), 100 );
		}
		else
		{
			NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
				m.WriteByte(TE_SMOKE);
				m.WriteCoord(self.GetOrigin().x);
				m.WriteCoord(self.GetOrigin().y);
				m.WriteCoord(self.GetOrigin().z);
				m.WriteShort(g_EngineFuncs.ModelIndex("sprites/steam1.spr"));
				m.WriteByte(int ( ( pev.dmg - 50.0 ) * 0.8 ));
				m.WriteByte(12);
			m.End();
		}
		g_EntityFuncs.Remove( self );
	}
	
	
	void Detonate()
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
			m.WriteByte(TE_EXPLOSION);
			m.WriteCoord(pev.origin.x);
			m.WriteCoord(pev.origin.y);
			m.WriteCoord(pev.origin.z);
			m.WriteShort(g_EngineFuncs.ModelIndex("sprites/zerogxplode.spr"));
			m.WriteByte(50);//scale
			m.WriteByte(15);//framrate
			m.WriteByte(0);//flag
		m.End();
		g_WeaponFuncs.RadiusDamage(pev.origin, self.pev, pev.owner.vars, pev.dmg, PENGUINRADIUS, -1, DMG_BLAST);
		
		SetThink(ThinkFunction(Smoke));
		pev.nextthink = g_Engine.time + 1.0f;
	}
	
	CBaseEntity@ FindClosestEnemy( float fRadius )
	{
		CBaseEntity@ ent = null;
		CBaseEntity@ enemy = null;
		float iNearest = fRadius;

		do
		{
			@ent = g_EntityFuncs.FindEntityInSphere( ent, self.pev.origin,
				fRadius, "*", "classname" ); 
			
			if ( ent is null || !ent.IsAlive() )
				continue;
	
			if ( ent.pev.classname == "squadmaker" )
				continue;
	
			if ( ent.entindex() == self.entindex() )
				continue;
				
			if ( ent.edict() is pev.owner )
				continue;
				
			int rel = self.IRelationship(ent);
			if ( rel == R_AL || rel == R_NO )
				continue;
	
			float iDist = ( ent.pev.origin - self.pev.origin ).Length();
			if ( iDist < iNearest )
			{
				iNearest = iDist;
				@enemy = ent;
			}
		}
		while ( ent !is null );
		
		if ( enemy !is null )	
			g_Game.AlertMessage( at_console, "new enemy %1, relationship %2\n", enemy.GetClassname(), self.IRelationship(enemy) );

		return enemy;
	}
	
}

void RegisterDMPenguin()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "monster_penguin", "monster_penguin" );
	g_DMEntityList.insertLast("monster_penguin");
}