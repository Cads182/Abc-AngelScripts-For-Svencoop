/***
	Conversion by Dr.Abc
***/

const float flSkPlrGauss		= g_EngineFuncs.CVarGetFloat( "sk_plr_gauss" );


class weapon_dmgauss : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;

	private float m_flPlayAftershock;
	private bool m_bPrimaryFire;
	private uint m_iInAttack;
	private float m_flNextAmmoBurn;
	private float m_flAmmoStartCharge;
	private uint m_iSoundState;
	private float m_flStartCharge;
	private  bool bIsMultiplayer = true;

	float GetFullChargeTime()
	{
		return ( ( bIsMultiplayer ) ? 1.5f : 4.0f );
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_gauss.mdl" );
		self.m_iDefaultAmmo = 20;
		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/hlclassic/p_gauss.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/v_gauss.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_gauss.mdl" );
		g_Game.PrecacheModel( "sprites/hotglow.spr" );
		g_Game.PrecacheModel( "sprites/hotglow.spr" );
		g_Game.PrecacheModel( "sprites/smoke.spr" );
		g_SoundSystem.PrecacheSound( "weapons/electro4.wav" );
		g_SoundSystem.PrecacheSound( "weapons/electro5.wav" );
		g_SoundSystem.PrecacheSound( "weapons/electro6.wav" );
		g_SoundSystem.PrecacheSound( "ambience/pulsemachine.wav" );
		g_SoundSystem.PrecacheSound( "weapons/gauss2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
		g_Game.PrecacheGeneric( "sprites/dm_weapons/weapon_dmgauss.txt" );
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

	bool IsUseable()
	{
		return BaseClass.IsUseable() || m_iInAttack != 0;
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 100;
		info.iMaxAmmo2	= -1;
		info.iMaxClip 	= -1;
		info.iSlot 		= 3;
		info.iPosition 	= 4;
		info.iFlags 	= 0;
		info.iWeight 	= 20;
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
		m_flPlayAftershock = 0.0f;
		return self.DefaultDeploy( "models/hlclassic/v_gauss.mdl", "models/hlclassic/p_gauss.mdl", 8, "gauss" );
	}

	void Holster( int skipLocal = 0 )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav" );
		SetThink( null );
		BaseClass.Holster( skipLocal );
		self.SendWeaponAnim( 7 );
		m_iInAttack = 0;
	}

	void PrimaryAttack()
	{
		// don't fire underwater
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.15f;
			return;
		}

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) < 2 )
		{
			self.PlayEmptySound();
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
			return;
		}

		m_pPlayer.m_iWeaponVolume = 450;
		m_bPrimaryFire = true;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 2 );

		DmGaussStartFire( m_pPlayer );
		m_iInAttack = 0;
		self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
		self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.2f; // m_pPlayer.m_flNextAttack = g_Engine.time + 0.2f;
	}

	void SecondaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			if( m_iInAttack != 0 )
			{
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro4.wav", 1.0f, ATTN_NORM, 0, 80 + Math.RandomLong( 0,0x3f ) );
				self.SendWeaponAnim( 0 );
				m_iInAttack = 0;
			}
			else
			{
				self.PlayEmptySound();
			}
			self.m_flNextSecondaryAttack = self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;
			return;
		}
		
		if( m_iInAttack == 0 )
		{
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			{
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/357_cock1.wav", 0.8f, ATTN_NORM );
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = g_Engine.time + 0.5f; // m_pPlayer.m_flNextAttack = g_Engine.time + 0.5f;
				return;
			}

			m_bPrimaryFire = false;

			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );	// take one ammo just to start the spin
			g_SoundSystem.PlaySound( m_pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
			
			m_flNextAmmoBurn = g_Engine.time;

			// spin up
			m_pPlayer.m_iWeaponVolume = 256;
	
			self.SendWeaponAnim( 3 );
			m_iInAttack = 1;
			self.m_flTimeWeaponIdle = g_Engine.time + 0.5f;
			m_flStartCharge = g_Engine.time;
			m_flAmmoStartCharge = g_Engine.time + GetFullChargeTime();
			m_iSoundState = SND_CHANGE_PITCH;
		}
		else if( m_iInAttack == 1 )
		{
			if( self.m_flTimeWeaponIdle < g_Engine.time )
			{
				self.SendWeaponAnim( 4 );
				m_iInAttack = 2;
			}
		}
		else
		{
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			{
				DmGaussStartFire( m_pPlayer );
				m_iInAttack = 0;
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;
				return;
			}
			if( g_Engine.time >= m_flNextAmmoBurn && m_flNextAmmoBurn != 1000 )
			{
				m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
				m_flNextAmmoBurn = g_Engine.time + ( ( bIsMultiplayer ) ? 0.1f : 0.3f ); // 0.1 for HLDM
			}

			if( g_Engine.time >= m_flAmmoStartCharge )
			{
				m_flNextAmmoBurn = 1000;
			}

			float pitch = ( g_Engine.time - m_flStartCharge ) * ( 150 / GetFullChargeTime() ) + 100;

			if( pitch > 250 ) 
				pitch = 250;

			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav", 1.0f, ATTN_NORM, m_iSoundState, int( pitch ) );

			m_iSoundState = SND_CHANGE_PITCH;	// hack for going through level transitions

			m_pPlayer.m_iWeaponVolume = 256;
			if( m_flStartCharge < g_Engine.time - 10 )
			{
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro4.wav", 1.0f, ATTN_NORM, 0, 80 + Math.RandomLong( 0,0x3f ) );
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM,   "weapons/electro6.wav", 1.0f, ATTN_NORM, 0, 75 + Math.RandomLong( 0,0x3f ) );
		
				m_iInAttack = 0;
				self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 1.0f;

				m_pPlayer.TakeDamage( g_EntityFuncs.Instance( 0 ).pev, g_EntityFuncs.Instance( 0 ).pev, 50, DMG_SHOCK );
				g_PlayerFuncs.ScreenFade( m_pPlayer, Vector( 255,128,0 ), 2, 0.5, 128, FFADE_IN );

				self.SendWeaponAnim( 0 );
				return;
			}
		}
	}
	void DmGaussStartFire( CBasePlayer@ pPlayer )
	{
		float flDamage;

		Math.MakeVectors( pPlayer.pev.v_angle + pPlayer.pev.punchangle );
		Vector vecAiming = g_Engine.v_forward;
		Vector vecSrc = pPlayer.GetGunPosition();

		if( g_Engine.time - m_flStartCharge > GetFullChargeTime() )
		{
			flDamage = flSkPlrGauss * 10; //200
		}
		else
		{
			flDamage = ( flSkPlrGauss * 10 ) * ( ( g_Engine.time - m_flStartCharge ) / GetFullChargeTime() ); //200
		}

		if( m_bPrimaryFire )
		{
			flDamage = flSkPlrGauss;
		}
		else
		{
			pPlayer.pev.velocity = pPlayer.pev.velocity - g_Engine.v_forward * flDamage * 5;
		}

		pPlayer.SetAnimation( PLAYER_ATTACK1 );
		m_flPlayAftershock = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( pPlayer.random_seed, 0.3f, 0.8f );

		Fire( vecSrc, vecAiming, flDamage , pPlayer);
	}

	void Fire( Vector vecOrigSrc, Vector vecDir, float flDamage , CBasePlayer@ pPlayer )
	{
		pPlayer.m_iWeaponVolume = 100;
		g_SoundSystem.StopSound( pPlayer.edict(), CHAN_WEAPON, "ambience/pulsemachine.wav" );

		pPlayer.pev.punchangle.x = -2.0f;
		g_SoundSystem.PlaySound( pPlayer.edict(), CHAN_WEAPON, "weapons/gauss2.wav", 1, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		self.SendWeaponAnim( 6 );

		Vector vecSrc = vecOrigSrc;
		Vector vecDest = vecSrc + vecDir * 8192;

		TraceResult tr, beam_tr;

		edict_t@ pentIgnore = pPlayer.edict();

		float flMaxFrac = 1.0f;

		int	nTotal = 0;
		bool fHasPunched = false;
		bool fFirstBeam = true;
		int	nMaxHits = 10;

		while( flDamage > 10 && nMaxHits > 0 )
		{
			nMaxHits--;

			// g_Game.AlertMessage( at_console, "." );
			g_Utility.TraceLine( vecSrc, vecDest, dont_ignore_monsters, pentIgnore, tr );

			if( tr.fAllSolid != 0 )
				break;

			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( pEntity is null )
				break;

			if( fFirstBeam )
			{
				// Add muzzle flash to current weapon model
				pPlayer.pev.effects |= EF_MUZZLEFLASH;
				fFirstBeam = false;

				// https://github.com/SamVanheer/HLEnhanced/blob/master/game/client/ev_hldm.cpp#L816
				// https://github.com/SamVanheer/HLEnhanced/blob/09e3f1db51abcfebf43eac5d5fb3ccb7d3809196/shared/engine/client/r_efx.h#L804
				NetworkMessage beampoint( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, tr.vecEndPos );
					beampoint.WriteByte( TE_BEAMENTPOINT );
					beampoint.WriteShort( pPlayer.entindex() + 0x1000 ); // Entity target for the beam to follow
					beampoint.WriteCoord( tr.vecEndPos.x ); // End position of the beam X
					beampoint.WriteCoord( tr.vecEndPos.y ); // End position of the beam Y
					beampoint.WriteCoord( tr.vecEndPos.z ); // End position of the beam Z
					beampoint.WriteShort( g_EngineFuncs.ModelIndex( "sprites/smoke.spr" ) ); // Index of the sprite to use
					beampoint.WriteByte( 0 ); // Starting frame for the beam sprite
					beampoint.WriteByte( 0 ); // Frame rate of the beam sprite
					beampoint.WriteByte( 1 ); // How long to display the beam (0.1)  *10
					beampoint.WriteByte( m_bPrimaryFire ? 10 : 25 ); // Width of the beam (1.0, 2.5) * 100
					beampoint.WriteByte( 0 ); // Noise amplitude. (SC's is 0.1) * 100
					beampoint.WriteByte( 255 ); // Red color
					beampoint.WriteByte( 255 ); // Green color
					beampoint.WriteByte( m_bPrimaryFire ? 0 : 255 ); // Blue color
					beampoint.WriteByte( 200 ); // Brightness
					beampoint.WriteByte( 0 ); // Scroll rate of the beam sprite
				beampoint.End();

				nTotal += 26;
			}
			else // Beam reflection -R4to0
			{
				// https://github.com/SamVanheer/HLEnhanced/blob/master/game/client/ev_hldm.cpp#L834
				NetworkMessage beampoints( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
					beampoints.WriteByte( TE_BEAMPOINTS );
					beampoints.WriteCoord( vecSrc.x ); // Starting position of the beam X
					beampoints.WriteCoord( vecSrc.y ); // Starting position of the beam Y
					beampoints.WriteCoord( vecSrc.z ); // Starting position of the beam Z
					beampoints.WriteCoord( tr.vecEndPos.x ); // End position of the beam X
					beampoints.WriteCoord( tr.vecEndPos.y ); // End position of the beam Y
					beampoints.WriteCoord( tr.vecEndPos.z ); // End position of the beam Z
					beampoints.WriteShort( g_EngineFuncs.ModelIndex( "sprites/smoke.spr" ) ); // Index of the sprite to use
					beampoints.WriteByte( 0 ); // Starting frame for the beam sprite
					beampoints.WriteByte( 0 ); // Frame rate of the beam sprite
					beampoints.WriteByte( 1 ); // How long to display the beam (0.1) *10
					beampoints.WriteByte( m_bPrimaryFire ? 10 : 25 ); // Width of the beam (1.0, 2.5) * 100
					beampoints.WriteByte( 0 ); // Noise amplitude. (SC's is 0.1) * 10
					beampoints.WriteByte( 255 ); // Red color
					beampoints.WriteByte( 255 ); // Green color
					beampoints.WriteByte( m_bPrimaryFire ? 0 : 255 ); // Blue color
					beampoints.WriteByte( 200 ); // Brightness
					beampoints.WriteByte( 0 ); // Scroll rate of the beam sprite
				beampoints.End();
			}

			if( pEntity.pev.takedamage != DAMAGE_NO )
			{
				g_WeaponFuncs.ClearMultiDamage();
				pEntity.TraceAttack( pPlayer.pev, flDamage, vecDir, tr, DMG_BULLET );
				g_WeaponFuncs.ApplyMultiDamage( pPlayer.pev, pPlayer.pev );
			}
			if( pEntity.ReflectGauss() || pEntity.pev.solid == SOLID_BSP )
			{
				@pentIgnore = null;

				float n = -DotProduct( tr.vecPlaneNormal, vecDir );

				// Reflect point -R4to0
				if( n < 0.5 ) // 60 degrees
				{
					Vector r;

					r = 2.0 * tr.vecPlaneNormal * n + vecDir;
					flMaxFrac = flMaxFrac - tr.flFraction;
					vecDir = r;
					vecSrc = tr.vecEndPos + vecDir * 8;
					vecDest = vecSrc + vecDir * 8192;
					GaussGlow( tr, 0.2f, flDamage * n, flDamage * n * 0.5f * 0.1f ); // scale, alpha, life
					g_WeaponFuncs.RadiusDamage( tr.vecEndPos, self.pev, pPlayer.pev, flDamage * n, (flDamage * n) * 2.5f, CLASS_NONE, DMG_BLAST );
					GaussBall( tr, ( tr.vecEndPos + tr.vecPlaneNormal ), 3, 0.1, 100, 100 ); // quantity, life, amplitude, speed

					nTotal += 34;
					if( n == 0 ) n = 0.1f;
					flDamage = flDamage * ( 1 - n );
				}
				else
				{
					g_WeaponFuncs.DecalGunshot( tr, BULLET_MONSTER_12MM );
					GaussGlow( tr, 0.2f, 200.0f, 6.0f ); // scale, alpha, life
					nTotal += 13;

					// limit it to one hole punch
					if( fHasPunched )
						break;
					fHasPunched = true;

					// try punching through wall if secondary attack (primary is incapable of breaking through)
					if( !m_bPrimaryFire )
					{
						g_Utility.TraceLine( tr.vecEndPos + vecDir * 8, vecDest, dont_ignore_monsters, pentIgnore, beam_tr);
						if( beam_tr.fAllSolid == 0 )
						{
							// trace backwards to find exit point
							g_Utility.TraceLine( beam_tr.vecEndPos, tr.vecEndPos, dont_ignore_monsters, pentIgnore, beam_tr);

							n = ( beam_tr.vecEndPos - tr.vecEndPos ).Length();

							if( n < flDamage )
							{
								if( n == 0 ) n = 1;
								flDamage -= n;
								GaussBall( tr, ( tr.vecEndPos - vecDir ), 3, 0.1f, 100, 100 ); // quantity, life, amplitude, speed.
								nTotal += 21;
								float damage_radius = flDamage * ( ( bIsMultiplayer ) ? 1.75f : 2.5f );


								g_WeaponFuncs.RadiusDamage( beam_tr.vecEndPos + vecDir * 8, self.pev, pPlayer.pev, flDamage, damage_radius, CLASS_NONE, DMG_BLAST );


								GaussGlow( tr, 0.2f, 200.0f, 6.0f ); // scale, alpha, life
								GaussBall( beam_tr, ( beam_tr.vecEndPos - vecDir ), int( flDamage * 0.02f ), 0.1f, 200, 40 ); // quantity, life, amplitude, speed. Needs better calculator for quantity -R4to0

								nTotal += 53;

								vecSrc = beam_tr.vecEndPos + vecDir;
							}
						}
						else
						{
							flDamage = 0;
						}
					}
					else
					{
						if( m_bPrimaryFire )
						{
							GaussGlow( tr, 0.2f, 200.0f, 0.3f ); // scale, alpha, life
							GaussBall( tr, ( tr.vecEndPos + tr.vecPlaneNormal ), 8, 0.6f, 100, 200 ); // quantity, life, amplitude, speed
						}

						flDamage = 0;
					}
				}
			}
			else
			{
				vecSrc = tr.vecEndPos + vecDir;
				@pentIgnore = pEntity.edict();
			}
		}
	}
	void GaussGlow( TraceResult &in tr, float flScale, float flDamage, float flLife )
	{
		NetworkMessage glow( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			glow.WriteByte( TE_GLOWSPRITE );
			glow.WriteCoord( tr.vecEndPos.x ); // Ending position X
			glow.WriteCoord( tr.vecEndPos.y ); // Ending position Y
			glow.WriteCoord( tr.vecEndPos.z ); // Ending position Z
			glow.WriteShort( g_EngineFuncs.ModelIndex( "sprites/hotglow.spr" ) ); // sprite index
			glow.WriteByte( int( flLife * 10 ) ); // Time to wait before fading out
			glow.WriteByte( int( flScale ) ); // Sprite scale (0.2)
			glow.WriteByte( int( flDamage ) ); // alpha
		glow.End();
	}
	void GaussBall( TraceResult &in tr, Vector vecEnd, uint iCount, float flLife, uint iAmplitude, uint iSpeed )
	{
		NetworkMessage gaussball( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			gaussball.WriteByte( TE_SPRITETRAIL );
			gaussball.WriteCoord( tr.vecEndPos.x ); // Starting position X
			gaussball.WriteCoord( tr.vecEndPos.y ); // Starting position Y
			gaussball.WriteCoord( tr.vecEndPos.z ); // Starting position Z
			gaussball.WriteCoord( vecEnd.x ); // Ending position X
			gaussball.WriteCoord( vecEnd.y ); // Ending position Y
			gaussball.WriteCoord( vecEnd.z ); // Ending position Z
			gaussball.WriteShort( g_EngineFuncs.ModelIndex( "sprites/hotglow.spr" ) ); // sprite index
			gaussball.WriteByte( iCount ); // count
			gaussball.WriteByte( int( flLife * 100 ) ); // Time to wait before fading out 
			gaussball.WriteByte( Math.RandomLong( 1, 2 ) ); // Sprite scale
			gaussball.WriteByte( iSpeed/10 ); // Initial speed
			gaussball.WriteByte( iAmplitude/10 ); // Amount to randomize speed and direction
		gaussball.End();
	}
	


	void WeaponIdle()
	{
		self.ResetEmptySound();
		if(  m_flPlayAftershock > 0 && m_flPlayAftershock < g_Engine.time  )
		{
			switch( Math.RandomLong( 0,3 ) )
			{
			case 0:	g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro4.wav", Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
			case 1:	g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro5.wav", Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
			case 2:	g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "weapons/electro6.wav", Math.RandomFloat( 0.7f, 0.8f ), ATTN_NORM ); break;
			case 3:	break; // no sound
			}
			m_flPlayAftershock = 0.0f;
		}

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iInAttack != 0 )
		{
			DmGaussStartFire( m_pPlayer );
			m_iInAttack = 0;
			self.m_flTimeWeaponIdle = g_Engine.time + 2.0f;
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
				self.m_flNextPrimaryAttack = g_Engine.time + 0.5;
		}
		else
		{
			int iAnim;
			float flRand = Math.RandomFloat( 0, 1 );
			if( flRand <= 0.5f )
			{
				iAnim = 0;
				self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			}
			else if( flRand <= 0.75f )
			{
				iAnim = 1;
				self.m_flTimeWeaponIdle = g_Engine.time + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed, 10, 15 );
			}
			else
			{
				iAnim = 2;
				self.m_flTimeWeaponIdle = g_Engine.time + 3;
			}

			self.SendWeaponAnim( iAnim );
			return;
		}
	}
}

string GetName()
{
	return "weapon_dmgauss";
}

void RegisterDMGauss()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_dmgauss", GetName() );
	g_ItemRegistry.RegisterWeapon( GetName(), "dm_weapons", "uranium" );
}