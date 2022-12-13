const MLFeed::HookRaceStatsEventsBase_V2@ raceData;

uint nbPlayers;

void Main() {
    startnew(MainCoro);
}

void MainCoro() {
    sleep(100);
    @raceData = MLFeed::GetRaceData_V2();
}

/** Called every frame. `dt` is the delta time (milliseconds since last frame).
*/
void Update(float dt) {
    if (raceData is null) return;
    uint _nbPlayers = raceData.SortedPlayers_Race.Length;
    bool playersWentToZero = _nbPlayers == 0 && nbPlayers != 0;
    nbPlayers = _nbPlayers;
    if (playersWentToZero) {
        // we unloaded a map
        Reset();
    } else if (nbPlayers > 0 && S_SendRespawnNotifications) {
        // check for updates
        CheckForRespawns();
    }
}

dictionary playerRespawnTrackers;

void Reset() {
    playerRespawnTrackers.DeleteAll();
}

void CheckForRespawns() {
    if (!S_SendRespawnNotifications) return;
    // trace("checking for respawns. nb players: " + nbPlayers);
    uint r = 0;
    for (uint i = 0; i < raceData.SortedPlayers_Race.Length; i++) {
        r = 0;
        auto player = raceData.SortedPlayers_Race[i];
        if (playerRespawnTrackers.Exists(player.name)) {
            r = uint(playerRespawnTrackers[player.name]);
        }
        // print(player.name + ": " + r + "; " + player.NbRespawnsRequested);
        if (player.NbRespawnsRequested != r) {
            playerRespawnTrackers[player.name] = player.NbRespawnsRequested;
            if (player.NbRespawnsRequested == 0) {
                // either we have restarted a race or respawned during TA, etc
                if (player.CurrentRaceTime <= 50) {
                    // ignore for the moment
                    continue;
                }
            } else {
                // respawn
                OnRespawn(player);
            }
        }
    }
}

void OnRespawn(MLFeed::PlayerCpInfo_V2@ player) {
    // if (!S_SendRespawnNotifications) return;
    UI::ShowNotification("Respawn: " + player.name, "Time lost to respawns: " + Time::Format(player.TimeLostToRespawns, true, false) + "\nNb Respawns: " + player.NbRespawnsRequested, vec4(.8, .3, .8, .3));
}

void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}
