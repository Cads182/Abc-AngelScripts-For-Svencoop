CClientCommand g_LMSModeVote( "votedmlms", "starts the LMS Mode vote", @CLMSVote::StartLMSModeVote );

namespace CLMSVote
{
	const int m_iLMSMaxTime = 60;
	const float m_flDMVoteTime  = 60.0f;
	const float m_flLMSMaxRadius  = 8092.0f;
	CScheduledFunction@ LMSCheacker;
	HUDTextParams Param;
	Vector vecRnd;
	float m_flLMSRadius;
	int m_iRoundCounter;
	int m_iLMSRoundTime;
	bool m_bLMSActive = false;
		
	bool IsLMS()
	{
		if(	g_SurvivalMode.IsActive() && m_bLMSActive )
			return true;
		return false;
	}
	
	bool IsTDM()
	{
		string lowcasemapname = string(g_Engine.mapname).ToLowercase();
		if (int8 (g_ReadFiles.g_PVPMapList[lowcasemapname]) == 1 || int8 (g_ReadFiles.g_PVPMapList[lowcasemapname]) == 2 ) 
			return true;
		return false;
	}
	
	bool IsScore()
	{
		string lowcasemapname = string(g_Engine.mapname).ToLowercase();
		if (int8 (g_ReadFiles.g_PVPMapList[lowcasemapname]) == 2 ) 
			return true;
		return false;
	}

	void StartLMSModeVote( const CCommand@ pArgs )
	{
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		if (g_Engine.time >= m_flDMVoteTime)
		{
			g_PlayerFuncs.SayText( pPlayer, "Game has been started for a while"+"(>"+m_flDMVoteTime+"s)" +", you can't change rule any more!" );
			return;
		}
		if (!g_SurvivalMode.IsEnabled())
		{
			g_PlayerFuncs.SayText( pPlayer, "You guys just trun off the survival mode! enable it again!" );
			return;
		}
		if( !m_bIsStart )
		{
			g_PlayerFuncs.SayText( pPlayer , "Game hasn't started." );
			return;
		}
		
		uint8 u = 0;
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ cPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(cPlayer !is null && cPlayer.IsConnected())
			{
				if(cPlayer.IsAlive())
					u++;
			}
		}
		
		if( u > 1)
		{
			float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
			
			if( flVoteTime <= 0 )
				flVoteTime = 16;
				
			float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_voteclassicmoderequired" );
			
			if( flPercentage <= 0 )
				flPercentage = 51;
			
			Vote vote( "LMS Mode vote", ( IsLMS() ? "Disable" : "Enable" ) + " LMS Mode?", flVoteTime, flPercentage );
			
			vote.SetVoteBlockedCallback( @LMSModeVoteBlocked );
			vote.SetVoteEndCallback( @LMSModeVoteEnd );
			vote.Start();
		}
		else
			g_PlayerFuncs.SayText( pPlayer , "Man, There's only you in the server." );
	}

	void LMSModeVoteBlocked( Vote@ pVote, float flTime )
	{
		g_Scheduler.SetTimeout( "StartLMSModeVote", flTime, false );
	}

	void LMSModeVoteEnd( Vote@ pVote, bool bResult, int iVoters )
	{
		if( !bResult )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for LMS Mode failed" );
			return;
		}
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( !IsLMS() ? "Enable" : "Disable" ) + " LMS mode passed\n" );
		EnableLMS();
	}
	
	void EnableLMS()
	{
		if(IsScore())
		{
			m_iScoreTeam2 = m_iScoreTeam1 = 0;
			PVPHUD::RefreshScore();
		}
		
		FoundRndSpwan();
		
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "LMS Mode Started." );
		RespawnPlayers();
		m_bLMSActive = true;
		g_SurvivalMode.Activate();
		@LMSCheacker = g_Scheduler.SetInterval( "AlivePlayerCounter", 1, g_Scheduler.REPEAT_INFINITE_TIMES );
	}

	void DisableLMS()
	{
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "LMS Mode Disabled." );
		RespawnPlayers();
		m_bLMSActive = false;
		g_SurvivalMode.Disable();
		@LMSCheacker = null;
	}
	
	void RoundEnd( CBasePlayer@ pPlayer , int Survival )
	{
		if(pPlayer is null)
			return;
		m_iRoundCounter++;
		RespawnPlayers();
		pPlayer.pev.frags += 100;
		g_SoundSystem.EmitSound( g_EntityFuncs.Instance(0).edict(), CHAN_AUTO, "barney/ba_bring.wav", 1.0, ATTN_NONE );
		if( Survival == 1)
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, the winner is " + pPlayer.pev.netname + "!\n" );
		else
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, nobody is winner!\n" );
	}
	
	void TeamRoundEnd( int Survival1 , int Survival2 )
	{
		m_iRoundCounter++;
		RespawnPlayers();
		g_SoundSystem.EmitSound( g_EntityFuncs.Instance(0).edict(), CHAN_AUTO, "barney/ba_bring.wav", 1.0, ATTN_NONE );
		if( Survival1 == 0 && Survival2 != 0 )
		{
			if(IsScore())
				m_iScoreTeam2 += 5;
			else
				TeamAddFrags ("team2");
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, the winner is Team HECU!\n" );
		}
		else if( Survival1 != 0 && Survival2 == 0 )
		{
			if(IsScore())
				m_iScoreTeam1 += 5;
			else
				TeamAddFrags ("team1");
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, the winner is Team Lambda!\n" );
		}
		else if( Survival1 == 0 && Survival2 == 0 )
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, nobody is winner!\n" );
		if(IsScore())
			PVPHUD::RefreshScore();
	}
	
	void TeamAddFrags( string Str_Teamname )
	{
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				if(pPlayer.pev.targetname == Str_Teamname )
					pPlayer.pev.frags += 100;
			}
		}
	}
	
	void RespawnPlayers()
	{
		FoundRndSpwan();
		m_iLMSRoundTime = 0;
		m_flLMSRadius = 0;
		g_PlayerFuncs.RespawnAllPlayers(true, true);
		for (int i = 1; i <= g_Engine.maxClients; i++)
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
			if(pPlayer !is null && pPlayer.IsConnected())
			{
				pPlayer.RemoveAllItems(false);
				pPlayer.SetItemPickupTimes(0);
				pPlayer.GiveNamedItem("weapon_9mmhandgun" , 1 , 34 );
				pPlayer.GiveNamedItem("weapon_crowbar" , 0 , 0 );
				pPlayer.pev.health = 100;
				pPlayer.pev.armorvalue = 0;
			}
		}
	}
	
	void AlivePlayerCounter()
	{
		if( !m_bLMSActive )
			return;
		if(IsLMS())
		{
			if( g_Engine.maxClients > 1 )
			{
				if(!IsTDM())
				{
					CBasePlayer@ cPlayer;
					int8 m_shortAlivePlayer = 0;
					for (int i = 1; i <= g_Engine.maxClients; i++)
					{
						CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
						if(pPlayer !is null && pPlayer.IsConnected())
						{
							if(pPlayer.IsAlive())
							{
								m_shortAlivePlayer++;
								@cPlayer = @pPlayer;
							}
						}
					}
					if( m_shortAlivePlayer <= 1 && !IsTDM() )
						RoundEnd( cPlayer , m_shortAlivePlayer );
				}
				else
				{
					int8 m_iTeam1Player = 0, m_iTeam2Player = 0;
					bool m_bHaveTeam = false;
					for (int i = 1; i <= g_Engine.maxClients; i++)
					{
						CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
						if(pPlayer !is null && pPlayer.IsConnected())
						{
							if(pPlayer.IsAlive())
							{
								if(pPlayer.pev.targetname == "team1")
								{
									m_iTeam1Player++;
									m_bHaveTeam = true;
								}
								else if (pPlayer.pev.targetname == "team2")
								{
									m_iTeam2Player++;
									m_bHaveTeam = true;
								}
								else
								{	
									if( m_iTeam2 >= m_iTeam1 )
										PVPTeam::AddToTeam1(pPlayer);
									else
										PVPTeam::AddToTeam2(pPlayer);
								}
							}
						}
					}
					if(( m_iTeam1Player == 0 || m_iTeam2Player == 0 ) && m_bHaveTeam )
						TeamRoundEnd ( m_iTeam1Player, m_iTeam2Player );
				}
				SendMessage();
			}
		}
		else
			DisableLMS();
	}
	
	void SendMessage()
	{
		Param.x = -1;
		Param.y = 0.97;
			
		Param.r1 = 200;
		Param.g1 = 122;
		Param.b1 = 100;
		Param.a1 = 0;

		Param.fadeinTime = 0.1;
		Param.holdTime = 1;
		Param.channel = 11;
		
		m_iLMSRoundTime++;
		
		if( m_iLMSRoundTime >= m_iLMSMaxTime )
		{
			TimeOut();
		}
			
		else
			g_PlayerFuncs.HudMessageAll( Param, "Round time left: " + (m_iLMSMaxTime - m_iLMSRoundTime) + "s." );
	}
	
	void TimeOut()
	{
		m_flLMSRadius += 200;
		float BattleRadius = Math.max(m_flLMSMaxRadius - m_flLMSRadius, 512);
		CBaseEntity@ pPlayer = null;
		while((@pPlayer = g_EntityFuncs.FindEntityByClassname(pPlayer, "player")) !is null)
		{
			float le = (pPlayer.pev.origin - vecRnd).Length();
			if( le >= BattleRadius )
			{
				g_PlayerFuncs.ScreenFade(pPlayer, Vector(137,207,240), 0.2, 0.1, 25, FFADE_OUT);
				pPlayer.TakeDamage(g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, 5.0f, DMG_SHOCK);
				g_PlayerFuncs.ClientPrint( cast<CBasePlayer@>(pPlayer), HUD_PRINTCENTER, "You are in the shock zone!\n" );
			}
		}
		te_beamcylinder( vecRnd, BattleRadius, uint(BattleRadius) );
		
		g_PlayerFuncs.HudMessageAll( Param, "Time out, Reducing playable zone." );
		//g_PlayerFuncs.ClientPrintAll( HUD_PRINTCENTER, "Round " + m_iRoundCounter + " ended, all you guys are losers!\n" );
	}
	
	void FoundRndSpwan()
	{
		CBaseEntity@ pSpawn = null;
		while((@pSpawn = g_EntityFuncs.FindEntityByClassname(pSpawn, "info_player_*")) !is null)
		{
			if(Math.RandomLong(0,1) < 0.65)
			{
				vecRnd = pSpawn.pev.origin;
				break;
			}
		}
	}
	
	void te_beamcylinder(Vector pos, float radius, uint frameRate=16 )
	{
		NetworkMessage m(MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null);
			m.WriteByte(TE_BEAMCYLINDER);
			m.WriteCoord(pos.x);
			m.WriteCoord(pos.y);
			m.WriteCoord(pos.z);
			m.WriteCoord(pos.x);
			m.WriteCoord(pos.y);
			m.WriteCoord(pos.z + radius + 48);
			m.WriteShort(g_EngineFuncs.ModelIndex("sprites/laserbeam.spr"));
			m.WriteByte(0);
			m.WriteByte(frameRate);
			m.WriteByte(5);
			m.WriteByte(192);
			m.WriteByte(0);
			m.WriteByte(137);
			m.WriteByte(207);
			m.WriteByte(240);
			m.WriteByte(129);
			m.WriteByte(0);
		m.End();
	}
}

class CLMSMode
{
	void LMSModeInitialized()
	{
		CLMSVote::m_iRoundCounter = CLMSVote::m_iLMSRoundTime = 0;
		CLMSVote::m_flLMSRadius = 0;
		g_SurvivalMode.SetStartOn( false );
		g_SurvivalMode.Disable();
		g_SurvivalMode.SetDelayBeforeStart( 0.1 );
		CLMSVote::m_bLMSActive = false;
		g_SoundSystem.PrecacheSound("barney/ba_bring.wav");
		g_Game.PrecacheModel( "sprites/laserbeam.spr" );
	}
}

CLMSMode g_LMSMode;