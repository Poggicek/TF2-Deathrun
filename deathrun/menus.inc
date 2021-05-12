public int LanguageMenu_Handler(Menu menu, MenuAction action, int client, int param2)
{

	if(!IsValidPlayer(client))
	{
		delete menu;
		return 0;
	}

	char langCode[4];
	int cLang = GetClientLanguage(client);
	GetLanguageInfo(cLang, langCode, sizeof(langCode));

	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			SetClientLanguage(client, GetLanguageByCode(info));
			SetClientCookie(client, g_hLangCookie, info);

			LanguageMenu(client);
		}

		case MenuAction_DisplayItem:
		{
			char info[32];
			char dispName[32];
			menu.GetItem(param2, info, sizeof(info), _, dispName, sizeof(dispName));

			if(StrEqual(langCode, info))
			{
				Format(dispName, sizeof(dispName), "%s (Selected)", dispName);
				return RedrawMenuItem(dispName);
			}
		}

		case MenuAction_End:
    {
      delete menu;
    }
	}

	return 0;
}

public void LanguageMenu(int client)
{
	Menu menu = new Menu(LanguageMenu_Handler, MENU_ACTIONS_DEFAULT | MenuAction_DisplayItem);
	menu.SetTitle("Language settings");
	menu.AddItem("en", "English");
	menu.AddItem("cze", "Czech");
	menu.ExitButton = true;
	menu.Display(client, 20);
}