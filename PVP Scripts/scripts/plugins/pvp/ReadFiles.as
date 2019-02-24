/***
	Made by Dr.Abc
***/

int g_TiemLeft,m_iTeam1,m_iTeam2,flDamage,m_iScoreTeam1,m_iScoreTeam2,g_MapMaxScore;
float format_float;
uint8 uint_PlayerTeam,iEndTime,WarnTime;
bool m_bIsTDM,m_bIsStart,m_bIsScore,m_bIsWarining;

class CReadFiles
{
	CScheduledFunction@ HUDStart;
	dictionary g_PVPMapList,g_PVPMapTimeTable,g_PVPSkillList,g_PVPSkillValue;
	array<string> @g_SklListVals;
	
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

				array<string> parseds = sLine.Split(" ");
				if (parseds.length() < 3)
				continue;

			g_PVPMapList[parseds[0].ToLowercase()] = atoi(parseds[1]);
			g_PVPMapTimeTable[parseds[0].ToLowercase()] = atoi(parseds[2]);
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
	
	void ApplySkills()
	{
		for (uint i = 1; i < g_SklListVals.length()+1; ++i) 
		{
			g_EngineFuncs.CVarSetFloat( string(g_PVPSkillList[g_SklListVals[i-1]]), float(g_PVPSkillValue[g_SklListVals[i-1]]));
		}
	}
	
	void Resetvariable()
	{
		format_float = g_WaitingTime;
		m_bIsTDM = m_bIsStart = m_bIsScore = m_bIsWarining = false;
		m_iTeam1 = m_iTeam2 = m_iScoreTeam1 = m_iScoreTeam2 = 0;
		iEndTime = WarnTime = 0;
		uint_PlayerTeam = 0;
		g_Scheduler.ClearTimerList();
		g_Hooks.RemoveHook(Hooks::Player::ClientPutInServer, @PVPTeam::ClientPutInServer);
		g_Hooks.RemoveHook(Hooks::Player::ClientDisconnect, @PVPTeam::ClientDisconnect);
		g_Hooks.RemoveHook(Hooks::Player::PlayerTakeDamage, @TakeDamage::PlayerTakeDamage);
		g_CustomEntityFuncs.UnRegisterCustomEntity( "info_ctfspawn" );
	}
	
	void deleteAll()
	{
		g_PVPMapList.deleteAll();
		g_PVPMapTimeTable.deleteAll();
		g_PVPSkillList.deleteAll();
		g_PVPSkillValue.deleteAll();
	}
	
	bool IsPVP()
	{
		string lowcasemapname = string(g_Engine.mapname).ToLowercase();
		if(g_PVPMapList.exists(lowcasemapname))
		{
			g_Hooks.RegisterHook(Hooks::Player::ClientPutInServer, @PVPTeam::ClientPutInServer);
			g_Hooks.RegisterHook(Hooks::Player::PlayerTakeDamage, @TakeDamage::PlayerTakeDamage);
			g_CustomEntityFuncs.RegisterCustomEntity( "info_ctfspawn", "info_ctfspawn" );
			
			@HUDStart = g_Scheduler.SetInterval( "RefreshHUD", 1, g_Scheduler.REPEAT_INFINITE_TIMES );
			
			g_SoundSystem.PrecacheSound("vox/warning.wav");
			g_SoundSystem.PrecacheSound("common/bodysplat.wav");
			
			g_ReadFiles.ApplySkills();
			
			m_bIsTDM = IsTDM();
			m_bIsScore = IsScore();

			return true;
		}
		return false;
	}
	
	bool IsTDM()
	{
		string lowcasemapname = string(g_Engine.mapname).ToLowercase();
		if (int8 (g_PVPMapList[lowcasemapname]) == 1 || int8 (g_PVPMapList[lowcasemapname]) == 2 ) 
		{
			PVPTeam::TeamPluginInt();
			g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @PVPTeam::ClientDisconnect);
			return true;
		}
		return false;
	}
	
	bool IsScore()
	{
		string lowcasemapname = string(g_Engine.mapname).ToLowercase();
		if (int8 (g_PVPMapList[lowcasemapname]) == 2 ) 
		{
			g_MapMaxScore = (!g_PVPMapTimeTable.exists(g_Engine.mapname) || int8 (g_PVPMapTimeTable[g_Engine.mapname]) == 0 ) ? g_MaxScore : int8 (g_PVPMapTimeTable[g_Engine.mapname]);
			g_Game.PrecacheModel("sprites/misc/hecu.spr");
			g_Game.PrecacheModel("sprites/misc/lambda.spr");
			g_SoundSystem.PrecacheSound("vox/victor.wav");
			return true;
		}
		else
		{
			g_TiemLeft = (!g_PVPMapTimeTable.exists(g_Engine.mapname) || int8 (g_PVPMapTimeTable[g_Engine.mapname]) == 0 ) ? g_LeftTime : int8 (g_PVPMapTimeTable[g_Engine.mapname]);
			return false;
		}
	}
}

CReadFiles g_ReadFiles;