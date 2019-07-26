/***
	Made by Dr.Abc
***/

HookReturnCode ClientConnected( edict_t@ pEntity, const string& in szPlayerName, const string& in szIPAddress, bool& out bDisallowJoin, string& out szRejectReason )
{
	
	return HOOK_HANDLED;
}

HookReturnCode ClientPutInServer(CBasePlayer@ pPlayer)
{
	PVPTeam::PutInServerHook(pPlayer);
	g_DMUtility.CCommandApplyer(pPlayer,"cl_updaterate 102;cl_cmdrate 300;cl_cmdbackup 1;");
	g_EntityFuncs.SetSize(pPlayer.pev, g_vecZero, g_vecZero);
		
	if( CSvenZM::IsZM() || CSvenZM::m_bIsZM )
	{
		g_SvenZM.BuildDic(pPlayer);
		return HOOK_HANDLED;
	}
	
	if(!m_bIsTDM)
	{
		++uint_PlayerTeam;
		g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", uint_PlayerTeam );
		return HOOK_HANDLED;
	}
	
	return HOOK_HANDLED;
}

HookReturnCode ClientSay(SayParameters@ pParams) 
{
	g_SvenZM.ClientSay( pParams );
	
	return HOOK_HANDLED;
}

HookReturnCode ClientDisconnect(CBasePlayer@ pPlayer )
{
	PVPTeam::DisconectHook( pPlayer );
	g_DMUtility.CCommandApplyer(pPlayer,"cl_updaterate 101;cl_cmdrate 132;cl_cmdbackup 1;");
	
	g_HitBox.DestroyHitBox(pPlayer);
	
	g_SvenZM.PlayerDis(pPlayer);
	return HOOK_HANDLED;
}
	
HookReturnCode PlayerTakeDamage(DamageInfo@ info)
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(info.pVictim.pev));
	CBaseEntity@ pAttacker = cast<CBaseEntity@>(g_EntityFuncs.Instance(info.pAttacker.pev));
	CBaseEntity@ pInflictor = cast<CBaseEntity@>(g_EntityFuncs.Instance(info.pInflictor.pev));
	CBasePlayer@ atkPlayer = cast<CBasePlayer@>(pAttacker);
	if (pPlayer !is null && pAttacker !is null && pInflictor!is null && ((pPlayer.Classify() == pAttacker.Classify())))
	{
			if( pPlayer !is pAttacker )
					return HOOK_CONTINUE;
	}
	if(TakeDamage::TakeDamege(pPlayer,pAttacker,pInflictor,info.flDamage,info.bitsDamageType))
	{
		if(g_DMDropRule.IsDrop())
			g_DMDropRule.DropIt(pPlayer);
		
		g_Arcade.ArcadeRespwan( atkPlayer );
		
		g_SvenZM.CritKill( atkPlayer, info.bitsDamageType);
	}
	
	g_SvenZM.WeaponShock( pPlayer , pPlayer.pev.dmg_take , atkPlayer );
	
	info.flDamage = 0;
	return HOOK_CONTINUE;
}

HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
{
	g_HitBox.PutInServer(pPlayer);
	pPlayer.pev.takedamage = DAMAGE_AIM;
	g_Arcade.ArcadeRespwan(pPlayer);
	g_DMClassMode.PlayerSpwanHook(pPlayer);
	return HOOK_HANDLED;
}