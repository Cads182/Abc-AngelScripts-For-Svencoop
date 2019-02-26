class item_dmweaponpack : ScriptBaseEntity
{
	int m_iAmmo1,m_iAmmo2;
	string m_strpWeapon;
	float m_fDeathTime;
	CBasePlayerWeapon@ pWeapon = null;
	void Spawn() 
	{
		Precache();
		BaseClass.Spawn();
		self.pev.movetype = MOVETYPE_TOSS;
		self.pev.solid = SOLID_TRIGGER;
		g_EntityFuncs.SetModel(self, "models/w_weaponbox.mdl");
		g_EntityFuncs.SetSize(self.pev, Vector(-16, -16, 0), Vector(16, 16, 56));
		SetTouch( TouchFunction( Touch ) );
		SetThink( ThinkFunction( Think ) );
		m_fDeathTime = g_Engine.time + 120.0;
		self.pev.nextthink = g_Engine.time + m_fDeathTime + 0.01;
	}

	void Precache() 
	{
		g_Game.PrecacheModel("models/w_weaponbox.mdl");
		g_SoundSystem.PrecacheSound("items/9mmclip1.wav");
	}

	void Think()
	{
		if (m_fDeathTime < g_Engine.time)
			Die();
	}

	void Die() 
	{
		g_EntityFuncs.Remove(self);
	}

	void Touch(CBaseEntity@ pOther) 
	{
		if (pOther is null) return;
		if (!pOther.IsPlayer()) return;
		if (pOther.pev.health <= 0) return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		if( m_iAmmo1 != 0)
			pPlayer.GiveAmmo(m_iAmmo1, pWeapon.pszAmmo1(), pWeapon.iMaxAmmo1());
		if( m_iAmmo2 != 0)
			pPlayer.GiveAmmo(m_iAmmo2, pWeapon.pszAmmo2(), pWeapon.iMaxAmmo2());
		if( pWeapon !is null )
		{
			CBasePlayerItem@ pItem = cast<CBasePlayerItem@>(pWeapon);
			pPlayer.AddPlayerItem(pItem);
		}
		g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM);
		Die();
	}
}