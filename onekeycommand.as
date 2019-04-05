/***
Dr.Abc is good for you.
Dr.Abc@foxmail.com
****/

const float iMinSpeed = 100.0f;

string MapSky;
dictionary g_CommandList;
array<string> @g_CommandListKey;
dictionary g_PlayerData;
CScheduledFunction@ pScheduler;

class CPlayerData
{
	private uint ui_WarnTime = 3;
	
	uint WarnTime
	{
		get const { return ui_WarnTime;}
		set {ui_WarnTime = value;}
	}
}

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Dr.Abc");
	g_Module.ScriptInfo.SetContactInfo("https://github.com/DrAbcrealone");
	
	g_CommandList.deleteAll();
	g_PlayerData.deleteAll();
	g_Scheduler.ClearTimerList();
	
	RegistCommand( "pvp", "PVP all the time", "Fight Good 4 U", @PvpEnable );
	RegistCommand( "night", "Night time", "Night Bad 4 U", @NightEnable );
	RegistCommand( "owl", "Become someone","Owl Really Fun", @A2bEnable );
	RegistCommand( "moveordie", "Move or Die","Healthy 4 U", @MoveEnable );
	
	@g_CommandListKey = g_CommandList.getKeys();
	
	MapSky = g_EngineFuncs.GetInfoKeyBuffer(g_EntityFuncs.IndexEnt(0)).GetValue("skyname");
}

void MapInit()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_modeler", "trigger_modeler" );
	g_Game.PrecacheOther( "trigger_modeler" );
	g_Game.PrecacheModel( "models/player/DGF_robogrunt/DGF_robogrunt.mdl" );
}

CClientCommand g_Onekeylist("onekeylist", "List all Onekey", @ListCallback);

void ListCallback(const CCommand@ Argments)
{
	CBasePlayer@ pGouGuangLi = g_ConCommandSystem.GetCurrentPlayer();
	string printf;
	for(uint i = 0; i <= g_CommandListKey.length() - 1; i++ )
	{
		OnekeyCommand@ data = cast<OnekeyCommand@>(g_CommandList[g_CommandListKey[i]]);
		printf = printf + data.Name + " | " + data.HelpInfo + ".\n";
	}
	g_Game.AlertMessage(at_console, printf );
}

funcdef void OneKeyCallback( CBasePlayer@, const bool ,const OnekeyCommand@ );

class OnekeyCommand
{
	private string szName = "";
	private string szHelpInfo = "";
	private string szPrintf = "";
	private CClientCommand@ c_ClientCom;
	private OneKeyCallback@ c_CallBack;
	
	string Name
	{
		get const{ return szName;}
		set{ szName = value;}
	}
		
	string HelpInfo
	{
		get const{ return szHelpInfo;}
		set { szHelpInfo = value; }
	}
	
	string Printf
	{
		get const{ return szPrintf;}
		set { szPrintf = value; }
	}
		
	CClientCommand@ ClientCommand
	{
		get{ return c_ClientCom;}
		set{ @c_ClientCom = value;}
	}
	
	OneKeyCallback@ ClientCallback
	{
		get{ return c_CallBack;}
		set{ @c_CallBack = value;}
	}
}

void RegistCommand( string szName, string szHelpInfo, string szPrintf, OneKeyCallback@ pCallback, int iFlags = 0 )
{
	OnekeyCommand command;
	command.Name = "onekey" + szName;
	command.HelpInfo = szHelpInfo;
	command.Printf = "One Key " + szPrintf;
	@command.ClientCallback = pCallback;
	@command.ClientCommand = CClientCommand("onekey" + szName, szHelpInfo, @HandelCallback, iFlags);
	g_CommandList["onekey" + szName] = command;
}

OnekeyCommand GetCommand( string szName )
{
	if(g_CommandList.exists(szName))
	{
		OnekeyCommand@ data = cast<OnekeyCommand@>(g_CommandList[szName]);
		//ErrorPrintf("Founded.");
		return data;
	}
	else
	{
		ErrorPrintf("Not Found Command In list.");
		OnekeyCommand data;
		return data;
	}
}

void HandelCallback( const CCommand@ Argments )
{
	string ArgName = Argments[0].SubString(1,Argments[0].Length());
	string ArgVal = Argments[1];
	
	OnekeyCommand@ data = GetCommand(ArgName);
	
	if(data is null)
	{
		ErrorPrintf("Null Access.");
		return;
	}
	
	if( data.ClientCallback is null )
	{
		ErrorPrintf("Null Callback.");
		return;
	}
	
	CBasePlayer@ pGouGuangLi = g_ConCommandSystem.GetCurrentPlayer();
	if(g_PlayerFuncs.AdminLevel(pGouGuangLi) < ADMIN_YES)
	{
		g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "You don't have access to that command, peasent.\n");
		return;
	}
	
	bool bVal;
	if( Argments[1] == 1 )
	{
		bVal = true;
		g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "Opened.\n");
	}
	else if (Argments[1] == 0)
	{
		bVal = false;
		g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "Closed.\n");
	}
	else if ( Argments[1] == "")
	{
		bVal = !bVal;
		g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "Toggled.\n");
	}
	else
	{
		g_PlayerFuncs.SayText(pGouGuangLi, "[" + data.Printf + "]" + "Dat not right u fool.\n");
		return;
	}
	OneKeyCallback@ Callback = @data.ClientCallback;
	Callback(pGouGuangLi,bVal,data);
}

void ErrorPrintf( string&in  szError )
{
	g_Game.AlertMessage(at_error, "[OneKey Plugin]" + szError + "\n");
}

void PvpEnable( CBasePlayer@ pGouGuangLi, const bool b_Canwefight ,const OnekeyCommand@ data )
{
	for (int i = 1; i <= g_Engine.maxClients; i++)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if( pPlayer !is null && pPlayer.IsConnected())
		{
			g_EntityFuncs.DispatchKeyValue(pPlayer.edict(), "classify", b_Canwefight ? i-1 : 2 );
			g_PlayerFuncs.SayText(pPlayer, "[" + data.Printf + "]" + ( b_Canwefight ? "Fight!\n" : "Wut....no fight,peaceful..\n" ) );
		}
	}
}

void NightEnable( CBasePlayer@ pGouGuangLi, const bool b_CanweNight, const OnekeyCommand@ data )
{
	g_EngineFuncs.LightStyle(0, ( b_CanweNight ? "b" : "h" ));
	g_EntityFuncs.DispatchKeyValue(g_EntityFuncs.IndexEnt(0), "skyname", ( b_CanweNight ? "carnival" : MapSky ) );
	g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[" + data.Printf + "]" + ( b_CanweNight ? "Night time~\n" : "Day time!\n" ) );
}


void A2bEnable(  CBasePlayer@ pGouGuangLi, const bool b_CanweOwl ,const OnekeyCommand@ data )
{
	for (int i = 1; i <= g_Engine.maxClients; i++)
	{
		CBasePlayer@ cPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if( cPlayer !is null && cPlayer.IsConnected() )
		{
			g_PlayerFuncs.SayText(cPlayer, "[" + data.Printf + "]" + (b_CanweOwl ? "You Owl2, You real Owl2, You Owl2 4ever.\n" : "No more Owl2 cry.\n"));
			if(b_CanweOwl)
			{
				CBaseEntity@ cbeEntity = g_EntityFuncs.CreateEntity( "trigger_modeler", null,  false);
				trigger_modeler@ pEntity = cast<trigger_modeler@>(CastToScriptClass(cbeEntity));
				g_EntityFuncs.SetOrigin( pEntity.self, cPlayer.pev.origin );
				@pEntity.pev.owner = @cPlayer.edict();
				pEntity.pev.angles = cPlayer.pev.angles;
				pEntity.pev.targetname =  cPlayer.pev.netname;
				g_EntityFuncs.DispatchSpawn( pEntity.self.edict());
				
				cPlayer.pev.rendermode = kRenderTransTexture;
				cPlayer.pev.renderamt = 0;
				cPlayer.pev.netname = "null";
			}
			else
			{
				cPlayer.pev.rendermode = kRenderNormal;
			}
		}
	}
	
	if(!b_CanweOwl)
	{
		CBaseEntity@ pEntity = null;
		while((@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, "trigger_modeler" )) !is null)
		{
			pEntity.pev.owner.vars.netname = pEntity.pev.targetname;
			g_EntityFuncs.Remove(pEntity);
		}
	}
}

void MoveEnable( CBasePlayer@ pGouGuangLi, const bool b_CanweMove, const OnekeyCommand@ data )
{
	g_PlayerData.deleteAll();
	if(b_CanweMove)
	{
		if( pScheduler !is null )
		{
			if(!pScheduler.HasBeenRemoved())
			{
				g_PlayerFuncs.SayText( @pGouGuangLi, "[" + data.Printf + "]U actived it u fool.\n");
				return;
			}
			else
				@pScheduler = g_Scheduler.SetInterval("MoveCheacker", 1, g_Scheduler.REPEAT_INFINITE_TIMES);
		}
		else
			@pScheduler = g_Scheduler.SetInterval("MoveCheacker", 1, g_Scheduler.REPEAT_INFINITE_TIMES);
	}
	else
	{
		if( pScheduler is null)
		{
			g_PlayerFuncs.SayText( @pGouGuangLi, "[" + data.Printf + "]Active it first u fool.\n");
			return;
		}
		else
			g_Scheduler.RemoveTimer(pScheduler);
	}
	g_PlayerFuncs.ClientPrintAll( HUD_PRINTTALK, "[" + data.Printf + "]" + (b_CanweMove ? "Runn! Gump! Run!.\n" : "Take a break, Gump.\n"));
}

void MoveCheacker()
{
	for (int i = 1; i <= g_Engine.maxClients; i++)
	{
		CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(i);
		if( pPlayer !is null && pPlayer.IsConnected())
		{
			const string szSteamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
			if(!g_PlayerData.exists(szSteamId))
			{
				CPlayerData list;
				g_PlayerData[szSteamId] = list;
			}
			
			CPlayerData@ data = cast<CPlayerData@>(g_PlayerData[szSteamId]);
			
			if(pPlayer.IsAlive())
			{
				if(sqrt( pow( pPlayer.pev.velocity.x, 2.0 ) + pow( pPlayer.pev.velocity.y, 2.0 ) ) < iMinSpeed )
				{
					if( data.WarnTime > 0 )
					{
						g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCENTER, "Move Faster or you will blow in " + data.WarnTime + " sec.\n" );
						data.WarnTime = data.WarnTime - 1;
					}
					else if( data.WarnTime == 0 )
					{
						g_WeaponFuncs.RadiusDamage( pPlayer.pev.origin, pPlayer.pev, pPlayer.pev, 9999.0f, 200, 99, DMG_BLAST | DMG_ALWAYSGIB );
						g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_ITEM, "common/bodysplat.wav", 0.65, ATTN_NORM, 0, 95 + Math.RandomLong( 0,0x1f ) );
						g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string(pPlayer.pev.netname) + " BLOW UP CUS HIS LAZINESS." );
					}
				}
				else
				{
					data.WarnTime = 3;
				}
			}
			else
			{
				data.WarnTime = 10;
			}
		}
	}
}

class trigger_modeler : ScriptBaseEntity
{
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/player/DGF_robogrunt/DGF_robogrunt.mdl" );
		
		if( pev.owner !is null )
		{
			@pev.owner		= @pev.owner;
			pev.movetype	= MOVETYPE_FOLLOW;
			@pev.aiment		= @pev.owner;
			pev.solid		= SOLID_NOT;
			pev.colormap	= pev.owner.vars.colormap;
		}
		g_EntityFuncs.SetOrigin( self, pev.origin );
	}
	
	void Precache()
	{
		BaseClass.Precache();
		g_Game.PrecacheModel( self, "models/player/DGF_robogrunt/DGF_robogrunt.mdl" );
	}
}
