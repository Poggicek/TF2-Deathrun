#define TAG "{Lime}[DR]"

enum struct Player {
  int id;

  bool thirdperson;
  int grabbing;
  float grabDistance;
}

enum SpecialRound {
	SPECIALROUND_NONE = 0,
	SPECIALROUND_LONG_RESPAWN,
	SPECIALROUND_HIGH_SPEED,
	SPECIALROUND_SMALL_PLAYER
}

SpecialRound g_specialRound = SPECIALROUND_NONE;

Player g_players[MAXPLAYERS + 1];
ArrayList g_aBreakables;

int g_iDeath = -1;
int g_iGhosts[MAXPLAYERS + 1];

float g_fMaxRunnerSpeed = 300.0;
float g_fMaxRunnerSpeedSpecialRound = 400.0;
float g_fMaxDeathSpeed = 420.0;
float g_fLastRoundStart = 0.0;

bool g_freeRun = false;

Handle g_hLangCookie = INVALID_HANDLE;