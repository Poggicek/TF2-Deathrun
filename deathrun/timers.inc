public Action TimerSwitchTeam(Handle timer, int client)
{
	if(IsValidPlayer(client))
		ChangeClientTeam(client, TEAM_RED);
}

public Action TimerPlayerSpawn(Handle timer, int client)
{

	if(!IsValidPlayer(client)) return;

	if(g_players[client].thirdperson)
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}

	if(!GetClientTeam(client) != TEAM_RED && g_specialRound == SPECIALROUND_SMALL_PLAYER) {
		SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.7);
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 0.7 * 18);
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
			for(int client = 0; client <= MaxClients; client++)
			{
				if(!IsValidPlayer(client) || GetClientTeam(client) == TEAM_SPECTATOR) continue;

				if(TF2_GetPlayerClass(client) == TFClass_Unknown) TF2_SetPlayerClass(client, TFClass_Scout);

				ChangeClientTeam_Safe(client, TEAM_RED);
			}

			PickRandomDeath();
		}
	} else {
		tick = 0;
	}

	bool nearEntity[4096];

	for(int client = 0; client <= MaxClients; client++)
	{
		if(!IsValidPlayer(client) || !IsPlayerAlive(client)) continue;

		float pCoords[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", pCoords);

		for(int i = 0; i < GetMaxEntities(); i++)
		{
			float coords[3];
			coords[0] = g_aBreakables.Get(i, 0);
			coords[1] = g_aBreakables.Get(i, 1);
			coords[2] = g_aBreakables.Get(i, 2);

			if(g_aBreakables.Get(i, 3) == 1 && IsValidEntity(i))
			{
				if(GetVectorDistance(pCoords, coords) < 200)
				{
					SetEntityRenderMode(i, RENDER_TRANSCOLOR);
					SetEntityRenderColor(i, 254, 180, 180, 254);
					nearEntity[i] = true;
				} else {
					int r, g, b, a;
					GetEntityRenderColor(i, r, g, b, a);
					if(r == 254 && g == 180 && b == 180 && a == 254 && !nearEntity[i])
					{
						SetEntityRenderMode(i, RENDER_NORMAL);
						SetEntityRenderColor(i, 255, 255, 255, 255);
						nearEntity[i] = false;
					}
				}
			}
		}
	}
}