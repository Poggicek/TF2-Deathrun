void PlayerConnect(int client)
{
	Player player;
	player.id = client;

	g_players[client] = player;

	//SetClientLanguage(client, GetLanguageByCode("en"));

	int players = GetClientCount(true);

	if(players <= 2)
		TF2_RestartRound();

	//ChangeClientTeam(client, TEAM_RED);

	// Hooks
	SDKHook(client, SDKHook_PreThink, OnPlayerThink);
	SDKHook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKHook(client, SDKHook_SetTransmit, Ghost_SetTransmit);

	char langCode[4];
	GetClientCookie(client, g_hLangCookie, langCode, sizeof(langCode));

	if(strlen(langCode) && GetLanguageByCode(langCode)>=0)
	{
		SetClientLanguage(client, GetLanguageByCode(langCode));
	}
}

void PlayerDisconnect(int client)
{
	Player player;
	player.grabbing = INVALID_ENT_REFERENCE;

	g_players[client] = player;

	CPrintToChatAll("%t", "player serverleave", _GetClientName(client));

	// Hooks
	SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
	SDKUnhook(client, SDKHook_GetMaxHealth, OnGetMaxHealth);
	SDKUnhook(client, SDKHook_SetTransmit, Ghost_SetTransmit);
}


public void OnPlayerThink(int client)
{
	if(!client || !IsValidPlayer(client))
			return;

	if(IsPlayerAlive(client))
	{
		NeutralizeClass(client);
	} else if(g_iGhosts[client] == 2) {
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 300.0);
	}
}

public Action OnGetMaxHealth(int client, int &maxhealth)
{
	maxhealth = 150;
	return Plugin_Changed;
}

void NeutralizeClass(int client)
{
	if(GetClientTeam(client) != TEAM_SPECTATOR)
		SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", GetClientTeam(client) == TEAM_RED ? (g_specialRound == SPECIALROUND_HIGH_SPEED ? g_fMaxRunnerSpeedSpecialRound : g_fMaxRunnerSpeed) : g_fMaxDeathSpeed);

	if(TF2_GetPlayerClass(client) == TFClass_Spy)
		SetCloak(client, 1.0);

	if(TF2_GetPlayerClass(client) == TFClass_Scout)
		SetDrink(client, 1.0);

	if((TF2_GetPlayerClass(client) == TFClass_DemoMan) && (!TF2_IsPlayerInCondition(client, TFCond_Charging)))
		SetCharge(client, 1.0);
}