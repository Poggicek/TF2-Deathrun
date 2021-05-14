#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

char SR_Names[][] = {
	"specialround none",
	"specialround longrespawn",
	"specialround highspeed",
	"specialround smallplayer",
	"specialround bhop",
};

public void SpecialRounds_OnPluginStart()
{
	HookEvent("teamplay_round_start", SpecialRounds_RoundStart, EventHookMode_Post);

	RegAdminCmd("sm_forcespecialround", SpecialRounds_ForceCmd, ADMFLAG_KICK);
}

public Action SpecialRounds_ForceCmd(int client, int args)
{
	if(IsValidPlayer(client))
	{
		g_forcedSpecialRound = true;
		CPrintToChatAll("%s %t", TAG, "specialround force");
	}

	return Plugin_Handled;
}


public Action SpecialRounds_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	g_specialRound = SPECIALROUND_NONE;

	if(GetRandomInt(0, 10) == 0 || g_forcedSpecialRound)
	{
		g_forcedSpecialRound = false;
		g_specialRound = view_as<SpecialRound>(GetRandomInt(1, 5 - 1));
		CPrintToChatAll("%s %t", TAG, SR_Names[view_as<int>(g_specialRound)]);

		switch(g_specialRound)
		{
			case SPECIALROUND_SMALL_PLAYER:
			{
				for(int client = 0; client <= MaxClients; client++)
				{
					if(!IsValidPlayer(client, true) || GetClientTeam(client) != TEAM_RED) continue;

					SetEntPropFloat(client, Prop_Send, "m_flModelScale", 0.7);
					SetEntPropFloat(client, Prop_Send, "m_flStepSize", 0.7 * 18);
				}
			}
			case SPECIALROUND_HIGH_SPEED:
			{
				for(int client = 0; client <= MaxClients; client++)
				{
					if(!IsValidPlayer(client, true) || GetClientTeam(client) != TEAM_RED) continue;

					SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", g_fMaxRunnerSpeedSpecialRound);
				}
			}
		}
	}
}