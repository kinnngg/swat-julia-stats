class Extension extends Julia.Extension
 implements Julia.InterestedInMissionStarted,
            Julia.InterestedInMissionEnded,
            Julia.InterestedInPlayerDisconnected,
            Julia.InterestedInCommandDispatched;

/**
 * Copyright (c) 2014 Sergei Khoroshilov <kh.sergei@gmail.com>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

/**
 * Min number of fired ammuntion required for accuracy calculation
 * @type int
 */
const MIN_ACCURACY_SHOTS=10;

/**
 * Min number of thrown grenades required for accuracy calculation
 * @type int
 */
const MIN_ACCURACY_THROWN=5;


enum eRoundStatType
{
    STAT_NONE,

    HIGHEST_HITS,
    LOWEST_HITS,

    HIGHEST_TEAM_HITS,
    LOWEST_TEAM_HITS,

    HIGHEST_AMMO_FIRED,
    LOWEST_AMMO_FIRED,

    HIGHEST_ACCURACY,
    LOWEST_ACCURACY,

    HIGHEST_NADE_HITS,
    LOWEST_NADE_HITS,

    HIGHEST_NADE_TEAM_HITS,
    LOWEST_NADE_TEAM_HITS,

    HIGHEST_NADE_THROWN,
    LOWEST_NADE_THROWN,

    HIGHEST_NADE_ACCURACY,
    LOWEST_NADE_ACCURACY,

    HIGHEST_KILL_DISTANCE,
    LOWEST_KILL_DISTANCE,

    HIGHEST_SCORE,
    LOWEST_SCORE,

    HIGHEST_KILLS,
    LOWEST_KILLS,

    HIGHEST_ARRESTS,
    LOWEST_ARRESTS,

    HIGHEST_ARRESTED,
    LOWEST_ARRESTED,

    HIGHEST_TEAM_KILLS,
    LOWEST_TEAM_KILLS,

    HIGHEST_SUICIDES,
    LOWEST_SUICIDES,

    HIGHEST_DEATHS,
    LOWEST_DEATHS,

    HIGHEST_KILL_STREAK,
    LOWEST_KILL_STREAK,

    HIGHEST_ARREST_STREAK,
    LOWEST_ARREST_STREAK,

    HIGHEST_DEATH_STREAK,
    LOWEST_DEATH_STREAK,

    HIGHEST_VIP_CAPTURES,
    LOWEST_VIP_CAPTURES,

    HIGHEST_VIP_RESCUES,
    LOWEST_VIP_RESCUES,

    HIGHEST_BOMBS_DEFUSED,
    LOWEST_BOMBS_DEFUSED,

    HIGHEST_CASE_KILLS,
    LOWEST_CASE_KILLS,

    HIGHEST_REPORTS,
    LOWEST_REPORTS,

    HIGHEST_HOSTAGE_ARRESTS,
    LOWEST_HOSTAGE_ARRESTS,

    HIGHEST_HOSTAGE_HITS,
    LOWEST_HOSTAGE_HITS,

    HIGHEST_HOSTAGE_INCAPS,
    LOWEST_HOSTAGE_INCAPS,

    HIGHEST_HOSTAGE_KILLS,
    LOWEST_HOSTAGE_KILLS,

    HIGHEST_ENEMY_ARRESTS,
    LOWEST_ENEMY_ARRESTS,

    HIGHEST_ENEMY_INCAPS,
    LOWEST_ENEMY_INCAPS,

    HIGHEST_ENEMY_KILLS,
    LOWEST_ENEMY_KILLS,

    HIGHEST_ENEMY_INCAPS_INVALID,
    LOWEST_ENEMY_INCAPS_INVALID,

    HIGHEST_ENEMY_KILLS_INVALID,
    LOWEST_ENEMY_KILLS_INVALID,
};

enum ePlayerStatType
{
    STAT_NONE,

    HITS,
    TEAM_HITS,
    AMMO_FIRED,
    ACCURACY,

    NADE_HITS,
    NADE_TEAM_HITS,
    NADE_THROWN,
    NADE_ACCURACY,

    KILL_DISTANCE,

    SCORE,
    KILLS,
    ARRESTS,
    ARRESTED,
    TEAM_KILLS,
    SUICIDES,
    DEATHS,

    KILL_STREAK,
    ARREST_STREAK,
    DEATH_STREAK,

    VIP_CAPTURES,
    VIP_RESCUES,

    BOMBS_DEFUSED,

    CASE_KILLS,

    REPORTS,
    HOSTAGE_ARRESTS,
    HOSTAGE_HITS,
    HOSTAGE_INCAPS,
    HOSTAGE_KILLS,

    ENEMY_ARRESTS,
    ENEMY_INCAPS,
    ENEMY_KILLS,
    ENEMY_INCAPS_INVALID,
    ENEMY_KILLS_INVALID,
};

struct sRoundStat
{
    /**
     * Round stat type
     * @type enum'eRoundStatType'
     */
    var eRoundStatType Type;

    /**
     * Current record holders
     * @type array<class'Julia.Player'>
     */
    var array<Julia.Player> Players;

    /**
     * Points scored
     * @type float
     */
    var float Points;
};

struct sPlayerStatCache
{
    /**
     * Reference to the stats owner
     * @type class'Julia.Player'
     */
    var protected Julia.Player Player;

    /**
     * List of stats in the following format: Stats[STAT_NONE]=0.0, Stats[HITS]=n, Stats[TEAM_HITS]=n, etc
     * @type array<float>
     */
    var array<float> Stats;
};

/**
 * List of player stats cached entries that remain available only between rounds
 * @type array<struct'sPlayerStatCache'>
 */
var protected array<sPlayerStatCache> PlayerStatsCache;

/**
 * List of best/worst player stats that will be displayed upon a round end
 * @type array<enum'eRoundStatType'>
 */
var config array<eRoundStatType> FixedStats;

/**
 * List of extra round stats
 * @type array<enum'eRoundStatType'>
 */
var config array<eRoundStatType> VariableStats;

/**
 * The number of extra round stats to pick from the list
 * @type int
 */
var config int VariableStatsLimit;

/**
 * Max number of round record holders to display
 * @type int
 */
var config int MaxNames;

/**
 * Min time played/round time ratio required to challenge the "lowest" categories of round stats
 * @type float
 */
var config float MinTimeRatio;

/**
 * List of personal stats that are displayed to a player with the !stats command
 * @type array<enum'ePlayerStatType'>
 */
var config array<ePlayerStatType> PlayerStats;

/**
 * @return  void
 */
public function PreBeginPlay()
{
    Super.PreBeginPlay();
    self.MaxNames = Max(1, self.MaxNames);
}

/**
 * Bind the !stats command and register with the Julia's signal handlers
 * 
 * @return  void
 */
public function BeginPlay()
{
    Super.BeginPlay();

    // Bind the !stats command
    self.Core.GetDispatcher().Bind(
        "stats", self, self.Locale.Translate("StatsCommandUsage"), self.Locale.Translate("StatsCommandDescription")
    );
    
    self.Core.RegisterInterestedInMissionStarted(self);
    self.Core.RegisterInterestedInMissionEnded(self);
    self.Core.RegisterInterestedInPlayerDisconnected(self);
}

/**
 * Attempt to display the Player's personal stats
 * 
 * @see Julia.InterestedInCommandDispatched.OnCommandDispatched
 */
public function OnCommandDispatched(Julia.Dispatcher Dispatcher, string Name, string Id, array<string> Args, Julia.Player Player)
{
    local int i, j;
    local array<string> Response;
    local array<float> Stats;
    local Julia.Player PlayerOfInterest;

    if (Args.Length > 0)
    {
        PlayerOfInterest = self.Core.GetServer().GetPlayerByWildName(Args[0]);
    }
    else 
    {
        PlayerOfInterest = Player;
    }    

    if (PlayerOfInterest != None)
    {
        // Check the cache first
        Stats = self.GetPlayerStatsFromCache(PlayerOfInterest);
        
        if (Stats.Length == 0)
        {
            Stats = self.GetPlayerStats(PlayerOfInterest, self.PlayerStats);
        }

        for (i = 0; i < self.PlayerStats.Length; i++)
        {
            j = self.PlayerStats[i];
            // Skip "STAT_NONE"
            if (j != 0)
            {
                Response[Response.Length] = self.Locale.Translate(
                    "Player" $ class'Extension'.static.GetLocaleString(string(GetEnum(ePlayerStatType, j))), 
                    class'Extension'.static.GetNeatNumericString(Stats[j])
                );
            }
        }
    }

    if (Response.Length == 0)
    {
        if (PlayerOfInterest == None)
        {
            Dispatcher.ThrowError(Id, self.Locale.Translate("PlayerErrorNoMatch"));
        }
        else
        {
            Dispatcher.ThrowError(Id, self.Locale.Translate("PlayerErrorNoStats"));
        }
        return;
    }

    // Display the other player's name
    if (PlayerOfInterest != Player)
    {
        Response.Insert(0, 1);
        Response[0] = self.Locale.Translate("PlayerDescription", class'Extension'.static.ColorifyName(PlayerOfInterest));
    }

    Dispatcher.Respond(Id, class'Utils.ArrayUtils'.static.Join(Response, "\\n"));
}

/**
 * Remove all Player matching sPlayerStatCache entries from the player stats cache their leaving
 * 
 * @see  Julia.InterestedInPlayerDisconnected.OnPlayerDisconnected
 */
public function OnPlayerDisconnected(Julia.Player Player)
{
    local int i;

    for (i = self.PlayerStatsCache.Length-1; i >= 0 ; i--)
    {
        if (self.PlayerStatsCache[i].Player == Player)
        {
            self.PlayerStatsCache.Remove(i, 1);
        }
    }
}

/**
 * Show next map message upon start of the first round
 * 
 * @see  Julia.InterestedInMissionStarted.OnMissionStarted
 */
public function OnMissionStarted()
{
    self.ClearPlayerStatsCache();

    if (self.Core.GetServer().GetRoundIndex() == 0)
    {
        self.DisplayNextMapMessage();
    }
}

/**
 * Show round stats upon a round end
 * Also attempt to show the next map message
 * 
 * @see  Julia.InterestedInMissionEnded.OnMissionEnded
 */
public function OnMissionEnded()
{
    // Fill the player stats cache, so players issuing the !stats command
    // dont end up with zeroed values during the PostGame state
    self.FillPlayerStatsCache();
    self.DisplayRoundPlayer();
    self.DisplayRoundStats();
    // Display next map message at the end of a map
    if (self.Core.GetServer().GetRoundIndex() == self.Core.GetServer().GetRoundLimit()-1)
    {
        self.DisplayNextMapMessage();
    }
}

/**
 * Display player of the round message
 * 
 * @return  void
 */
protected function DisplayRoundPlayer()
{
    local Julia.Player Player;
    local string RoundPlayerName;

    Player = self.GetBestRoundPlayer();

    if (Player != None)
    {
        RoundPlayerName = class'Extension'.static.ColorifyName(Player);
    }
    else
    {
        RoundPlayerName = self.Locale.Translate("PlayerErrorNotAvailable");
    }

    // Display the best round player message
    class'Utils.LevelUtils'.static.TellAll(
        Level,
        self.Locale.Translate("RoundPlayerMessage", RoundPlayerName),
        self.Locale.Translate("MessageColor")
    );
}

/**
 * Display round stats defined in the RoundStats and RoundStatsRandom lists
 * 
 * @return  void
 */
protected function DisplayRoundStats()
{
    local int i, j, k, n;
    local array<eRoundStatType> Categories, Variable, Shuffled;
    local array<sRoundStat> Stats, Sorted;
    local int VariableStatCount;

    Categories = self.FixedStats;
    Variable = self.VariableStats;

    // Append varying categories
    for (i = 0; i < Variable.Length; i++)
    {
        Categories[Categories.Length] = Variable[i];
    }

    Stats = self.GetRoundStats(Categories);

    // Display predefined stats first
    for (i = 0; i < self.FixedStats.Length; i++)
    {
        self.DisplayRoundStatEntry(Stats[self.FixedStats[i]]);
    }
    // Shuffle variable categories
    while (Variable.Length > 0)
    {
        n = Rand(Variable.Length);
        Shuffled[Shuffled.Length] = Variable[n];
        Variable.Remove(n, 1);
    }
    // Attempt to sort variable stat entries by the number of assotiated record holders
    // so entries with the lowest number of players are at the beginning of the list
    for (i = 0; i < Shuffled.Length; i++)
    {
        j = Shuffled[i];

        if (Stats[j].Players.Length == 0)
        {
            continue;
        }

        n = -1;

        for (k = 0; k < Sorted.Length; k++)
        {
            if (Stats[j].Players.Length <= Sorted[k].Players.Length)
            {
                n = k;
                break;
            }
        }

        // This stat has the greatest number of players, append it to the end
        if (n == -1)
        {
            n = Sorted.Length;
        }

        Sorted.Insert(n, 1);
        Sorted[n] = Stats[j];
    }

    log(self $ ": " $ Sorted.Length $ " variable stats were sorted in the order:");

    for (i = 0; i < Sorted.Length; i++)
    {
        log(self $ ": " $ GetEnum(eRoundStatType, Sorted[i].Type) $ " - " $ Sorted[i].Players.Length $ " players");
    }

    log(self $ ": displaying the first " $ self.VariableStatsLimit);

    for (i = 0; i < Sorted.Length; i++)
    {
        if (++VariableStatCount > self.VariableStatsLimit)
        {
            break;
        }
        self.DisplayRoundStatEntry(Sorted[i]);
    }
}

/**
 * Display a round stat StatEntry
 * 
 * @param   struct'StatEntry' StatEntry
 * @return  void
 */
protected function DisplayRoundStatEntry(sRoundStat StatEntry)
{
    local int i, j;
    local array<string> Names;
    local string NamesCombined, NamesTranslated;

    if (StatEntry.Players.Length == 0)
    {
        return;
    }

    for (i = 0; i < self.MaxNames; i++)
    {
        if (StatEntry.Players.Length == 0)
        {
            break;
        }
        // Pick a random player
        j = Rand(StatEntry.Players.Length);
        Names[Names.Length] = class'Extension'.static.ColorifyName(StatEntry.Players[j]);
        StatEntry.Players.Remove(j, 1);
    }

    // Join the names in a string
    NamesCombined = class'Utils.ArrayUtils'.static.Join(Names, ", ");

    // Let everyone know if there are more players
    if (StatEntry.Players.Length > 0)
    {
        NamesTranslated = self.Locale.Translate("RoundPlayerNameMore", NamesCombined, StatEntry.Players.Length);
    }
    // Display names normally
    else
    {
        NamesTranslated = self.Locale.Translate("RoundPlayerName", NamesCombined);
    }

    class'Utils.LevelUtils'.static.TellAll(
        Level,
        self.Locale.Translate(
            "Round" $ class'Extension'.static.GetLocaleString(string(GetEnum(eRoundStatType, StatEntry.Type))), 
            NamesTranslated,
            class'Extension'.static.GetNeatNumericString(StatEntry.Points)
        ),
        self.Locale.Translate("MessageColor")
    );
}

/**
 * Display the next map message
 * 
 * @return  void
 */
protected function DisplayNextMapMessage()
{
    class'Utils.LevelUtils'.static.TellAll(
        Level,
        self.Locale.Translate(
            "NextMapMessage", 
            class'Julia.Utils'.static.GetFriendlyMapName(class'Julia.Utils'.static.GetNextMap(Level))
        ),
        self.Locale.Translate("MessageColor")
    );
}

/**
 * Return the the Player's stats defined with Types
 * 
 * @param   class'Julia.Player' Player
 * @param   array<enum'ePlayerStatType'> Types
 * @return  array<float>
 */
protected function array<float> GetPlayerStats(Julia.Player Player, array<ePlayerStatType> Types)
{
    local int i, j;
    local bool bSkip;
    local array<float> Stats;

    for (i = 0; i < ePlayerStatType.EnumCount; i++)
    {
        // Initialize an empty stat entry
        Stats[i] = 0.0;

        bSkip = true;
        // Check whether the caller is interested in this stat
        for (j = 0; j < Types.Length; j++)
        {
            if (ePlayerStatType(i) == Types[j])
            {
                bSkip = false;
                break;
            }
        }

        if (bSkip)
        {
            continue;
        }

        switch (ePlayerStatType(i))
        {
            case HITS:
                Stats[i] = class'Extension'.static.GetPlayerHits(Player);
                break;
            case TEAM_HITS:
                Stats[i] = class'Extension'.static.GetPlayerTeamHits(Player);
                break;
            case AMMO_FIRED:
                Stats[i] = class'Extension'.static.GetPlayerAmmoFired(Player);
                break;
            case ACCURACY:
                Stats[i] = class'Extension'.static.GetPlayerAccuracy(Player);
                break;
            case NADE_HITS:
                Stats[i] = class'Extension'.static.GetPlayerNadeHits(Player);
                break;
            case NADE_TEAM_HITS:
                Stats[i] = class'Extension'.static.GetPlayerNadeTeamHits(Player);
                break;
            case NADE_THROWN:
                Stats[i] = class'Extension'.static.GetPlayerNadeThrown(Player);
                break;
            case NADE_ACCURACY:
                Stats[i] = class'Extension'.static.GetPlayerNadeAccuracy(Player);
                break;
            case KILL_DISTANCE:
                Stats[i] = class'Extension'.static.GetPlayerKillDistance(Player);
                break;
            case SCORE:
                Stats[i] = Player.GetLastScore();
                break;
            case KILLS:
                Stats[i] = Player.GetLastKills();
                break;
            case ARRESTS:
                Stats[i] = Player.GetLastArrests();
                break;
            case ARRESTED:
                Stats[i] = Player.GetLastArrested();
                break;
            case TEAM_KILLS:
                Stats[i] = Player.GetLastTeamKills();
                break;
            case SUICIDES:
                Stats[i] = Player.GetSuicides();
                break;
            case DEATHS:
                Stats[i] = Player.GetLastDeaths();
                break;
            case KILL_STREAK:
                Stats[i] = Player.GetBestKillStreak();
                break;
            case ARREST_STREAK:
                Stats[i] = Player.GetBestArrestStreak();
                break;
            case DEATH_STREAK:
                Stats[i] = Player.GetBestDeathStreak();
                break;
            case VIP_CAPTURES:
                Stats[i] = Player.GetLastVIPCaptures();
                break;
            case VIP_RESCUES:
                Stats[i] = Player.GetLastVIPRescues();
                break;
            case BOMBS_DEFUSED:
                Stats[i] = Player.GetLastBombsDefused();
                break;
            case CASE_KILLS:
                Stats[i] = Player.GetLastSGKills();
                break;
            case REPORTS:
                Stats[i] = Player.GetCharacterReports();
                break;
            case HOSTAGE_ARRESTS:
                Stats[i] = Player.GetCivilianArrests();
                break;
            case HOSTAGE_HITS:
                Stats[i] = Player.GetCivilianHits();
                break;
            case HOSTAGE_INCAPS:
                Stats[i] = Player.GetCivilianIncaps();
                break;
            case HOSTAGE_KILLS:
                Stats[i] = Player.GetCivilianKills();
                break;
            case ENEMY_ARRESTS:
                Stats[i] = Player.GetEnemyArrests();
                break;
            case ENEMY_INCAPS:
                Stats[i] = Player.GetEnemyIncaps();
                break;
            case ENEMY_KILLS:
                Stats[i] = Player.GetEnemyKills();
                break;
            case ENEMY_INCAPS_INVALID:
                Stats[i] = Player.GetEnemyIncapsInvalid();
                break;
            case ENEMY_KILLS_INVALID:
                Stats[i] = Player.GetEnemyKillsInvalid();
                break;
            default:
                break;
        }
    }
    return Stats;
}

/**
 * Attempt to retrieve Player's stats from cache
 * 
 * @param   class'Julia.Player' Player
 * @return  array<float>
 */
protected function array<float> GetPlayerStatsFromCache(Julia.Player Player)
{
    local int i;
    local array<float> Empty;

    for (i = 0; i < self.PlayerStatsCache.Length; i++)
    {
        if (self.PlayerStatsCache[i].Player == Player)
        {
            return self.PlayerStatsCache[i].Stats;
        }
    }

    return Empty;
}

/**
 * Fill the player stats cache
 * 
 * @return  void
 */
protected function FillPlayerStatsCache()
{
    local int i;
    local sPlayerStatCache CacheEntry;
    local array<Julia.Player> Players;

    Players = self.Core.GetServer().GetPlayers();

    for (i = 0; i < Players.Length; i++)
    {
        // Only cache online players' stats
        if (Players[i].GetPC() == None)
        {
            continue;
        }

        CacheEntry.Player = Players[i];
        CacheEntry.Stats = self.GetPlayerStats(Players[i], self.PlayerStats);

        self.PlayerStatsCache[self.PlayerStatsCache.Length] = CacheEntry;
    }
}

/**
 * Clear the player stats cache
 * 
 * @return  void
 */
protected function ClearPlayerStatsCache()
{
    while (self.PlayerStatsCache.Length > 0)
    {
        self.PlayerStatsCache[0].Player = None;
        self.PlayerStatsCache.Remove(0, 1);
    }
}

/**
 * Return a list of round records. 
 * The list will contain all eRoundStatType entries,
 * but only the categories matching Categories will be actually be calculated
 * 
 * @param   array<eRoundStatType> Categories
 *          List of categories the caller is interested in
 * @return  array<struct'sRoundStat'>
 */
protected function array<sRoundStat> GetRoundStats(array<eRoundStatType> Categories)
{
    local int i, j;
    local bool bSkip;
    local sRoundStat StatEntry;
    local array<sRoundStat> Stats;
    local array<Julia.Player> Players;

    Players = self.Core.GetServer().GetPlayers();

    for (j = 0; j < eRoundStatType.EnumCount; j++)
    {
        // Set an empty struct for this type of round stat
        // this is required for array integrity
        Stats[j] = StatEntry;
        Stats[j].Type = eRoundStatType(j);

        bSkip = true;

        for (i = 0; i < Categories.Length; i++)
        {
            if (Stats[j].Type == Categories[i])
            {
                bSkip = false;
                break;
            }
        }

        if (bSkip)
        {
            continue;
        }

        log(self $ ": iterating " $ Players.Length $ " players for " $ GetEnum(eRoundStatType, j));

        for (i = 0; i < Players.Length; i++)
        {
            switch (eRoundStatType(j))
            {
                case HIGHEST_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerHits(Players[i]), -1);
                    break;
                case LOWEST_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerHits(Players[i]), -1, true);
                    break;

                case HIGHEST_TEAM_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerTeamHits(Players[i]), -1);
                    break;
                case LOWEST_TEAM_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerTeamHits(Players[i]), -1, true);
                    break;

                case HIGHEST_AMMO_FIRED:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerAmmoFired(Players[i]), -1);
                    break;
                case LOWEST_AMMO_FIRED:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerAmmoFired(Players[i]), -1, true);
                    break;

                case HIGHEST_ACCURACY:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerAccuracy(Players[i]), -1);
                    break;
                case LOWEST_ACCURACY:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerAccuracy(Players[i]), -1, true);
                    break;

                case HIGHEST_NADE_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerNadeHits(Players[i]), -1);
                    break;
                case LOWEST_NADE_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerNadeHits(Players[i]), -1, true);
                    break;

                case HIGHEST_NADE_TEAM_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerNadeTeamHits(Players[i]), -1);
                    break;
                case LOWEST_NADE_TEAM_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerNadeTeamHits(Players[i]), -1, true);
                    break;

                case HIGHEST_NADE_THROWN:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerNadeThrown(Players[i]), -1);
                    break;
                case LOWEST_NADE_THROWN:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerNadeThrown(Players[i]), -1, true);
                    break;

                case HIGHEST_NADE_ACCURACY:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerNadeAccuracy(Players[i]), -1);
                    break;
                case LOWEST_NADE_ACCURACY:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerNadeAccuracy(Players[i]), -1, true);
                    break;

                case HIGHEST_KILL_DISTANCE:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerKillDistance(Players[i]), -1);
                    break;
                case LOWEST_KILL_DISTANCE:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], class'Extension'.static.GetPlayerKillDistance(Players[i]), -1, true);
                    break;

                case HIGHEST_SCORE:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastScore(), -1);
                    break;
                case LOWEST_SCORE:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastScore(), -1, true);
                    break;

                case HIGHEST_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastKills(), -1);
                    break;
                case LOWEST_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastKills(), -1, true);
                    break;

                case HIGHEST_ARRESTS:

                    if (!Players[i].WasVIP())
                    {
                        self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastArrests(), -1);
                    }
                    break;

                case LOWEST_ARRESTS:

                    if (!Players[i].WasVIP())
                    {
                        self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastArrests(), -1, true);
                    }
                    break;

                case HIGHEST_ARRESTED:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastArrested(), -1);
                    break;
                case LOWEST_ARRESTED:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastArrested(), -1, true);
                    break;

                case HIGHEST_TEAM_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastTeamKills(), -1);
                    break;
                case LOWEST_TEAM_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastTeamKills(), -1, true);
                    break;

                case HIGHEST_SUICIDES:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetSuicides(), -1);
                    break;
                case LOWEST_SUICIDES:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetSuicides(), -1, true);
                    break;

                case HIGHEST_DEATHS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastDeaths(), -1);
                    break;
                case LOWEST_DEATHS:

                    if (!Players[i].WasVIP())
                    {
                        self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastDeaths(), -1, true);
                    }
                    break;

                case HIGHEST_KILL_STREAK:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetBestKillStreak(), -1);
                    break;
                case LOWEST_KILL_STREAK:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetBestKillStreak(), -1, true);
                    break;

                case HIGHEST_ARREST_STREAK:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetBestArrestStreak(), -1);
                    break;
                case LOWEST_ARREST_STREAK:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetBestArrestStreak(), -1, true);
                    break;

                case HIGHEST_DEATH_STREAK:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetBestDeathStreak(), -1);
                    break;
                case LOWEST_DEATH_STREAK:
                
                    if (!Players[i].WasVIP())
                    {
                        self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetBestDeathStreak(), -1, true);
                    }
                    break;

                case HIGHEST_VIP_CAPTURES:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastVIPCaptures(), 1);
                    break;
                case LOWEST_VIP_CAPTURES:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastVIPCaptures(), 1, true);
                    break;

                case HIGHEST_VIP_RESCUES:

                    if (!Players[i].WasVIP())
                    {
                        self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastVIPRescues(), 0);
                    }
                    break;

                case LOWEST_VIP_RESCUES:

                    if (!Players[i].WasVIP())
                    {
                        self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastVIPRescues(), 0, true);
                    }
                    break;

                case HIGHEST_BOMBS_DEFUSED:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastBombsDefused(), 0);
                    break;
                case LOWEST_BOMBS_DEFUSED:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastBombsDefused(), 0, true);
                    break;

                case HIGHEST_CASE_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastSGKills(), 0);
                    break;
                case LOWEST_CASE_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetLastSGKills(), 0, true);
                    break;

                case HIGHEST_REPORTS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCharacterReports(), -1);
                    break;
                case LOWEST_REPORTS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCharacterReports(), -1, true);
                    break;

                case HIGHEST_HOSTAGE_ARRESTS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCivilianArrests(), -1);
                    break;
                case LOWEST_HOSTAGE_ARRESTS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCivilianArrests(), -1, true);
                    break;

                case HIGHEST_HOSTAGE_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCivilianHits(), -1);
                    break;
                case LOWEST_HOSTAGE_HITS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCivilianHits(), -1, true);
                    break;

                case HIGHEST_HOSTAGE_INCAPS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCivilianIncaps(), -1);
                    break;
                case LOWEST_HOSTAGE_INCAPS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCivilianIncaps(), -1, true);
                    break;

                case HIGHEST_HOSTAGE_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCivilianKills(), -1);
                    break;
                case LOWEST_HOSTAGE_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetCivilianKills(), -1, true);
                    break;

                case HIGHEST_ENEMY_ARRESTS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyArrests(), -1);
                    break;
                case LOWEST_ENEMY_ARRESTS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyArrests(), -1, true);
                    break;

                case HIGHEST_ENEMY_INCAPS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyIncaps(), -1);
                    break;
                case LOWEST_ENEMY_INCAPS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyIncaps(), -1, true);
                    break;

                case HIGHEST_ENEMY_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyKills(), -1);
                    break;
                case LOWEST_ENEMY_KILLS:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyKills(), -1, true);
                    break;

                case HIGHEST_ENEMY_INCAPS_INVALID:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyIncapsInvalid(), -1);
                    break;
                case LOWEST_ENEMY_INCAPS_INVALID:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyIncapsInvalid(), -1, true);
                    break;

                case HIGHEST_ENEMY_KILLS_INVALID:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyKillsInvalid(), -1);
                    break;
                case LOWEST_ENEMY_KILLS_INVALID:
                    self.ChallengeRoundStatRecord(Stats[j], Players[i], Players[i].GetEnemyKillsInvalid(), -1, true);
                    break;
            }
        }
    }
    return Stats;
}

/**
 * Compare the current stat record holder's points with Player's Points
 * If the latter beats the record, replace the record holder
 * 
 * @param   struct'sRoundStat' StatEntry
 *          Current record entry
 * @param   class'Julia.Player' Player
 *          The stat record candiate
 * @param   float Points
 *          Player's points
 * @param   int TeamNumber
 *          Force team specific stat comparison. Pass -1 to ignore the players' teams
 * @param   bool bLowest (optional)
 *          Indicate whether best player is supposed to have the least of the compared points
 * @return  void
 */
protected function ChallengeRoundStatRecord(out sRoundStat StatEntry, Julia.Player Player, coerce float Points, int TeamNumber, optional bool bLowest)
{
    if (!(TeamNumber == -1 || Player.GetLastTeam() == TeamNumber))
    {
        return;
    }

    // Ignore players joined midgame in COOP
    if (self.Core.GetServer().IsCOOP() && Player.GetLastValidPawn() == None)
    {
        log(self $ ": skipping " $ Player.GetLastName() $ " (LastValidPawn=None)");
        return;
    }

    // Dont let just connected players take all of the "lowest" stat records
    if (bLowest)
    {
        if (Player.GetTimePlayed() / self.Core.GetServer().GetTimePlayed() < self.MinTimeRatio)
        {
            log(self $ ": skipping " $ Player.GetLastName() $ " (" $ Player.GetTimePlayed() $ " sec played)");
            return;
        }
    }
    // See if the player is actually better than the current record holders' stats
    if (StatEntry.Players.Length == 0 || (bLowest && Points < StatEntry.Points) || (!bLowest && Points > StatEntry.Points))
    {
        // Discard the list of the old record holders
        StatEntry.Players.Remove(0, StatEntry.Players.Length);
        StatEntry.Players[0] = Player;
        StatEntry.Points = Points;
    }
    // Extend the list
    else if (Points == StatEntry.Points)
    {
        StatEntry.Players[StatEntry.Players.Length] = Player;
    }
}

/**
 * Attempt to "guess" the best player of the round
 * 
 * @return  class'Julia.Player'
 */
protected function Julia.Player GetBestRoundPlayer()
{
    switch (self.Core.GetServer().GetOutcome())
    {
        // A tie
        case SRO_RoundEndedInTie :
            return self.GetBestScoredPlayer(-1);

        // COOP round
        case SRO_COOPCompleted:
        case SRO_COOPFailed:
            return self.GetBestCOOPPlayer();

        // SWAT victory in BS
        case SRO_SwatVictoriousNormal :
            return self.GetBestScoredPlayer(0);

        // Suspects victory in BS
        case SRO_SuspectsVictoriousNormal :
            return self.GetBestScoredPlayer(1);

        // SWAT victory in RD
        case SRO_SwatVictoriousRapidDeployment :
            return self.GetBestRDSwatPlayer();

        // Suspects victory in RD
        case SRO_SuspectsVictoriousRapidDeployment :
            return self.GetBestScoredPlayer(1);

        // SWAT victory in VIP
        case SRO_SwatVictoriousVIPEscaped :
        case SRO_SwatVictoriousSuspectsKilledVIPInvalid :
            return self.GetBestVIPSwatPlayer();

        // Suspects victory in VIP
        case SRO_SuspectsVictoriousKilledVIPValid :
        case SRO_SuspectsVictoriousSwatKilledVIP :
            return self.GetBestVIPSuspectsPlayer();

        // Suspects victory in SG
        case SRO_SuspectsVictoriousSmashAndGrab :
            return self.GetBestSGSuspectsPlayer();

        // Swat victory in SG
        case SRO_SwatVictoriousSmashAndGrab :
            return self.GetBestSGSwatPlayer();

        default:
            break;
    }
    return None;
}

/**
 * Return the round best swat player in RD
 * 
 * @return  class'Julia.Player'
 */
protected function Julia.Player GetBestRDSwatPlayer()
{
    local int i;
    local Julia.Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local array<Julia.Player> Players;

    log(self $ ": retrieving the best RD swat player");

    Players = self.Core.GetServer().GetPlayers();

    for (i = 0; i < Players.Length; i++)
    {
        // Ignore suspects
        if (Players[i].GetLastTeam() != 0)
        {
            continue;
        }

        CurrentStats[0] = Players[i].GetLastBombsDefused();
        CurrentStats[1] = Players[i].GetLastScore();
        CurrentStats[2] = Players[i].GetLastKills();
        CurrentStats[3] = Players[i].GetLastArrests();
        CurrentStats[4] = Players[i].GetLastDeaths()*-1;
        CurrentStats[5] = Players[i].GetLastArrested()*-1;

        log(self $ ": checking " $ Players[i].GetLastName());

        if (BestPlayer == None || class'Extension'.static.CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Players[i];
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.GetLastName());
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.GetLastName());

    return BestPlayer;
}

/**
 * Return the round best swat player in VIP Escort
 * 
 * @return  class'Julia.Player'
 */
protected function Julia.Player GetBestVIPSwatPlayer()
{
    local int i;
    local Julia.Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local array<Julia.Player> Players;

    Players = self.Core.GetServer().GetPlayers();

    log(self $ ": retrieving the best VIP swat player");

    for (i = 0; i < Players.Length; i++)
    {
        // Ignore suspects
        if (Players[i].GetLastTeam() != 0)
        {
            continue;
        }

        CurrentStats[0] = Players[i].GetLastVIPKillsInvalid()*-1;
        CurrentStats[1] = Players[i].GetLastVIPRescues();
        CurrentStats[2] = Players[i].GetLastScore();
        CurrentStats[3] = Players[i].GetLastKills();
        CurrentStats[4] = Players[i].GetLastArrests();
        CurrentStats[5] = Players[i].GetLastDeaths()*-1;
        CurrentStats[6] = Players[i].GetLastArrested()*-1;

        log(self $ ": checking " $ Players[i].GetLastName());

        if (BestPlayer == None || class'Extension'.static.CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Players[i];
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.GetLastName());
        }
    }

    // Set the escaped VIP the best best round player if no swat has rescued the VIP 
    if (BestPlayer != None && BestPlayer.GetLastVIPRescues() == 0)
    {
        log(self $ ": " $ BestPlayer.GetLastName() $ " is the best player with no vip rescues");

        for (i = 0; i < Players.Length; i++)
        {
            if (Players[i].GetLastVIPEscapes() > 0)
            {
                BestPlayer = Players[i];
                log(self $ ": " $ BestPlayer.GetLastName() $ " has escaped, hence the best player");
                break;
            }
        }
    }
    
    log(self $ ": at last the best player is " $ BestPlayer.GetLastName());

    return BestPlayer;
}

/**
 * Return the round best suspects player in VIP Escort
 * 
 * @return  class'Julia.Player'
 */
protected function Julia.Player GetBestVIPSuspectsPlayer()
{
    local int i;
    local Julia.Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local array<Julia.Player> Players;

    log(self $ ": retrieving the best VIP suspects player");

    Players = self.Core.GetServer().GetPlayers();

    for (i = 0; i < Players.Length; i++)
    {
        // Ignore swat players
        if (Players[i].GetLastTeam() != 1)
        {
            continue;
        }

        CurrentStats[0] = Players[i].GetLastVIPKillsInvalid()*-1;
        CurrentStats[1] = Players[i].GetLastVIPCaptures();
        CurrentStats[2] = Players[i].GetLastVIPKillsValid();
        CurrentStats[3] = Players[i].GetLastScore();
        CurrentStats[4] = Players[i].GetLastKills();
        CurrentStats[5] = Players[i].GetLastArrests();
        CurrentStats[6] = Players[i].GetLastDeaths()*-1;
        CurrentStats[7] = Players[i].GetLastArrested()*-1;

        log(self $ ": checking " $ Players[i].GetLastName());

        if (BestPlayer == None || class'Extension'.static.CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Players[i];
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.GetLastName());
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.GetLastName());

    return BestPlayer;
}

/**
 * Return the case escaped Smash&Grab suspects player
 * 
 * @return  class'Julia.Player'
 */
protected function Julia.Player GetBestSGSuspectsPlayer()
{
    local int i;
    local Julia.Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local array<Julia.Player> Players;

    log(self $ ": retrieving the best SG suspects player");

    Players = self.Core.GetServer().GetPlayers();

    for (i = 0; i < Players.Length; i++)
    {
        // Ignore swat players
        if (Players[i].GetLastTeam() != 1)
        {
            continue;
        }

        CurrentStats[0] = Players[i].GetLastSGEscapes();
        CurrentStats[1] = Players[i].GetLastScore();
        CurrentStats[2] = Players[i].GetLastKills();
        CurrentStats[3] = Players[i].GetLastArrests();
        CurrentStats[4] = Players[i].GetLastDeaths()*-1;
        CurrentStats[5] = Players[i].GetLastArrested()*-1;

        log(self $ ": checking " $ Players[i].GetLastName());

        if (BestPlayer == None || class'Extension'.static.CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Players[i];
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.GetLastName());
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.GetLastName());

    return BestPlayer;
}

/**
 * Return a Smash&Grab swat player with the highest number of case-carrying suspects kills
 * 
 * @return  class'Julia.Player'
 */
protected function Julia.Player GetBestSGSwatPlayer()
{
    local int i;
    local Julia.Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local array<Julia.Player> Players;

    log(self $ ": retrieving the best SG swat player");

    Players = self.Core.GetServer().GetPlayers();

    for (i = 0; i < Players.Length; i++)
    {
        // Ignore suspects
        if (Players[i].GetLastTeam() != 0)
        {
            continue;
        }

        CurrentStats[0] = Players[i].GetLastSGCryBaby();
        CurrentStats[1] = Players[i].GetLastSGKills();
        CurrentStats[2] = Players[i].GetLastScore();
        CurrentStats[3] = Players[i].GetLastKills();
        CurrentStats[4] = Players[i].GetLastArrests();
        CurrentStats[5] = Players[i].GetLastDeaths()*-1;
        CurrentStats[6] = Players[i].GetLastArrested()*-1;

        log(self $ ": checking " $ Players[i].GetLastName());

        if (BestPlayer == None || class'Extension'.static.CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Players[i];
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.GetLastName());
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.GetLastName());

    return BestPlayer;
}

/**
 * Return the best COOP player
 * 
 * @return  class'Julia.Player'
 */
protected function Julia.Player GetBestCOOPPlayer()
{
    local int i;
    local Julia.Player BestPlayer;
    local array<int> BestStats, CurrentStats;
    local array<Julia.Player> Players;

    Players = self.Core.GetServer().GetPlayers();

    log(self $ ": retrieving the best COOP player");

    for (i = 0; i < Players.Length; i++)
    {
        // Skip players connected midgame
        if (Players[i].GetLastValidPawn() == None)
        {
            continue;
        }

        CurrentStats[0] = Players[i].GetCivilianKills()*-1;
        CurrentStats[1] = Players[i].GetCivilianIncaps()*-1;
        CurrentStats[2] = Players[i].GetCivilianHits()*-1;
        CurrentStats[3] = Players[i].GetEnemyKillsInvalid()*-1;
        CurrentStats[4] = Players[i].GetEnemyIncapsInvalid()*-1;
        CurrentStats[5] = Players[i].GetLastDeaths()*-1;
        CurrentStats[6] = Players[i].GetEnemyArrests();
        CurrentStats[7] = Players[i].GetCivilianArrests();
        CurrentStats[8] = Players[i].GetEnemyKills()*-1;
        CurrentStats[9] = Players[i].GetCharacterReports();

        log(self $ ": checking " $ Players[i].GetLastName());

        if (BestPlayer == None || class'Extension'.static.CompareStats(CurrentStats, BestStats))
        {
            BestPlayer = Players[i];
            BestStats = CurrentStats;

            log(self $ ": best player is now " $ BestPlayer.GetLastName());
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.GetLastName());

    return BestPlayer;
}

/**
 * Return the best player from team TeamNumber sorted by score, kills, arrests, < deaths, < arrested
 * 
 * @param   int TeamNumber
 *          Pass -1 for a team-insensitive sorting
 * @return  class'Julia.Player'
 */
protected function Julia.Player GetBestScoredPlayer(int TeamNumber)
{
    local int i;
    local Julia.Player BestPlayer;
    local array<int> CurrentStats, BestStats;
    local array<Julia.Player> Players;

    Players = self.Core.GetServer().GetPlayers();

    log(self $ ": retrieving the best scored player for team " $ TeamNumber);

    for (i = 0; i < Players.Length; i++)
    {
        if (Players[i].GetLastTeam() == TeamNumber || TeamNumber == -1)
        {
            CurrentStats[0] = Players[i].GetLastScore();
            CurrentStats[1] = Players[i].GetLastKills();
            CurrentStats[2] = Players[i].GetLastArrests();
            CurrentStats[3] = Players[i].GetLastDeaths()*-1;
            CurrentStats[4] = Players[i].GetLastArrested()*-1;

            log(self $ ": checking " $ Players[i].GetLastName());

            if (BestPlayer == None || class'Extension'.static.CompareStats(CurrentStats, BestStats))
            {
                BestPlayer = Players[i];
                BestStats = CurrentStats;

                log(self $ ": best player is now " $ BestPlayer.GetLastName());
            }
        }
    }

    log(self $ ": at last the best player is " $ BestPlayer.GetLastName());

    return BestPlayer;
}

/**
 * Return a list of non-grenade weapons used by Player
 * 
 * @param   class'Julia.Player' Player
 * @return  array<class'Weapon'>
 */
static function array<Weapon> GetNonGrenadeWeapons(Julia.Player Player)
{
    local int i;
    local array<Julia.Weapon> Weapons, WeaponsFiltered;

    Weapons = Player.GetWeapons();

    for (i = 0; i < Weapons.Length; i++)
    {
        if (!Weapons[i].IsGrenade())
        {
            WeaponsFiltered[WeaponsFiltered.Length] = Weapons[i];
        }
    }

    return WeaponsFiltered;
}

/**
 * Return the total number of enemies hit by Player
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function int GetPlayerHits(Julia.Player Player)
{
    local int i, Hits;
    local array<Julia.Weapon> Weapons;

    Weapons = class'Extension'.static.GetNonGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        Hits += Weapons[i].GetHits();
    }

    return Hits;
}

/**
 * Return the total number of teammates hit by Player
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function int GetPlayerTeamHits(Julia.Player Player)
{
    local int i, TeamHits;
    local array<Julia.Weapon> Weapons;

    Weapons = class'Extension'.static.GetNonGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        TeamHits += Weapons[i].GetTeamHits();
    }

    return TeamHits;
}

/**
 * Return the number of ammo fired by Player
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function int GetPlayerAmmoFired(Julia.Player Player)
{
    local int i, Shots;
    local array<Julia.Weapon> Weapons;

    Weapons = class'Extension'.static.GetNonGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        Shots += Weapons[i].GetShots();
    }

    return Shots;
}

/**
 * Return the percent value of Player's accuracy for non-grenade weapons
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function int GetPlayerAccuracy(Julia.Player Player)
{
    local int Hits, Shots;

    Hits = class'Extension'.static.GetPlayerHits(Player);
    Shots = class'Extension'.static.GetPlayerAmmoFired(Player);

    // Avoid 100% accuracy with only 2 tazer direct hits 
    if (Shots >= class'Extension'.const.MIN_ACCURACY_SHOTS)
    {
        return int(float(Hits) / float(Shots) * 100.0);
    }

    return 0;
}

/**
 * Return a list of grenades used by Player
 * 
 * @param   class'Julia.Player' Player
 * @return  array<class'Weapon'>
 */
static function array<Weapon> GetGrenadeWeapons(Julia.Player Player)
{
    local int i;
    local array<Julia.Weapon> Weapons, WeaponsFiltered;

    Weapons = Player.GetWeapons();

    for (i = 0; i < Weapons.Length; i++)
    {
        if (Weapons[i].IsGrenade())
        {
            WeaponsFiltered[WeaponsFiltered.Length] = Weapons[i];
        }
    }

    return WeaponsFiltered;
}

/**
 * Return the total number of grenade enemy hits
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function int GetPlayerNadeHits(Julia.Player Player)
{
    local int i, Hits;
    local array<Julia.Weapon> Weapons;

    Weapons = class'Extension'.static.GetGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        Hits += Weapons[i].GetHits();
    }

    return Hits;
}

/**
 * Return the total number of teamnades
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function int GetPlayerNadeTeamHits(Julia.Player Player)
{
    local int i, TeamHits;
    local array<Julia.Weapon> Weapons;

    Weapons = class'Extension'.static.GetGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        TeamHits += Weapons[i].GetTeamHits();
    }

    return TeamHits;
}

/**
 * Return the total number grenades thrown
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function int GetPlayerNadeThrown(Julia.Player Player)
{
    local int i, Thrown;
    local array<Julia.Weapon> Weapons;

    Weapons = class'Extension'.static.GetGrenadeWeapons(Player);

    for (i = 0; i < Weapons.Length; i++)
    {
        Thrown += Weapons[i].GetShots();
    }

    return Thrown;
}

/**
 * Return the percent value of Player's grenade accuracy
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function int GetPlayerNadeAccuracy(Julia.Player Player)
{
    local int Hits, Thrown;

    Hits = class'Extension'.static.GetPlayerNadeHits(Player);
    Thrown = class'Extension'.static.GetPlayerNadeThrown(Player);

    if (Thrown >= class'Extension'.const.MIN_ACCURACY_THROWN)
    {
        return int(float(Hits) / float(Thrown) * 100.0);
    }

    return 0;
}

/**
 * Return the Player's best kill distance
 * 
 * @param   class'Julia.Player' Player
 * @return  int
 */
static function float GetPlayerKillDistance(Julia.Player Player)
{
    local int i;
    local float Distance, BestDistance;
    local array<Julia.Weapon> Weapons;

    Weapons = Player.GetWeapons();

    for (i = 0; i < Weapons.Length; i++)
    {
        Distance = Weapons[i].GetBestKillDistance() / 100;

        if (Distance > BestDistance)
        {
            BestDistance = Distance;
        }
    }

    return BestDistance;
}

/**
 * Perform an integer array comparison and tell whether array This is greater than array That
 * 
 * @param   array<int> This
 * @param   array<int> That
 * @return  bool
 */
static function bool CompareStats(array<int> This, array<int> That)
{
    local int i;

    for (i = 0; i < This.Length; i++)
    {
        if (i >= That.Length)
        {
            log("CompareStats(): the other array has no element with the index of " $ i);
            return true;
        }
        if (This[i] > That[i])
        {
            log(This[i] $ " > " $ That[i]);
            return true;
        }
        // Stats equal - attempt the next cycle of comparison
        else if (This[i] == That[i])
        {
            log(This[i] $ " == " $ That[i]);
            continue;
        }
        else
        {
            log(This[i] $ " < " $ That[i]);
            return false;
        }
    }
    // If players have all stats equal, assume the other player is better
    return false;
}

/**
 * Return a Locale normalized string for a dashed string,
 * so HIGHEST_HITS would be converted to HighestHits
 * 
 * @param   string DashedString
 * @return  string
 */
static function string GetLocaleString(string DashedString)
{
    local int i;
    local array<string> Words;

    // Split by a dash
    Words = class'Utils.StringUtils'.static.Part(Lower(DashedString), "_");

    for (i = 0; i < Words.Length; i++)
    {
        // Make the first letter uppercase
        Words[i] = class'Utils.StringUtils'.static.Capitalize(Words[i]);
    }

    return class'Utils.ArrayUtils'.static.Join(Words, "");
}

/**
 * Return a string with Number rounded up to 2 decimal points
 * Remove the fractional part if it filled with zeroes
 * 
 * @param   float Number
 * @return  string
 */
static function string GetNeatNumericString(float Number)
{
    if (Number % 1.0 == 0.0)
    {
        return string(int(Number));
    }
    return class'Utils.StringUtils'.static.Round(Number, 2);
}

/**
 * Colorify a Player's name
 * 
 * @param   class'Julia.Player' Player
 * @return  string
 */
static function string ColorifyName(Julia.Player Player)
{
    return class'Julia.Utils'.static.GetTeamColoredName(Player.GetLastName(), Player.GetLastTeam(), Player.WasVIP());
}

event Destroyed()
{
    if (self.Core != None)
    {
        self.Core.GetDispatcher().UnbindAll(self);
        self.Core.UnregisterInterestedInMissionStarted(self);
        self.Core.UnregisterInterestedInMissionEnded(self);
        self.Core.UnregisterInterestedInPlayerDisconnected(self);
    }

    self.ClearPlayerStatsCache();

    Super.Destroyed();
}

defaultproperties
{
    Title="Julia/Stats";
    Version="1.0.0";
    LocaleClass=class'Locale';

    MaxNames=1;
    MinTimeRatio=0.3;
}

/* vim: set ft=java: */