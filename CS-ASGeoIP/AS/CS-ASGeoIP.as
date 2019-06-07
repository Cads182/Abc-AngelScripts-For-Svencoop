/***
	CS-AS联用 IP返回
*****/

namespace CIPAdderss
{
	const string JoinCast = "正在加入搅基";
	const string LeaveCast = "觉得一阵迷茫,离开这里去寻找他的人♂参";
	const string FileDir	= "scripts/plugins/store/IPOutput.txt";
	const string FileOut	= "scripts/plugins/store/IPInput.txt";
	dictionary GeoIPDataBase;
	void ReadIP()
	{
		File @pFile = g_FileSystem.OpenFile( FileDir , OpenFile::READ );
		if ( pFile !is null && pFile.IsOpen() )
		{
			string line;
			while ( !pFile.EOFReached() )
			{
				pFile.ReadLine( line );
				if ( line.IsEmpty() )
					continue;
				array<string>@ buff = line.Split( "," );				//分割
				CCIPData data; //实例化
				if(buff.length() > 0)
				{	
					data.Code = buff[1];
					data.Country = buff[2];
					data.Region = buff[3];
					data.City = buff[4];
					GeoIPDataBase[buff[0]] = data;
				}
			}
			pFile.Close();
		}
		else
			FormatLog("IP data No Read!");							//畜生，你中了甚么
	}
	
	void WriteMetaIP( string MetaIP ,string FilePath = FileOut )
	{
		File @pFile = g_FileSystem.OpenFile( FilePath , OpenFile::WRITE );
		if ( pFile !is null && pFile.IsOpen())
		{
			pFile.Write(MetaIP);	//写出元数据
			pFile.Close();	
		}
		else
			FormatLog("IP data No Write!");				//畜生，你中了甚么
	}

	void BroadIPAddress( string&in Name, string szID )
	{			
		CCIPData@ data = null;
		if(GeoIPDataBase.exists(szID))
			@ data = cast<CCIPData@>(GeoIPDataBase[szID]);
		else
			@ data = cast<CCIPData@>(GeoIPDataBase["Unkown"]);
		CIPAdderss::SayToAll("[New Player]玩家:" +Name+ "[" + data.Code + "]"+"来自["+ data.Country + "|" + data.Region + "|" + data.City + "]" + CIPAdderss::JoinCast + ".\n");	//来了
	}
	
	void CastLeave( CBasePlayer@ pPlayer )
	{
		CIPAdderss::SayToAll("[New Player]玩家:" +string(pPlayer.pev.netname)+ CIPAdderss::LeaveCast+".\n");		//走了
	}

	void SayToAll( string&in InPut )
	{
		//发送信息并记录日志
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, InPut + "\n" );
		g_Game.AlertMessage(at_logged, InPut + "\n");
	}

	void FormatLog(string&in InPut)
	{
		string szCurrentTime;
		DateTime time;
		time.Format(szCurrentTime, "%Y.%m.%d - %H:%M:%S" );
		g_Game.AlertMessage(at_logged, "==> [" + szCurrentTime + "] "+ InPut + ".\n");
	}
}

class CCIPData
{
	private string sz_Code;
	private string sz_Country;
	private string sz_Region;
	private string sz_City;

	string Code
	{
		get const{ return sz_Code;}
		set{ sz_Code = value;}
	}

	string Country
	{
		get const{ return sz_Country;}
		set{ sz_Country = value;}
	}

	string Region
	{
		get const{ return sz_Region;}
		set{ sz_Region = value;}
	}

	string City
	{
		get const{ return sz_City;}
		set{ sz_City = value;}
	}
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Dr.Abc");
	g_Module.ScriptInfo.SetContactInfo("Bruh.");
	
	CCIPData data;
	data.Code = "UNK";
	data.Country = "互联网";
	data.Region = "地球";
	data.City = "未知";
	CIPAdderss::GeoIPDataBase["Unkown"] = data;

	CIPAdderss::WriteMetaIP("",CIPAdderss::FileDir);

	//注册Time
	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
}

HookReturnCode ClientConnected( edict_t@ pEntity, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
	const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pEntity);
	CIPAdderss::WriteMetaIP(szSteamId + "," +szIPAddress);
	return HOOK_HANDLED;
}

HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer)
{
	CIPAdderss::ReadIP();
	const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
	CIPAdderss::BroadIPAddress(pPlayer.pev.netname, szSteamId );
	return HOOK_HANDLED;
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer )
{
	CIPAdderss::CastLeave(pPlayer);								//Call
	return HOOK_HANDLED;
}
