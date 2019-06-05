const string g_SpriteName = 'sprites/chatspr/voiceicon.spr';
const string g_SoundFile = "scripts/plugins/ChatSounds.txt";
const uint g_Delay = 3500;
const int g_PitchMax = 255;
const int g_PitchMin = 40;
const bool b_Stats = true;

#include "ChatSounds_Statistics"

int g_SoundPitch;
bool g_isSafe = false;
dictionary g_SoundList,g_ChatTimes,g_Pitch;
CTextMenu@ cateMenu = CTextMenu(cateMenuRespond);
array<string> g_SoundListKeys;

CClientCommand g_ListSounds("listsounds", "List all chat sounds", @listsounds);

class CChatSound
{
	string Name;
	string Sound;
	string Sprite;
	int8 SoundType;
}

void PluginInit() 
{
	g_Module.ScriptInfo.SetAuthor("animaliZed,Dr.Abc");
	g_Module.ScriptInfo.SetContactInfo("Bruh");
	cateMenu.Unregister();
	cateMenu.Register();
	cateMenu.SetTitle("[ChatSounds Menu]\n" + "Annoying bastards." + "\n");
	g_Hooks.RegisterHook(Hooks::Player::ClientSay, @ClientSay);
	g_SoundList.deleteAll();
	g_ChatTimes.deleteAll();
	g_SoundListKeys = {};
	g_Pitch.deleteAll();
	ReadSounds();
	for (uint i = 0; i < g_SoundListKeys.length(); ++i) 
	{
		CChatSound@ data = cast<CChatSound@>(g_SoundList[g_SoundListKeys[i]]);
		cateMenu.AddItem(data.Name,null);
	}
}

void MapInit() 
{
	for (uint i = 0; i < g_SoundListKeys.length(); ++i) 
	{
		CChatSound@ data = cast<CChatSound@>(g_SoundList[g_SoundListKeys[i]]);
		g_Game.PrecacheGeneric("sound/" + data.Sound );
		g_SoundSystem.PrecacheSound(data.Sound);
		if (data.SoundType == 3)
			g_Game.PrecacheModel(data.Sprite);
	}
	
	g_Game.PrecacheModel(g_SpriteName);
	g_Game.PrecacheModel("sprites/saveme.spr");
	g_isSafe = true;
	
	if(b_Stats)
		ChatStatistics();
}

void ReadSounds() 
{
	CChatSound data;
	File@ file = g_FileSystem.OpenFile(g_SoundFile, OpenFile::READ);
	if (file !is null && file.IsOpen()) 
	{
		while(!file.EOFReached()) 
		{
			string sLine;
			file.ReadLine(sLine);
			if (sLine.SubString(0,1) == "#" || sLine.IsEmpty())
			continue;

			array<string> parsed = sLine.Split(" ");
			if (parsed.length() < 3)
			continue;
		
		data.Name = parsed[0];
		data.Sound = parsed[1];
		data.SoundType = atoi(parsed[2]);
		g_SoundListKeys.insertLast(parsed[0]);
		if (atoi(parsed[2]) == 3)
			data.Sprite = parsed[3];
		g_SoundList[parsed[0]] = data;
		}
		file.Close();
	}
}

void cateMenuRespond(CTextMenu@ mMenu, CBasePlayer@ pPlayer, int iPage, const CTextMenuItem@ mItem)
{
	if(mItem !is null)
	{
		PlayChatSounds(string(mItem.m_szName),pPlayer);
	}
}

HookReturnCode ClientSay(SayParameters@ pParams) 
{
	const CCommand@ pArguments = pParams.GetArguments();
	CBasePlayer@ pPlayer = pParams.GetPlayer();
	const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
	if(!g_isSafe )
	{
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[ChatSounds] Please wait until map change, this plugins needs to precache sounds.\n");
		return HOOK_HANDLED;
	}
	if(pPlayer !is null && (pArguments[0].ToLowercase() == "!pt" || pArguments[0] == "/pt"))
	{
		int16 CachePitch = atoi (pArguments[1]);
		CachePitch = ( atoi(pArguments[1]) == 0 ) ? 100 : Math.clamp(g_PitchMin,g_PitchMax,CachePitch);
		string str_Pitch = ( CachePitch == 100 ) ? "default value" : CachePitch;
		g_Pitch[steamId] = Math.clamp(45, 245, atoi(CachePitch));
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[ChatSounds] Now, your default pitch is set to " + str_Pitch + ".");
		pParams.ShouldHide = true;
		return HOOK_HANDLED;
	}
	else if (pArguments.ArgC() > 0) 
	{
		const string soundArg = pArguments.Arg(0).ToLowercase();
		if (g_SoundList.exists(soundArg) || (pArguments[0] == "!ls" || pArguments[0] == "/ls" || pArguments[0] == "!LS" || pArguments[0] == "/LS")) 
		{
			if (!g_ChatTimes.exists(steamId))
				g_ChatTimes[steamId] = 0;

			uint t = uint(g_EngineFuncs.Time()*1000);
			uint d = t - uint(g_ChatTimes[steamId]);

			if (d < g_Delay) 
			{
				float w = float(g_Delay - d) / 1000.0f;
				g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCENTER, "Wait " + format_float(w) + " seconds\n");

				if ( pArguments.ArgC() == 1 )
					pParams.ShouldHide = true;

				return HOOK_HANDLED;
			}
			else
			{
				if( pPlayer !is null && (pArguments[0] == "!ls" || pArguments[0] == "/ls" || pArguments[0] == "!LS" || pArguments[0] == "/LS"))
				{
					cateMenu.Open(0, 0, pPlayer);
					pParams.ShouldHide = true;
					g_ChatTimes[steamId] = t;
					return HOOK_HANDLED;
				}
				if (atoi( pArguments[1]) != 0)
				{
					g_SoundPitch = atoi(pArguments[1]);
					g_SoundPitch = Math.clamp(g_PitchMin,g_PitchMax,g_SoundPitch);
				}
				else
					g_SoundPitch = g_Pitch.exists(steamId) ? int(g_Pitch[steamId]): 100;
				PlayChatSounds(soundArg,pPlayer);
				
				g_ChatStatistics.AddStatistics(soundArg);
				
				g_ChatTimes[steamId] = t;
				if ( pArguments.ArgC() == 1 ) 
					return HOOK_HANDLED;
				else 
					return HOOK_CONTINUE;
			}
		}
	}
  return HOOK_CONTINUE;
}

void PlayChatSounds(string sound,CBasePlayer@ pPlayer)
{
	const string steamId = g_EngineFuncs.GetPlayerAuthId(pPlayer.edict());
	const CChatSound@ data = cast<CChatSound@>(g_SoundList[sound]);
	if (data.SoundType == 1) 
	{
		pPlayer.ShowOverheadSprite('sprites/saveme.spr', 72.0f, 3.5f);
	}
	else if (data.SoundType == 3) 
	{
		pPlayer.ShowOverheadSprite(data.Sprite, 72.0f, 3.5f);
	}
	else 
	{
		pPlayer.ShowOverheadSprite( g_SpriteName, 56.0f, 2.25f);
		if (pPlayer.IsAlive() && data.SoundType == 2) 
		{
			if( Math.RandomLong(0, 2) == 0 )
			{
				pPlayer.TakeDamage(g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, 9999.9f, DMG_SHOCK);
				g_PlayerFuncs.SayText(pPlayer, "[ChatSounds] Bad'to luck , annoying little bastard.\n");
			}
		}
	}
	g_SoundSystem.PlaySound(pPlayer.edict(), CHAN_VOICE, data.Sound, 1.0f, 0.4f, 0, g_SoundPitch , 0, true, pPlayer.pev.origin);
	g_SoundPitch = g_Pitch.exists(steamId) ? int(g_Pitch[steamId]): 100;
}

string format_float(float f) 
{
   uint decimal = uint(((f - int(f)) * 10)) % 10;
   return "" + int(f) + "." + decimal;
}

void listsounds(const CCommand@ pArgs) 
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
	g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "AVAILABLE SOUND TRIGGERS\n" + "------------------------\n");
	string sMessage = "";
	for (uint i = 1; i < g_SoundListKeys.length()+1; ++i) 
	{
		sMessage += g_SoundListKeys[i-1] + " | ";
		if (i % 5 == 0) 
		{
			sMessage.Resize(sMessage.Length() -2);
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, sMessage);
			g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "\n");
			sMessage = "";
		}
	}
	if (sMessage.Length() > 2) 
	{
		sMessage.Resize(sMessage.Length() -2);
		g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, sMessage + "\n");
	}
	g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "\n");
}
