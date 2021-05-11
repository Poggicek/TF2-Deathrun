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

	g_freeRun = false;
	if(g_fLastRoundStart >= GetEngineTime()) return Plugin_Continue;

	g_fLastRoundStart = GetEngineTime() + 1.0;

	for(int client = 0; client <= MaxClients; client++)
	{
		if(!IsValidPlayer(client) || GetClientTeam(client) == TEAM_SPECTATOR) continue;

		if(TF2_GetPlayerClass(client) == TFClass_Unknown) TF2_SetPlayerClass(client, TFClass_Scout);

		ChangeClientTeam_Safe(client, TEAM_RED);
	}

	PickRandomDeath();

	return Plugin_Continue;
}

/*
	Player full connect (pre)
*/

public Action OnFullConnect_Pre(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(!IsValidPlayer(client))
        return Plugin_Handled;

    PlayerConnect(client);

    return Plugin_Handled;
}

public Action PlayerConnect_Pre(Event event, const char[] name, bool dontBroadcast)
{
	event.SetBool("silent", true);
	event.BroadcastDisabled = true;

	return Plugin_Changed;
}

public Action PlayerDisconnect_Pre(Event event, const char[] name, bool dontBroadcast)
{
	event.SetBool("silent", true);
	event.BroadcastDisabled = true;

	return Plugin_Changed;
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

public Action PlayerChangeTeam_Pre(Event event, const char[] name, bool dontBroadcast)
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

	event.BroadcastDisabled = true;

	return Plugin_Continue;
}

/*
	Player suicide
*/

public Action OnSuicide(int client, const char[] command, int argc)
{
	return Plugin_Handled;
}

public Action OnSayMessage(int client, const char[] command, int argc)
{
	if(IsChatTrigger())
		return Plugin_Handled;

	char args[10];
	GetCmdArgString(args, sizeof(args));
	StripQuotes(args);
	TrimString(args);

	if(!IsValidPlayer(client, true)) return Plugin_Continue;

	if(strncmp(args, "free", 4, false) == 0 && g_iDeath == client && !g_freeRun)
	{
		CPrintToChatAll("%s %t", TAG, "freerun activated");
		EmitSoundToAll("ui/duel_event.wav");
		g_freeRun = true;
	}

	return Plugin_Continue;
}

/*
	On medic call
*/

public Action OnVoiceMenu(int client, const char[] command, int argc)
{
	if(!IsValidPlayer(client, true)) return Plugin_Continue;

	char args[4];
	GetCmdArgString(args, sizeof(args));

	if(StrEqual(args, "0 0") && IsValidPlayer(client, true) && g_iDeath == client)
	{
		float ang[3], pos[3];
		GetClientEyeAngles(client, ang);
		GetClientEyePosition(client, pos);

		Handle tr = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, TraceFilterNotSelf, client);
		if(TR_DidHit(tr))
		{
			int ent = TR_GetEntityIndex(tr);
			if(IsValidEntity(ent))
			{
				char classname[32];
				GetEntityClassname(ent, classname, sizeof(classname));

				if(StrEqual(classname, "func_button"))
				{
					if(Entity_GetDistance(ent, client) < 100)
					{
						AcceptEntityInput(ent, "Press", client);
						FireEntityOutput(ent, "OnDamaged", client, 0.0);
						delete tr;
						return Plugin_Handled;
					}
				}
			}
		}

		delete tr;
	}

	return Plugin_Continue;
}

public Action Button_Pressed(const char[] output, int caller, int activator, float delay)
{
	if(!IsValidPlayer(activator, true) || !IsValidEntity(caller)) return Plugin_Continue;

	if(g_freeRun && activator == g_iDeath)
	{
		CPrintToChat(activator, "%s %t", TAG, "freerun cannot press button");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Button_Damaged(const char[] output, int caller, int activator, float delay)
{
	if((g_iDeath == activator || activator == -1) && g_freeRun)return Plugin_Handled;

	return Plugin_Continue;
}