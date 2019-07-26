/***
	Made by Dr.Abc
***/

class info_ctfspawn : ScriptBaseEntity
{	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if(szKey == "team_no")
		{
			CBaseEntity@ pSpwan = g_EntityFuncs.Create("info_player_deathmatch", self.GetOrigin(), self.pev.angles, false);
			pSpwan.pev.spawnflags = 8;
			if(szValue == 2)
			{
				pSpwan.pev.message = "team2";
			}
			else if (szValue == 1)
			{
				pSpwan.pev.message = "team1";
			}
			
			CBaseEntity@ nSpwan = g_EntityFuncs.Create("info_player_deathmatch", self.GetOrigin(), self.pev.angles, false);
			nSpwan.pev.spawnflags = 8;
			nSpwan.pev.message = "normalplayer";
			
			g_EntityFuncs.Remove(self);
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}
}