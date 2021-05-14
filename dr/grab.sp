#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

public void Grab_OnPluginStart()
{
	PrintToServer("[+] Grab module loaded");

	RegAdminCmd("+grab", Ghost_GrabStartCmd, ADMFLAG_KICK);
	RegAdminCmd("-grab", Ghost_GrabEndCmd, ADMFLAG_KICK);
}

public Action Ghost_GrabStartCmd(int client, int args)
{
	if(IsValidPlayer(client))
	{
		float ang[3], pos[3];
		GetClientEyeAngles(client, ang);
		GetClientEyePosition(client, pos);

		TR_EnumerateEntities(pos, ang, PARTITION_SOLID_EDICTS, RayType_Infinite, HitPlayer, client);
	}
}

public bool HitPlayer(int entity, int client)
{
	if(entity != client && IsValidPlayer(client))
	{
		if(IsValidPlayer(entity, true))
		{
			TR_ClipCurrentRayToEntity(MASK_ALL, entity);

			if(TR_DidHit())
			{
				float dist = Entity_GetDistance(entity, client);
				g_players[client].grabbing = EntIndexToEntRef(entity);
				g_players[client].grabDistance = dist;
				TF2_SetClientGlow(entity, true);
				return false;
			}
		}
	}

	return true;
}

public Action Ghost_GrabEndCmd(int client, int args)
{
	if(IsValidPlayer(client))
	{
		if(g_players[client].grabbing != INVALID_ENT_REFERENCE)
		{
			int ent = EntRefToEntIndex(g_players[client].grabbing);
			if(!IsValidPlayer(ent, true)) return Plugin_Handled;

			TF2_SetClientGlow(ent, false);
		}

		g_players[client].grabbing = INVALID_ENT_REFERENCE;
	}

	return Plugin_Handled;
}

public bool TraceFilterGrab(int entityhit, int mask, any entity)
{
	if(entityhit > 0 && entityhit != entity && IsValidPlayer(entityhit, true))
	{
		return true;
	}
	return false;
}

public void Grab_OnPlayerRunCmd(int client, int& buttons, int mouse[2])
{
	if(!g_players[client].grabbing || g_players[client].grabbing == INVALID_ENT_REFERENCE) return;
	if(!IsValidPlayer(client)) return;

	int ent = EntRefToEntIndex(g_players[client].grabbing);
	if(!IsValidPlayer(ent, true))
	{
		g_players[client].grabbing = INVALID_ENT_REFERENCE;
		return;
	}

	if(buttons & (IN_ATTACK | IN_ATTACK2))
	{
		g_players[client].grabDistance += 10.0 * (buttons & IN_ATTACK ? 1.0 : -1.0);
		if(g_players[client].grabDistance < 25.0)
			g_players[client].grabDistance = 25.0;
	}

	float fAng[3], fPos[3], fForward[3], fVel[3], oldPos[3];
	GetClientEyeAngles(client, fAng);
	GetClientEyePosition(client, fPos);

	GetAngleVectors(fAng, fForward, NULL_VECTOR, NULL_VECTOR);
	ScaleVector(fForward, g_players[client].grabDistance);
	AddVectors(fPos, fForward, fForward);
	fForward[2] = fForward[2] - 35.0;

	fVel = view_as<float>({0.0, 0.0, 0.0});
	/*fVel[2] = mouse[1] * -100.0;
	fVel[1] = mouse[0] * -100.0;
	*/


	Entity_GetAbsOrigin(ent, oldPos);
	MakeVectorFromPoints(oldPos, fForward, fVel);
	ScaleVector(fVel, 50.0);

	TeleportEntity(ent, fForward, NULL_VECTOR, fVel);
}