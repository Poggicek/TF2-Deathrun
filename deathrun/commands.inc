public Action RestartRound_Cmd(int client, int args)
{
	CPrintToChatAll("%s %t", TAG, "round restart");

	TF2_RestartRound();
	return Plugin_Handled;
}

public Action ThirdPerson_Cmd(int client, int args)
{
	if(IsValidPlayer(client))
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		g_players[client].thirdperson = true;
	}

	return Plugin_Handled;
}

public Action FirstPerson_Cmd(int client, int args)
{
	if(IsValidPlayer(client))
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		g_players[client].thirdperson = false;
	}

	return Plugin_Handled;
}

public Action Language_Cmd(int client, int args)
{
	if(IsValidPlayer(client))
	{
		LanguageMenu(client);
	}

	return Plugin_Handled;
}