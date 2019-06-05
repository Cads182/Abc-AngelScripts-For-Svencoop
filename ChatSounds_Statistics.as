dictionary g_ChatStatsVals;
array<string> @g_ChatStatsKeys;

class CStatData { string Name; int time; }

void ChatStatistics() 
{	
	string szCurrentTime;
	DateTime time;
	time.Format(szCurrentTime, "%Y.%m.%d - %H:%M:%S" );
	
	string g_SoundStats = "scripts/plugins/store/ChatSoundsStats.txt";
	
	File@ file = g_FileSystem.OpenFile(g_SoundStats, OpenFile::READ);
	
	g_Game.AlertMessage(at_console, "Opening\n");
	
	if(file !is null && file.IsOpen())
	{
		while(!file.EOFReached()) 
		{
			string sLine;
			file.ReadLine(sLine);
			if (sLine.SubString(0,1) == "#" || sLine.IsEmpty())
			continue;

			array<string> parsed = sLine.Split(" ");
			if (parsed.length() < 3)
			continue;
		
			CStatData index;
			index.Name = parsed[0];
			index.time = atoi(parsed[1]);
			g_ChatStatsVals[parsed[0]] = index;
		}
		g_Game.AlertMessage(at_console, "Readed\n");
		
		@g_ChatStatsKeys = g_ChatStatsVals.getKeys();
		
		file.Close();
	}
	else
		g_Game.AlertMessage(at_console, "No Read\n");
	
	@ file = g_FileSystem.OpenFile(g_SoundStats, OpenFile::APPEND);
	if(file !is null && file.IsOpen())
	{
		for (uint i = 0; i < g_ChatStatsKeys.length(); ++i) 
		{
			CStatData@ data = cast<CStatData@>(g_ChatStatsVals[g_ChatStatsKeys[i]]);
			file.Write( ( i == 0 ? "#======="  + szCurrentTime + "=======\n" : "") + data.Name + " " + data.time + "\n");
		}
		
		g_Game.AlertMessage(at_console, "Written\n");
		
		file.Close();
		
		g_ChatStatsVals.deleteAll();
	}
	else
		g_Game.AlertMessage(at_console, "No Write\n");
}

class CChatStatistics
{

	void AddStatistics( string soundArg )
	{
		if(b_Stats)
		{
			if( g_ChatStatsVals.exists(soundArg) )
			{
				CStatData@ data = cast<CStatData@>(g_ChatStatsVals[soundArg]);
				data.Name = data.Name;
				data.time++;
				g_ChatStatsVals[soundArg] = data;
			}
			else
			{
				CStatData data;
				data.Name = soundArg;
				data.time = 1;
				g_ChatStatsVals[soundArg] = data;
			}
		}
	}
}

CChatStatistics g_ChatStatistics;