#pragma semicolon 1

#define DEBUG

#define TEAM_SPECTATOR 1
#define TEAM_RED 2
#define TEAM_BLUE 3

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>
#include <colorvariables>
#include <smlib>
#include lifeEnhancer/lifeEnhancer.sp

#pragma newdecls required

#include deathrun/globals.inc
#include deathrun/tools.inc
#include deathrun/timers.inc
#include deathrun/player.inc
#include deathrun/sdkhooks.inc
#include deathrun/commands.inc

public Plugin myinfo =
{
  name = "Deathrun",
  author = "Poggu",
  description = "Funplay Deathrun Plugin",
  version = "0.1"
};

public void OnPluginStart()
{
  LoadTranslations("deathrun.phrases");
  // FormatEx(message, sizeof(message), "t", "kokot xdd", client);


  /*
    Event Hooks
  */

  HookEvent("teamplay_round_start", RoundStart_Post, EventHookMode_Post);
  // HookEvent("player_connect", OnFullConnect_Pre, EventHookMode_Pre);
  HookEvent("player_spawn", PlayerSpawn_Post, EventHookMode_Post);
  HookEvent("player_team", PlayerChangeTeam_Pre, EventHookMode_Post);
  // HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);

  /*
    Listeners
  */

  AddCommandListener(OnPlayerJoinTeam, "jointeam");
  AddCommandListener(OnPlayerJoinTeam, "changeteam");
  AddCommandListener(OnSuicide, "explode");
  AddCommandListener(OnSuicide, "kill");
  AddCommandListener(OnSayMessage,"say");
  AddCommandListener(OnSayMessage,"say_team");

  /*
    Commands
  */

  RegAdminCmd("sm_restart", RestartRound_Cmd, ADMFLAG_ROOT, "Restart round");
  RegConsoleCmd("sm_tp", ThirdPerson_Cmd, "Enable thirdperson");
  RegConsoleCmd("sm_fp", FirstPerson_Cmd, "Disable thirdperson");

  /*
    TIMERS
  */

  CreateTimer(0.1, GameTimer, _, TIMER_REPEAT);

  for(int client = 0; client <= MaxClients; client++)
  {
      if(IsValidPlayer(client))
      {
          PlayerConnect(client);
      }
  }
}

public void OnClientPutInServer(int client)
{
  PlayerConnect(client);
}

public void OnPluginEnd()
{
  UnhookEvent("teamplay_round_start", RoundStart_Post, EventHookMode_Post);
}

public void OnMapStart()
{
  SetConvars();
}