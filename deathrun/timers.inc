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

public Action GameTimer(Handle timer)
{
	static int tick;
	int players = GetClientCount(true);
	if(GameRules_GetRoundState() == RoundState_Pregame && players >= 2)
	{
		tick++;
		if(tick > 2)
		{
			int randomPlayer = GetRandomInt(1, players);
			if(IsValidPlayer(randomPlayer))
			{
				g_iDeath = randomPlayer;
				ChangeClientTeam_Safe(randomPlayer, TEAM_BLUE);
			}
		}
	} else {
		tick = 0;
	}
}