/***
	Inspired from w00tguy's Classic Mode Deluxe: https://forums.svencoop.com/showthread.php/45371-Classic-Mode-Deluxe
  
	PVP Enable
	Dr.Abc
	Dr.Abc@foxmail.com
***/

#include "pvp/HUD"
#include "pvp/Team"
#include "pvp/TakeDamage"
#include "pvp/ReadFiles"
#include "pvp/ClassMode"

//Setting
const float g_WaitingTime = 30;						//TDM Waiting Time
const int g_WarningTime = 60;						//Warning Time
const int g_iBanlance = 3;						//The gap for autobalance (minimum is 2)
const int g_LeftTime = 600;						//Default Game time
const int g_MaxScore = 50;						//Defalut Max team score
const int HUD_CHAN_PVP = 14;						//HUD Channel
const string g_PVPMapFile = "scripts/plugins/PVPMapList.cfg";		//file name
const string g_PVPSkillFile = "scripts/plugins/pvp_skl.txt";		//file name
const string MenuTitle = "Chose Your Team";			//Chose Your Team
const bool IsClassMode 	= false;						//Is classic Mode
const float ARMOR_RATIO = 0.2f; 					//80% Ratio
const float ARMOR_BONUS = 0.5f;						//150% Bounus

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Dr.Abc");
	g_Module.ScriptInfo.SetContactInfo("https://forums.svencoop.com/showthread.php/46283-Plugin-PVP-Enable");
	g_ReadFiles.deleteAll();
	g_ReadFiles.ReadMaps();
	g_ReadFiles.ReadSkills();
}

void MapInit()
{
	g_ReadFiles.Resetvariable();
	g_ReadFiles.IsPVP();
	g_DMClassMode.EnableClassMode( IsClassMode );
}

void MapActivate()
{
	if( g_ReadFiles.IsPVP() )
		g_DMClassMode.WeaponReplace();
}