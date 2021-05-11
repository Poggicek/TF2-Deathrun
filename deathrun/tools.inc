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

  int aClients[MAXPLAYERS + 1];
  int players = 0;

  for(int i = 0; i < MAXPLAYERS + 1; i++)
  {
    if(IsValidPlayer(i) && g_iDeath != i && GetClientTeam(i) != TEAM_SPECTATOR)
    {
      aClients[players] = i;
      players++;
    }
  }

  int randomPlayer = GetRandomInt(0, players - 1);
  int client = aClients[randomPlayer];

  if(players < 1)
  {
    CPrintToChatAll("%s Not enough players! (At least 2)", TAG);
    return;
  }

  if(IsValidPlayer(client))
  {
    g_iDeath = client;
    if(TF2_GetPlayerClass(client) == TFClass_Unknown) TF2_SetPlayerClass(client, TFClass_Scout);

    ChangeClientTeam_Safe(client, TEAM_BLUE);
    CPrintToChatAll("%s %t", TAG, "select death", _GetClientName(client));
    return;
  } else {
    PrintToChatAll("Invalid player!!");
    return;
  }
}

public bool TraceFilterNotSelf(int entityhit, int mask, any entity)
{
  if(entityhit >= 0 && entityhit != entity)
  {
    return true;
  }
  return false;
}