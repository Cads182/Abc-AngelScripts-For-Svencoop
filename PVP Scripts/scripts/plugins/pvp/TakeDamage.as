/***
	Made by Dr.Abc
***/
namespace TakeDamage
{
	const dictionary g_WeaponName = {{"crossbow_bolt", "Bolt"},
									{"monster_snark", "Snark"},
									{"dmhornet", "Hornet Gun"},
									{"weapon_dmpenguin", "Penguin Grenade"},
									{"monster_penguin", "Penguin Grenade"},
									{"dm_shockbeam", "Shock Rifle"},
									{"weapon_gauss", "Gauss"},
									{"weapon_dmgauss", "Gauss"},
									{"weapon_crowbar", "Crowbar"},
								    {"weapon_hlcrowbar", "Crowbar"},
									{"weapon_pipewrench", "Pipe Wrench"},
									{"weapon_grapple", "Grapple"},
									{"weapon_medkit", "WTF A medkit kill"},
									{"weapon_9mmhandgun", "Pistol"},
									{"weapon_dmglock", "Pistol"},
									{"weapon_357", "Python 357"},
									{"weapon_dm357", "Python 357"},
									{"weapon_eagle", "Desert Eagle"},
									{"weapon_uzi", "UZI"},
									{"weapon_9mmAR", "MP5"},
									{"weapon_hlmp5", "MP5"},
									{"weapon_shotgun", "Shotgun"},
									{"weapon_hlshotgun", "Shotgun"},
									{"weapon_crossbow", "Crossbow"},
									{"weapon_dmbow", "Crossbow"},
									{"weapon_m16", "M16"},
									{"weapon_rpg", "RPG"},
									{"weapon_egon", "Egon"},
									{"weapon_hornetgun", "Hornet Gun"},
									{"weapon_dmhornetgun", "Hornet Gun"},
									{"weapon_handgrenade", "Hand Grenade"},
									{"weapon_tripmine", "Trip Mine"},
									{"weapon_satchel", "Satchel"},
									{"weapon_snark", "Snark"},
									{"weapon_dmsnark", "Snark"},
									{"weapon_sniperrifle", "Sniper Rifle"},
									{"weapon_m249", "M249"},
									{"weapon_sporelauncher", "Spore Launcher"},
									{"weapon_displacer", "Displacer"},
									{"weapon_minigun", "Minigun"},
									{"weapon_shockrifle", "Shock Rifle"},
									{"weapon_dmshockrifle", "Shock Rifle"}};
	
	const float m_flRespwantime = g_EngineFuncs.CVarGetFloat("mp_respawndelay");
	
	bool TakeDamege(CBasePlayer@ pPlayer,CBaseEntity@ atkPlayer, CBaseEntity@ pInflictor, float flDamage, int bitsDamageType)
	{
		if(pPlayer is null)
			return false;
		float flBonus = ARMOR_BONUS;
		if ( !pPlayer.IsAlive() )
			return true;
			
		//g_Game.AlertMessage( at_console, "1." + flDamage + "\n" );
		
		pPlayer.m_lastDamageAmount = int(flDamage); 
		
		if (pPlayer.pev.armorvalue != 0 && !(bitsDamageType & (DMG_FALL | DMG_DROWN) != 0) )
		{
			float flNew = flDamage * ARMOR_RATIO;
			float flArmor = (flDamage - flNew) * flBonus;
			if (flArmor > pPlayer.pev.armorvalue)
			{
				flArmor = pPlayer.pev.armorvalue;
				flArmor *= (1.0f/flBonus);
				flNew = flDamage - flArmor;
				pPlayer.pev.armorvalue = 0;
			}
			else
				pPlayer.pev.armorvalue -= flArmor;
			flDamage = flNew;
		}
		float flTake = flDamage;
		
		//g_Game.AlertMessage( at_console, "2." + flTake + "\n" );
		
		if (pInflictor !is null)
			@pPlayer.pev.dmg_inflictor = pInflictor.pev.get_pContainingEntity();
		pPlayer.pev.dmg_take += flTake;
		pPlayer.pev.health -= flTake;
		if (pPlayer.pev.health <= 0)
		{
			if(atkPlayer !is null && atkPlayer.IsPlayer() && atkPlayer.IsNetClient())
			{
				if(g_Engine.time - pPlayer.m_fDeadTime > m_flRespwantime)
				{
					if( atkPlayer !is pPlayer )
					{		
						g_PlayerFuncs.ClientPrintAll(HUD_PRINTNOTIFY, string(atkPlayer.pev.netname) + " :: ["  + KillWeaponName(atkPlayer, pInflictor) + "] :: " + string(pPlayer.pev.netname) + "\n");
						atkPlayer.pev.frags++;
						if(g_ReadFiles.IsScore())
						{
							if(pPlayer.pev.targetname == "team1")
								++m_iScoreTeam2;
							if(pPlayer.pev.targetname == "team2")
								++m_iScoreTeam1;
							PVPHUD::RefreshScore();
						}
					}
					else
					{
						string suicidereason;
						int8 deathtype;
						if((bitsDamageType & DMG_BLAST != 0) || (bitsDamageType & DMG_MORTAR != 0))
							deathtype = Math.RandomLong(4,5);
						else
							deathtype = Math.RandomLong(0,3);
						switch(deathtype)
						{
							case 0 : suicidereason = string(atkPlayer.pev.netname) + " accidentally killed himself and ran away. \n";break;
							case 1 : suicidereason = string(atkPlayer.pev.netname) + " wanna meet with Karl Marx eagerly. \n";break;
							case 2 : suicidereason = "Life made " + string(atkPlayer.pev.netname) + " abandon all hope. \n";break;
							case 3 : suicidereason = string(atkPlayer.pev.netname) + " just click the mouse accidentally. ";break;
							case 4 : suicidereason = string(atkPlayer.pev.netname) + " ALLAHU AKBAR SALEEL SAWARIM NASHEED.\n";break;
							case 5 : suicidereason = string(atkPlayer.pev.netname) + " put IED on himself and detonated it.\n";break;
						}
						g_PlayerFuncs.ClientPrintAll(HUD_PRINTNOTIFY, suicidereason);
						--pPlayer.pev.frags;
					}
				}
			}
			else if(atkPlayer !is null && atkPlayer.IsMonster())
			{
				CBaseMonster@ pMonster = cast<CBaseMonster@>(atkPlayer);
				g_PlayerFuncs.ClientPrintAll(HUD_PRINTNOTIFY, MonsterKill( pPlayer , pMonster ) );
			}
			else
				g_PlayerFuncs.ClientPrintAll(HUD_PRINTNOTIFY, AccidentDeathReason( pPlayer , bitsDamageType ) );
			ApplyDeath( flTake ,pPlayer );
			return true;
		}
		return false;
	}
	
	void ApplyDeath( float&in flTake , CBasePlayer@ pPlayer )
	{
		if( flTake <= 200 )
			pPlayer.SetAnimation( PLAYER_DIE );
		else
		{	
			pPlayer.pev.rendermode = 1;
			pPlayer.pev.renderamt = 0;
			g_EntityFuncs.SpawnRandomGibs(pPlayer.pev, 1, 1);
			g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_AUTO, "common/bodysplat.wav", 1.0f, 1.0f);
		}
		pPlayer.pev.health = 0;
		pPlayer.pev.armorvalue = 0;
		pPlayer.pev.deadflag = DEAD_DYING;
		++pPlayer.m_iDeaths;
	}
	
	string MonsterKill(	CBasePlayer@ pPlayer , CBaseMonster@ pInflictor )
	{
		string szOwnername = "";
		if(pInflictor.pev.owner !is null)
			szOwnername = string(pInflictor.pev.owner.vars.netname) + "'s ";
		return szOwnername + string(pInflictor.m_FormattedName) + " just killed " + string(pPlayer.pev.classname) + ".\n";
	}
	
	string KillWeaponName(	CBaseEntity@ atkPlayer , CBaseEntity@ pInflictor )
	{
		CBasePlayer@ pPlayer = cast<CBasePlayer@>(atkPlayer);
		string Inflicetor = pInflictor.GetClassname();
		if( Inflicetor == "player" )
			Inflicetor = string(pPlayer.m_hActiveItem.GetEntity().pev.classname);
		return g_WeaponName.exists(Inflicetor) ? string(g_WeaponName[Inflicetor]) : Inflicetor;
	}

	string AccidentDeathReason( CBasePlayer@ pPlayer , int bitsDamageType )
	{
		string AccDeathReason;
		if(bitsDamageType & DMG_FALL != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " jump too high to fall. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " landing too fast. \n";break;
			}
		}
		else if(bitsDamageType & DMG_CRUSH != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " has been pressed into meatloaf. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " has been hydrauliced. \n";break;
			}
		}
		else if(bitsDamageType & DMG_BULLET != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = "There's a big hole in " + string(pPlayer.pev.netname) + "'s body. \n";break;
				case 1 : AccDeathReason = "The bullet did not hit the apple on the " + string(pPlayer.pev.netname) + "'s head. \n";break;
			}
		}
		else if(bitsDamageType & DMG_SLASH != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " has been cut into pieces. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " could by way of spam. \n";break;
			}
		}
		else if(bitsDamageType & DMG_BURN != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " has been crispy baked. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " has been cooked. \n";break;
			}
		}
		else if(bitsDamageType & DMG_FREEZE != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " has been stopped thinking. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " has been became a ice sucker. \n";break;
			}
		}
		else if(bitsDamageType & DMG_SHOCK != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " will never net play again. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " completed the treatment of Internet Addiction. \n";break;
			}
		}
		else if(bitsDamageType & DMG_SONIC != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + "'s viscera is singing. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " is torn. \n";break;
			}
		}
		else if(bitsDamageType & DMG_POISON != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " No antidotes purchased. \n";break;
				case 1 : AccDeathReason = "No priest treats " + string(pPlayer.pev.netname) + " for poisoning. \n";break;
			}
		}
		else if(bitsDamageType & DMG_RADIATION != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " Nuked. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " started the chain reaction. \n";break;
			}
		}
		else if(bitsDamageType & DMG_DROWN != 0)
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " is sleeping with fishes. \n";break;
				case 1 : AccDeathReason = string(pPlayer.pev.netname) + " won't breathing with his gills. \n";break;
			}
		}
		else
		{
			switch(Math.RandomLong (0,1))
			{
				case 0 : AccDeathReason = string(pPlayer.pev.netname) + " died mysteriously. \n";break;
				case 1 : AccDeathReason = "Strange forces killed " + string(pPlayer.pev.netname) + ". \n";break;
			}
		}
		return AccDeathReason;
	}
}