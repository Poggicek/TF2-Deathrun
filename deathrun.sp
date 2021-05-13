#pragma semicolon 1

#define DEBUG

#define TEAM_SPECTATOR 1
#define TEAM_RED 2
#define TEAM_BLUE 3

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <colorvariables>
#include <smlib>
#include <geoip>
#include <clientprefs>
#include <steamtools>
#include lifeEnhancer/lifeEnhancer.sp

#pragma newdecls required

#include deathrun/globals.inc
#include deathrun/configs.inc
#include deathrun/tools.inc
#include deathrun/menus.inc
#include deathrun/timers.inc
#include deathrun/player.inc
#include deathrun/sdkhooks.inc
#include deathrun/commands.inc

#include "dr/ghost.sp"
#include "dr/grab.sp"
#include "dr/adminmenu.sp"

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

  g_aBreakables = new ArrayList(4);
  for(int i = 0; i < GetMaxEntities(); i++)
  {
    g_aBreakables.Push(0);
    for(int i2 = 0; i2 < 4; i2++)
      g_aBreakables.Set(i, 0, i2);
  }

  g_hLangCookie = RegClientCookie("client_language", "Sets client language", CookieAccess_Private);
  /*
    Event Hooks
  */

  HookEvent("teamplay_round_start", RoundStart_Post, EventHookMode_Post);
  HookEvent("player_spawn", PlayerSpawn_Post, EventHookMode_Post);
  HookEvent("player_team", PlayerChangeTeam_Pre, EventHookMode_Post);
  HookEvent("player_connect_client", PlayerConnect_Pre, EventHookMode_Pre);
  HookEvent("player_disconnect", PlayerDisconnect_Pre, EventHookMode_Pre);

  HookEntityOutput("func_button", "OnPressed", Button_Pressed);
  HookEntityOutput("func_button", "OnDamaged", Button_Damaged);
  // HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);

  /*
    Listeners
  */

  AddCommandListener(OnPlayerJoinTeam, "jointeam");
  AddCommandListener(OnPlayerJoinTeam, "changeteam");
  AddCommandListener(OnSuicide, "explode");
  AddCommandListener(OnSuicide, "kill");
  AddCommandListener(OnSayMessage, "say");
  AddCommandListener(OnSayMessage, "say_team");
  AddCommandListener(OnVoiceMenu, "voicemenu");

  /*
    Commands
  */

  RegAdminCmd("sm_restart", RestartRound_Cmd, ADMFLAG_ROOT, "Restart round");
  RegConsoleCmd("sm_tp", ThirdPerson_Cmd, "Enable thirdperson");
  RegConsoleCmd("sm_fp", FirstPerson_Cmd, "Disable thirdperson");
  RegConsoleCmd("sm_lang", Language_Cmd, "Sets lanaguage");
  RegConsoleCmd("sm_language", Language_Cmd, "Sets lanaguage");
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

  Ghost_OnPluginStart();
  Grab_OnPluginStart();
  AdminMenu_OnPluginStart();
}

public void OnEntityCreated(int entity, const char[] classname)
{
  if(StrEqual(classname, "func_breakable") || StrEqual(classname, "func_breakable_surf"))
    SDKHook(entity, SDKHook_SpawnPost, _OnEntitySpawned);
}

public void OnEntityDestroyed(int entity)
{
  if(IsValidEntity(entity) && IsValidEdict(entity))
  {
    for(int i = 0; i < 4; i++)
      g_aBreakables.Set(entity, 0, i);
  }
}

public void _OnEntitySpawned(int entity)
{
  if(IsValidEntity(entity) && IsValidEdict(entity))
  {
    float coords[3];
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", coords);
    g_aBreakables.Set(entity, view_as<int>(coords[0]), 0);
    g_aBreakables.Set(entity, view_as<int>(coords[1]), 1);
    g_aBreakables.Set(entity, view_as<int>(coords[2]), 2);
    g_aBreakables.Set(entity, 1, 3);
  }
}

public void OnClientAuthorized(int client)
{
  char ip[16], country[45];

  GetClientIP(client, ip, sizeof(ip));
  GeoipCountry(ip, country, sizeof(country));

  if(country[0] == '\0') country = "Unknown";

  CPrintToChatAll("%t", "player serverjoin", _GetClientName(client), country);
}

public void OnClientPutInServer(int client)
{
  PlayerConnect(client);
}

public void OnPluginEnd()
{
  UnhookEvent("teamplay_round_start", RoundStart_Post, EventHookMode_Post);
  g_aBreakables.Clear();
}

public void OnMapStart()
{
  SetConvars();

  // KV Configs
  ManageConfigs();

  g_fLastRoundStart = 0.0;
  g_iDeath = -1;
  g_freeRun = false;
  for(int i = 0; i < GetMaxEntities(); i++)
  {
    for(int i2 = 0; i2 < 4; i2++)
      g_aBreakables.Set(i, 0, i2);
  }

  Steam_SetGameDescription("FunPlay DeathRun");
  AddServerTag("deathrun");
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	Grab_OnPlayerRunCmd(client, buttons, mouse);
	Ghost_OnPlayerRunCmd(client, buttons, impulse, vel, angles);
}