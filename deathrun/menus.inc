public int LanguageMenu_Handler(Menu menu, MenuAction action, int client, int param2)
{
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
		case MenuAction_End:
    {
      delete menu;
    }
	}

}

public void LanguageMenu(int client)
{
  Menu menu = new Menu(LanguageMenu_Handler);
  menu.SetTitle("Language settings");
  menu.AddItem("en", "English");
  menu.AddItem("cze", "Czech");
  menu.ExitButton = true;
  menu.Display(client, 20);
}