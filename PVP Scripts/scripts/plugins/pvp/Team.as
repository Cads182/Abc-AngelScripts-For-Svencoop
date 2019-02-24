/***
	Made by Dr.Abc
***/

namespace PVPTeam
{
	CTextMenu@ TeamMenu = CTextMenu(TeamMenuRespond);
	CClientCommand g_ChangeTeam("changeteam", "Change Your Team", @ChangeTeam);

	void TeamPluginInt()
	{
		TeamMenu.Unregister();
		TeamMenu.Register();
		TeamMenu.AddItem("Team Lambda", null);
		TeamMenu.AddItem("Team HECU", null);
		TeamMenu.SetTitle("[" + MenuTitle + "]\n");
	}

	HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer)
	{
		pPlayer.pev.targetname = "normalplayer";
		pPlayer.pev.solid	   = SOLID_BBOX;
		g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", 0 );
		CCommandApplyer(pPlayer,"cl_updaterate 102;cl_cmdrate 999;cl_cmdbackup 999");
		if(!m_bIsTDM)
		{
			++uint_PlayerTeam;
			if (uint_PlayerTeam == 1)
				++uint_PlayerTeam;
			g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", uint_PlayerTeam );
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
		CCommandApplyer(pPlayer,"cl_updaterate 101;cl_cmdrate 132;cl_cmdbackup 1");
		return HOOK_HANDLED;
	}
	
	void CCommandApplyer(CBasePlayer@ pPlayer, const string Arg)
	{
		NetworkMessage m(MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict());
			m.WriteString(Arg);
		m.End();
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
		g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", 5 );
		pPlayer.pev.targetname = "team1";
		++m_iTeam1;
		PVPHUD::ResetWeapons(pPlayer);
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
		CCommandApplyer(pPlayer,"setinfo model " + StrpModel);
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
		g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", 6 );
		pPlayer.pev.targetname = "team2";
		++m_iTeam2;
		PVPHUD::ResetWeapons(pPlayer);
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
		CCommandApplyer(pPlayer,"setinfo model " + StrpModel);
		g_PlayerFuncs.RespawnPlayer(pPlayer,true,true);
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "You joined the Team H.E.C.U.\n");
	}
	
	void ChangeTeam(const CCommand@ pArgs)
	{
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		if(m_bIsTDM)
		{
			PVPTeam::TeamMenu.Open(0, 0, pPlayer);
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Chose Your Team.\n");
		}
		else
		{
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "There's no team you fool.\n");
		}
	}
}