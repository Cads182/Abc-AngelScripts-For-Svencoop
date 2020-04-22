void ShowMotd(CBasePlayer@ pPlayer, string&in strTitle, string&in strContent) 
{
	NetworkMessage motd1( MSG_ONE, NetworkMessages::ServerName, pPlayer.edict() );
		motd1.WriteString( strTitle );
	motd1.End();
	
	NetworkMessage motd2( MSG_ONE, NetworkMessages::MOTD, pPlayer.edict() );
		motd2.WriteByte( 1 );
		motd2.WriteString( strContent );
	motd2.End();
}

void ChangeServerName(CBasePlayer@ pPlayer, string&in strTitle)
{
	NetworkMessage motd1( MSG_ONE, NetworkMessages::ServerName, pPlayer.edict() );
		motd1.WriteString( strTitle );
	motd1.End();
}
