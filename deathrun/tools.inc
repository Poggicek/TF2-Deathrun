stock bool IsValidPlayer(int client, bool alive = false) {
    if (client < 1 || client > MaxClients || !IsClientConnected(client))
        return false;
    return (IsClientInGame(client) && (!alive || IsPlayerAlive(client)));
}

stock void SetCloak(int client, float value)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", value);
}

stock void SetDrink(int client, float value)
{
	SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", value);
}

stock void SetCharge(int client, float value)
{
	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", value);
}


stock void TF2_SwitchtoSlot(int client, int slot)
{

    char nameTarget[128];
    int wep = GetPlayerWeaponSlot(client, slot);
    if (wep != -1 && GetEntityClassname(wep, nameTarget, sizeof(nameTarget)))
    {
        FakeClientCommandEx(client, "use %s", nameTarget);
    }
}

stock void ChangeClientTeam_Safe(int client, int team)
{
  SetEntProp(client, Prop_Send, "m_lifeState", 2);
  ChangeClientTeam(client, team);
  SetEntProp(client, Prop_Send, "m_lifeState", 0);
  TF2_RespawnPlayer(client);
}

stock void SetConvars()
{
  SetConVarInt(FindConVar("tf_arena_use_queue"), 0);
  SetConVarInt(FindConVar("mp_teams_unbalance_limit"), 0);
  SetConVarInt(FindConVar("mp_autoteambalance"), 0);
  SetConVarInt(FindConVar("tf_arena_first_blood"), 0);
  SetConVarInt(FindConVar("mp_scrambleteams_auto"), 0);
  SetConVarInt(FindConVar("tf_scout_air_dash_count"), 0);
}

stock void TF2_RestartRound()
{
  int iEnt = -1;
  iEnt = FindEntityByClassname(iEnt, "game_round_win");

  if (iEnt < 1)
  {
    iEnt = CreateEntityByName("game_round_win");
    if (IsValidEntity(iEnt))
      DispatchSpawn(iEnt);
    else
    {
      return;
    }
  }

  SetVariantInt(0);
  AcceptEntityInput(iEnt, "SetTeam");
  AcceptEntityInput(iEnt, "RoundWin");
}

stock void PickRandomDeath()
{
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
}