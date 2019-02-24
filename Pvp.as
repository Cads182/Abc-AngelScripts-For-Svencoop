/*
	Inspired from w00tguy's Classic Mode Deluxe: https://forums.svencoop.com/showthread.php/45371-Classic-Mode-Deluxe
  
	PVP Enable
	Dr.Abc
	Dr.Abc@foxmail.com
*/

//Setting
const float g_WaitingTime = 30;						//TDM Waiting Time
const int g_WarningTime = 60;						//Warning Time
const int g_iBanlance = 2;						//The gap for autobalance (minimum is 2)
const int g_LeftTime = 600;						//Default Game time
const int g_MaxScore = 50;						//Defalut Max team score
const int HUD_CHAN_PVP = 14;						//HUD Channel
const string g_PVPMapFile = "scripts/plugins/PVPMapList.txt";		//file name
const string g_PVPSkillFile = "scripts/plugins/pvp_skl.txt";		//file name
const string MenuTitle = "Chose Your Team";			//Chose Your Team
const bool IsClassMode 	= true;						//Is classic Mode
const float ARMOR_RATIO = 0.2f; 					//80% Ratio
const float ARMOR_BONUS = 0.5f;						//150% Bounus

uint8 uint_PlayerTeam,iEndTime,WarnTime,Replacetime;
int g_TiemLeft,m_iTeam1,m_iTeam2,flDamage,m_iScoreTeam1,m_iScoreTeam2,g_MapMaxScore;
bool IsTDM,IsStart,IsScore,IsWarining;
float format_float,m_flFlagTakeTime;
CTextMenu@ TeamMenu = CTextMenu(TeamMenuRespond);
CScheduledFunction@ HUDStart;
dictionary g_PVPMapList,g_PVPMapTimeTable,g_PVPSkillList,g_PVPSkillValue;
array<string> @g_SklListVals;
HUDNumDisplayParams params,paramsT1,paramsT2;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Dr.Abc,w00tguy");
	g_Module.ScriptInfo.SetContactInfo("https://forums.svencoop.com/showthread.php/46283-Plugin-PVP-Enable");
	g_PVPMapList.deleteAll();
	g_PVPMapTimeTable.deleteAll();
	g_PVPSkillList.deleteAll();
	g_PVPSkillValue.deleteAll();
	TeamMenu.Register();
	TeamMenu.AddItem("Team Lambda", null);
	TeamMenu.AddItem("Team HECU", null);
	TeamMenu.SetTitle("[" + MenuTitle + "]\n");
	ReadMaps();
	ReadSkills();
}

void MapInit()
{
	format_float = g_WaitingTime;
	IsTDM = IsStart = IsScore = IsWarining = false;
	m_iTeam1 = m_iTeam2 = m_iScoreTeam1 = m_iScoreTeam2 = 0;
	uint_PlayerTeam = 0;
	g_Scheduler.ClearTimerList();
	g_Hooks.RemoveHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
	g_Hooks.RemoveHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
	g_Hooks.RemoveHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
	g_CustomEntityFuncs.UnRegisterCustomEntity( "weapon_hlmp5" );
	g_CustomEntityFuncs.UnRegisterCustomEntity( "info_ctfspawn" );
	
	if(g_PVPMapList.exists(g_Engine.mapname))
	{
		g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
		g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
		g_CustomEntityFuncs.RegisterCustomEntity( "info_ctfspawn", "info_ctfspawn" );
		
		for (uint i = 1; i < g_SklListVals.length()+1; ++i) 
		{
			g_EngineFuncs.CVarSetFloat( string(g_PVPSkillList[g_SklListVals[i-1]]), float(g_PVPSkillValue[g_SklListVals[i-1]]));
		}
		@HUDStart = g_Scheduler.SetInterval( "RefreshHUD", 1, g_Scheduler.REPEAT_INFINITE_TIMES );
		g_SoundSystem.PrecacheSound("vox/warning.wav");
		g_SoundSystem.PrecacheSound("common/bodysplat.wav");
		if(IsClassMode)
		{
			g_CustomEntityFuncs.RegisterCustomEntity( "weapon_hlmp5", "weapon_hlmp5" );
			g_ItemRegistry.RegisterWeapon( "weapon_hlmp5", "hl_weapons", "9mm", "ARgrenades" );
		}
		if (int8 (g_PVPMapList[g_Engine.mapname]) != 0 ) 
		{
			IsTDM = true;
			g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
			if (int8 (g_PVPMapList[g_Engine.mapname]) >= 2 ) 
			{
				IsScore = true;
				g_MapMaxScore = (!g_PVPMapTimeTable.exists(g_Engine.mapname) || int8 (g_PVPMapTimeTable[g_Engine.mapname]) == 0 ) ? g_MaxScore : int8 (g_PVPMapTimeTable[g_Engine.mapname]);
				g_Game.PrecacheModel("sprites/misc/hecu.spr");
				g_Game.PrecacheModel("sprites/misc/lambda.spr");
				g_SoundSystem.PrecacheSound("vox/victor.wav");
			}
		}
		else	
		{
			g_TiemLeft = (!g_PVPMapTimeTable.exists(g_Engine.mapname) || int8 (g_PVPMapTimeTable[g_Engine.mapname]) == 0 ) ? g_LeftTime : int8 (g_PVPMapTimeTable[g_Engine.mapname]);
		}
	}	
}

HookReturnCode PlayerTakeDamage(DamageInfo@ info)
{
		CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(info.pVictim.pev));
		CBasePlayer@ pAttacker = cast<CBasePlayer@>(g_EntityFuncs.Instance(info.pAttacker.pev));
		CBaseEntity@ pInflictor = cast<CBaseEntity@>(g_EntityFuncs.Instance(info.pInflictor.pev));
		if (pPlayer !is null && pAttacker !is null && pInflictor!is null && ((pPlayer.Classify() == pAttacker.Classify())))
		{
			if( pPlayer !is pAttacker )
			{
				return HOOK_CONTINUE;
			}
		}
		TakeDamege(pPlayer,pAttacker,pInflictor,info.flDamage,info.bitsDamageType);
		info.flDamage = 0;
		return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer)
{
	pPlayer.pev.targetname = "normalplayer";
	pPlayer.pev.solid	   = SOLID_BBOX;
	pPlayer.KeyValue("classify", 0 );
	if(!IsTDM)
	{
		++uint_PlayerTeam;
		pPlayer.KeyValue("classify", uint_PlayerTeam );
		return HOOK_HANDLED;
	}
	return HOOK_HANDLED;
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer )
{
	if(pPlayer.pev.targetname == "team1")
	{
		--m_iTeam1;
	}
	if(pPlayer.pev.targetname == "team2")
	{
		--m_iTeam2;
	}
	return HOOK_HANDLED;
}

void TeamMenuRespond(CTextMenu@ mMenu, CBasePlayer@ pPlayer, int iPage, const CTextMenuItem@ mItem)
{
	if(mItem !is null)
	{
		if(mItem.m_szName == "Team Lambda")
		{
			if(m_iTeam1 - m_iTeam2 >= g_iBanlance)
			{
				g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sorry, But there are too many people in this team.\n");
				TeamMenu.Open(0, 0, pPlayer);
			}
			else
			{
				AddToTeam1(pPlayer);
			}
		}
		if(mItem.m_szName == "Team HECU")
		{
			if(m_iTeam2 - m_iTeam1 >= g_iBanlance)
			{
				g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Sorry, But there are too many people in this team.\n");
				TeamMenu.Open(0, 0, pPlayer);
			}
			else
			{
				AddToTeam2(pPlayer);
			}
		}
	}
}

void AddToTeam1(CBasePlayer@ pPlayer)
{
	if(pPlayer.pev.targetname == "team1")
	{
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You're already in the team Lambda!\n");
		return;
	}
	else if(pPlayer.pev.targetname == "team2")
	{
		--m_iTeam2;
	}
	pPlayer.KeyValue("classify", 5 );
	pPlayer.pev.targetname = "team1";
	++m_iTeam1;
	ResetWeapons(pPlayer);
	string StrpModel;
	switch (Math.RandomLong(0,7))
	{
		case 0 :StrpModel = "gordon";break;
		case 1 :StrpModel = "helmet";break;
		case 2 :StrpModel = "gina";break;
		case 3 :StrpModel = "colette";break;
		case 4 :StrpModel = "hevscientist";break;
		case 5 :StrpModel = "hevscientist2";break;
		case 6 :StrpModel = "hevscientist3";break;
		case 7 :StrpModel = "hevbarney";break;
	}
	ModelChanger(pPlayer,StrpModel);
	g_PlayerFuncs.RespawnPlayer(pPlayer,true,true);
	g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "You joined the Team Lambda.\n");
}

void AddToTeam2(CBasePlayer@ pPlayer)
{
	if(pPlayer.pev.targetname == "team2")
	{
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You're already in the team H.E.C.U!\n");
		return;
	}
	else if(pPlayer.pev.targetname == "team1")
	{
		--m_iTeam1;
	}
	pPlayer.KeyValue("classify", 6 );
	pPlayer.pev.targetname = "team2";
	++m_iTeam2;
	ResetWeapons(pPlayer);
	string StrpModel;
	switch (Math.RandomLong(0,7))
	{
		case 0 :StrpModel = "OP4_Robot";break;
		case 1 :StrpModel = "OP4_Sniper";break;
		case 2 :StrpModel = "OP4_Torch2";break;
		case 3 :StrpModel = "OP4_Medic";break;
		case 4 :StrpModel = "OP4_Shotgun";break;
		case 5 :StrpModel = "OP4_Tower";break;
		case 6 :StrpModel = "OP4_Grunt";break;
		case 7 :StrpModel = "OP4_Shephard";break;
	}
	ModelChanger(pPlayer,StrpModel);
	g_PlayerFuncs.RespawnPlayer(pPlayer,true,true);
	g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "You joined the Team H.E.C.U.\n");
}

void ResetWeapons(CBasePlayer@ pPlayer)
{
	pPlayer.RemoveAllItems(false);
	pPlayer.GiveNamedItem("weapon_9mmhandgun" , 0 , 34 );
	pPlayer.GiveNamedItem("weapon_crowbar" , 0 , 0 );
}

void ModelChanger(CBasePlayer@ pPlayer,string Arg)
{
	NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict());
		m.WriteString("setinfo model " + Arg);
	m.End();
}
/*给地图触发用的*/
void CTFTeam1Score( CBaseEntity@ pActivator, CBaseEntity@ pCaller,USE_TYPE useType, float flValue )
{
	++m_iScoreTeam1;
	RefreshScore();
}
/*给地图触发用的*/
void CTFTeam2Score( CBaseEntity@ pActivator, CBaseEntity@ pCaller,USE_TYPE useType, float flValue )
{
	++m_iScoreTeam2;
	RefreshScore();
}

void ReadMaps() 
{
	File@ file = g_FileSystem.OpenFile(g_PVPMapFile, OpenFile::READ);
	if (file !is null && file.IsOpen()) 
	{
		while(!file.EOFReached()) 
		{
			string sLine;
			file.ReadLine(sLine);
			if (sLine.SubString(0,1) == "//" || sLine.IsEmpty())
			continue;

			array<string> parsed = sLine.Split(" ");
			if (parsed.length() < 3)
			continue;

		g_PVPMapList[parsed[0]] = atoi(parsed[1]);
		g_PVPMapTimeTable[parsed[0]] = atoi(parsed[2]);
		}
	file.Close();
	}
}

void ReadSkills() 
{
	File@ file = g_FileSystem.OpenFile(g_PVPSkillFile, OpenFile::READ);
	if (file !is null && file.IsOpen()) 
	{
		while(!file.EOFReached()) 
		{
			string sLine;
			file.ReadLine(sLine);
			if (sLine.SubString(0,1) == "//" || sLine.IsEmpty())
				continue;

			array<string> parsed = sLine.Split(" ");
			if (parsed.length() < 2)
				continue;
			g_PVPSkillList[parsed[0]] = parsed[0];
			g_PVPSkillValue[parsed[0]] = atoi(parsed[1]);
		}
	file.Close();
	@g_SklListVals = g_PVPSkillValue.getKeys();
	}
}
	
void SendTime(CBasePlayer@ pPlayer)
{
	if ( g_TiemLeft + g_WaitingTime - g_Engine.time <= g_WarningTime && WarnTime < 3 )
	{
		IsWarining = true;
		++WarnTime;
		if( g_Engine.maxClients != 0 )
		{
			CBasePlayer@ tPlayer = g_PlayerFuncs.FindPlayerByIndex(1);
			g_SoundSystem.EmitSound( tPlayer.edict(), CHAN_AUTO, "vox/warning.wav", 1.0, ATTN_NONE );
		}
	}
	if(g_TiemLeft + g_WaitingTime - g_Engine.time <= 0)
	{
		EndGame();
	}	
		
	params.channel = HUD_CHAN_PVP;
	params.flags = HUD_ELEM_DEFAULT_ALPHA | HUD_TIME_MINUTES | HUD_TIME_SECONDS | HUD_ELEM_SCR_CENTER_X | HUD_TIME_COUNT_DOWN;
	if(IsWarining)
	{
		params.flags +=  HUD_TIME_MILLISECONDS ;
	}
	params.x = 0;
	params.y = 0.06;
	params.value = g_TiemLeft + g_WaitingTime - g_Engine.time;
	params.color1 = IsWarining ? RGBA_RED : RGBA_SVENCOOP;
	params.spritename = "stopwatch";
	g_PlayerFuncs.HudTimeDisplay( pPlayer, params );
}
	
void SendScore(CBasePlayer@ pPlayer)
{
	params.channel = HUD_CHAN_PVP;
	params.flags = HUD_ELEM_DEFAULT_ALPHA | HUD_ELEM_SCR_CENTER_X ;
	params.value = g_MapMaxScore;
	params.x = 0;
	params.y = paramsT1.y = paramsT2.y = 0.06;
	params.defdigits = paramsT1.defdigits = paramsT2.defdigits = 2;
	params.maxdigits = paramsT1.maxdigits = paramsT2.maxdigits = 3;
	params.color1 = IsWarining ? RGBA_RED : RGBA_SVENCOOP;

	paramsT1.channel = HUD_CHAN_PVP + 1;
	paramsT1.flags = HUD_ELEM_DEFAULT_ALPHA | HUD_NUM_SEPARATOR;
	paramsT1.x = 0.36;
	paramsT1.spritename = "misc/lambda.spr";
	paramsT1.value = m_iScoreTeam1;
	paramsT1.color1 = RGBA_ORANGE;

	paramsT2.channel = HUD_CHAN_PVP - 1;
	paramsT2.flags = HUD_ELEM_DEFAULT_ALPHA | HUD_NUM_RIGHT_ALIGN | HUD_NUM_SEPARATOR ;
	paramsT2.x = -0.36;
	paramsT2.spritename = "misc/hecu.spr";
	paramsT2.value = m_iScoreTeam2;
	paramsT2.color1 = RGBA_GREEN;
	
	g_PlayerFuncs.HudNumDisplay( pPlayer, params );
	g_PlayerFuncs.HudNumDisplay( pPlayer, paramsT1 );
	g_PlayerFuncs.HudNumDisplay( pPlayer, paramsT2 );
}

void EndGame()
{
	g_EngineFuncs.CVarSetFloat("mp_timelimit", 0.01);
}

void RefreshScore()
{
	for (int i = 1; i <= g_Engine.maxClients; i++)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if(pPlayer !is null && pPlayer.IsConnected())
		{
			SendScore( pPlayer );
		}
	}
}

void RefreshHUD()
{
	CBaseEntity@ abdSpwan = null;
	while((@abdSpwan = g_EntityFuncs.FindEntityByClassname(abdSpwan, "info_player_start")) !is null)
	{
		g_EntityFuncs.Remove(abdSpwan);
	}	

	if(IsClassMode)
	{
		CBaseEntity@ pEntity = null;
		while((@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "weapon_9mmAR")) !is null)
		{
			g_EntityFuncs.Create("weapon_hlmp5", pEntity.GetOrigin(), Vector(0, 0, 0), false);
			g_EntityFuncs.Remove(pEntity);
		}	
	}
	if(!IsStart )
	{
	int StartTimeLeft = int(format_float  - g_Engine.time);
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Game will start in " + StartTimeLeft + " seconds\n");
		if (format_float - g_Engine.time <= 0 )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Game Started.\n");
			g_PlayerFuncs.RespawnAllPlayers(true,true);
			IsStart = true;
			if(IsScore)
			{
				RefreshScore();
			}
		}
	}
	else
	{
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				if(pPlayer.pev.health <= 0 && g_Engine.time - pPlayer.m_fDeadTime > g_EngineFuncs.CVarGetFloat("mp_respawndelay"))
				{
					pPlayer.pev.health = 0;
					pPlayer.pev.armorvalue = 0;
					pPlayer.pev.deadflag = DEAD_DEAD;
				}
				if (!IsScore) 
				{
					SendTime( pPlayer );
				}
				else
				{
					CBasePlayer@ tPlayer = null;
					if( g_Engine.maxClients != 0 )
					{
						@tPlayer = g_PlayerFuncs.FindPlayerByIndex(1);
						if (g_MapMaxScore - (m_iScoreTeam1 | m_iScoreTeam2 ) <= g_MapMaxScore/10 && WarnTime < 3 )
						{
							++WarnTime;
							IsWarining = true;
							g_SoundSystem.EmitSound( tPlayer.edict(), CHAN_AUTO, "vox/warning.wav", 1.0, ATTN_NONE );
						}
						if( ( m_iScoreTeam1  >= g_MapMaxScore || m_iScoreTeam2  >= g_MapMaxScore ) && iEndTime < 1 )
						{
							g_SoundSystem.EmitSound( tPlayer.edict(), CHAN_AUTO, "vox/victor.wav", 1.0, ATTN_NONE );
						}
					}
					if(m_iScoreTeam1 >= g_MapMaxScore)
					{
						g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Team Lambda Win!\n");
						++iEndTime;
						g_Hooks.RemoveHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
					}
					else if (m_iScoreTeam2 >= g_MapMaxScore)
					{
						g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Team H.E.C.U Win!\n");
						++iEndTime;
						g_Hooks.RemoveHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
					}
					if( iEndTime >= 4 && iEndTime != 0 )
					{
						EndGame();
					}
				}
				if(IsTDM)
				{
					if( pPlayer.pev.targetname == "normalplayer" && pPlayer.IsAlive() )
					{
						g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Chose Your Team.\n");	
						TeamMenu.Open(0, 0, pPlayer);
					}
					if(pPlayer.FlashlightIsOn())
					{
						TeamMenu.Open(0, 0, pPlayer);
						pPlayer.FlashlightTurnOff();
						g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Chose Your Team.\n");
					}
					if(abs(m_iTeam1 - m_iTeam2) > g_iBanlance - 1)
					{
						if(pPlayer.pev.targetname == "team1")
						{
							AddToTeam2(pPlayer);
							g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You have been move to team 2 for balance.\n");
							g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string(pPlayer.pev.netname) + " have been move to team 2 for balance.\n");
						}
						else if(pPlayer.pev.targetname == "team2")
						{
							AddToTeam1(pPlayer);
							g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You have been move to team 1 for balance.\n");
							g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string(pPlayer.pev.netname) + " have been move to team 1 for balance.\n");
						}
					}
				}
			}
		}
	}
}

int TakeDamege(CBasePlayer@ pPlayer,CBasePlayer@ atkPlayer, CBaseEntity@ pInflictor, float flDamage, int bitsDamageType)
{
	float flBonus = ARMOR_BONUS;
	if ( !pPlayer.IsAlive() )
		return 0;
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
	float flTake = int(flDamage);
	if (pInflictor !is null)
		@pPlayer.pev.dmg_inflictor = pInflictor.pev.get_pContainingEntity();
	pPlayer.pev.dmg_take += flTake;
	pPlayer.pev.health -= flTake;
	if (pPlayer.pev.health <= 0)
	{
		if(atkPlayer !is null && atkPlayer.IsPlayer() && atkPlayer.IsNetClient())
		{
			if(g_Engine.time - pPlayer.m_fDeadTime > g_EngineFuncs.CVarGetFloat("mp_respawndelay"))
			{
					if( atkPlayer !is pPlayer )
					{
						g_PlayerFuncs.ClientPrintAll(HUD_PRINTNOTIFY, string(atkPlayer.pev.netname) + " :: "  + string(atkPlayer.m_hActiveItem.GetEntity().pev.classname) + " :: " + string(pPlayer.pev.netname) + "\n");
						atkPlayer.pev.frags++;
						if(IsScore)
						{
							if(pPlayer.pev.targetname == "team1")
							{
								++m_iScoreTeam2;
							}
							if(pPlayer.pev.targetname == "team2")
							{
								++m_iScoreTeam1;
							}
							RefreshScore();
						}
					}
					else
					{
						string suicidereason;
						int8 deathtype;
						if((bitsDamageType & DMG_BLAST != 0) || (bitsDamageType & DMG_MORTAR != 0))
						{
							deathtype = Math.RandomLong(4,5);
						}
						else
						{
							deathtype = Math.RandomLong(0,3);
						}
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
				if( bitsDamageType <= 200 )
				{
					pPlayer.SetAnimation( PLAYER_DIE );
				}
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
		}
		else
		{
			if(bitsDamageType & DMG_ALWAYSGIB != 0)
			{
				pPlayer.Killed(atkPlayer.pev, GIB_ALWAYS);
			}
			else if(bitsDamageType & DMG_NEVERGIB != 0)
			{
				pPlayer.Killed(atkPlayer.pev, GIB_NEVER);
			}
			else
			{
				pPlayer.Killed(atkPlayer.pev, GIB_NORMAL);
			}
		}
		return 0;
	}
	return 1;
}

class weapon_hlmp5 : ScriptBasePlayerWeaponEntity
{
	private CBasePlayer@ m_pPlayer = null;
	float m_flNextAnimTime;
	int m_iShell,m_iSecondaryAmmo;
	void Spawn()
	{
		if(IsClassMode)
			Precache();
		g_EntityFuncs.SetModel( self, "models/hlclassic/w_9mmAR.mdl" );
		self.m_iDefaultAmmo = 25;
		self.m_iSecondaryAmmoType = 0;
		self.FallInit();
	}
	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/hlclassic/v_9mmAR.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/w_9mmAR.mdl" );
		g_Game.PrecacheModel( "models/hlclassic/p_9mmAR.mdl" );
		m_iShell = g_Game.PrecacheModel( "models/shell.mdl" );
		g_Game.PrecacheModel( "models/grenade.mdl" );
		g_Game.PrecacheModel( "models/w_9mmARclip.mdl" );
		g_SoundSystem.PrecacheSound( "items/9mmclip1.wav" );              
		g_SoundSystem.PrecacheSound( "hlclassic/items/clipinsert1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/items/cliprelease1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/items/guncock1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks1.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/hks3.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/glauncher.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/glauncher2.wav" );
		g_SoundSystem.PrecacheSound( "hlclassic/weapons/357_cock1.wav" );
	}
	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= 250;
		info.iMaxAmmo2 	= 10;
		info.iMaxClip 	= 50;
		info.iSlot 		= 2;
		info.iPosition 	= 4;
		info.iFlags 	= 0;
		info.iWeight 	= 5;
		return true;
	}
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer( pPlayer ) )
			return false;
		@m_pPlayer = pPlayer;
		NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			message.WriteLong( self.m_iId );
		message.End();
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
		return self.DefaultDeploy( self.GetV_Model( "models/hlclassic/v_9mmAR.mdl" ), self.GetP_Model( "models/hlclassic/p_9mmAR.mdl" ), 4, "mp5" );
	}
	float WeaponTimeBase()
	{
		return g_Engine.time;
	}
	void PrimaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD ){
			self.PlayEmptySound( );
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;}
		if( self.m_iClip <= 0 ){
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;}
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		--self.m_iClip;
		switch ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 2 ) ){
			case 0: self.SendWeaponAnim( 5, 0, 0 ); break;
			case 1: self.SendWeaponAnim( 6, 0, 0 ); break;
			case 2: self.SendWeaponAnim( 7, 0, 0 ); break;}
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/hks1.wav", 1.0, ATTN_NORM, 0, 95 + Math.RandomLong( 0, 10 ) );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, VECTOR_CONE_6DEGREES, 8192, BULLET_PLAYER_MP5, 2 );
		if( self.m_iClip == 0 && m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
		m_pPlayer.pev.punchangle.x = Math.RandomLong( -2, 2 );
		self.m_flNextPrimaryAttack = self.m_flNextPrimaryAttack + 0.1;
		if( self.m_flNextPrimaryAttack < WeaponTimeBase() )
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.1;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
		TraceResult tr;
		float x, y;
		g_Utility.GetCircularGaussianSpread( x, y );
		Vector vecDir = vecAiming + x * VECTOR_CONE_6DEGREES.x * g_Engine.v_right + y * VECTOR_CONE_6DEGREES.y * g_Engine.v_up;
		Vector vecEnd	= vecSrc + vecDir * 4096;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );
		if( tr.flFraction < 1.0 ){
			if( tr.pHit !is null ){
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				if( pHit is null || pHit.IsBSPModel() )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_MP5 );}}
	}
	void SecondaryAttack()
	{
		if( m_pPlayer.pev.waterlevel == WATERLEVEL_HEAD ){
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = WeaponTimeBase() + 0.15;
			return;}
		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 ){
			self.PlayEmptySound();
			return;}
		m_pPlayer.m_iWeaponVolume = NORMAL_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.m_iExtraSoundTypes = bits_SOUND_DANGER;
		m_pPlayer.m_flStopExtraSoundTime = WeaponTimeBase() + 0.2;
		m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iSecondaryAmmoType ) - 1 );
		m_pPlayer.pev.punchangle.x = -10.0;
		self.SendWeaponAnim( 2 );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		if ( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed, 0, 1 ) != 0 )
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/glauncher.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		else
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, "hlclassic/weapons/glauncher2.wav", 0.8, ATTN_NORM, 0, PITCH_NORM );
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		if( ( m_pPlayer.pev.button & IN_DUCK ) != 0 )
			g_EntityFuncs.ShootContact( m_pPlayer.pev, m_pPlayer.pev.origin + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 800 );
		else
			g_EntityFuncs.ShootContact( m_pPlayer.pev, m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs * 0.5 + g_Engine.v_forward * 16 + g_Engine.v_right * 6, g_Engine.v_forward * 800 );
		self.m_flNextPrimaryAttack = WeaponTimeBase() + 1;
		self.m_flNextSecondaryAttack = WeaponTimeBase() + 1;
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 5;
		if( m_pPlayer.m_rgAmmo(self.m_iSecondaryAmmoType) <= 0 )
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
	}
	void Reload()
	{
		self.DefaultReload( 50, 3, 1.5, 0 );
		BaseClass.Reload();
	}
	void WeaponIdle()
	{
		self.ResetEmptySound();
		m_pPlayer.GetAutoaimVector( AUTOAIM_5DEGREES );
		if( self.m_flTimeWeaponIdle > WeaponTimeBase() )
			return;
		int iAnim;
		switch( g_PlayerFuncs.SharedRandomLong( m_pPlayer.random_seed,  0, 1 ) ){
			case 0:	iAnim = 0;break;
			case 1:iAnim = 1;break;
			default:iAnim = 1;break;}
		self.SendWeaponAnim( iAnim );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + g_PlayerFuncs.SharedRandomFloat( m_pPlayer.random_seed,  10, 15 );
	}
}

class info_ctfspawn : ScriptBaseEntity
{	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "team_no")
		{
			CBaseEntity@ pSpwan = g_EntityFuncs.Create("info_player_deathmatch", self.GetOrigin(), Vector(0, 0, 0), false);
			pSpwan.pev.spawnflags = 8;
			if(szValue == 2)
			{
				pSpwan.pev.message = "team2";
			}
			else if (szValue == 1)
			{
				pSpwan.pev.message = "team1";
			}
			CBaseEntity@ nSpwan = g_EntityFuncs.Create("info_player_deathmatch", self.GetOrigin(), Vector(0, 0, 0), false);
			nSpwan.pev.spawnflags = 8;
			nSpwan.pev.message = "normalplayer";
			
			g_EntityFuncs.Remove(self);
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
}