/***
	Made by Dr.Abc
***/

int g_TiemLeft,m_iTeam1,m_iTeam2,flDamage,m_iScoreTeam1,m_iScoreTeam2,g_MapMaxScore;
float format_float;
uint8 uint_PlayerTeam = 3,iEndTime,WarnTime;
bool m_bIsTDM,m_bIsStart,m_bIsScore,m_bIsWarining,m_bSendTime,m_bIsPVP;

class CMapData{ int8 MapMode; int MapTime; }
class CSkilldata{ string SkillName; float SkillValue; }
class CReadFiles
{
	CScheduledFunction@ HUDStart;
	dictionary g_PVPMapList,g_PVPSkillList;
	array<CSkilldata> g_SklListVals;

	void ReadMaps() 
	{
		CMapData data;
		File@ file = g_FileSystem.OpenFile(g_PVPMapFile, OpenFile::READ);
		if (file !is null && file.IsOpen()) 
		{
			while(!file.EOFReached()) 
			{
				string sLine;
				file.ReadLine(sLine);
				if (sLine.SubString(0,1) == "//" || sLine.IsEmpty())
					continue;

				array<string> parseds = sLine.Split(" ");
				if (parseds.length() < 3)
					continue;
			
				data.MapMode = atoi(parseds[1]);
				data.MapTime = atoi(parseds[2]);
				g_PVPMapList[parseds[0].ToLowercase()] = data;
			}
			file.Close();
		}
	}

	void ReadSkills() 
	{
		CSkilldata data;
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
				
				data.SkillName = parsed[0];
				data.SkillValue = atof(parsed[1]);
				g_SklListVals.insertLast( data );
			}
			file.Close();
		}
	}
	
	void ApplySkills()
	{
		for (uint i = 0; i < g_SklListVals.length(); ++i) 
		{
			const CSkilldata@ data = cast<CSkilldata@>(g_SklListVals[i]);
			g_DMUtility.CServerCommand( data.SkillName, data.SkillValue );
		}
	}
	
	void Resetvariable()
	{
		format_float = g_WaitingTime;
		m_bIsTDM = m_bIsStart = m_bIsScore = m_bIsWarining = m_bIsPVP = false;
		m_bSendTime = true;
		m_iTeam1 = m_iTeam2 = m_iScoreTeam1 = m_iScoreTeam2 = 0;
		iEndTime = WarnTime = 0;
		uint_PlayerTeam = 3;
		g_Scheduler.ClearTimerList();
		g_Hooks.RemoveHook(Hooks::Player::ClientConnected, @ClientConnected);
		g_Hooks.RemoveHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
		g_Hooks.RemoveHook(Hooks::Player::ClientSay, @ClientSay);
		g_Hooks.RemoveHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
		g_Hooks.RemoveHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
		g_Hooks.RemoveHook(Hooks::Player::PlayerSpawn, @PlayerSpawn);
		g_Hooks.RemoveHook(Hooks::Player::ClientSay, @ClientSay);
	}
	
	void deleteAll()
	{
		g_PVPMapList.deleteAll();
		g_SklListVals = {};
	}
	
	void PluginInit()
	{
		deleteAll();
		ReadMaps();
		ReadSkills();
	}
	
	bool IsPVP()
	{
		string szMapName = string(g_Engine.mapname).ToLowercase();
		if(g_PVPMapList.exists(szMapName))
		{
			g_Hooks.RegisterHook(Hooks::Player::ClientConnected, @ClientConnected);
			g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @ClientPutInServer);
			g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage);
			g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @PlayerSpawn);
			g_CustomEntityFuncs.RegisterCustomEntity( "info_ctfspawn", "info_ctfspawn" );
			g_CustomEntityFuncs.RegisterCustomEntity( "item_dmweaponpack", "item_dmweaponpack" );
			g_DMEntityList.insertLast("info_ctfspawn");
			g_DMEntityList.insertLast("item_dmweaponpack");
			
			@HUDStart = g_Scheduler.SetInterval( "RefreshHUD", 1, g_Scheduler.REPEAT_INFINITE_TIMES );
			
			g_SoundSystem.PrecacheSound("vox/warning.wav");
			g_SoundSystem.PrecacheSound("common/bodysplat.wav");
			
			g_ReadFiles.ApplySkills();
			
			m_bIsTDM = IsTDM();
			m_bIsScore = IsScore();
			m_bIsPVP = true;
			return true;
		}
		return false;
	}
	
	bool IsTDM()
	{
		string szMapName = string(g_Engine.mapname).ToLowercase();
		const CMapData@ data = cast<CMapData@>(g_PVPMapList[szMapName]);
		if ( data !is null && (data.MapMode == 1 || data.MapMode == 2) ) 
		{
			g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @ClientDisconnect);
			return true;
		}
		return false;
	}
	
	bool IsScore()
	{
		string szMapName = string(g_Engine.mapname).ToLowercase();
		const CMapData@ data = cast<CMapData@>(g_PVPMapList[szMapName]);
		
		if(data is null)
			return false;
			
		if ( data.MapMode == 2 ) 
		{
			g_MapMaxScore = data.MapTime == 0 ? g_MaxScore : data.MapTime;
			g_Game.PrecacheModel("sprites/misc/hecu.spr");
			g_Game.PrecacheGeneric("sprites/misc/hecu.spr");
			g_Game.PrecacheModel("sprites/misc/lambda.spr");
			g_Game.PrecacheGeneric("sprites/misc/lambda.spr");
			g_SoundSystem.PrecacheSound("vox/victor.wav");
			return true;
		}
		else
		{
			g_TiemLeft = data.MapTime == 0 ? g_LeftTime : data.MapTime;
			return false;
		}
	}
}

CReadFiles g_ReadFiles;