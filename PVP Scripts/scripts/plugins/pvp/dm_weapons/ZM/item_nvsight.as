class item_nvsight : ScriptBasePlayerItemEntity
{	
	private Vector color = Vector (0,203,17);
	private CBasePlayer@ m_pPlayer = null;
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) == true )
		{
			@m_pPlayer = pPlayer;
			g_PlayerFuncs.ScreenFade( pPlayer, color, 0.01, 0.5, 64, FFADE_OUT | FFADE_STAYOUT );
			return true;
		}
		return false;
	}
	
	void Spwan()
	{
		Precache();
		pev.movetype = MOVETYPE_FLY;
		
		g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "sound/weapons/desert_eagle_sight.wav", 1.0, ATTN_NORM, 0, 98 + Math.RandomLong( 0, 3 ) );
		g_EntityFuncs.SetModel( self, "model/w_rad.mdl" );
		BaseClass.Spawn();
		
		pev.nextthink = g_Engine.time;
	}
	
	void Precache()
	{
		g_Game.PrecacheModel( "model/w_rad.mdl" );
		g_Game.PrecacheModel( "model/w_radt.mdl" );
		g_Game.PrecacheModel( "sprites/iunknown.spr" );
		g_SoundSystem.PrecacheSound( "sound/weapons/desert_eagle_sight.wav" );
		BaseClass.Precache();
	}
	
	void Think()
	{
		BaseClass.Think();
		g_DMUtility.te_NVSight( m_pPlayer , m_pPlayer.EyePosition() );
		pev.nextthink = g_Engine.time + 0.1f;
	}
}

void RegisterHumanNV()
{
	g_ItemRegistry. RegisterItem("item_nvsight", "sprites/iunknown.spr" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_nvsight", "item_nvsight" );
	g_DMEntityList.insertLast("item_nvsight");
}