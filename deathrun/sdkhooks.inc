/*
	Player spawn (Post)
*/

public Action PlayerSpawn_Post(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidPlayer(client, true))
	{
		for(int i = 0; i < MAX_WEAPON_SLOTS; i++)
		{
			if(i == TFWeaponSlot_Melee) continue;
			TF2_RemoveWeaponSlot(client, i);
		}

		TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);

		CreateTimer(0.2, TimerPlayerSpawn, client);
	}
}

/*
	Round start (Post)
*/

public Action RoundStart_Post(Handle event, const char[] name, bool dontBroadcast)
{

	if(g_fLastRoundStart >= GetGameTime()) return Plugin_Continue;

	g_fLastRoundStart = GetGameTime() + 1.0;

	for(int client = 0; client <= MaxClients; client++)
	{
		if(!IsValidPlayer(client)) continue;

		ChangeClientTeam_Safe(client, TEAM_RED);
	}



	for(int i = 0; i < 1000; i++)
	{
		int players = GetClientCount(true);
		int randomPlayer = GetRandomInt(1, players);

		if(players <= 1)
		{
			CPrintToChatAll("%s Not enough players! (At least 2)", TAG);
			break;
		}

		if(randomPlayer != g_iDeath && IsValidPlayer(randomPlayer))
		{
			g_iDeath = randomPlayer;
			ChangeClientTeam_Safe(randomPlayer, TEAM_BLUE);
			CPrintToChatAll("%s %t", TAG, "select death",_GetClientName(randomPlayer));
			break;
		}
	}

	return Plugin_Continue;
}

/*
	Player connect (pre)
*/

public Action OnFullConnect_Pre(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsValidPlayer(client))
        return Plugin_Handled;

    PlayerConnect(client);

    return Plugin_Handled;
}

/*
	Player disconnect
*/

public void OnClientDisconnect(int client)
{
	PlayerDisconnect(client);
}

/*
	Player change team
*/

public Action OnPlayerJoinTeam(int client, const char[] command, int args)
{
	int oldTeam = GetClientTeam(client);
	char teamString[10];

	GetCmdArg(1, teamString, sizeof(teamString));


	if(oldTeam == TEAM_BLUE || StrEqual(teamString, "blue", false) || StrEqual(teamString, "auto", false)) return Plugin_Handled;

	return Plugin_Continue;
}

public Action PlayerChangeTeam_Pre(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int team = GetEventInt(event, "team");
	if(IsValidPlayer(client) && team == TEAM_BLUE && g_iDeath != client)
	{
		SetEventInt(event, "team", TEAM_RED);
		ChangeClientTeam(client, TEAM_RED);
		CreateTimer(0.1, TimerSwitchTeam, client);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

/*
	Player suicide
*/

public Action OnSuicide(int client, const char[] command, int args)
{
	return Plugin_Handled;
}

public Action OnSayMessage(int client, const char[] command, int argc)
{
	if(IsChatTrigger())
		return Plugin_Handled;

	return Plugin_Continue;
}