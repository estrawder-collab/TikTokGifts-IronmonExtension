# TikTok Gifts – Ironmon Tracker extension

Lets TikTok LIVE gifts change your Pokémon game while you play in BizHawk. Works with FireRed, LeafGreen, Emerald, Ruby and Sapphire, and with the Nat. Dex builds of FireRed and Emerald.
Out of the box, a **Hat and Mustache** gives your first party Pokémon +1 level.

```
TikTok LIVE ──► bridge (Node.js) ──► TikTokGifts/gifts.txt ──► TikTokGifts.lua (inside the Tracker)
```

By **Demon_Quingar91**. Latest version: [Releases](https://github.com/estrawder-collab/TikTokGifts-IronmonExtension/releases/latest).

## What you need

- **BizHawk** with the [Ironmon Tracker](https://github.com/besteon/Ironmon-Tracker) set up for your game.
- **Pokémon FireRed, LeafGreen, Emerald, Ruby or Sapphire (US)**, or the Nat. Dex ROM hack of FireRed or Emerald. You supply your own game file.
- **[Node.js](https://nodejs.org)** (current LTS version) for the bridge.
- **TikFinity Desktop** (free) or **TikOps** to pass your stream's gifts to the bridge.

Not needed, but available: the [Nat. Dex Abilities patch](#optional-nat-dex-abilities-patch), a ROM patch that makes the newer abilities, moves and items actually work in Nat. Dex FireRed. The extension runs fine without it.

## Setup (Windows, no typing commands)

The bridge doesn't connect to TikTok itself anymore. TikTok's connection library now requires a paid signing plan, so the bridge gets gifts from a streaming tool you run instead:
- **TikFinity Desktop (free, recommended).** Its local event feed (`ws://localhost:21213`) is picked up automatically. It can run alongside TikOps, which keeps doing your sounds and actions.
- **TikOps webhooks.** Point a TikOps webhook at `http://localhost:21214/gift`. See "Using TikOps" below.

1. **Copy the files.** Download the zip from the Releases page and unzip it. Put `TikTokGifts.lua` and the `TikTokGifts` folder into your Tracker's `extensions` folder, replacing old copies.
2. **Turn it on.** In BizHawk, open the Tracker's settings (gear icon) → **Extensions** → enable **TikTok Gifts**.
3. **Test it.** In `extensions\TikTokGifts\bridge`, double-click **Send Test Gift.bat**. Your first Pokémon should gain a level within a couple of seconds.
4. **Go live.** Start your LIVE, open TikFinity Desktop and connect it to your stream. Then double-click **Start TikTok Bridge.bat** and leave that window open. It should say "Connected to TikFinity!".

No `npm install` is needed. Always run the bridge from the copy inside the Tracker's `extensions` folder, not Downloads. When it starts, it prints where it's writing gifts.

### Using TikOps
In TikOps, create an action with a **webhook** for the gifts you want and point it at:
```
http://localhost:21214/gift?user={username}&gift={giftname}&coins={coins}&count={count}
```
Replace the `{...}` parts with TikOps' own placeholders for username, gift name, coin value and count. The receiver also accepts JSON bodies with fields such as `username`, `giftName`, `coins` and `count`. If a request arrives without a gift name, the bridge window prints what it received, so you can see TikOps' format.

This only works if TikOps sends webhooks from the TikOps app on your PC. If they come from TikOps' servers, they can't reach `localhost`, so use TikFinity for the game instead.

### Advanced: direct mode
`node tiktok-bridge.js --direct USERNAME` connects to TikTok with tiktok-live-connector. It needs `npm install` and currently a paid Euler Stream plan, with the API key in `apikey.txt`.

## Updating

In the Tracker, open **Extensions → TikTok Gifts → Check for Updates**.

- **Settings and gift rules made in the Options window are kept.** They live in `extensions\TikTokGifts\config.txt`, which an update never touches.
- **Edits made by hand inside `TikTokGifts.lua` are replaced**, because updating replaces that file. Your old file is saved first as `extensions\TikTokGifts\TikTokGifts-before-update.lua.txt`, so you can copy your changes back.

## The Options window

Everything most people want to change can be set without opening a file. In the Tracker, open **Extensions → TikTok Gifts → Options**.

**Settings window**
- **Ruleset:** the IronMon ruleset to keep gifts legal for (the ironmon.gg rules or the Nat. Dex versions of them), the BST limit, and whether newer moves of the banned kinds are skipped too.
- **Generation limit:** the highest generation allowed for random Pokémon, moves, abilities and items.
- **Level-ups and Exp. Candies:** whether a level-up can evolve, teach moves and raise friendship; whether you're asked which move to forget when all four slots are full; how candy gifts are given; the most levels or items one gift can give.
- **Gift handling:** how streaks repeat, the pause between effects, and how long held gifts are retried.
- **Effect details:** modes for the ability and EV effects, the level of a replacement Pokémon, STAB move power range, the surprise Gym Leader's strength, and whether Mega Evolutions and other alternate forms can be picked on Nat. Dex games.

Opening Options takes the Tracker back to its main Pokémon screen, and the Tracker stays clickable while the window is open (BizHawk 2.9 or newer), so you can watch your Pokémon change as you save settings or test effects. Drag the window wherever suits your stream layout: it stays there. Saving, testing an effect and editing rules all update the window in place, and its position is remembered the next time it opens, even after a restart. The move question window remembers its own spot the same way.

Press **Save** and the new settings are used straight away. Nothing needs a restart. A value that doesn't make sense (letters where a number goes) is left as it was, and the window tells you which one.

**Gift rules window** (the **Edit gift rules...** button)
- The list at the top shows every rule in the order gifts are checked.
- To add or change a rule: choose how to match the gift (its name, its exact coin value, or "this many coins or more"), type the name or number, pick what it does, and press **Save this rule**. A rule for the same gift replaces the old one.
- **Edit selected** loads a rule into the boxes. **Remove selected** deletes it.
- **Test this effect now** runs the chosen effect on your game right away, without a gift or the bridge.
- **Reset rules to defaults** brings back the rules the extension ships with.

Rules are saved as you make them. Once you change a rule here, your list is the one that's used, and later updates won't add or change rules behind your back.

Both windows save to `extensions\TikTokGifts\config.txt`. You can copy that file to another PC, or share it with another streamer, to carry your whole setup over. Delete it to go back to the defaults.

A few advanced things are still set in `TikTokGifts.lua`: the list of healing items and their odds, abilities that are never rolled, and the retry hotkey.

## Set up your own gifts

Every streamer's gifts are different, so the rules that decide what each gift does are yours to edit. The easy way is the **Gift rules window** described above. This section is the by-hand way: the same rules live in one list, `GIFT_RULES`, near the top of `TikTokGifts.lua`, and that list is what's used until you change a rule in the Options window. The rules that ship with the extension are only a starting point.

### 1. Open the rules
1. Open your Tracker folder, then `extensions`.
2. Right-click `TikTokGifts.lua` → **Open with** → **Notepad**. (Notepad++ also works. Don't use Word: it changes the quote marks and breaks the file.)
3. Scroll to `local GIFT_RULES = {`. Just above it is the list of every effect you can use.

Make a copy of the file first, so you can go back if something breaks.

### 2. How a gift finds its rule
When a gift arrives, the extension checks three lists in order and uses the first match:

1. **`byName`**: the gift's name.
2. **`byExactCoins`**: what one of that gift costs, for gifts not listed by name.
3. **`byCoins`**: "this many coins or more" tiers, for everything else. Empty by default.

A gift that matches nothing does nothing.

### 3. Write a rule
Each rule is one line, and every line ends with a comma.

**By name.** The name goes in lowercase, inside `["..."]`:
```lua
["rose"]            = { effect = "healParty" },
["hat and mustache"] = { effect = "levelUp", amount = 1 },
["lion"]            = { effect = "expCandyXL" },
```

**By coin value.** The number is the price of one gift:
```lua
[1]   = { effect = "healParty" },
[99]  = { effect = "levelUp", amount = 2 },
```

**By "this many or more".** Put these inside `byCoins`, highest first:
```lua
{ minCoins = 1000, effect = "spawnGymLeader" },
{ minCoins = 100,  effect = "teachRandomMove" },
{ minCoins = 1,    effect = "healParty" },
```

- To **change** what a gift does, change the word after `effect =` to another effect from the table below.
- To **add** a gift, copy a line and change the name (or number) and the effect.
- To **remove** a gift, delete its line, or set `effect = "none"`.
- List each name or coin value **once**. If it appears twice, the line further down wins.
- `amount` is only used by `levelUp` and `lowerLevel` (how many levels) and by the item effects (how many items).

### 4. Find a gift's exact name
The name must match what TikTok sends, letter for letter. While you're live, the bridge window prints every gift it receives:
```
[gift] someviewer sent 1x Hat and Mustache (99 coins each)
```
Use that name in lowercase (`hat and mustache`) and that coin value. Watch for odd spellings and punctuation: TikTok's "Doughnut" and "Bravo!" need `["doughnut"]` and `["bravo!"]`. If you're unsure, add both spellings as two lines.

### 5. Save and reload
Save the file, then in the Tracker open **Extensions** and turn **TikTok Gifts** off and on again (or restart the Tracker). Rules are only read when the extension starts.

### 6. Test without going live
In `extensions\TikTokGifts\bridge`, right-click **Send Test Gift.bat** → **Edit**. The line that matters is:
```
node tiktok-bridge.js --test "Hat and Mustache" 30 1
```
The three values are the gift name, the coins per gift and how many were sent. Change them to the gift you want to try, save, and double-click the file. The BizHawk Lua Console shows what happened.

### 7. Streaks (the same gift sent several times)
- `levelUp` and `lowerLevel`: the amount is multiplied by the streak, up to `maxLevelsPerGift`.
- `giveHealingItem` and the Exp. Candies: one item per gift, up to `maxItemsPerGift`.
- Everything else fires `repeatOtherEffects` times. The default is once per streak.

These three limits are in `SETTINGS`, right below `GIFT_RULES`, along with the other options.

### If it stops working after an edit
- **The extension won't turn on, or the Lua Console shows an error with a line number.** Look at that line and the one above it. The usual causes are a missing comma at the end of a line, a missing quote mark or bracket, or curly quotes pasted from another program.
- **A gift does nothing.** Check the name is lowercase and spelled the way the bridge window shows it, and that you reloaded the extension.
- **"Unknown effect in GIFT_RULES" in the Lua Console.** The word after `effect =` isn't one of the effects in the table. Capitals matter: `levelUp`, not `levelup`.
- **Still stuck?** Put your backup copy back.

Rules edited by hand in `TikTokGifts.lua` are replaced when the extension updates (see "Updating"). Rules made in the Options window are not.

## Match your ruleset

Two settings keep what gifts **give** you legal for the run you're doing. Both are in `SETTINGS`, right below `GIFT_RULES`, and both are off by default.

### IronMon ruleset

Pick it in the Options window (**Ruleset**), or set it by hand:

```lua
ruleset = "Nat. Dex Kaizo",
```

There are eleven choices:

- `"none"`: no rules applied.
- `"Standard"`, `"Ultimate"`, `"Kaizo"`, `"Super Kaizo"`, `"Survival"`: the rules on [ironmon.gg](https://ironmon.gg) and the banned-move list it links to.
- `"Nat. Dex Standard"`, `"Nat. Dex Ultimate"`, `"Nat. Dex Kaizo"`, `"Nat. Dex Super Kaizo"`, `"Nat. Dex Survival"`: the same five with the [Nat. Dex Ruleset Changes](https://github.com/CyanSMP64/NatDexExtension/wiki/Nat.-Dex-Ruleset-Changes) (v1.2.0 and later) from the NatDexExtension wiki.

You choose which set applies; the extension doesn't switch on its own. If a Nat. Dex ROM is loaded with one of the plain rulesets, the Lua Console reminds you that the Nat. Dex version exists. Both sets are as published in November 2026.

**Random Pokémon** (`replaceLead`)

| Difficulty | Plain ruleset (ironmon.gg) | "Nat. Dex ..." ruleset |
|---|---|---|
| Standard, Ultimate | No legendary, sub-legendary or mythical Pokémon. | No strong legendary or mythical Pokémon (50 species on a Nat. Dex ROM). Sub-legendaries are allowed. |
| Kaizo, Super Kaizo, Survival | The same, and BST 598 or less ("No using 599+ BST Pokémon"). | The same, and BST 599 or less ("600 BST or higher" is banned). |

On Nat. Dex games, Mega Evolutions and other alternate forms follow the same rules. A legendary's forms are excluded with it (Mega Mewtwo, Primal Kyogre, the Galarian birds under the plain rulesets, and so on), and the BST limit is checked against the form's own stats, so the stronger Megas are out under Kaizo, Super Kaizo and Survival (38 of the 94 Megas have a BST under 600).

**Random moves** (`teachRandomMove`, `teachStabMove`, a new Pokémon's moves)

| Ruleset | Never given |
|---|---|
| Ultimate | HM moves. The "Nat. Dex ..." rulesets don't skip them: Nat. Dex allows HM moves in battle unless they were taught with the HM item, and a gift isn't the HM item. |
| Kaizo | The Kaizo banned-move list: healing, status-healing, draining and pivoting moves, Spore and Assist, plus HM moves (not in "Nat. Dex Kaizo"). |
| Super Kaizo | The Super Kaizo list: as Kaizo, but draining attacks are allowed. |
| Survival | The Survival list: as Super Kaizo, but Cut, Spore and status-healing moves are allowed. |

**Random abilities** (`randomizeAbility`, and which ability a new Pokémon gets)

| Ruleset | Never given |
|---|---|
| Kaizo | Huge Power, Pure Power |
| Super Kaizo | Huge Power, Pure Power; and Battle Armor, Shell Armor, Magic Guard on any Pokémon |
| Survival | Huge Power, Pure Power, Battle Armor, Shell Armor, Parental Bond, Protean, Fur Coat, Magic Guard |

As in the rules, the abilities with a BST condition are still fine on weak Pokémon: BST 399 or less with the plain rulesets, 420 or less with the "Nat. Dex ..." ones.

Details worth knowing:
- **Legendaries** come from the Legendary Pokémon list both rule pages point to, and are found by name, so the ROM's order doesn't matter.
- **BST limit.** `rulesetMaxBST = "auto"` uses the numbers in the table. Set a number to use your own.
- **Newer moves.** The published move lists stop at Gen 7. With `rulesetNewerMoves = true` (the default), Gen 7–9 moves of the same kinds are skipped too: Strength Sap, Life Dew, Jungle Healing, Lunar Blessing, Flip Turn, Shed Tail, Chilly Reception, and for Kaizo also Take Heart, Bouncy Bubble, Bitter Blade and Matcha Gotcha. That part is this extension's own reading, not an official list.
- **Starter exceptions don't apply.** Some legendaries may be picked as a starter under the Nat. Dex rules. A gift Pokémon isn't a starter, so it never gets one.
- **Healing items** from `giveHealingItem` are legal to receive in every ruleset. When you're allowed to use them is still up to you.
- **The Gym Leader's team** from `spawnGymLeader` is your opponent, so the ruleset doesn't apply to it.
- **The ruleset doesn't block a gift itself.** A heal, a level-up or an Elite Four warp still happens. If your rules don't allow something, leave that effect out of `GIFT_RULES`.
- Moves that are legal only in some battles (for example draining attacks in Survival trainer battles) follow the published list as it stands.
- Nat. Dex's other rulesets (Evo Kaizo, Chaos Kaizo, Survival Revival, IronMON Journey) don't have presets. Use the closest one above.

The Lua Console confirms what's active, for example `Ruleset: Nat. Dex Kaizo (50 legendary Pokemon excluded, BST 599 or less, 54 banned moves skipped, banned abilities skipped)`.

### Generation limit

If your run only allows certain generations, set the highest one allowed for each kind of thing:

```lua
generationLimit = {
    pokemon = 3,
    moves = 3,
    abilities = 3,
    items = 3,
},
```

That example is a Gen 1–3 run. Use `5` for Gen 1–5, and so on. `9` (the default) means everything the ROM has. Each line is separate, so you can limit only the Pokémon and leave moves and abilities open. It works together with `ruleset`: a Gen 1–3 Kaizo run is `ruleset = "kaizo"` plus the example above.

| Setting | What it limits |
|---|---|
| `pokemon` | Random Pokémon: `replaceLead` and the surprise Gym Leader's team. |
| `moves` | Random moves: `teachRandomMove`, `teachStabMove`, and the moves of those random Pokémon. |
| `abilities` | `randomizeAbility`. Abilities first appeared in Gen 3, so 1, 2 and 3 all mean "Gen 3 abilities only". |
| `items` | Below 8, Exp. Candy gifts give the Exp. Points directly instead of the item, since the candies are Gen 8 items. Healing items are all Gen 1–3 already. |

When a limit is active, the Lua Console confirms it at startup, for example `Ruleset limit: pokemon Gen 1-3, moves Gen 1-3`.

On Nat. Dex games, a Mega Evolution or other alternate form counts as the generation that introduced the form, not its base species: Megas and Primals are Gen 6 (the newest Megas are Gen 9), Alolan forms Gen 7, Galarian and Hisuian forms Gen 8, Paldean forms Gen 9. A Gen 1–5 run therefore gets no Megas, and a Gen 1–3 run only gets Castform's and Deoxys's forms.

### What neither setting changes

These come from your ROM, not from the extension:
- **Evolutions and level-up moves** follow the ROM's own tables. If your randomizer kept those inside your ruleset, gifts stay inside it too.
- **A species' own abilities** are whatever the ROM gives it.
- **Nat. Dex "evolve every level" mode** rolls any species, exactly as the game does.

On the original games (FireRed, LeafGreen, Emerald, Ruby, Sapphire) everything is Gen 1–3 already, so only generation settings of 1 or 2 change anything there. The generation limit knows the Pokémon, move and ability order of the original games and of Nat. Dex FireRed 1.2.x. On a ROM that orders its Pokémon differently, the extension says so in the Lua Console and ignores the generation limit instead of guessing.

## Effects

"Lead" means the first Pokémon in your party.

| Effect | Default gift | What it does |
|---|---|---|
| `eliteFourWarp` | Diamond Gun, 5000 coins | The next door, staircase, cave entrance or warp tile you take sends you into the first Elite Four room (Lorelei's in FireRed and LeafGreen, Sidney's in Emerald, Ruby and Sapphire), and your lead is levelled up to Lv.100 (learning moves and evolving on the way) with max IVs, EVs and PP. See "Elite Four warp" below. |
| `spawnGymLeader` | Meteor Shower, 3000 coins | A random Gym Leader of your game's region challenges you on the spot with 6 Pokémon of their type, at your highest party level. Their team has max IVs and EVs, random moves and random abilities. See "Surprise Gym Leader" below. |
| `replaceLead` | Galaxy, 1000 coins | Releases the lead and gives you a random Lv.15 Pokémon with random moves, IVs, EVs, nature and ability. The old one's raw data is saved to `TikTokGifts/released_pokemon.txt`. |
| `maxIVs` | Manifesting, 500 coins | Lead gets 31 IVs in every stat. |
| `maxEVs` | Punch Cuddle, 400 coins | Lead gets max EVs. `maxEVsMode = "all"` (252 everywhere) or `"legal"` (252/252/4). |
| `teachStabMove` | GOAT, 200 coins | Lead learns a random damaging move of its own type. It fills an empty slot, or replaces a random move if there isn't one. |
| `teachRandomMove` | 150 coins | Lead learns any random move, using the same slot rule. |
| `giveHealingItem` | October, 88 coins | Puts one random healing item in your bag per gift: potions, status heals, Revives, drinks, Ethers and so on. Cheap items are more common. Streaks give one item per gift (up to `maxItemsPerGift`). Edit the `healingItems` list to change the items or their odds. |
| `levelUp` (`amount`) | Hat and Mustache, 99 coins | Lead gains levels the way a Rare Candy gives them: it evolves if it now qualifies and learns its level-up moves. Streaks multiply, capped by `maxLevelsPerGift`. See "Level-ups work like a Rare Candy" below. |
| `expCandyXS`, `expCandyS`, `expCandyM`, `expCandyL`, `expCandyXL` | not set | An Exp. Candy: 100, 800, 3,000, 10,000 or 30,000 Exp. Points. On a ROM that has Exp. Candy items, the candy goes into your bag; otherwise the points go straight to your lead. One candy per gift, so streaks give several (capped by `maxItemsPerGift`). See "Exp. Candies" below. |
| `randomizeIVs` | Perfume, 20 coins | Lead's IVs are re-rolled, each 0–31. |
| `lowerLevel` (`amount`) | not set | Lead loses levels (minimum Lv.1). Streaks multiply. |
| `randomizeEVs` | Bravo!, 15 coins | Lead's EVs are re-rolled: 510 points spread randomly (`randomEVsMode = "legal"`), or each stat 0–255 on its own (`"wild"`). |
| `randomizeAbility` | Gold Boxing Gloves, 10 coins | See "Abilities" below. |
| `randomStatus` | Finger Heart, 5 coins | Lead falls asleep or gets poisoned, burned or paralyzed. |
| `healParty` | Rose, Doughnut, 30 coins | Restores HP and clears status for the whole party. PP isn't restored. Works during battles too, but fainted Pokémon are only revived out of battle. |
| `poisonLead`, `stealItem`, `resetEVs` | not set | Extra effects you can assign to any gift. |
| `none` | | Ignore this gift. |

### Elite Four warp
The gift arms the warp, and it fires on the next door-style warp you take. Walking between outdoor routes, Fly and whiting out don't trigger it. When it fires, it:
- Clears the Elite Four "defeated" flags. In FireRed and LeafGreen that is Lorelei, Bruno, Agatha, Lance and the Champion, plus all six Champion trainer flags; in Emerald, Ruby and Sapphire it is Sidney, Phoebe, Glacia and Drake.
- Resets the League scene variable to 0.
- Boosts your lead to Lv.100 with 31 IVs, max EVs (`maxEVsMode`) and 3 PP Ups on every move, with PP refilled. Damage it had already taken carries over. Turn this off with `eliteFourBoostLead = false`.
- The lead reaches Lv.100 **as if it had earned the experience**, one level at a time, with the same rules and settings as a `levelUp` gift: it learns the moves it would have learned on the way, evolves when it qualifies (through every stage it passes), and gains friendship. If it already knows four moves, you get the move question for each new move, one after another, with the game paused until you choose; moves you pick there get their 3 PP Ups as well. A low-level lead can bring a dozen or more questions, so set `levelUpFullMoves = "skip"` if you'd rather keep your moves, or turn `levelUpLearnsMoves` / `levelUpEvolves` off to get the plain boost back.
- Sends you to the entrance of the first room: Lorelei's, or Sidney's in Emerald, Ruby and Sapphire.

These are the same resets the game does itself after the Hall of Fame or a whiteout. You arrive like a normal challenger: you walk in, the entrance seals behind you, and every room opens as you win. Gym badges aren't touched.

The only way out is to beat the Champion or white out. A whiteout sends you to your last Pokémon Center, and the game resets the League as usual. Warps that cutscenes trigger count as doors too, so avoid arming it right before a story event.

### Surprise Gym Leader
When the gift lands (and you're free to walk around, not in a menu or text box), a message pops up and the battle starts right away. The leader is picked at random, and their Pokémon match their type:

| Leader | Types |
|---|---|
| Brock | Rock, Ground |
| Misty | Water |
| Lt. Surge | Electric |
| Erika | Grass |
| Koga | Poison |
| Sabrina | Psychic |
| Blaine | Fire |
| Giovanni | Ground |

In Emerald, Ruby and Sapphire it is one of the Hoenn leaders instead:

| Leader | Types |
|---|---|
| Roxanne | Rock |
| Brawly | Fighting |
| Wattson | Electric |
| Flannery | Fire |
| Norman | Normal |
| Winona | Flying |
| Tate & Liza | Psychic |
| Juan (Emerald) or Wallace (Ruby, Sapphire) | Water |

Types are read from your ROM, so randomized types count. Tate & Liza fight a double battle, so they are only picked when you have at least two Pokémon able to fight.

- **It's a normal trainer fight.** You don't get a badge. The leader's "defeated" flag is put back afterwards, so their real Gym battle still happens later.
- **Losing works like losing to any trainer:** you white out.
- **Level:** the team's level is your highest party level. Use `gymLeaderLevelBonus` to make them stronger or weaker, and `gymLeaderEVs = "legal"` for a random 510-point EV spread instead of 252 everywhere.
- **How it works:** the extension writes a tiny event script into spare memory of the game's own script engine (RAM only; your ROM file isn't changed) and starts it there.

### Abilities
Gen 3 Pokémon only store *which of their species' two abilities* they use. That leaves two modes:
- `abilityMode = "slot"` (default): switches to the species' other ability. Pokémon with only one possible ability are skipped.
- `abilityMode = "rom"`: any random ability (Wonder Guard excluded) by editing the species in the loaded ROM. This changes every Pokémon of that species, including wild and trainer ones, until you restart the game, and the Tracker may keep showing the old ability.

## Held gifts (nothing gets wasted)

If a gift can't do anything right now, it's **held** and retried every 10 seconds instead of being thrown away. That covers things like a heal when everyone is already healthy, an egg in the first slot, a full bag, or a lead already at Lv.100.
- The Lua Console says "Holding ..." once, then "... (was held)" when it finally lands.
- To retry all held gifts right away, press **Insert** in BizHawk, or double-click **Retry Held Gifts.bat** in the bridge folder.
- A held gift is dropped after 15 minutes (`retryForMinutes`; 0 = never). You can change the hotkey with `retryHotkey`.

**During battles:** `healParty` and `giveHealingItem` apply immediately. A heal also updates the battle's copy of your active Pokémon, so it counts at once; the HP bar catches up on the next turn. All other effects wait and apply as soon as the battle ends.

## Things to know

- **Level-ups work like a Rare Candy, minus the animation.** After each level gained from `levelUp`, the extension applies the game's own level-up rules straight to the Pokémon:
  - **Evolution.** If the Pokémon now meets its evolution rule (level, friendship, Tyrogue's Attack vs Defense, Wurmple's personality, beauty, and the Nat. Dex rules for gender, nature, Regional Rock and caves), it evolves on the spot. An Everstone still stops it. Evolutions into Pokémon from any generation happen right away; there is no National Dex requirement. Trade and stone evolutions are not level-ups, so they don't happen. The evolution table is read from the loaded ROM, so randomized evolutions are followed. Nat. Dex's "evolve every level" mode makes the same roll the game does: any species with the same growth rate, Megas and alternate forms included.
  - **Moves.** Level-up moves are learned into empty move slots. If the Pokémon already knows four moves, a window pops up: it names the new move with its type, power, accuracy and PP, and you choose which move to forget, or to keep all four. **The game is paused and no other gift is applied until you choose.** Closing the window counts as keeping all four. If one gift brings several moves, you're asked about them one after another. Set `levelUpFullMoves = "skip"` (or "New move with 4 moves known" in Options) to skip such moves without asking.
  - **Friendship** goes up like a Rare Candy's (+5, +3 or +2).
  - There's no animation and no B button to cancel, and the Pokédex isn't updated. Turn any part off with `levelUpEvolves`, `levelUpLearnsMoves` and `levelUpFriendship` in `SETTINGS`.
  - `lowerLevel` never un-evolves a Pokémon or removes moves. Stats, HP and EXP are always recalculated from the ROM's base stats, so randomized ROMs work.
- **Exp. Candies** come in five sizes and follow `expCandyMode` in `SETTINGS`:
  - `"auto"` (default): if the loaded ROM has Exp. Candy items, the real candy is added to your bag's Items pocket, even during a battle, and you use it yourself like a Rare Candy. If the pocket is full, the gift is held. On any other ROM, the Exp. Points go straight to your lead once you're out of battle.
  - `"direct"`: always give the points straight to the lead. `"item"`: only ever give the item.
  - Points given directly work like the candy does in the newer games: every level passed teaches its moves (asking you first if all four slots are full), then there is one evolution check at the end, and friendship rises once. It stops at Lv. 100.
- Built for the US versions of **FireRed and LeafGreen (v1.0/v1.1)**, **Emerald**, **Ruby and Sapphire (v1.0–v1.2)**, and the **Nat. Dex** ROM hacks of FireRed and Emerald (1.2.x). LeafGreen addresses are included but untested. Other languages aren't supported. If the ROM's data tables can't be read, only the heal, status, item and warp effects run.

## Emerald, Ruby and Sapphire

The extension recognises the game from the ROM and switches to that game's addresses by itself; there is nothing to set. Every effect works the same as in FireRed, with these differences:

- **Elite Four warp** leads to Sidney's room in Ever Grande City, and **Surprise Gym Leader** picks from the Hoenn leaders (see both sections above).
- **Espeon and Umbreon:** these games have a clock, so a gift level-up can evolve a friendly Eevee. As in the game itself, it becomes Espeon when the in-game clock reads 12:00–23:59 and Umbreon when it reads 0:00–11:59.
- **Bag space:** the Items pocket holds 20 kinds of item in Ruby and Sapphire and 30 in Emerald (FireRed has 42). When it's full, an item gift is held until there is room.
- **ROM hacks of these games** (difficulty hacks, for example) aren't tested. A hack that keeps the original game's data in the same places should work; one that moves its tables won't be read correctly.

What was tested: all seven US ROMs (Emerald, Ruby v1.0–v1.2, Sapphire v1.0–v1.2) and Nat. Dex Emerald 1.2.2 in an emulator test bench, including a Gym Leader battle and the warp into Sidney's room. Not yet tried inside BizHawk with the Tracker on a real run, so please report anything odd.

## Nat. Dex compatibility

Works alongside CyanSMP64's [NatDexExtension](https://github.com/CyanSMP64/NatDexExtension) (Nat. Dex FireRed and Nat. Dex Emerald 1.2.x). It detects a Nat. Dex ROM the same way that extension does and reads addresses and struct sizes from the ROM header, so it doesn't matter which extension loads first.
- Random Pokémon (`replaceLead`) and the surprise Gym Leader's team come from all 1,025 base species plus the 233 Mega Evolutions and other alternate forms the ROM has (Megas, Primals, Alolan, Galarian, Hisuian and Paldean forms, Rotom's appliances, Therian forms and the rest). Every one of them has the same chance, so about 1 pick in 5 is a form. Messages say which form it is ("Mega Charizard X", "Alolan Vulpix"); the in-game name is the base species' name, as it is everywhere else in Nat. Dex. Forms follow your ruleset and generation limit. To leave them out, untick **Nat. Dex: random picks include Megas and other forms** in Options (`alternateForms = false`).
- A Pokémon handed out as a Mega or other form stays that form. It is an ordinary species in Nat. Dex, the same way the Nat. Dex randomizer places forms in the wild, on trainers and as randomized evolutions.
- Random moves and abilities only come from the ones that work in your ROM. Nat. Dex 1.2.x has 847 move slots and 320 ability names, but many are unfinished placeholders, and those are skipped. A ROM hack that implements more of them is picked up automatically.
- **Nat. Dex Emerald** gets the Hoenn versions of the Elite Four warp and the Surprise Gym Leader, like Emerald itself. Eevee evolves with stones in Nat. Dex, so the clock doesn't matter there.
- The Elite Four warp works the same. Nat. Dex moves the warp-destination slot in RAM, so the extension finds it when the gift arrives. It does this by matching your current location while you're standing in a map.
- The bridge uses the unofficial [`tiktok-live-connector`](https://www.npmjs.com/package/tiktok-live-connector) library. If TikTok changes something and it stops connecting, run `npm update` in the bridge folder.
- Make a save state before testing.

## Optional: Nat. Dex Abilities patch

You don't need this to use the extension. It is a separate, optional ROM patch for people who play Nat. Dex FireRed and want the newer mechanics to do something.

Nat. Dex FireRed 1.2.2 lists Gen 4 to 9 abilities and moves, but many of them are placeholders with no effect. This patch fills them in.

Everything for it is in the [`optional/natdex-abilities-patch`](optional/natdex-abilities-patch) folder. It is not in the release zip.

| File | What it is |
| --- | --- |
| [`pokefirered_natdex_1.2.2_abilities.bps`](https://github.com/estrawder-collab/TikTokGifts-IronmonExtension/raw/main/optional/natdex-abilities-patch/pokefirered_natdex_1.2.2_abilities.bps) | The ROM patch. |
| [`randomizer_natdex_1.2.2_abilities.jar`](https://github.com/estrawder-collab/TikTokGifts-IronmonExtension/raw/main/optional/natdex-abilities-patch/randomizer_natdex_1.2.2_abilities.jar) | The randomizer that matches the patched ROM. |
| [`NatDexSplitCategories.lua`](https://github.com/estrawder-collab/TikTokGifts-IronmonExtension/raw/main/optional/natdex-abilities-patch/NatDexSplitCategories.lua) | A Tracker extension that makes the Tracker show the patched ROM correctly. |

### What it changes

- **Abilities:** more than 230 Gen 4 to 9 abilities now work in battle. That includes the terrain abilities and terrains themselves, form changes such as Stance Change and Disguise, and species-specific abilities, which work on whichever Pokémon rolls them in a randomized game.
- **Moves:** 482 Gen 4 to 9 moves are implemented, 352 damaging and 130 status, along with the Toxic Spikes hazard.
- **Physical/special split:** each move is physical or special on its own, as in the newer games, instead of by type.
- **Animations:** 150 of the newer moves have their own animations.
- **Held items:** 50 single-use held items, including Focus Sash, Weakness Policy, Air Balloon, Power Herb, Eject Button, Throat Spray, the terrain seeds, seven Gems and the 18 type-resist berries.
- **Exp. Candies:** XS, S, M, L and XL exist as real bag items worth 100, 800, 3,000, 10,000 and 30,000 Exp. Points. They are used like a Rare Candy.

### What it does for the extension

The extension detects the patched ROM by itself. Nothing needs to be switched on.

- Random move and ability gifts pick from the much larger set that now works.
- Exp. Candy gifts put the real candy in your bag instead of giving the points directly (see `expCandyMode`).

### How to set it up

1. **Make the base ROM.** Make a Nat. Dex FireRed 1.2.2 ROM the usual way: FireRed (US) v1.1 with CyanSMP64's Nat. Dex 1.2.2 patch applied. Its CRC32 is `34AAFED7`.
2. **Apply the patch.** Apply the `.bps` to that ROM with a BPS patcher such as Floating IPS (Flips) or Rom Patcher JS. A BPS patcher refuses the wrong starting ROM, so an error here means step 1 doesn't match. The result has CRC32 `EBD4339B`.
3. **Randomize with the matching randomizer.** Use `randomizer_natdex_1.2.2_abilities.jar` with the patched ROM and your usual Nat. Dex settings file. If the Tracker makes your ROMs for you (Quickload), point its randomizer and source ROM settings at this jar and the patched ROM. The randomizer needs Java.
4. **Add the Tracker extension.** Copy `NatDexSplitCategories.lua` into the Tracker's `extensions` folder and enable it, with CyanSMP64's NatDexExtension enabled too.
5. **Start a new game.** Save states made on the unpatched ROM won't work.

### The randomizer

The patch moves the game's data, so the standard Nat. Dex randomizer can't read the patched ROM. The one here is that same randomizer, changed to read the patched ROM and to hand out the moves and items the patch adds.

- Use it only with the patched ROM. It no longer reads an unpatched FireRed 1.1 or Nat. Dex 1.2.2 ROM, so keep your original randomizer for those.
- It is a modified copy of the Universal Pokemon Randomizer ZX build that ships with NatDexExtension, shared under the same GPL-3.0 license. The exact changes are listed in the [folder's README](optional/natdex-abilities-patch/README.md).

### The Tracker extension

Without it, the Tracker labels moves physical or special by type and calls some of the newer moves and abilities "not implemented", even though they work in the game. `NatDexSplitCategories.lua` fixes what the Tracker shows:

- each move's real physical or special category;
- the type, power, accuracy, PP and description of the moves the patch implements;
- the descriptions of the abilities the patch implements;
- the names of the new held items and Exp. Candies.

It does nothing on a ROM without the patch, so it is safe to leave enabled.

### Before you use it

- **It has only been tested in single battles.** In doubles, a few animation effects aimed at a partner Pokémon draw on the main target instead.
- **It is an unofficial fan modification.** It isn't made or supported by CyanSMP64 or the Nat. Dex project, so please don't report its bugs to them. Report them here instead.
- **It is a patch, not a game.** No ROM is included or will be. You supply your own game file.

## Privacy

`TikTokGifts/gifts.txt` is a log of every gift, including your viewers' usernames. It is created on your PC and isn't part of the download. Don't share it.

## Credits

Made by **Demon_Quingar91**.

This extension only exists because of other people's work:

- **The IronMon Challenge** was created by [iateyourpie](https://www.twitch.tv/iateyourpie). The rules, and the banned-move lists the ruleset options use, are kept up by the IronMon community at [ironmon.gg](https://ironmon.gg).
- **The Ironmon Tracker** was created by Besteon, with UTDZac and the rest of the [Tracker's contributors](https://github.com/besteon/Ironmon-Tracker). This extension runs inside it and uses its extension tools.
- **The Nat. Dex ROM hack and NatDexExtension** are by [CyanSMP64](https://github.com/CyanSMP64/NatDexExtension) and that project's contributors. The Nat. Dex rules used here come from its wiki. The optional Abilities patch is a modification of their ROM hack.
- **pokeemerald-expansion** by [rh-hideout](https://github.com/rh-hideout/pokeemerald-expansion) and its contributors. The 150 move animations in the optional Abilities patch were ported from it.
- **Universal Pokemon Randomizer ZX** by [Ajarmar](https://github.com/Ajarmar/universal-pokemon-randomizer-zx), with significant contributions from darkeye and cleartonic, based on the Universal Pokemon Randomizer by Dabomstew. The optional patch's randomizer is a modified copy of the build that ships with NatDexExtension.

Special thanks:

- **Trip** ([@tripc423](https://www.tiktok.com/@tripc423) on TikTok) and **Nino** ([@ninopokebros](https://www.tiktok.com/@ninopokebros) on TikTok), for the inspiration and for being sounding boards.

Not affiliated with or endorsed by any of the people or projects above, or by TikTok, Nintendo, Game Freak or The Pokémon Company.

## License

MIT. See the `LICENSE` file. The license covers the extension and the bridge. The optional Abilities patch is a fan modification of other people's work and is shared as it is, with no license of its own. Its randomizer is under the GNU General Public License, version 3; the license text is in the patch's folder.
