/***
	简易IP地址返回
	Dr.Abc
*****/

namespace CIPAdderss
{
	const string JoinCast = "正在加入搅基";
	const string LeaveCast = "觉得一阵迷茫,离开这里去寻找他的人♂参";
	const string FileDir	= "scripts/plugins/Configs/IPCountry.csv";
	const string FileCNDir	= "scripts/plugins/Configs/IPCountry_CN.csv";
	
	array<CIPData> g_IPData;											//14w行东西写进内存
	dictionary CNdata;
	class CIPData{ array<string> min, max; string code, country; }
	
	CClientCommand g_ShowIP("showipall", "显示每个人的位置", @showipall);	//调试内容
	dictionary Where;
	void showipall( const CCommand@ Argments )
	{
		CBasePlayer@ pGouGuangLi = g_ConCommandSystem.GetCurrentPlayer();
		if(g_PlayerFuncs.AdminLevel(pGouGuangLi) < ADMIN_YES)
			g_PlayerFuncs.SayText(pGouGuangLi, "哪来的屁民, Guna.\n");
		else
		{
			for (int i = 1; i <= g_Engine.maxClients; i++)
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
				if( pPlayer !is null && pPlayer.IsConnected())
				{
					const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
					if(Where.exists(szSteamId))
						g_IPAdderss.BroadIPAddress(string(pPlayer.pev.netname), string(Where[szSteamId]));
				}
			}
		}
	}
	
	//嵌套判断，你妈的，卡死了
	bool Isit(uint&in intIP , const CIPData@ data)
	{
		for ( uint i = 0; i <= data.min.length() - 1; ++i )
		{
			if( intIP > atoui(data.min[i]) && intIP < atoui(data.max[i]) )
				return true;
		}
		return false;
	}

	CIPData ConnectLocation(string&in IP)
	{
		CIPData bullshit;
		if( IP == "127.0.0.1")					//是主机
		{
			bullshit.code = "BOT";
			bullshit.country = "主机";
			return bullshit;
		}
		else if(IP == "192.168" + "*")			//是网吧
		{
			bullshit.code = "LAN";
			bullshit.country = "局域网";
			return bullshit;
		}
		else if(IP == "loopback")				//你竟然用客户端开服务器？！
		{
			bullshit.code = "HOST";
			bullshit.country = "狗服主";
			return bullshit;
		}
		
		//字符串IP转换为长整型
		array<string>@ ip = IP.Split( "." );
		uint intIP = atoi( ip[3] ) | atoi( ip[2] ) << 8 | atoi( ip[1] ) << 16 | atoi( ip[0] ) << 24;
		
		//搜寻IP是否存在
		for ( uint i = 0; i <= g_IPData.length() - 1; ++i )
		{
			const CIPData@ data = cast<CIPData@>(g_IPData[i]);
			if( Isit(intIP,data) )
				return data;					//打破循环，返回数据
		}
		
		//妈的，没有
		bullshit.code = "UKN";
		bullshit.country = "地球某处";
		return bullshit;						//狗屎
	}
	
	void ReadIP()
	{
		File @pFile = g_FileSystem.OpenFile( FileDir , OpenFile::READ );
		g_Game.AlertMessage(at_logged, "Loading IP database...\n");		//在读取啦！

		if ( pFile !is null && pFile.IsOpen() )
		{
			string line;
			CIPData data;												//定义一个数据
			while ( !pFile.EOFReached() )
			{
				pFile.ReadLine( line );
					
				if ( line.IsEmpty() )
					continue;
					
				array<string>@ buff = line.Split( "," );				//分割
				array<string>@ strmin =  buff[0].Split( "." );				//分割
				array<string>@ strmax =  buff[1].Split( "." );				//再分割
			
				//重复赋值
				data.min = strmin;		
				data.max = strmax;	
				data.code = buff[2];
				data.country = buff[3];
				g_IPData.insertLast(data);								//插入数组
			}
				
			pFile.Close();	
			g_Game.AlertMessage(at_logged, "IP database READED.\n");				//噫，我中了
			
			ReadCN();													//讲汉话
		}
		else
			g_Game.AlertMessage(at_logged, "IP database No READ.\n");				//畜生，你中了甚么
	}
	
	void ReadCN()
	{
		File @pFile = g_FileSystem.OpenFile( FileCNDir , OpenFile::READ );
		g_Game.AlertMessage(at_logged, "Loading CN Location database...\n");		//在读取啦！

		if ( pFile !is null && pFile.IsOpen() )
		{
			string line;
			while ( !pFile.EOFReached() )
			{
				pFile.ReadLine( line );
					
				if ( line.IsEmpty() )
					continue;
					
				array<string>@ buff = line.Split( "," );				//分割
				CNdata[buff[0]] = buff[1];
			}
				
			pFile.Close();	
			g_Game.AlertMessage(at_logged, "CN Location READED.\n");				//噫，我中了
		}
		else
			g_Game.AlertMessage(at_logged, "CN Location No READ.\n");				//畜生，你中了甚么
	}
	
	void SayToAll( string&in InPut )
	{
		//发送信息并记录日志
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, InPut + "\n" );
		g_Game.AlertMessage(at_logged, InPut + "\n");
	}
}

class CIPAdderss
{
	void PluginInIt()
	{
		CIPAdderss::g_IPData = {};		//清空数据
		CIPAdderss::CNdata.deleteAll();
		CIPAdderss::ReadIP();			//读取数据
	}
	
	void BroadIPAddress( string&in Name, string&in IP )
	{
		array<string>@ szIP = IP.Split( ':' );		//不要端口
			
		const CIPAdderss::CIPData data = CIPAdderss::ConnectLocation(szIP[0]);		//读取数据
		
		string Country;
		if(CIPAdderss::CNdata.exists(data.code))
			Country = string (CIPAdderss::CNdata[data.code]);
		else
			Country = data.country;
			
		CIPAdderss::SayToAll("[New Player]玩家:" +Name+ "[" + data.code + "]("+ szIP[0] + ")来自["+ Country + "]" + CIPAdderss::JoinCast + ".\n");	//来了
	}
	
	void CastLeave( CBasePlayer@ pPlayer )
	{
		CIPAdderss::SayToAll("[New Player]玩家:" +string(pPlayer.pev.netname)+ CIPAdderss::LeaveCast+".\n");		//走了
	}
}
CIPAdderss g_IPAdderss;	//定义变量

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Dr.Abc");
	g_Module.ScriptInfo.SetContactInfo("Bruh.");
	//注册Time
	g_Hooks.RegisterHook( Hooks::Player::ClientConnected, @ClientConnected );
	g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	//Call it
	g_IPAdderss.PluginInIt();
}

HookReturnCode ClientConnected( edict_t@ pEntity, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
	const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pEntity);
	CIPAdderss::Where[szSteamId] = szIPAddress;
	
	g_IPAdderss.BroadIPAddress(szPlayerName, szIPAddress);		//Call
	return HOOK_HANDLED;
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer )
{
	g_IPAdderss.CastLeave(pPlayer);								//Call
	return HOOK_HANDLED;
}
