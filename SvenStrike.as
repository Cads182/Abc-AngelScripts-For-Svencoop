/*** 
	Dr.Abc
	Dr.Abc@foxmail.com
***/

//Core
#include "SvenStrike/JoinTeam"
#include "SvenStrike/BuyMenu"
#include "SvenStrike/CashBank"
#include "SvenStrike/weapons/cs16common"

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Dr.Abc | Paranoid_AF");
	g_Module.ScriptInfo.SetContactInfo("");
	
	g_Hooks.RegisterHook(Hooks::Player::ClientDisconnect, @onDisconnect);
	
	CBuyMenu::PluginInit();

}

void MapInit()
{
	RegisterCS16();
	CBuyMenu::MapInit();
}

void MapActivate()
{

}

HookReturnCode onDisconnect( CBasePlayer@ pPlayer )
{
	if(CCashBank::g_SSPlayerData.exists(szSteamID))
	{
		CCashBank::g_SSPlayerData.delete(szSteamID);
		return HOOK_HANDLED;
	}
	return HOOK_CONTINUE;
}