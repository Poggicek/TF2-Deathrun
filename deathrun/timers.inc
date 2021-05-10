public Action TimerSwitchTeam(Handle timer, int client)
{
	if(IsValidPlayer(client))
		ChangeClientTeam(client, TEAM_RED);
}

public Action TimerPlayerSpawn(Handle timer, int client)
{
	if(IsValidPlayer(client) && g_players[client].thirdperson)
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}