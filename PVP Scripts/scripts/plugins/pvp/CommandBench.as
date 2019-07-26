/***
PVP Command Bench
base on PVPCommand
Dr.Abc@foxmail.com
****/

funcdef void DMCCallback( const CCommand@ );

namespace CDMCommandBench
{
	dictionary g_CommandList;
	array<string> @g_CommandListKey;

	CClientCommand g_Onekeylist("dm_help", "List all Onekey", @ListCallback);

	void ListCallback(const CCommand@ Argments)
	{
		CBasePlayer@ pGouGuangLi = g_ConCommandSystem.GetCurrentPlayer();
		string printf;
		if(g_CommandListKey.length() == 0)
			printf = "Not any commands at all!";
		else
		{
			uint f = 0;
			g_PlayerFuncs.ClientPrint(pGouGuangLi, HUD_PRINTCONSOLE, "----AVAILABLE COMMAND-----------------------------------------\n");
			for(uint i = 0; i <= g_CommandListKey.length() - 1; i++ )
			{
				PVPCommand@ data = cast<PVPCommand@>(g_CommandList[g_CommandListKey[i]]);
				if(g_PlayerFuncs.AdminLevel(pGouGuangLi) < ADMIN_YES && data.Flag != 0)
					continue;
				else
				{
					printf = printf + "[."+data.Name+"] | "+ data.HelpInfo + " | " + data.Printf + ".\n";
					f++;
				}
				if( f % 2 == 0)
				{
					g_PlayerFuncs.ClientPrint(pGouGuangLi, HUD_PRINTCONSOLE, printf);
					printf = "";
				}
			}
			if( printf != "" )
				g_PlayerFuncs.ClientPrint(pGouGuangLi, HUD_PRINTCONSOLE, printf);
			g_PlayerFuncs.ClientPrint(pGouGuangLi, HUD_PRINTCONSOLE, "--------------------------------------------------------------\n");
		}
	}

	class PVPCommand
	{
		private string szName = "";
		private string szHelpInfo = "";
		private string szPrintf = "";
		private uint8 usFlag = 0;
		private CClientCommand@ c_ClientCom;
		private DMCCallback@ c_CallBack;
		
		string Name
		{
			get const{ return szName;}
			set{ szName = value;}
		}
			
		string HelpInfo
		{
			get const{ return szHelpInfo;}
			set { szHelpInfo = value; }
		}
		
		string Printf
		{
			get const{ return szPrintf;}
			set { szPrintf = value; }
		}
		
		uint8 Flag
		{
			get const{ return usFlag;}
			set { usFlag = value; }
		}
			
		CClientCommand@ ClientCommand
		{
			get{ return c_ClientCom;}
			set{ @c_ClientCom = value;}
		}
		
		DMCCallback@ ClientCallback
		{
			get{ return c_CallBack;}
			set{ @c_CallBack = value;}
		}
	}

	void RegistCommand( string szName, string szHelpInfo, string szPrintf, DMCCallback@ pCallback, int iFlags = 0 )
	{
		PVPCommand command;
		command.Name = szName;
		command.HelpInfo = szHelpInfo;
		command.Printf = szPrintf;
		command.Flag = iFlags;
		@command.ClientCallback = pCallback;
		@command.ClientCommand = CClientCommand( szName, szHelpInfo, @HandelCallback, iFlags);
		g_CommandList[szName] = command;
	}

	PVPCommand GetCommand( string szName )
	{
		if(g_CommandList.exists(szName))
		{
			PVPCommand@ data = cast<PVPCommand@>(g_CommandList[szName]);
			//ErrorPrintf("Founded.");
			return data;
		}
		else
		{
			ErrorPrintf("Not Found Command In list.");
			PVPCommand data;
			return data;
		}
	}

	void HandelCallback( const CCommand@ Argments )
	{
		string ArgName = Argments[0].SubString(1,Argments[0].Length());
		string ArgVal = Argments[1];
		
		PVPCommand@ data = GetCommand(ArgName);
		
		if(data is null)
		{
			ErrorPrintf("Null Access.");
			return;
		}
		
		if( data.ClientCallback is null )
		{
			ErrorPrintf("Null Callback.");
			return;
		}
		
		CBasePlayer@ pGouGuangLi = g_ConCommandSystem.GetCurrentPlayer();
		if(g_PlayerFuncs.AdminLevel(pGouGuangLi) < ADMIN_YES)
		{
			if( data.Flag != 0)
			{
				g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "You don't have access to that command, peasent.\n");
			}
		}
		
		if( Argments[1] == 1 )
		{
			g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "Opened.\n");
		}
		else if (Argments[1] == 0)
		{
			g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "Closed.\n");
		}
		else if ( Argments[1] == "")
		{
			g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "Toggled.\n");
		}
		else
		{
			g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "Dat not right u fool.\n");
			return;
		}
		DMCCallback@ Callback = @data.ClientCallback;
		Callback( Argments);
	}

	void ErrorPrintf( string&in  szError )
	{
		g_Game.AlertMessage(at_error, "[OneKey Plugin]" + szError + "\n");
	}
}

class CDMCommandBench
{
	void CommandPluginInit()
	{
		CDMCommandBench::g_CommandList.deleteAll();
		
		g_DMCommandBench.CommandRegister("weaponmode_multi","Change Weapon Mode multiplay or not","Class",@CGameRules::MultiCallBack);
		g_DMCommandBench.CommandRegister( "votedmlms", "starts the LMS Mode vote", "LMS",@CLMSVote::StartLMSModeVote );
		g_DMCommandBench.CommandRegister( "votedmdrop", "starts the HLDM drop Mode vote", "Drop Rule", @CDropWeaponBoxVote::StartDropModeVote );
		g_DMCommandBench.CommandRegister( "votedmrule", "starts the DM rule Mode vote", "Vote Rule", @CVoteDMRule::DMRuleVoteCallback );
		g_DMCommandBench.CommandRegister( "votedmarcade", "starts the arcade Mode vote", "Arcade", @CVoteArcade::DMArcadeVoteCallback );
		
		@CDMCommandBench::g_CommandListKey = CDMCommandBench::g_CommandList.getKeys();
	}
	
	void CommandRegister( string szName, string szHelpInfo, string szPrintf, DMCCallback@ pCallback, int iFlags = 0 )
	{
		CDMCommandBench::RegistCommand( szName, szHelpInfo, szPrintf, @pCallback );
	}
}

CDMCommandBench g_DMCommandBench;