#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <colorvariables>
#include <smlib>

#define GHOST_USSOLIDFLAGS ((1 << 1)|(1 << 2))

Handle g_hGhostCookie = INVALID_HANDLE;

float g_lastVec[MAXPLAYERS + 1][3];
float g_lastAng[MAXPLAYERS + 1][3];

enum struct GhostOptions
{
	int id;

	bool noclip;
}

GhostOptions g_ghostOptions[MAXPLAYERS + 1];

void Ghost_OnPluginStart()
{
	PrintToServer("[+] Ghost module loaded");

	HookEvent("player_death", Ghost_OnPlayerDeath);
	HookEvent("player_changeclass", Ghost_OnPlayerClassChange);
	HookEvent("player_spawn", Ghost_OnPlayerSpawn);
	HookEvent("teamplay_round_win", Ghost_OnEndRound);
	HookEvent("teamplay_round_active", Ghost_OnStartRound);
	HookEvent("arena_round_start", Ghost_OnStartRound);

	RegConsoleCmd("sm_ghost", Ghost_Cmd, "Open ghost menu");

	AddNormalSoundHook(Ghost_SoundHook);

	g_hGhostCookie = RegClientCookie("ghost_mode", "Enables/disables ghost mode", CookieAccess_Protected);
}

public Action Ghost_SoundHook(int iClients[64], int &iNumClients, char strSample[PLATFORM_MAX_PATH], int &iEntity, int &iChannel, float &flVolume, int &iLevel, int &iPitch, int &iFlags)
{
	if(IsValidPlayer(iEntity) && g_iGhosts[iEntity])
	{
		if(StrContains(strSample, "footsteps", false) != -1 || StrContains(strSample, "weapons", false) != -1 || StrContains(strSample, "pain", false) != -1)
			return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Ghost_SetTransmit(int ent, int client)
{
	if(g_iGhosts[ent] == 2 && IsPlayerAlive(client))
	{
		if(GetClientTeam(client) > 1)
			return Plugin_Handled;
	}

	return Plugin_Continue;
}

bool CanBeGhost(int client)
{
	if(g_iGhosts[client] == 3) return false;

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

	CreateTimer(0.4, GhostTimer_Respawn, GetClientUserId(client));

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

	GhostOptions ghostOptions;
	g_ghostOptions[client] = ghostOptions;

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
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_iGhosts[client] = 0;
		return Plugin_Continue;
	}

	TeleportEntity(client, g_lastVec[client], g_lastAng[client], NULL_VECTOR);
	SetEntProp(client, Prop_Send, "m_CollisionGroup", 1);
	SetEntProp(client, Prop_Send, "m_usSolidFlags", (GetEntProp(client, Prop_Send, "m_usSolidFlags") | GHOST_USSOLIDFLAGS));
	SetEntProp(client, Prop_Send, "m_lifeState", 1);
	SetEntProp(client, Prop_Send, "m_iHideHUD", GetEntProp(client, Prop_Send, "m_iHideHUD") | (1 << 3));
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
	SetEntityRenderMode(client, RENDER_TRANSALPHA);
	SetEntityRenderColor(client, _, _, _, 100);
	SetWearableInvis(client);
	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", -1);
	SetEntPropEnt(client, Prop_Send, "m_hLastWeapon", -1);
	g_iGhosts[client] = 2;

	OpenGhostMenu(client);
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

public int GhostMenu_Handler(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(!IsValidPlayer(client) || g_iGhosts[client] != 2)
			{
				return 0;
			}

			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			if (StrEqual(info, "noclip"))
			{
				g_ghostOptions[client].noclip = !g_ghostOptions[client].noclip;
				SetEntityMoveType(client, g_ghostOptions[client].noclip ? MOVETYPE_NOCLIP : MOVETYPE_WALK);
			}

			OpenGhostMenu(client);
		}

		case MenuAction_DisplayItem:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			char display[32];

			if (StrEqual(info, "noclip"))
			{
				Format(display, sizeof(display), "Noclip [%s]", g_ghostOptions[client].noclip ? "ON": "OFF");
				return RedrawMenuItem(display);
			}
		}

		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

public void OpenGhostMenu(int client)
{
	Menu menu = new Menu(GhostMenu_Handler, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	menu.SetTitle("Ghost Menu\n%T\n", "ghost menu disable", client);
	menu.AddItem("noclip", "Noclip [OFF]");
	menu.ExitButton = true;
	menu.Display(client, 0);
}

public Action Ghost_Cmd(int client, int args)
{
	if(!IsValidPlayer(client) || g_iGhosts[client] != 2) return Plugin_Handled;
	OpenGhostMenu(client);

	return Plugin_Handled;
}


public Action Ghost_OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3])
{
	if(buttons & IN_RELOAD && g_iGhosts[client] == 2)
	{
		if (GetEntProp(client, Prop_Send, "m_CollisionGroup") == 1) SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
		SetEntProp(client, Prop_Send, "m_usSolidFlags", (GetEntProp(client, Prop_Send, "m_usSolidFlags") & ~GHOST_USSOLIDFLAGS));

		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, _, _, _, _);
		SetWearableInvis(client, false);
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_iGhosts[client] = 3;
		ChangeClientTeam(client, TEAM_SPECTATOR);
		ChangeClientTeam(client, TEAM_RED);
	}
}