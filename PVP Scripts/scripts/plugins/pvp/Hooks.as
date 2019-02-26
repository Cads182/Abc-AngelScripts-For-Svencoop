/***
	Made by Dr.Abc
***/

HookReturnCode PlayerSpawn(CBasePlayer@ pPlayer)
{
	if(CVoteArcade::g_IsArcade)
		CVoteArcade::ApplyArcade( pPlayer );
	return HOOK_HANDLED;
}