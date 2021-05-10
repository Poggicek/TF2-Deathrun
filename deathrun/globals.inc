#define TAG "{Lime}[DR]"

enum struct Player {
  int id;

  bool thirdperson;
}

Player g_players[MAXPLAYERS + 1];

float g_fMaxRunnerSpeed = 300.0;
float g_fMaxDeathSpeed = 400.0;
float g_fLastRoundStart = 0.0;

int g_iDeath = -1;