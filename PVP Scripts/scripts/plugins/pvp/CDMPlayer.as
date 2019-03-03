class CDMPlayer : ScriptBaseEntity
{
	int IRelationship( CBaseEntity@ pTarget )
	{
		if ( pTarget.Classify() == CLASS_BARNACLE )
			return R_NM;

		return self.IRelationship( pTarget );
	}
}