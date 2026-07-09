# "+1 Speed" Backrooms Escape

A complete incremental/idle loop for Roblox, built in Luau with [Rojo](https://rojo.space/). Part of a Roblox scripting portfolio. Run to earn Speed, level it up, prestige for a permanent multiplier — while a personal monster hunts you down if you fall behind.

## What it demonstrates

- **Currency → Level → Rebirth loop** — `CurrencyService` is the sole owner of Speed mutations, `LevelService` spends it against a cost curve and raises `Humanoid.WalkSpeed` directly (progress is felt, not just displayed), and `RebirthService` resets progress for a permanent multiplier applied to all future earnings.
- **Real DataStore persistence** — `DataService` wraps every read/write in `pcall` with retry/backoff, autosaves on a staggered interval (not every player at once), and saves again on `PlayerRemoving` and `BindToClose` inside a safe shutdown budget. Profile schema versioning lives in `ProfileMigrations`.
- **Live OrderedDataStore leaderboard** — `LeaderboardService` throttles writes and caches the top-N read so the board doesn't hit DataStore limits under load.
- **Idempotent Robux purchases** — `MonetizationService.ProcessReceipt` checks a persisted `GrantedPurchaseIds` ledger before granting anything, so Roblox's automatic retry-for-3-days behavior on a receipt can never double-grant.
- **Per-player personal monster AI** — `MonsterService` keeps private chase state per `(player, zone)` pair server-side and never spawns a shared Workspace instance; the client-owned `Part` created by `PersonalMonsterController` is only ever visible to its own player, by Roblox's normal replication rules, not a visibility hack. Catching a player costs a knockback + a percentage of current Speed.
- **Procedural room generation from data** — `WorldBuilder`/`RoomTemplates` build rooms out of primitives from `StageConfig` entries, so adding a new stage is a data change, not new geometry code.

## Structure

```
src/shared/    Classes (Signal/Trove/Class), Net (Remotes/NetConstants), Config, World (WorldBuilder/RoomTemplates), Types, Utils
src/server/    DataService, CurrencyService, LevelService, RebirthService, MonsterService, MonetizationService, LeaderboardService, StageService
src/client/    StateController + InputController, HUD, Leaderboard/StageSelect/popup UI, PersonalMonsterController
```

## Running

Needs an empty Roblox Studio place with the Rojo plugin connected:

```
rojo serve
```

Enable "Studio Access to API Services" in place settings to exercise DataStore/leaderboard persistence locally.
