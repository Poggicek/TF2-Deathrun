#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <colorvariables>
#include <smlib>

#define GHOST_USSOLIDFLAGS ((1 << 1)|(1 << 2))

Handle g_hGhostCookie = INVALID_HANDLE;

int g_iGhosts[MAXPLAYERS + 1];
float g_lastVec[MAXPLAYERS + 1][3];
float g_lastAng[MAXPLAYERS + 1][3];

void Ghost_OnPluginStart()
{
	HookEvent("player_death", Ghost_OnPlayerDeath);
	HookEvent("player_changeclass", Ghost_OnPlayerClassChange);
	HookEvent("player_spawn", Ghost_OnPlayerSpawn);
	HookEvent("teamplay_round_win", Ghost_OnEndRound);
	HookEvent("teamplay_round_active", Ghost_OnStartRound);
	HookEvent("arena_round_start", Ghost_OnStartRound);

	g_hGhostCookie = RegClientCookie("ghost_mode", "Enables/disables ghost mode", CookieAccess_Protected);
}

bool CanBeGhost(int client)
{
	char cookie[10];
	GetClientCookie_Safe(client, g_hGhostCookie, cookie, sizeof(cookie));
	if(cookie[0] == '\0') return true;
	return view_as<bool>(StringToInt(cookie));
}

public Action Ghost_OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidPlayer(client)) return Plugin_Continue;
	if((GameRules_GetRoundState() != RoundState_RoundRunning && GameRules_GetRoundState() != RoundState_Stalemate)) return Plugin_Continue;
	if(!CanBeGhost(client)) return Plugin_Continue;
	if(TF2_GetPlayerDesiredClass(client) == TFClass_Unknown) return Plugin_Continue;

	g_iGhosts[client] = 1;
	GetClientAbsOrigin(client, g_lastVec[client]);
	GetClientAbsAngles(client, g_lastAng[client]);

	CreateTimer(0.1, GhostTimer_Respawn, GetClientUserId(client));

	return Plugin_Continue;
}

public Action Ghost_OnPlayerClassChange(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidPlayer(client)) return Plugin_Continue;
	if(IsPlayerAlive(client)) g_iGhosts[client] = 0;

	return Plugin_Continue;
}

public Action Ghost_OnEndRound(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 0; client <= MaxClients; client++)
	{
		g_iGhosts[client] = 0;
	}
}

public Action Ghost_OnStartRound(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 0; client <= MaxClients; client++)
	{
		g_iGhosts[client] = 0;
	}
}

public Action Ghost_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(!IsValidPlayer(client)) return Plugin_Continue;
	if ((GameRules_GetRoundState() != RoundState_RoundRunning && GameRules_GetRoundState() != RoundState_Stalemate) || !IsPlayerAlive(client) || GetClientTeam(client) <= TEAM_SPECTATOR || g_iGhosts[client] != 1)
	{
		if(IsPlayerAlive(client))
		{
			if (GetEntProp(client, Prop_Send, "m_CollisionGroup") == 1) SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
			SetEntProp(client, Prop_Send, "m_usSolidFlags", (GetEntProp(client, Prop_Send, "m_usSolidFlags") & ~GHOST_USSOLIDFLAGS));
		}

		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, _, _, _, _);
		SetWearableInvis(client, false);
		g_iGhosts[client] = 0;
		return Plugin_Continue;
	}

	TeleportEntity(client, g_lastVec[client], g_lastAng[client], NULL_VECTOR);
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 1);
	SetEntProp(client, Prop_Send, "m_usSolidFlags", (GetEntProp(client, Prop_Send, "m_usSolidFlags") | GHOST_USSOLIDFLAGS));
	SetEntProp(client, Prop_Send, "m_lifeState", 2);
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | (1 << 3));
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, _, _, _, 100);
	SetWearableInvis(client);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
	SetEntPropEnt(client, Prop_Send, "m_hLastWeapon", -1);
	g_iGhosts[client] = 2;

	//CreateTimer(0.1, Timer_Thirdperson, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Handled;
}

stock void GetClientCookie_Safe(int client, Handle cookie, char[] buffer, int maxlen)
{
	if (!AreClientCookiesCached(client))
	{
		strcopy(buffer, maxlen, "1");
		return;
	}
	GetClientCookie(client, cookie, buffer, maxlen);
}

public Action GhostTimer_Respawn(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidPlayer(client)) return;

	if (GameRules_GetRoundState() != RoundState_RoundRunning && GameRules_GetRoundState() != RoundState_Stalemate)
	{
		g_iGhosts[client] = 0;
		return;
	}

	if(TF2_GetPlayerDesiredClass(client) != TFClass_Unknown) TF2_RespawnPlayer(client);
}