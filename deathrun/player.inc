void PlayerConnect(int client)
{
	Player player;
	player.id = client;

	g_players[client] = player;

	SetClientLanguage(client, GetLanguageByCode("en"));
	CPrintToChatAll("%t", "player serverjoin", _GetClientName(client));

	int players = GetClientCount(true);

	if(players <= 2)
		TF2_RestartRound();

	//ChangeClientTeam(client, TEAM_RED);

	// Hooks
	SDKHook(client, SDKHook_PreThink, OnPlayerThink);
}

void PlayerDisconnect(int client)
{
	Player player;
	g_players[client] = player;

	CPrintToChatAll("%t", "player serverleave", _GetClientName(client));

	// Hooks
	SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
}


public void OnPlayerThink(int client)
{
	if(!client || !IsValidPlayer(client))
			return;

	if(IsPlayerAlive(client))
	{
		NeutralizeClass(client);
	}
}

void NeutralizeClass(int client)
{

	//PrintToChatAll("THINK");
	if(GetClientTeam(client) != TEAM_SPECTATOR)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetClientTeam(client) == TEAM_RED ? g_fMaxRunnerSpeed : g_fMaxDeathSpeed);

	if(TF2_GetPlayerClass(client) == TFClass_Spy)
		SetCloak(client, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Scout)
		SetDrink(client, 1.0);

	if((TF2_GetPlayerClass(client) == TFClass_DemoMan) && (!TF2_IsPlayerInCondition(client, TFCond_Charging)))
		SetCharge(client, 1.0);
}