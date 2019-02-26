/***
	Made by Dr.Abc
***/

CClientCommand g_DMRuleModeVote( "votedmrule", "starts the DM rule Mode vote", @CVoteDMRule::DMRuleVoteCallback );

namespace CVoteDMRule
{
	const float m_flDMVoteTime  = 60.0f;
	string m_strmapname = string(g_Engine.mapname).ToLowercase();
	bool g_IsFFA()
	{
		if(g_ReadFiles.g_PVPMapList.exists(m_strmapname) && int8 (g_ReadFiles.g_PVPMapList[m_strmapname]) == 0)
			return true;
		else if(g_ReadFiles.g_PVPMapList.exists(m_strmapname) && int8 (g_ReadFiles.g_PVPMapList[m_strmapname]) == 1)
			return false;
		return false;
	}
	
	void StartDMRuleVote()
	{
		float flVoteTime = g_EngineFuncs.CVarGetFloat( "mp_votetimecheck" );
		
		if( flVoteTime <= 0 )
			flVoteTime = 16;
			
		float flPercentage = g_EngineFuncs.CVarGetFloat( "mp_voteclassicmoderequired" );
		
		if( flPercentage <= 0 )
			flPercentage = 51;

		Vote vote( "DM rule vote ", ( g_IsFFA() ? "Enable" : "Disable" ) + " Team Play ?", flVoteTime, flPercentage );
		
		vote.SetVoteBlockedCallback( @DMRuleVoteBlocked );
		vote.SetVoteEndCallback( @DMRuleVoteEnd );
		vote.Start();
	}

	void DMRuleVoteBlocked( Vote@ pVote, float flTime )
	{
		g_Scheduler.SetTimeout( "StartDMRuleVote", flTime, false );
	}

	void DMRuleVoteEnd( Vote@ pVote, bool bResult, int iVoters )
	{
		if( !bResult )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote for Team play failed" );
			return;
		}
		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, "Vote to " + ( !g_IsFFA() ? "Disable" : "Enable" ) + " Team play passed\n" );
		ChangeDMRule();
	}
	
	void DMRuleVoteCallback( const CCommand@ pArgs )
	{
		CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
		if (g_Engine.time >= m_flDMVoteTime)
			g_PlayerFuncs.SayText( pPlayer, "Game has been started for a while"+"(>"+m_flDMVoteTime+"s)" +", you can't change rule any more!" );
		else if(g_ReadFiles.g_PVPMapList.exists(m_strmapname) && int8 (g_ReadFiles.g_PVPMapList[m_strmapname]) != 2)
			StartDMRuleVote();
		else
			g_PlayerFuncs.SayText( pPlayer, "This Map can not be changed the game rule!" );
	}
	
	void ChangeDMRule()
	{
		if(g_IsFFA())
		{
			g_ReadFiles.g_PVPMapList[m_strmapname] = 1;
		}
		else
		{
			g_ReadFiles.g_PVPMapList[m_strmapname] = 0;
		}
		g_EngineFuncs.ChangeLevel(m_strmapname);
	}
}