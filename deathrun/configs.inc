static char DownloadsPath[64];

stock void ManageConfigs()
{
	PrintToServer("[*] Adding files to download table");

	BuildPath(Path_SM, DownloadsPath, sizeof(DownloadsPath), "configs/downloads.txt");
	if(FileExists(DownloadsPath) == false) return;

	Handle file = OpenFile(DownloadsPath, "r");
	char buffer[256];

	while(ReadFileLine(file, buffer, sizeof(buffer)))
	{
		int len = strlen(buffer);
		if(buffer[len - 1] == '\n')
		{
			buffer[--len] = '\0';
		}

		char split[2][100];

		ExplodeString(buffer, ";", split, sizeof(split), sizeof(split[]));

		if(split[1][0] == '\0')
		{
			if(FileExists(buffer))
				AddFileToDownloadsTable(buffer);
		} else {
			if(FileExists(split[0]))
			{
				AddFileToDownloadsTable(split[0]);

				if(StrContains(buffer, "sound/", false) != -1)
				{
					PrintToServer("[+] Precaching sound %s", split[0]);
					PrecacheSound(split[0]);
				}
			}
		}

		if(IsEndOfFile(file))
		{
			break;
		}
	}
}