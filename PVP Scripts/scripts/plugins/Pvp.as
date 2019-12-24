/*** 
	PVP Enable
	Dr.Abc
	Dr.Abc@foxmail.com
***/

//Core
#include "pvp/HUD"
#include "pvp/Team"
#include "pvp/Hooks"
#include "pvp/TakeDamage"
#include "pvp/ReadFiles"
#include "pvp/Utility"
#include "pvp/CommandBench"
//#include "pvp/Hitbox"

//Addition
#include "pvp/ClassMode"
#include "pvp/DropBox"
#include "pvp/VoteRule"
#include "pvp/Arcade"
#include "pvp/LMS"
#include "pvp/ZM"

//Setting
const float g_WaitingTime = 30;						//TDM Waiting Time
const int g_WarningTime = 60;						//Warning Time
const int g_iBanlance = 3;						//The gap for autobalance (minimum is 2)
const int g_LeftTime = 600;						//Default Game time
const int g_MaxScore = 50;						//Defalut Max team score
const int HUD_CHAN_PVP = 14;						//HUD Channel
const string g_PVPMapFile = "scripts/plugins/pvp/config/PVPMapList.ini";		//file name
const string g_PVPSkillFile = "scripts/plugins/pvp/config/pvp_skl.ini";		//file name
const string MenuTitle = "Chose Your Team";			//Chose Your Team
const bool IsClassMode 	= true;						//Is classic Mode
const float ARMOR_RATIO = 0.2f; 					//80% Ratio
const float ARMOR_BONUS = 0.5f;						//150% Bounus

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Dr.Abc");
	g_Module.ScriptInfo.SetContactInfo("https://forums.svencoop.com/showthread.php/46283-Plugin-PVP-Enable");
	g_ReadFiles.PluginInit();
	//Put ur call below
	g_PVPTeam.TeamPluginInt();
	g_DMCommandBench.CommandPluginInit();
}

void MapInit()
{
	g_ReadFiles.Resetvariable();//HACK HACK: keep this one as first, or you will mess up the timelist.
	g_ReadFiles.IsPVP();//HACK HACK: keep this one as seccond, or you will keep the script off.
	
	if(!m_bIsPVP)
	{
		//g_DMUtility.EntityUnregister();//Useless
		return;
	}
		
	g_SurvivalMode.EnableMapSupport();

	//g_HitBox.MapInit();
	
	//Put ur call below
	g_DMDropRule.ApplyDropRule();
	g_DMClassMode.EnableClassMode( IsClassMode );
	g_LMSMode.LMSModeInitialized();
	g_Arcade.ArcadeModeInitialized();
	g_SvenZM.ZMMapInit();
}

void MapActivate()
{
	if(!m_bIsPVP)
		return;
	
	//Put ur call below
	g_DMClassMode.WeaponReplace();
	g_SvenZM.ZMItemRemover();
}
