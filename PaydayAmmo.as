const string strAmmoBox = "models/fun/payday_ammo.mdl";
const string strPickSound = "items/9mmclip1.wav" ;
const int DestoryTime = 45;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Dr.Abc");
	g_Module.ScriptInfo.SetContactInfo("Bruh");
}

void MapInit()
{
	g_Scheduler.ClearTimerList();
	
	MonsterCounter::IntIt();
	
	g_Game.PrecacheModel(strAmmoBox);
	g_SoundSystem.PrecacheSound(strPickSound);
	g_Game.PrecacheGeneric("sound/" + strPickSound);
	
	g_CustomEntityFuncs.RegisterCustomEntity("item_paydayammoclip", "item_paydayammoclip");
}

namespace MonsterCounter
{
	array<Vector> monsterPos;
	array<EHandle> monsterHandle;
	CScheduledFunction@ entityCheck;

	void IntIt()
	{
		for(uint i=0; i<uint(monsterHandle.length()); i++)
		{
			monsterHandle[i] = null;
			monsterPos[i] = Vector(0,0,0);
		}
		@entityCheck = g_Scheduler.SetInterval("timer_checkEntities", 1.2f, g_Scheduler.REPEAT_INFINITE_TIMES);
	}

	void timer_checkEntities()
	{
		CBaseEntity@ pMonster = null;
		while((@pMonster = g_EntityFuncs.FindEntityByClassname(pMonster, "monster_*")) !is null)
		{
			int relationship = pMonster.IRelationshipByClass(CLASS_PLAYER);
			if(pMonster.IsAlive() && relationship != R_AL && relationship != R_NO && checkClassname(pMonster) )
			{
				EHandle thisHandle = pMonster;
				if(!isInTheList(pMonster))
				{
					monsterHandle.insertLast(thisHandle);
					monsterPos.insertLast(pMonster.pev.origin + g_Engine.v_up * 16 );
				}
				else
				{
					monsterPos[findIndex(pMonster)] = pMonster.pev.origin + g_Engine.v_up * 16;
				}
			}
		}
		for(uint i=0; i<uint(monsterHandle.length()); i++)
		{
			CBaseEntity@ pEntity = monsterHandle[i];
			if(pEntity is null || !pEntity.IsAlive() && (pEntity.Classify() != CLASS_PLAYER))
			{
				for(int8 j=0; j< Math.RandomLong(1,3); j++)
				{
					CBaseEntity@ pAmmo = g_EntityFuncs.Create("item_paydayammoclip", monsterPos[i],Vector(Math.RandomLong (-25,25),Math.RandomLong (-25,25),Math.RandomLong (-25,25)), false);
					pAmmo.pev.velocity = g_Engine.v_forward * Math.RandomLong (-200,200) + g_Engine.v_up * Math.RandomLong (-200,200) + g_Engine.v_right * Math.RandomLong (-200,200);
					pAmmo.pev.angles = Math.VecToAngles( pAmmo.pev.velocity );
				}
				monsterHandle.removeAt(i);
				monsterPos.removeAt(i);
			}
		}
	}

	bool checkClassname( CBaseEntity@ m_Entity )
	{
		return m_Entity.pev.classname != "monster_generic" && 
			   m_Entity.pev.classname != "monster_rat" && 
			   m_Entity.pev.classname != "monster_satchel" && 
			   m_Entity.pev.classname != "monster_shockroach" && 
			   m_Entity.pev.classname != "monster_snark" && 
			   m_Entity.pev.classname != "monster_sqknest" && 
			   m_Entity.pev.classname != "monster_tripmine" && 
			   m_Entity.pev.classname != "monster_scientist_dead" && 
			   m_Entity.pev.classname != "monster_otis_dead" && 
			   m_Entity.pev.classname != "monster_leech" && 
			   m_Entity.pev.classname != "monster_human_grunt_ally_dead" && 
			   m_Entity.pev.classname != "monster_hgrunt_dead" && 
			   m_Entity.pev.classname != "monster_hevsuit_dead" && 
			   m_Entity.pev.classname != "monster_handgrenade" && 
			   m_Entity.pev.classname != "monster_gman" && 
			   m_Entity.pev.classname != "monster_furniture" && 
			   m_Entity.pev.classname != "monster_flyer_flock" && 
			   m_Entity.pev.classname != "monster_cockroach" && 
			   m_Entity.pev.classname != "monster_bloater" && 
			   m_Entity.pev.classname != "monster_osparey" && 
			   m_Entity.pev.classname != "monster_apache" && 
			   m_Entity.pev.classname != "monster_barney_dead" && 
			   m_Entity.pev.classname != "monster_babycrab" && 
			   m_Entity.pev.classname != "monster_headcrab" && 
			   m_Entity.pev.classname != "monster_barnacle" ;
	}
	
	int findIndex(CBaseEntity@ targetEntity)
	{
		for(uint i=0; i<uint(monsterHandle.length()); i++)
		{
			CBaseEntity@ pEntity = monsterHandle[i];
			if(pEntity !is null && targetEntity !is null && pEntity is targetEntity)
			{
				return i;
			}
		}
		return -1;
	}

	bool isInTheList(CBaseEntity@ targetEntity)
	{
		bool isIt = false;
		for(uint i=0; i<uint(monsterHandle.length()); i++)
		{
			CBaseEntity@ pEntity = monsterHandle[i];
			if(pEntity !is null && targetEntity !is null && pEntity is targetEntity)
			{
				isIt = true;
				break;
			}
		}
	return isIt;
	}
}

class item_paydayammoclip: ScriptBasePlayerAmmoEntity
{
	private float mLifeTime;
	private int int357Supply ,int556Supply , int9mmSupply , intARgrenadesSupply , intBoltsSupply , intRocketSupply , intShotgunSupply , intReSupply;
	void Spawn()
	{ 
		g_EntityFuncs.SetModel(self, strAmmoBox);
		this.mLifeTime = g_Engine.time + DestoryTime;
		g_EntityFuncs.SetSize(self.pev, Vector( -12, -12, -8 ), Vector( 12, 12, 8 ));
		
		RandomSupply();
		
		BaseClass.Spawn();
	}
	
	void RandomSupply()
	{
		int357Supply = RandomAmmoSupply( 2 , 4 ) ;
		int556Supply = RandomAmmoSupply( 10 , 15 );
		int9mmSupply = RandomAmmoSupply( 12 , 25 );
		intARgrenadesSupply = RandomAmmoSupply( 0 , 2 );
		intBoltsSupply = RandomAmmoSupply( 1 , 3 );
		intRocketSupply = RandomAmmoSupply( 0 , 2 );
		intShotgunSupply = RandomAmmoSupply( 1 , 5 );
		intReSupply = RandomAmmoSupply( 12 , 17 );
	}
	
	int RandomAmmoSupply( float min , float max )
	{
		float valReturn = Math.RandomFloat ( min , max ) ;
		return valReturn < 1 ? 0 : int(valReturn);
	}

	bool AddAmmo( CBaseEntity@ pOther ) 
	{ 
		if( pOther.IsPlayer() )
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
			CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>(pPlayer.m_hActiveItem.GetEntity());
			if( pWeapon.PrimaryAmmoIndex() != -1 )
			{
				if( pPlayer.m_rgAmmo(pWeapon.PrimaryAmmoIndex()) >= pWeapon.iMaxAmmo1())
				{
					return false;
				}
				else if(CheackWeaponName(pWeapon))
				{
					if( pPlayer.m_rgAmmo(pWeapon.PrimaryAmmoIndex()) + iFoundWeaponAmmoType(pWeapon) >=  pWeapon.iMaxAmmo1() )
						pPlayer.m_rgAmmo(pWeapon.PrimaryAmmoIndex() , pWeapon.iMaxAmmo1() );
					else
						pPlayer.m_rgAmmo(pWeapon.PrimaryAmmoIndex() , pPlayer.m_rgAmmo(pWeapon.PrimaryAmmoIndex()) + iFoundWeaponAmmoType(pWeapon) );
					if(pWeapon.SecondaryAmmoIndex() != -1 )
					{
						if( pPlayer.m_rgAmmo(pWeapon.SecondaryAmmoIndex()) < pWeapon.iMaxAmmo2())
						{
							if( pPlayer.m_rgAmmo(pWeapon.SecondaryAmmoIndex()) + iFoundWeaponSubAmmoType(pWeapon) >=  pWeapon.iMaxAmmo2() )
								pPlayer.m_rgAmmo(pWeapon.SecondaryAmmoIndex() , pWeapon.iMaxAmmo2() );
							else
								pPlayer.m_rgAmmo(pWeapon.SecondaryAmmoIndex() , pPlayer.m_rgAmmo(pWeapon.SecondaryAmmoIndex()) + iFoundWeaponSubAmmoType(pWeapon) );
						}
					}
					g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, strPickSound, 1, ATTN_NORM);
					g_EntityFuncs.Remove( self );
					return true;
				}
				return false;
			}
		}
		return false;
	}
	
	bool CheackWeaponName( CBasePlayerWeapon@ pWeapon )
	{
		return  pWeapon.pev.classname != "weapon_handgrenade" && 
				pWeapon.pev.classname != "weapon_sporelauncher" && 
				pWeapon.pev.classname != "weapon_hornetgun" && 
				pWeapon.pev.classname != "weapon_satchel" && 
				pWeapon.pev.classname != "weapon_tripmine" && 
				pWeapon.pev.classname != "weapon_shockrifle" && 
				pWeapon.pev.classname != "weapon_snark" && 
				pWeapon.pev.classname != "weapon_as_jetpack" && 
				pWeapon.pev.classname != "weapon_observer";		
	}
	
	void Think() 
	{
        pev.nextthink = g_Engine.time + DestoryTime + 1;
        if ((this.mLifeTime > 0) && (g_Engine.time  >= this.mLifeTime)) {
            g_EntityFuncs.Remove( self );
        }
		BaseClass.Think();
    }
	
	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float value )
	{
		if (pActivator.IsPlayer())
		{
			TraceResult tr;
			g_Utility.TraceLine( pev.origin, pActivator.pev.origin, dont_ignore_monsters, pActivator.edict(), tr );
			if (tr.flFraction >= 1.0f)
				self.AddAmmo(pActivator);
		}
	}
	
	int iFoundWeaponAmmoType(CBasePlayerWeapon@ pWeapon)
	{
		if(pWeapon.pszAmmo1() == "buckshot" )
			return intShotgunSupply ;
		else if (pWeapon.pszAmmo1() == "rockets" )
			return intRocketSupply ;
		else if (pWeapon.pszAmmo1() == "556" )
			return int556Supply ;
		else if (pWeapon.pszAmmo1() == "9mm" )
			return int9mmSupply ;
		else if (pWeapon.pszAmmo1() == "357" )
			return int357Supply ;
		else if (pWeapon.pszAmmo1() == "bolts" )
			return intBoltsSupply ;
		else if (pWeapon.pszAmmo1() == "ARgrenades" )
			return intARgrenadesSupply ;	
		else if(pWeapon.m_iClip != -1)
			return int( pWeapon.iMaxClip() * Math.RandomFloat(0.2 , 0.3) );
		return intReSupply ;
	}
	
	int iFoundWeaponSubAmmoType(CBasePlayerWeapon@ pWeapon)
	{
		if(pWeapon.pszAmmo2() == "buckshot" )
			return intShotgunSupply ;
		else if (pWeapon.pszAmmo2() == "rockets" )
			return intRocketSupply ;
		else if (pWeapon.pszAmmo2() == "556" )
			return int556Supply ;
		else if (pWeapon.pszAmmo2() == "9mm" )
			return int9mmSupply ;
		else if (pWeapon.pszAmmo2() == "357" )
			return int357Supply ;
		else if (pWeapon.pszAmmo2() == "bolts" )
			return intBoltsSupply ;
		else if (pWeapon.pszAmmo2() == "ARgrenades" )
			return intARgrenadesSupply ;
		else if(pWeapon.m_iClip2 != -1)
			return int( pWeapon.m_iClip2 * Math.RandomFloat(0.1 , 0.15) );
		return 1 ;
	}
}
