/***
	Made by Dr.Abc
***/

HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer)
	{
		pPlayer.pev.targetname = "normalplayer";
		pPlayer.pev.solid	   = SOLID_BBOX;
		g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", 0 );
		PVPTeam::CCommandApplyer(pPlayer,"cl_updaterate 102;cl_cmdrate 999;cl_cmdbackup 999");
		if(!m_bIsTDM)
		{
			pPlayer.IRelationship( pPlayer );
			++uint_PlayerTeam;
			g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", uint_PlayerTeam );
			return HOOK_HANDLED;
		}
		return HOOK_HANDLED;
	}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer )
{
	if(pPlayer.pev.targetname == "team1")
		--m_iTeam1;
	if(pPlayer.pev.targetname == "team2")
		--m_iTeam2;
	PVPTeam::CCommandApplyer(pPlayer,"cl_updaterate 101;cl_cmdrate 132;cl_cmdbackup 1");
	return HOOK_HANDLED;
}
	
HookReturnCode PlayerTakeDamage(DamageInfo@ info)
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(info.pVictim.pev));
	CBasePlayer@ pAttacker = cast<CBasePlayer@>(g_EntityFuncs.Instance(info.pAttacker.pev));
	CBaseEntity@ pInflictor = cast<CBaseEntity@>(g_EntityFuncs.Instance(info.pInflictor.pev));
	if (pPlayer !is null && pAttacker !is null && pInflictor!is null && ((pPlayer.Classify() == pAttacker.Classify())))
	{
			if( pPlayer !is pAttacker )
					return HOOK_CONTINUE;
	}
	if(TakeDamage::TakeDamege(pPlayer,pAttacker,pInflictor,info.flDamage,info.bitsDamageType))
		g_DMDropRule.DropIt(pPlayer);
	info.flDamage = 0;
	return HOOK_CONTINUE;
}

HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
{
	if(CVoteArcade::g_IsArcade)
		CVoteArcade::ApplyArcade( pPlayer );
	return HOOK_HANDLED;
}