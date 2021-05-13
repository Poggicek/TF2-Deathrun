#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <adminmenu>

#pragma newdecls required
#pragma semicolon 1

TopMenu hTopMenu = null;

public void AdminMenu_OnPluginStart()
{
	PrintToServer("[+] Admin menu module loaded");

	TopMenu topmenu;

	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
	{
		OnAdminMenuReady(topmenu);
	}
}

public void OnLibraryRemoved(const char[] name)
{
  if (StrEqual(name, "adminmenu", false))
  {
    hTopMenu = null;
  }
}


public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if (topmenu == hTopMenu)
	{
		return;
	}

	hTopMenu = topmenu;

	TopMenuObject player_commands = hTopMenu.FindCategory(ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		hTopMenu.AddItem("sm_respawn", AdminMenu_Respawn, player_commands, "sm_respawn", ADMFLAG_SLAY);
	}
}

public void AdminMenu_Respawn(TopMenu topmenu,
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%s", "Respawn player");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayRespawnMenu(param);
	}
}

void DisplayRespawnMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Respawn);

	char title[100];
	Format(title, sizeof(title), "%s:", "Respawn player");
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	AddTargetsToMenu2(menu, client, COMMAND_FILTER_DEAD);

	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Respawn(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;

		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %s", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %s", "Unable to find target");
		}
		else
		{
			char name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));

			TF2_RespawnPlayer(target);
		}

		//Re-draw the menu if they're still valid
		if (IsClientInGame(param1) && !IsClientInKickQueue(param1))
		{
			DisplayRespawnMenu(param1);
		}
	}
}
