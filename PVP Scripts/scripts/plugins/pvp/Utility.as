/***				DM Utility - Dr.Abc
							 - Dr.Abc@foxmail.com ****/
							 
const int iDMDamageMulti = 1;
array<string> g_DMEntityList;
class CDMUtility
{
	void te_beamcylinder(Vector pos, float radius, uint frameRate=16 ,Vector color = Vector(255,255,255) , int height = 192)
	{
		NetworkMessage message(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
			message.WriteByte(TE_BEAMCYLINDER);
			message.WriteCoord(pos.x);
			message.WriteCoord(pos.y);
			message.WriteCoord(pos.z);
			message.WriteCoord(pos.x);
			message.WriteCoord(pos.y );
			message.WriteCoord(pos.z + radius + 48 );
			message.WriteShort(g_EngineFuncs.ModelIndex("sprites/laserbeam.spr"));
			message.WriteByte(0);
			message.WriteByte(frameRate);
			message.WriteByte(5);
			message.WriteByte(height);
			message.WriteByte(0);
			message.WriteByte(int(color.x));
			message.WriteByte(int(color.y));
			message.WriteByte(int(color.z));
			message.WriteByte(249);
			message.WriteByte(0);
		message.End();
	}
	
	void te_beampoints(Vector start, Vector end, Vector color = Vector(255, 0, 255), int Alpha = 255,
	string sprite="sprites/laserbeam.spr", uint8 frameStart=0, 
	uint8 frameRate=100, uint8 life=5, uint8 width=8, uint8 noise=1, uint8 scroll=32)
	{
		NetworkMessage message(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
			message.WriteByte(TE_BEAMPOINTS);
			message.WriteCoord(start.x);
			message.WriteCoord(start.y);
			message.WriteCoord(start.z);
			message.WriteCoord(end.x);
			message.WriteCoord(end.y);
			message.WriteCoord(end.z);
			message.WriteShort(g_EngineFuncs.ModelIndex(sprite));
			message.WriteByte(frameStart);
			message.WriteByte(frameRate);
			message.WriteByte(life);
			message.WriteByte(width);
			message.WriteByte(noise);
			message.WriteByte(int(color.x));
			message.WriteByte(int(color.y));
			message.WriteByte(int(color.z));
			message.WriteByte(Alpha); // actually brightness
			message.WriteByte(scroll);
		message.End();
	}
	
	void te_NVSight( CBasePlayer@ pPlayer, Vector vecSrc, Vector color = Vector(10, 10, 10), uint8 Radius = 96, uint8 life = 10, uint8 decay = 1 )
	{
		NetworkMessage message( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, pPlayer.edict() );
			message.WriteByte( TE_DLIGHT );
			message.WriteCoord( vecSrc.x );
			message.WriteCoord( vecSrc.y );
			message.WriteCoord( vecSrc.z );
			message.WriteByte( Radius );
			message.WriteByte( int(color.x) );
			message.WriteByte( int(color.y) );
			message.WriteByte( int(color.z) );
			message.WriteByte( life );
			message.WriteByte( decay );
		message.End();
	}

	void SayToAll( string&in InPut )
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[PvP Plugin]" + InPut + "\n" );
		g_Game.AlertMessage(at_logged, "[PvP Plugin]" + InPut + "\n");
	}
	
	void SayToYou( CBasePlayer@ pPlayer, string&in InPut )
	{
		g_PlayerFuncs.SayText( pPlayer, "[PvP Plugin]" + InPut + "\n");
		g_Game.AlertMessage(at_logged, "[PvP Plugin]" + InPut + "\n");
	}
	
	void DMTraceDamage( CBasePlayer@pPlayer, entvars_t@ pevInflictor, uint cShots, Vector vecSrc, Vector vecDirShooting, Vector vecSpread,float flDistance, Bullet iBulletType, int iDamage = 0 ,bool IsLight = true)
	{
		TraceResult tr;
		float x, y;
		
		if(IsLight)
			DMGunLight(vecSrc,18);

		for( uint i = 0; i < cShots ; i++ )
		{
			g_Utility.GetCircularGaussianSpread( x, y );
			Vector vecDir = vecDirShooting + x * vecSpread.x * g_Engine.v_right + y * vecSpread.y * g_Engine.v_up;
			Vector vecEnd	= vecSrc + vecDir * flDistance;
			
			g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );
			if ( tr.flFraction >= 1.0 )
			{
				g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, pPlayer.edict(), tr );
				if ( tr.flFraction < 1.0 )
				{
					// Calculate the point of intersection of the line (or hull) and the object we hit
					// This is and approximation of the "best" intersection
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					if ( pHit is null || pHit.IsBSPModel() )
						g_Utility.FindHullIntersection( vecSrc, tr, tr, VEC_DUCK_HULL_MIN, VEC_DUCK_HULL_MAX, pPlayer.edict() );
					vecEnd = tr.vecEndPos;	// This is the point on the actual surface (the hull could have hit space)
				}
			}

			int iTakeDamage = DMBulletDamage(iBulletType, iDamage, tr.iHitgroup);
			if( pPlayer.pev.waterlevel != WATERLEVEL_DRY)
					g_Utility.BubbleTrail(vecSrc, tr.vecEndPos, int(iTakeDamage/4));
			DMGunTracer(vecSrc,tr.vecEndPos);

				if( tr.pHit !is null )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					if( pHit is null || pHit.IsBSPModel() )
						g_WeaponFuncs.DecalGunshot( tr, iBulletType );
						
					if(pHit.IsAlive() && pHit.pev.takedamage != DAMAGE_NO)
					{
						g_WeaponFuncs.ClearMultiDamage();
						pHit.TraceAttack( pPlayer.pev, iTakeDamage, vecDirShooting, tr, iBulletType == BULLET_PLAYER_CROWBAR ? DMG_CLUB : DMG_BULLET );
						g_WeaponFuncs.ApplyMultiDamage( pPlayer.pev, pPlayer.pev );
						
						if( pHit.IsMonster() || pHit.IsPlayer())
							DMCreatBlood(pHit, iBulletType, tr.vecEndPos, pPlayer.pev.origin, pHit.BloodColor(),iTakeDamage);
					}
				}
		}
	}

	void DMGunTracer(Vector start, Vector end)
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
		m.WriteByte(TE_TRACER);
		m.WriteCoord(start.x);
		m.WriteCoord(start.y);
		m.WriteCoord(start.z);
		m.WriteCoord(end.x);
		m.WriteCoord(end.y);
		m.WriteCoord(end.z);
		m.End();
	}

	void DMGunLight(Vector pos, uint8 radius=32)
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
		m.WriteByte(TE_DLIGHT);
		m.WriteCoord(pos.x);
		m.WriteCoord(pos.y);
		m.WriteCoord(pos.z);
		m.WriteByte(radius);
		m.WriteByte(255);//r
		m.WriteByte(255);//g
		m.WriteByte(128);//b
		m.WriteByte(100);//life
		m.WriteByte(100);//decayRate
		m.End();
	}
	
	void DMCreatBlood( CBaseEntity@ pVictim, Bullet iBulletType, const Vector& in vecOrigin, const Vector& in vecDirection, int iColor, int iAmount )
	{
		if( iBulletType == BULLET_PLAYER_SNIPER )
			g_Utility.BloodStream(vecOrigin, vecDirection, iColor, iAmount);
		else
			g_Utility.BloodDrips(vecOrigin, g_Utility.RandomBloodVector(), iColor, iAmount);
		
		TraceResult tr;
		Vector vecEnd	= vecOrigin + vecDirection * 64;
		g_Utility.TraceLine( vecOrigin, vecDirection, dont_ignore_monsters, pVictim.edict(), tr );
		
		g_Utility.BloodDecalTrace(tr, iColor);
	}
	
	int DMBulletDamage( Bullet&in iBulletType, int&in iTakeDamage, int iHitgroup)
	{
		int iDamage = iTakeDamage;
		if( iBulletType == BULLET_NONE )
			iDamage = 0;
		else if ( iBulletType == BULLET_PLAYER_9MM )
			iDamage = int(g_EngineFuncs.CVarGetFloat( "sk_plr_9mm_bullet" ));
		else if ( iBulletType == BULLET_PLAYER_MP5 )
			iDamage = int(g_EngineFuncs.CVarGetFloat( "sk_plr_9mmAR_bullet" ));
		else if ( iBulletType == BULLET_PLAYER_SAW )
			iDamage = int(g_EngineFuncs.CVarGetFloat( "sk_556_bullet" ));
		else if ( iBulletType == BULLET_PLAYER_SNIPER )
			iDamage = int(g_EngineFuncs.CVarGetFloat( "sk_plr_762_bullet" ));
		else if ( iBulletType == BULLET_PLAYER_357 )
			iDamage = int(g_EngineFuncs.CVarGetFloat( "sk_plr_357_bullet" ));
		else if ( iBulletType == BULLET_PLAYER_EAGLE )
			iDamage = int(g_EngineFuncs.CVarGetFloat( "sk_plr_357_bullet" ));
		else if ( iBulletType == BULLET_PLAYER_BUCKSHOT )
			iDamage = int(g_EngineFuncs.CVarGetFloat( "sk_plr_buckshot" ));
		else if ( iBulletType == BULLET_PLAYER_CROWBAR )
			iDamage = int(g_EngineFuncs.CVarGetFloat( "sk_plr_crowbar" ));
		
		if( iHitgroup == HITGROUP_GENERIC )
			iDamage = iDamage * iDMDamageMulti;
		else if( iHitgroup == HITGROUP_HEAD )
			iDamage = iDamage * int(g_EngineFuncs.CVarGetFloat( "sk_player_head" ));
		else if( iHitgroup == HITGROUP_CHEST )
			iDamage = iDamage * int(g_EngineFuncs.CVarGetFloat( "sk_player_chest" ));
		else if( iHitgroup == HITGROUP_STOMACH )
			iDamage = iDamage * int(g_EngineFuncs.CVarGetFloat( "sk_player_stomach" ));
		else if( iHitgroup == HITGROUP_LEFTARM || iHitgroup == HITGROUP_RIGHTARM )
			iDamage = iDamage * int(g_EngineFuncs.CVarGetFloat( "sk_player_arm" ));
		else if( iHitgroup == HITGROUP_LEFTLEG || iHitgroup == HITGROUP_RIGHTLEG )
			iDamage = iDamage * int(g_EngineFuncs.CVarGetFloat( "sk_player_leg" ));
		
		//SayToAll(iDamage);
		return iDamage;
	}
	
	void DMBulletEjection( Vector vecOrigin, Vector vecOrgDrf, float flAngle ,int m_iShell, TE_BOUNCE soundtype ,Vector vecVelocity = Vector(0,0,0), uint8 uiShell = 1 )
	{
		for(uint8 i = 0; i < uiShell ; i++)
		{
			g_EntityFuncs.EjectBrass( vecOrigin + g_Engine.v_forward * vecOrgDrf[1] + g_Engine.v_right * vecOrgDrf[0] + g_Engine.v_up * vecOrgDrf[2], vecVelocity + g_Engine.v_right * Math.RandomLong(80,120) + g_Engine.v_forward * Math.RandomLong(-30,30)+ g_Engine.v_up * Math.RandomLong(60,90), flAngle, m_iShell, soundtype );
		}
	}
	
	void ResetWeapons(CBasePlayer@ pPlayer)
	{
		pPlayer.RemoveAllItems(false);
		pPlayer.SetItemPickupTimes(0);
		pPlayer.GiveNamedItem( IsClassMode ? "weapon_dmglock" : "weapon_9mmhandgun" , 0 , 34 );
		pPlayer.GiveNamedItem( IsClassMode ? "weapon_hlcrowbar" : "weapon_crowbar" , 0 , 0 );
		pPlayer.pev.health = 100;
		pPlayer.pev.armorvalue = 0;
		pPlayer.pev.frags = 0;
		pPlayer.m_iDeaths = 0;
	}
	
	void EntityUnregister() //反注册实体，为非PVP地图腾出实体位//Useless but more bug
	{
		for(uint i = 0; i < g_DMEntityList.length() - 1; i++ )
		{
			g_CustomEntityFuncs.UnRegisterCustomEntity(g_DMEntityList[i]);
		}
	}
	
	void CCommandApplyer(CBasePlayer@ pPlayer, const string Arg)
	{
		NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict());
			m.WriteString(Arg);
		m.End();
	}
	
	void CServerCommand( string&in szName, float&in flValue)
	{
		g_Game.AlertMessage( at_console, "[DM Plugin]Sever CVar has been changed: " + szName + " " + flValue + ".\n" );
		g_EngineFuncs.CVarSetFloat( szName, flValue );
	}
}

CDMUtility g_DMUtility;