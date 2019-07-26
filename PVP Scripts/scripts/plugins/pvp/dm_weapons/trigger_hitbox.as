class trigger_hitbox : ScriptBaseMonsterEntity
{
    private Vector m_vecMins,m_vecMaxs;
    CBaseEntity@ OwnerEnt
	{
		get const	{ return g_EntityFuncs.Instance( pev.owner ); }
	}
	
	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/player.mdl" );
		
		if( pev.owner !is null )
		{
			pev.movetype	= MOVETYPE_FOLLOW;
			@pev.aiment		= @pev.owner;
			pev.solid		= SOLID_BBOX;
			pev.colormap	= pev.owner.vars.colormap;

            m_vecMins = pev.owner.vars.mins;
            m_vecMaxs = pev.owner.vars.maxs;
            g_EntityFuncs.SetSize( pev, m_vecMins, m_vecMaxs );
		}
		g_EntityFuncs.SetOrigin( self, pev.origin );
	}
	
	void Precache()
	{
		BaseClass.Precache();
		g_Game.PrecacheModel( self, "models/player.mdl" );
		g_Game.PrecacheModel( self, "models/playert.mdl" );
	}

    int TakeDamage(entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType)
    {
        BaseClass.TakeDamage( pevInflictor,  pevAttacker, flDamage, bitsDamageType);
        CBasePlayer@ pPlayer = cast<CBasePlayer@>(g_EntityFuncs.Instance(self.pev.owner.vars));
        CBaseEntity@ pAttacker = cast<CBaseEntity@>(g_EntityFuncs.Instance(pevAttacker));
        CBaseEntity@ pInflictor = cast<CBaseEntity@>(g_EntityFuncs.Instance(pevInflictor));
        CBasePlayer@ atkPlayer = cast<CBasePlayer@>(pAttacker);
        if (pPlayer !is null && pAttacker !is null && pInflictor!is null && ((pPlayer.Classify() == pAttacker.Classify())))
        {
                if( pPlayer !is pAttacker )
                        return HOOK_CONTINUE;
        }
        if(TakeDamage::TakeDamege(pPlayer,pAttacker,pInflictor,flDamage,bitsDamageType))
        {
            g_HitBox.DestroyHitBox( pPlayer );

            if(g_DMDropRule.IsDrop())
                g_DMDropRule.DropIt(pPlayer);
            
            g_Arcade.ArcadeRespwan( atkPlayer );
            
            g_SvenZM.CritKill( atkPlayer, bitsDamageType);
        }
        
        g_SvenZM.WeaponShock( pPlayer , pPlayer.pev.dmg_take , atkPlayer );
        
        flDamage = 0;

        return 0;
    } 
}