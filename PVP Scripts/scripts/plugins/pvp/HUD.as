/***
	Made by Dr.Abc
***/

namespace PVPHUD
{
	HUDNumDisplayParams params,paramsT1,paramsT2;
	
	void EndGame()
	{
		g_EngineFuncs.CVarSetFloat("mp_timelimit", 0.01);
	}

	void RefreshHUD()
	{
		CBaseEntity@ abdSpwan = null;
		while((@abdSpwan = g_EntityFuncs.FindEntityByClassname(abdSpwan, "info_player_start")) !is null)
		{
			g_EntityFuncs.Remove(abdSpwan);
		}	
		if(!m_bIsStart )
		{
		int StartTimeLeft = int(format_float  - g_Engine.time);
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Game will start in " + StartTimeLeft + " seconds\n");
			if (format_float - g_Engine.time <= 0 )
			{
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Game Started.\n");
				g_PlayerFuncs.RespawnAllPlayers(true, true);
				for (int i = 1; i <= g_Engine.maxClients; i++)
				{
					CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
					if(pPlayer !is null && pPlayer.IsConnected())
						ResetWeapons(pPlayer);
				}
				m_bIsStart = true;
				if(m_bIsScore)
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
						pPlayer.pev.deadflag = DEAD_DYING;
					}
					if (!m_bIsScore) 
					{
						SendTime( pPlayer );
					}
					else
					{
						if( g_Engine.maxClients != 0 )
						{
							if( g_MapMaxScore == 0)
								g_MapMaxScore = g_MaxScore;
							if (g_MapMaxScore - (m_iScoreTeam1 | m_iScoreTeam2 ) <= g_MapMaxScore/10 && WarnTime < 3 )
							{
								++WarnTime;
								m_bIsWarining = true;
								g_SoundSystem.EmitSound( g_EntityFuncs.Instance(0).edict(), CHAN_AUTO, "vox/warning.wav", 1.0, ATTN_NONE );
							}
							if( ( m_iScoreTeam1  >= g_MapMaxScore || m_iScoreTeam2  >= g_MapMaxScore ) && iEndTime < 1 )
							{
								g_SoundSystem.EmitSound( g_EntityFuncs.Instance(0).edict(), CHAN_AUTO, "vox/victor.wav", 1.0, ATTN_NONE );
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
							m_iScoreTeam1 = m_iScoreTeam2 = 0;
						}
					}
					if(m_bIsTDM)
					{
						if( pPlayer.pev.targetname == "normalplayer" && pPlayer.IsAlive() )
						{
							g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Chose Your Team.\n");	
							PVPTeam::TeamMenu.Open(0, 0, pPlayer);
						}
						if(abs(m_iTeam1 - m_iTeam2) > g_iBanlance - 1)
						{
							if(pPlayer.pev.targetname == "team1")
							{
								PVPTeam::AddToTeam2(pPlayer);
								g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You have been move to team 2 for balance.\n");
								g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string(pPlayer.pev.netname) + " have been move to team 2 for balance.\n");
							}
							else if(pPlayer.pev.targetname == "team2")
							{
								PVPTeam::AddToTeam1(pPlayer);
								g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "You have been move to team 1 for balance.\n");
								g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, string(pPlayer.pev.netname) + " have been move to team 1 for balance.\n");
							}
						}
					}
				}
			}
		}
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
		params.color1 = m_bIsWarining ? RGBA_RED : RGBA_SVENCOOP;

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

	void SendTime(CBasePlayer@ pPlayer)
	{
		if( g_TiemLeft <= 0)
			g_TiemLeft = g_LeftTime;
		if ( g_TiemLeft + g_WaitingTime - g_Engine.time <= g_WarningTime && WarnTime < 3 )
		{
			m_bIsWarining = true;
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
		if(m_bIsWarining)
		{
			params.flags +=  HUD_TIME_MILLISECONDS ;
		}
		params.x = 0;
		params.y = 0.06;
		params.value = g_TiemLeft + g_WaitingTime - g_Engine.time;
		params.color1 = m_bIsWarining ? RGBA_RED : RGBA_SVENCOOP;
		params.spritename = "stopwatch";
		g_PlayerFuncs.HudTimeDisplay( pPlayer, params );
	}

	void ResetWeapons(CBasePlayer@ pPlayer)
	{
		pPlayer.RemoveAllItems(false);
		pPlayer.SetItemPickupTimes(0);
		pPlayer.GiveNamedItem("weapon_9mmhandgun" , 0 , 34 );
		pPlayer.GiveNamedItem("weapon_crowbar" , 0 , 0 );
		pPlayer.pev.health = 100;
		pPlayer.pev.armorvalue = 0;
		pPlayer.pev.frags = 0;
		pPlayer.m_iDeaths = 0;
	}
}