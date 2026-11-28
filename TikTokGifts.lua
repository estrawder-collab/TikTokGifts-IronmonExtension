--[[
	TikTok Gifts - Ironmon Tracker extension (BizHawk)
	Works with Pokemon FireRed and LeafGreen, with the Nat. Dex ROM hack
	(CyanSMP64's NatDexExtension, FireRed and Emerald builds), and with Pokemon
	Emerald, Ruby and Sapphire.

	Lets TikTok LIVE gifts change your game. Gifts arrive through the small
	Node.js bridge in TikTokGifts/bridge, which appends each gift as one line to
	TikTokGifts/gifts.txt. This extension reads new lines, matches them against
	GIFT_RULES below, and applies the effect to your party.

	EASIEST WAY TO SET IT UP: in the Tracker, open Extensions > TikTok Gifts >
	Options. Gift rules and settings changed there are saved to
	TikTokGifts/config.txt and survive updates. The GIFT_RULES and SETTINGS
	below are the defaults, used until you change them in that window.

	Effects are held in a queue while you're in a battle and applied once the
	battle ends. If they were written mid-battle, the game would overwrite them
	when the battle ended.

	CREDITS
	  Made by Demon_Quingar91.
	  The IronMon Challenge: created by iateyourpie; rules kept by the IronMon
	    community at ironmon.gg.
	  The Ironmon Tracker: created by Besteon, with UTDZac and the Tracker's
	    contributors (github.com/besteon/Ironmon-Tracker).
	  The Nat. Dex ROM hack and NatDexExtension: CyanSMP64 and contributors
	    (github.com/CyanSMP64/NatDexExtension).
	  Special thanks to Trip (@tripc423 on TikTok) and Nino (@ninopokebros on
	    TikTok) for the inspiration and for being sounding boards.
]]

local function TikTokGifts()
	local self = {}

	-- ======================= METADATA =======================
	self.version = "1.18.0"
	self.name = "TikTok Gifts"
	self.author = "Demon_Quingar91"
	self.description = "TikTok LIVE gifts affect your game: level ups, EVs/IVs, new moves, curses, an Elite Four warp and more. Needs the bridge running (see README)."
	self.github = "estrawder-collab/TikTokGifts-IronmonExtension"
	self.url = string.format("https://github.com/%s", self.github or "")

	-- ======================= CONFIG =========================
	--[[ Available effects
		Good:     levelUp (amount; like a Rare Candy: can evolve and learn moves,
		                   and asks which move to forget when all four are full),
		          expCandyXS, expCandyS, expCandyM, expCandyL, expCandyXL
		            (100 / 800 / 3,000 / 10,000 / 30,000 Exp. Points; see expCandyMode)
		          healParty, maxEVs, maxIVs,
		          teachStabMove, teachRandomMove,
		          giveHealingItem (one random healing item per gift, see healingItems)
		Bad:      lowerLevel (amount), randomizeAbility, randomStatus,
		          poisonLead, stealItem, resetEVs
		Random:   randomizeIVs, randomizeEVs
		Chaos:    replaceLead   (releases your lead, gives a random Lv.15 Pokemon)
		          eliteFourWarp (the next door you enter takes you to the Elite Four,
		                         and your lead becomes Lv.100 with max IVs/EVs/PP)
		          spawnGymLeader (a random Gym Leader battles you with 6 Pokemon of
		                          their type; no badge, counts as a normal trainer)
		Other:    none
	]]
	--[[ HOW TO SET UP YOUR OWN GIFTS  (full guide: README, "Set up your own gifts")
		Each line below is one rule and ends with a comma:
		    ["gift name in lowercase"] = { effect = "effectName" },
		A gift is looked up by name first (byName), then by what one of it
		costs (byExactCoins), then by "this many coins or more" (byCoins).
		- Change a gift: change the word after "effect =" to one from the list above.
		- Add a gift:    copy a line, change the name (or coin value) and the effect.
		- Remove a gift: delete its line, or use effect = "none".
		The bridge window shows each gift's exact name and coin value while you
		are live. After saving, turn the extension off and on in the Tracker.
	]]
	-- Gift names are matched case-insensitively and take priority over coin
	-- tiers. "coins" means the value of ONE gift (Rose = 1).
	local GIFT_RULES = {
		-- 1) Gift names (lowercase), checked first
		byName = {
			["gold boxing gloves"] = { effect = "randomizeAbility" },
			["bravo!"]             = { effect = "randomizeEVs" },
			["bravo"]              = { effect = "randomizeEVs" },
			["hat and mustache"]   = { effect = "levelUp", amount = 1 },
			["goat"]               = { effect = "teachStabMove" },
			["doughnut"]           = { effect = "healParty" },  -- TikTok spells it "Doughnut"
			["donut"]              = { effect = "healParty" },
			["diamond gun"]        = { effect = "eliteFourWarp" },
			["finger heart"]       = { effect = "randomStatus" },
			["finger hearts"]      = { effect = "randomStatus" },
			["manifesting"]        = { effect = "maxIVs" },
			["punch cuddle"]       = { effect = "maxEVs" },
			["october"]            = { effect = "giveHealingItem" },
			["perfume"]            = { effect = "randomizeIVs" },
			["galaxy"]             = { effect = "replaceLead" },
			["meteor shower"]      = { effect = "spawnGymLeader" },
			["rose"]               = { effect = "healParty" },
		},
		-- 2) Any OTHER gift worth exactly this many coins (one gift's value)
		byExactCoins = {
			[5]    = { effect = "randomStatus" },      -- Finger Heart
			[10]   = { effect = "randomizeAbility" },  -- Gold Boxing Gloves
			[15]   = { effect = "randomizeEVs" },      -- Bravo!
			[20]   = { effect = "randomizeIVs" },      -- Perfume
			[30]   = { effect = "healParty" },         -- Doughnut
			[88]   = { effect = "giveHealingItem" },   -- October
			[99]   = { effect = "levelUp", amount = 1 }, -- Hat and Mustache, Paper Crane
			[150]  = { effect = "teachRandomMove" },
			[200]  = { effect = "teachStabMove" },     -- GOAT (200-coin version)
			[400]  = { effect = "maxEVs" },            -- Punch Cuddle
			[500]  = { effect = "maxIVs" },            -- Manifesting
			[1000] = { effect = "replaceLead" },       -- Galaxy
			[3000] = { effect = "spawnGymLeader" },    -- Meteor Shower
			[5000] = { effect = "eliteFourWarp" },     -- Diamond Gun
		},
		-- 3) Optional "this many coins or more" tiers, highest first. Empty = gifts
		--    that match nothing above do nothing.
		byCoins = {
		},
	}

	local SETTINGS = {
		maxLevelsPerGift = 10,       -- cap for one gift/streak of levelUp/lowerLevel

		-- levelUp works like a Rare Candy: after each level the game's own
		-- level-up rules are applied, just without the animation or prompts.
		levelUpEvolves = true,       -- evolve if the Pokemon now meets its evolution rule
		levelUpLearnsMoves = true,   -- learn level-up moves
		levelUpFullMoves = "ask",    -- when the Pokemon already knows 4 moves:
		                             --   "ask"  = a window asks which move to forget (or none);
		                             --            the game is paused until you choose
		                             --   "skip" = the new move is not learned
		levelUpFriendship = true,    -- friendship gain of a Rare Candy (+5/+3/+2)

		-- expCandyXS ... expCandyXL:
		--   "auto"   = if the ROM has Exp. Candy items (the Nat. Dex + Abilities
		--              hack), the real candy goes into your bag and you use it
		--              yourself. On any other ROM the Exp. Points go straight
		--              to your lead, with the same level-up rules as levelUp.
		--   "direct" = always give the Exp. Points straight to your lead
		--   "item"   = only ever give the item (skipped on ROMs without it)
		expCandyMode = "auto",

		-- IRONMON RULESET. Keeps what gifts GIVE you legal for the ruleset you play.
		-- Easiest to pick in the Options window.
		--   "none"       no rules applied (default)
		-- The rules as published on ironmon.gg:
		--   "standard"   random Pokemon are never legendary, sub-legendary or mythical
		--   "ultimate"   + random moves are never HM moves
		--   "kaizo"      + random Pokemon stay under the BST limit, random moves skip the
		--                  Kaizo banned-move list, no Huge Power / Pure Power
		--   "superKaizo" Kaizo, with the Super Kaizo move list and ability bans
		--   "survival"   Kaizo, with the Survival move list and ability bans
		-- The same five with the Nat. Dex rule changes (v1.2.0+, NatDexExtension wiki):
		--   "Nat. Dex Standard", "Nat. Dex Ultimate", "Nat. Dex Kaizo",
		--   "Nat. Dex Super Kaizo", "Nat. Dex Survival"
		--   Sub-legendaries are allowed, HM moves are allowed, the BST limit is 599,
		--   and banned abilities are fine on Pokemon of 420 BST or less.
		-- It covers replaceLead, teachRandomMove, teachStabMove and randomizeAbility.
		-- It does not stop a gift itself (a heal, a level) - leave gifts you
		-- don't want out of GIFT_RULES.
		ruleset = "none",
		rulesetMaxBST = "auto",    -- Kaizo and up. "auto" = 598 ("No using 599+ BST Pokemon"), or
		                           -- 599 with the Nat. Dex rules ("600 BST or higher" is banned).
		                           -- Or set your own number.
		rulesetNewerMoves = true,  -- the published move lists stop at Gen 7. true = also skip
		                           -- Gen 7-9 moves of the same kinds (healing, draining, pivoting)

		-- GENERATION LIMIT. Random picks made by gifts only use things introduced
		-- in generations 1 up to the number you set. 9 = everything the ROM has.
		--   Gen 1-3 Kaizo ruleset:  pokemon = 3, moves = 3, abilities = 3, items = 3
		--   Gen 1-5 ruleset:        pokemon = 5, moves = 5, abilities = 5, items = 5
		-- Each one can be set on its own (e.g. only limit the Pokemon).
		generationLimit = {
			pokemon = 9,    -- random Pokemon: replaceLead and surprise Gym Leader teams
			moves = 9,      -- random moves: teachRandomMove, teachStabMove, moves of those Pokemon
			abilities = 9,  -- randomizeAbility (abilities first appeared in Gen 3, so 1-3 mean the same)
			items = 9,      -- below 8, Exp. Candy gifts give the Exp. Points instead of the item
		},
		-- Nat. Dex games only: Mega Evolutions, regional forms and other alternate
		-- forms (the extra species the ROM keeps after Pecharunt) can be picked by
		-- replaceLead and for surprise Gym Leader teams. They follow the ruleset
		-- (BST limit, legendaries) and the generation limit like any other Pokemon.
		alternateForms = true,
		repeatOtherEffects = 1,      -- how many times other effects fire for a streak (e.g. 5x gift)
		maxQueueSize = 100,          -- extra gifts are dropped if the queue fills up
		secondsBetweenEffects = 2,   -- spacing so viewers can see each effect land

		-- Held gifts: if an effect can't happen right now (party already healthy,
		-- lead is an egg, bag full...), the gift is held and retried instead of lost.
		retryEverySeconds = 10,      -- how often held gifts are tried again
		retryForMinutes = 15,        -- give up after this long (0 = keep trying forever)
		retryHotkey = "Insert",      -- key in BizHawk to retry all held gifts now (nil = off)

		-- randomizeEVs: "legal" = 510 points spread randomly (max 255 per stat)
		--               "wild"  = each stat 0-255 on its own (can go past 510)
		randomEVsMode = "wild",
		skipOldGiftsOnStartup = true,-- ignore gifts logged before the extension was turned on

		-- maxEVs (and the Elite Four boost):
		--   "all"   = 252 in every stat (beyond the normal 510 limit, very strong)
		--   "legal" = 252 best attacking stat, 252 Speed, 4 HP (510 total)
		maxEVsMode = "all",

		-- randomizeAbility:
		--   "slot" = switches to the species' other ability (Gen 3 Pokemon only
		--            store which of their 2 ability slots they use). Safe.
		--   "rom"  = any random ability, by editing the species' ability in the
		--            loaded ROM. Affects EVERY Pokemon of that species (wild,
		--            trainers) until you restart the game, and the Tracker may
		--            still show the old ability.
		abilityMode = "rom",
		bannedAbilities = { [25] = true }, -- Wonder Guard

		-- teachStabMove: only damaging moves with power in this range
		stabMinPower = 1,
		stabMaxPower = 255,

		replaceLevel = 15,           -- level of the Pokemon replaceLead gives you

		-- giveHealingItem: one random item from this list goes into your bag per
		-- gift. Higher weight = more likely. Remove lines or set weight = 0 to
		-- exclude an item. (IDs are the same in every supported game.)
		maxItemsPerGift = 10,        -- cap for one streak (e.g. 20x the same gift)
		-- healParty and giveHealingItem also work DURING battles. In battle,
		-- fainted Pokemon aren't revived (that could confuse the battle).
		healingItems = {
			{ id = 13, name = "Potion",        weight = 12 },
			{ id = 22, name = "Super Potion",  weight = 8 },
			{ id = 21, name = "Hyper Potion",  weight = 4 },
			{ id = 20, name = "Max Potion",    weight = 2 },
			{ id = 19, name = "Full Restore",  weight = 1 },
			{ id = 14, name = "Antidote",      weight = 5 },
			{ id = 18, name = "Parlyz Heal",   weight = 5 },
			{ id = 17, name = "Awakening",     weight = 5 },
			{ id = 15, name = "Burn Heal",     weight = 5 },
			{ id = 16, name = "Ice Heal",      weight = 3 },
			{ id = 23, name = "Full Heal",     weight = 3 },
			{ id = 24, name = "Revive",        weight = 4 },
			{ id = 25, name = "Max Revive",    weight = 1 },
			{ id = 26, name = "Fresh Water",   weight = 5 },
			{ id = 27, name = "Soda Pop",      weight = 4 },
			{ id = 28, name = "Lemonade",      weight = 3 },
			{ id = 29, name = "Moomoo Milk",   weight = 2 },
			{ id = 30, name = "Energy Powder", weight = 3 },
			{ id = 31, name = "Energy Root",   weight = 2 },
			{ id = 32, name = "Heal Powder",   weight = 3 },
			{ id = 33, name = "Revival Herb",  weight = 1 },
			{ id = 34, name = "Ether",         weight = 3 },
			{ id = 35, name = "Max Ether",     weight = 1 },
			{ id = 36, name = "Elixir",        weight = 1 },
			{ id = 37, name = "Max Elixir",    weight = 1 },
			{ id = 38, name = "Lava Cookie",   weight = 2 },
			{ id = 44, name = "Berry Juice",   weight = 2 },
		},

		-- eliteFourWarp: when the warp fires, the lead becomes Lv.100 with max
		-- IVs, max EVs (maxEVsMode) and 3 PP Ups on every move (PP refilled)
		eliteFourBoostLead = true,   -- the lead reaches Lv.100 as if it earned the experience (learning
		                             -- moves and evolving on the way, per the levelUp settings above),
		                             -- then gets max IVs, EVs and PP

		-- spawnGymLeader: team level = your highest party level + this bonus
		gymLeaderLevelBonus = 0,
		gymLeaderEVs = "all",        -- "all" = 252 in every stat, "legal" = random 510 spread
	}

	-- ======================= STATE ==========================
	local giftsFilePath, backupFilePath = nil, nil
	local filePos = 0
	local queue = {}
	-- Level-up moves waiting for the player's choice (filled in near the end of this file)
	local MoveChoice = { pending = {}, open = false, justAsked = {} }
	local lastEffectTime = 0
	local G = nil -- game layout (addresses, struct sizes), set by detectGame()
	local currentlyInBattle = false
	local retryHeldNow -- defined with the queue code below
	local abilityWorks -- defined in the WORKING ABILITIES section below

	-- ======================= HELPERS ========================
	local function log(msg)
		print(string.format("[%s] %s", self.name, tostring(msg)))
	end

	local function getExtensionDir()
		local src = debug.getinfo(1, "S").source or ""
		if src:sub(1, 1) == "@" then
			local dir = src:sub(2):match("^(.*[/\\])")
			if dir then return dir end
		end
		local base = (IronmonTracker and IronmonTracker.workingDir) or ""
		return base .. "extensions/"
	end

	-- Bitwise helpers using plain arithmetic, so they work on both Lua 5.1
	-- (BizHawk 2.8) and Lua 5.4 (BizHawk 2.9+).
	local function bxor(a, b)
		local result, place = 0, 1
		for _ = 1, 32 do
			local x, y = a % 2, b % 2
			if x ~= y then result = result + place end
			a = math.floor(a / 2)
			b = math.floor(b / 2)
			place = place * 2
		end
		return result
	end
	local function bits(value, start, count)
		return math.floor(value / (2 ^ start)) % math.floor(2 ^ count)
	end
	local function setBits(value, start, count, newValue)
		return math.floor(value + (newValue - bits(value, start, count)) * (2 ^ start))
	end
	local function rand32()
		return math.random(0, 65535) * 65536 + math.random(0, 65535)
	end

	-- Memory access via BizHawk's GBA domains
	local function domainFor(addr)
		if addr >= 0x08000000 then return addr - 0x08000000, "ROM" end
		if addr >= 0x03000000 then return addr - 0x03000000, "IWRAM" end
		return addr - 0x02000000, "EWRAM"
	end
	local function read8(a)  local o, d = domainFor(a) return memory.read_u8(o, d) end
	local function read16(a) local o, d = domainFor(a) return memory.read_u16_le(o, d) end
	local function read32(a) local o, d = domainFor(a) return memory.read_u32_le(o, d) end
	local function write8(a, v)  local o, d = domainFor(a) memory.write_u8(o, math.floor(v), d) end
	local function write16(a, v) local o, d = domainFor(a) memory.write_u16_le(o, math.floor(v), d) end
	local function write32(a, v) local o, d = domainFor(a) memory.write_u32_le(o, math.floor(v), d) end
	local function readBytes(a, n)
		local t = {}
		for i = 0, n - 1 do t[#t + 1] = read8(a + i) end
		return t
	end
	local function sameBytes(x, y)
		for i = 1, #x do if x[i] ~= y[i] then return false end end
		return true
	end

	local function inBattle()
		if Battle and Battle.inActiveBattle then
			local ok, result = pcall(Battle.inActiveBattle)
			if ok then return result end
		end
		return false
	end

	-- ======================= GAME DETECTION =================
	-- Addresses for the original games are from pret's symbol maps.
	-- Nat. Dex ROMs publish their addresses and struct sizes in an extended ROM
	-- header (the same one the NatDexExtension reads), so those are read live.
	local VANILLA_TABLES = {
		BPRE = { [0] = { baseStats = 0x08254784, moves = 0x08250C04, names = 0x08245EE0, trainers = 0x0823EAC8, classNames = 0x0823E558,
		           evos = 0x08259754, learnsets = 0x0825D7B4 },
		         [1] = { baseStats = 0x082547F4, moves = 0x08250C74, names = 0x08245F50, trainers = 0x0823EB38, classNames = 0x0823E5C8,
		           evos = 0x082597C4, learnsets = 0x0825D824 } },
		BPGE = { [0] = { baseStats = 0x08254760, moves = 0x08250BE0, names = 0x08245EBC, trainers = 0x0823EAA4, classNames = 0x0823E534,
		           evos = 0x08259734, learnsets = 0x0825D794 },
		         [1] = { baseStats = 0x082547D0, moves = 0x08250C50, names = 0x08245F2C, trainers = 0x0823EB14, classNames = 0x0823E5A4,
		           evos = 0x082597A4, learnsets = 0x0825D804 } },
	}

	-- Emerald, Ruby and Sapphire, one set per revision. Emerald reaches its save
	-- data through pointers (sb1Ptr/sb2Ptr); Ruby and Sapphire keep it at fixed
	-- addresses (sb1/sb2) and don't scramble item quantities.
	local HOENN_TABLES = {
		BPEE = {
			[0] = { label = "Emerald", baseStats = 0x083203CC, moves = 0x0831C898, names = 0x083185C8,
				trainers = 0x08310030, classNames = 0x0830FCD4, evos = 0x0832531C, learnsets = 0x0832937C,
				party = 0x020244EC, enemyParty = 0x02024744, battleMons = 0x02024084, opponentA = 0x02038BCA,
				scriptCtx = 0x03000E40, warpDest = 0x020322E4, localTime = 0x03005CF8, sb1Ptr = 0x03005D8C,
				sb2Ptr = 0x03005D90 },
		},
		AXVE = {
			[0] = { label = "Ruby v1.0", baseStats = 0x081FEC18, moves = 0x081FB12C, names = 0x081F716C,
				trainers = 0x081F04FC, classNames = 0x081F0208, evos = 0x08203B68, learnsets = 0x08207BC8,
				party = 0x03004360, enemyParty = 0x030045C0, battleMons = 0x02024A80, opponentA = 0x0202FF5E,
				scriptCtx = 0x030005B8, warpDest = 0x020297F8, localTime = 0x03004038, sb1 = 0x02025734,
				sb2 = 0x02024EA4 },
			[1] = { label = "Ruby v1.1", baseStats = 0x081FEC30, moves = 0x081FB144, names = 0x081F7184,
				trainers = 0x081F0514, classNames = 0x081F0220, evos = 0x08203B80, learnsets = 0x08207BE0,
				party = 0x03004360, enemyParty = 0x030045C0, battleMons = 0x02024A80, opponentA = 0x0202FF5E,
				scriptCtx = 0x030005B8, warpDest = 0x020297F8, localTime = 0x03004038, sb1 = 0x02025734,
				sb2 = 0x02024EA4 },
			[2] = { label = "Ruby v1.2", baseStats = 0x081FEC30, moves = 0x081FB144, names = 0x081F7184,
				trainers = 0x081F0514, classNames = 0x081F0220, evos = 0x08203B80, learnsets = 0x08207BE0,
				party = 0x03004360, enemyParty = 0x030045C0, battleMons = 0x02024A80, opponentA = 0x0202FF5E,
				scriptCtx = 0x030005B8, warpDest = 0x020297F8, localTime = 0x03004038, sb1 = 0x02025734,
				sb2 = 0x02024EA4 },
		},
		AXPE = {
			[0] = { label = "Sapphire v1.0", baseStats = 0x081FEBA8, moves = 0x081FB0BC, names = 0x081F70FC,
				trainers = 0x081F048C, classNames = 0x081F0198, evos = 0x08203AF8, learnsets = 0x08207B58,
				party = 0x03004360, enemyParty = 0x030045C0, battleMons = 0x02024A80, opponentA = 0x0202FF5E,
				scriptCtx = 0x030005B8, warpDest = 0x020297F8, localTime = 0x03004038, sb1 = 0x02025734,
				sb2 = 0x02024EA4 },
			[1] = { label = "Sapphire v1.1", baseStats = 0x081FEBC0, moves = 0x081FB0D4, names = 0x081F7114,
				trainers = 0x081F04A4, classNames = 0x081F01B0, evos = 0x08203B10, learnsets = 0x08207B70,
				party = 0x03004360, enemyParty = 0x030045C0, battleMons = 0x02024A80, opponentA = 0x0202FF5E,
				scriptCtx = 0x030005B8, warpDest = 0x020297F8, localTime = 0x03004038, sb1 = 0x02025734,
				sb2 = 0x02024EA4 },
			[2] = { label = "Sapphire v1.2", baseStats = 0x081FEBC0, moves = 0x081FB0D4, names = 0x081F7114,
				trainers = 0x081F04A4, classNames = 0x081F01B0, evos = 0x08203B10, learnsets = 0x08207B70,
				party = 0x03004360, enemyParty = 0x030045C0, battleMons = 0x02024A80, opponentA = 0x0202FF5E,
				scriptCtx = 0x030005B8, warpDest = 0x020297F8, localTime = 0x03004038, sb1 = 0x02025734,
				sb2 = 0x02024EA4 },
		},
	}

	-- The Pokemon League of each region, for the Elite Four warp:
	-- where the first room is, which maps belong to the League (a door between
	-- two of them is never redirected), and what the game itself resets after
	-- the Hall of Fame or a whiteout so the League can be fought from the start.
	local KANTO_LEAGUE = {
		group = 1, firstRoom = 75, rooms = { [75] = true, [76] = true, [77] = true, [78] = true, [79] = true, [80] = true },
		flags = { 0x4B8, 0x4B9, 0x4BA, 0x4BB, 0x4BC },  -- FLAG_DEFEATED_LORELEI..FLAG_DEFEATED_CHAMP
		trainerFlags = { 438, 439, 440, 739, 740, 741 }, -- Champion first battles + rematches
		sceneVar = 0x4068, -- VAR_MAP_SCENE_POKEMON_LEAGUE: plays the walk-in and seals the entrance
	}
	local function hoennLeague(firstFlag, sceneVar)
		return {
			-- Group 16: 0-4 are Sidney's, Phoebe's, Glacia's, Drake's and the Champion's
			-- rooms, 5-9 the halls between them, 11 the Hall of Fame
			group = 16, firstRoom = 0, rooms = { [0] = true, [1] = true, [2] = true, [3] = true, [4] = true,
				[5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [11] = true },
			flags = { firstFlag, firstFlag + 1, firstFlag + 2, firstFlag + 3 }, -- FLAG_DEFEATED_ELITE_4_*
			trainerFlags = {},
			sceneVar = sceneVar or 0x409C, -- VAR_ELITE_4_STATE
		}
	end
	-- What differs between Emerald and Ruby/Sapphire (the two share everything)
	local HOENN_COMMON = {
		BPEE = { flagsOff = 0x1270, varsOff = 0x139C, bagItemsOff = 0x0560, bagItemsCount = 30, encKeyOff = 0x00AC,
			originGame = 3, league = hoennLeague(0x4FB) },
		AXVE = { flagsOff = 0x1220, varsOff = 0x1340, bagItemsOff = 0x0560, bagItemsCount = 20,
			originGame = 2, league = hoennLeague(0x4DD) },
		AXPE = { flagsOff = 0x1220, varsOff = 0x1340, bagItemsOff = 0x0560, bagItemsCount = 20,
			originGame = 1, league = hoennLeague(0x4DD) },
	}

	local function isRomAddr(a) return a >= 0x08000000 and a < 0x0A000000 end

	-- An item's name as lowercase letters only ("Exp.Candy XS" -> "expcandyxs")
	local function itemNameKey(addr, maxLen)
		local out = {}
		for i = 0, maxLen - 1 do
			local c = read8(addr + i)
			if c == 0xFF then break
			elseif c >= 0xBB and c <= 0xD4 then out[#out + 1] = string.char(97 + c - 0xBB)
			elseif c >= 0xD5 and c <= 0xEE then out[#out + 1] = string.char(97 + c - 0xD5)
			end
		end
		return table.concat(out)
	end

	-- Does this address hold an evolution table with the given layout?
	-- (species 0 is empty, entries are {method, param, target species})
	local function looksLikeEvoTable(addr, entrySize, perMon)
		if not isRomAddr(addr) then return false end
		local row = entrySize * perMon
		for i = 0, row - 2, 2 do
			if read16(addr + i) ~= 0 then return false end
		end
		local found = 0
		for sp = 1, 251 do
			for e = 0, perMon - 1 do
				local a = addr + sp * row + e * entrySize
				local method, param, target = read16(a), read16(a + 2), read16(a + 4)
				if method > 40 or target >= 2000 then return false end
				if entrySize == 8 and read16(a + 6) ~= 0 then return false end
				if method == 0 then
					if param ~= 0 or target ~= 0 then return false end
				else
					if target == 0 then return false end
					found = found + 1
				end
			end
		end
		return found >= 20
	end

	-- Does this address hold the table of level-up learnsets? Checks that the
	-- first species' lists are well-formed (levels 1-100, real moves, an end marker).
	local function looksLikeLearnsets(addr, wide, maxMove)
		if not isRomAddr(addr) then return false end
		if isRomAddr(read32(addr - 4)) then return false end -- the table starts here, not earlier
		for sp = 0, 25 do
			local p = read32(addr + sp * 4)
			if not isRomAddr(p) then return false end
			local ended = false
			for i = 0, 99 do
				local lv, move
				if wide then
					local v = read32(p + i * 4)
					if v == 0xFFFFFFFF then ended = true break end
					lv, move = math.floor(v / 65536), v % 65536
				else
					local v = read16(p + i * 2)
					if v == 0xFFFF then ended = true break end
					lv, move = math.floor(v / 512), v % 512
				end
				if lv > 100 or move > maxMove then return false end
			end
			if not ended then return false end
		end
		return true
	end

	-- Nat. Dex doesn't list its evolution table in the ROM header, but it does
	-- list the function that reads it. The table's address is one of the
	-- constants stored right inside that function.
	local function findNatDexEvoTable(g)
		local fn = read32(0x080002FC)
		if not isRomAddr(fn) then return end
		fn = fn - (fn % 2)
		local seen = {}
		for a = fn + ((4 - fn % 4) % 4), fn + 0x5FC, 4 do
			local v = read32(a)
			if isRomAddr(v) and not seen[v] then
				seen[v] = true
				for _, entrySize in ipairs({ 8, 6 }) do
					if looksLikeEvoTable(v, entrySize, 8) then
						g.evos, g.evoEntrySize, g.evosPerMon = v, entrySize, 8
						return
					end
				end
			end
		end
	end

	-- Nat. Dex Emerald: the game's clock (gLocalTime) isn't in the ROM header
	-- either, but the evolution function reads it for Espeon/Umbreon. It is the
	-- one work-RAM address stored in that function besides the save pointers.
	local function findNatDexLocalTime(g)
		local fn = read32(0x080002FC)
		if not isRomAddr(fn) then return nil end
		fn = fn - (fn % 2)
		local found, count = nil, 0
		for a = fn + ((4 - fn % 4) % 4), fn + 0x5FC, 4 do
			local v = read32(a)
			if v >= 0x03000000 and v < 0x03008000 and v % 4 == 0
				and v ~= g.sb1Ptr and v ~= g.sb2Ptr and v ~= found then
				found, count = v, count + 1
			end
		end
		return count == 1 and found or nil
	end

	local function detectGame()
		local code = string.char(read8(0x080000AC), read8(0x080000AD), read8(0x080000AE), read8(0x080000AF))
		local hoenn = HOENN_TABLES[code]
		if code ~= "BPRE" and code ~= "BPGE" and not hoenn then
			log("This game isn't supported (game code " .. code:gsub("[^%w]", "?") .. "). TikTok Gifts works with FireRed, LeafGreen, Emerald, Ruby and Sapphire. Effects are disabled.")
			return nil
		end
		local version = read8(0x080000BC)
		-- Nat. Dex builds (FireRed or Emerald): same check the NatDexExtension uses
		local natdexRom = read32(0x08000170) == 1258 and (code == "BPRE" or code == "BPGE" or code == "BPEE")
		local natdexEmerald = natdexRom and code == "BPEE"
		local g
		if hoenn and not natdexRom then
			local t, c = hoenn[version], HOENN_COMMON[code]
			if not t then
				log(string.format("Unknown %s version %d. Effects are disabled.", code, version))
				return nil
			end
			-- Pokemon, species, moves and trainers are laid out as in FireRed
			g = {
				natdex = false, hoenn = true, label = t.label,
				monSize = 100, subOff = 0x20, statusOff = 0x50, levelOff = 0x54, maxHpOff = 0x58,
				defOff = 0x5C, spaOff = 0x60, nameLen = 10,
				baseStats = t.baseStats, speciesSize = 28, moves = t.moves, moveSize = 12, names = t.names,
				typeOff = 6, friendOff = 0x12, growthOff = 0x13, abilityOff = 0x16, abilitySize = 1,
				maxSpecies = 411, maxMove = 354, maxAbility = 77, shedinja = 303,
				party = t.party, sb1Ptr = t.sb1Ptr, sb2Ptr = t.sb2Ptr, sb1 = t.sb1, sb2 = t.sb2,
				flagsOff = c.flagsOff, varsOff = c.varsOff,
				bagItemsOff = c.bagItemsOff, bagItemsCount = c.bagItemsCount, encKeyOff = c.encKeyOff,
				battleMons = t.battleMons, battleMonSize = 0x58,
				enemyParty = t.enemyParty, opponentA = t.opponentA, scriptCtx = t.scriptCtx,
				trainers = t.trainers, trainerSize = 40, trainerNameOff = 4, trainerNameLen = 12,
				classNames = t.classNames, classNameSize = 13,
				bmHpOff = 0x28, bmMaxHpOff = 0x2C, bmPidOff = 0x48, bmStatusOff = 0x4C,
				warpDest = t.warpDest,
				evos = t.evos, evoEntrySize = 8, evosPerMon = 5,
				learnsets = t.learnsets, learnsetWide = false,
				-- These games have a clock: Espeon and Umbreon depend on the time of day
				localTime = t.localTime,
				originGame = c.originGame, league = c.league,
			}
		elseif natdexRom then
			g = {
				natdex = true, hoenn = natdexEmerald, label = natdexEmerald and "Nat. Dex Emerald" or "Nat. Dex FireRed",
				-- Pokemon struct (104 bytes, 12-letter names)
				monSize = read16(0x08000442), subOff = read16(0x08000414), statusOff = read16(0x08000416),
				levelOff = read16(0x08000418), maxHpOff = read16(0x0800041A),
				defOff = read16(0x0800041C), spaOff = read16(0x0800041E), nameLen = read8(0x08000176),
				-- ROM tables
				baseStats = read32(0x080001BC), speciesSize = read16(0x08000428),
				moves = read32(0x080001CC), moveSize = read16(0x08000438),
				names = read32(0x08000144),
				typeOff = 6, friendOff = 0x12, growthOff = 0x13, abilityOff = 0x16, abilitySize = 2,
				-- Base species are 1-1050; 252-276 are placeholders, 1051+ are Megas/forms
				maxSpecies = 1050, maxMove = 847, maxAbility = 320, shedinja = 303,
				abilityNames = read32(0x080001C0), abilityNameStride = 17, abilityDescs = read32(0x080001C4),
				-- RAM
				party = read32(0x0800027C), sb1Ptr = read32(0x080002E0), sb2Ptr = read32(0x080002E4),
				-- Bag: Items pocket and the key its quantities are XOR'd with (from the ROM header)
				bagItemsOff = read32(0x080002BC), bagItemsCount = read8(0x080001E4), encKeyOff = read32(0x080002D0),
				-- Battle copies of the active Pokemon (struct BattlePokemon)
				battleMons = read32(0x08000228), battleMonSize = 0x5C,
				enemyParty = read32(0x08000280), opponentA = read32(0x08000294),
				-- Script engine: Nat. Dex FireRed 1.2.x keeps the original game's RAM
				-- address (checked against a real ROM). It is found by scanning if
				-- that ever changes, and always on Nat. Dex Emerald.
				scriptCtx = (not natdexEmerald) and 0x03000EB0 or nil,
				-- Trainer table + class names (for the Gym Leader's intro message)
				trainers = read32(0x08000314), trainerSize = read16(0x0800042E),
				trainerNameOff = read16(0x0800049A), trainerNameLen = read16(0x08000430),
				classNames = read32(0x08000310), classNameSize = read16(0x08000432),
				bmHpOff = 0x28, bmMaxHpOff = 0x2C, bmPidOff = 0x4C, bmStatusOff = 0x50,
				flagsOff = read32(0x08000150), varsOff = read32(0x08000154),
				-- Level-up rules: learnsets are 32-bit {level, move} entries
				learnsets = read32(0x0800030C), learnsetWide = true,
				mapHeader = read32(0x08000284),
				evoEveryLevelFlag = natdexEmerald and 0x884 or 0x82B, -- FLAG_EVO_EVERY_LEVEL
				regionalRock = 52,
				originGame = natdexEmerald and 3 or 4,
				-- Nat. Dex Emerald keeps Emerald's League flags but moved VAR_ELITE_4_STATE
				league = natdexEmerald and hoennLeague(0x4FB, 0x40A4) or KANTO_LEAGUE,
			}
			findNatDexEvoTable(g)
			if natdexEmerald then g.localTime = findNatDexLocalTime(g) end
			-- Every species slot the ROM has (NUM_SPECIES): the move names start
			-- right where the species names end. 1284 in Nat. Dex 1.2.x, of which
			-- 1051-1283 are Megas and other forms.
			local slots = (read32(0x08000148) - g.names) / (g.nameLen + 1)
			if slots == math.floor(slots) and slots > g.maxSpecies + 1 and slots <= 4000 then
				g.speciesCount = math.floor(slots)
			end
			-- Exp. Candy items, if this ROM has them (found by item name).
			-- Item entries are {name, u16 id, ...}; the name is 14 or 20 bytes.
			g.items, g.itemCount = read32(0x080001C8), read16(0x080004B8)
			g.expCandyItems = {}
			if isRomAddr(g.items) and g.itemCount > 68 and g.itemCount < 2000 then
				for _, layout in ipairs({ { 20, 52 }, { 14, 44 } }) do
					local nameLen, size = layout[1], layout[2]
					local fits = true
					for _, id in ipairs({ 1, 2, 3, 13, 68 }) do
						if read16(g.items + id * size + nameLen) ~= id then fits = false break end
					end
					if fits then
						for id = 1, g.itemCount - 1 do
							local a = g.items + id * size
							if read8(a) == 0xBF and read8(a + 1) == 0xEC and read8(a + 2) == 0xE4 -- "Exp"
								and read16(a + nameLen) == id then
								local candy = itemNameKey(a, nameLen):match("^expcandy(%a+)$")
								if candy then g.expCandyItems[candy] = id end
							end
						end
						break
					end
				end
			end
		else
			local t = VANILLA_TABLES[code][version]
			if not t then
				log(string.format("Unknown %s version %d. Effects are disabled.", code, version))
				return nil
			end
			g = {
				natdex = false, label = (code == "BPRE" and "FireRed" or "LeafGreen") .. " v1." .. version,
				monSize = 100, subOff = 0x20, statusOff = 0x50, levelOff = 0x54, maxHpOff = 0x58,
				defOff = 0x5C, spaOff = 0x60, nameLen = 10,
				baseStats = t.baseStats, speciesSize = 28, moves = t.moves, moveSize = 12, names = t.names,
				typeOff = 6, friendOff = 0x12, growthOff = 0x13, abilityOff = 0x16, abilitySize = 1,
				maxSpecies = 411, maxMove = 354, maxAbility = 77, shedinja = 303,
				party = 0x02024284, sb1Ptr = 0x03005008, sb2Ptr = 0x0300500C, flagsOff = 0x0EE0, varsOff = 0x1000,
				bagItemsOff = 0x0310, bagItemsCount = 42, encKeyOff = 0x0F20,
				battleMons = 0x02023BE4, battleMonSize = 0x58,
				enemyParty = 0x0202402C, opponentA = 0x020386AE, scriptCtx = 0x03000EB0,
				trainers = t.trainers, trainerSize = 40, trainerNameOff = 4, trainerNameLen = 12,
				classNames = t.classNames, classNameSize = 13,
				bmHpOff = 0x28, bmMaxHpOff = 0x2C, bmPidOff = 0x48, bmStatusOff = 0x4C,
				warpDest = 0x02031DBC,
				-- Level-up rules: learnsets are 16-bit (level << 9 | move) entries
				evos = t.evos, evoEntrySize = 8, evosPerMon = 5,
				learnsets = t.learnsets, learnsetWide = false,
				originGame = code == "BPRE" and 4 or 5, league = KANTO_LEAGUE,
			}
		end
		-- On the original games, prefer the Tracker's party address if it has one.
		-- (Nat. Dex values come straight from the ROM, so the result doesn't
		-- depend on whether NatDexExtension loaded before or after this one.)
		if not g.natdex and GameSettings and GameSettings.pstats and GameSettings.pstats > 0 then
			g.party = GameSettings.pstats
		end
		-- Derived offsets inside a party Pokemon
		g.checksumOff = g.nameLen + 18
		g.langOff, g.flagsByteOff = 8 + g.nameLen, 9 + g.nameLen
		g.markingsOff = g.nameLen + 17
		g.hpOff = g.levelOff + 2

		-- Sanity checks so a bad address can't corrupt your save
		local layoutOk = g.statusOff == g.subOff + 48 and g.levelOff == g.statusOff + 4
			and g.maxHpOff == g.levelOff + 4 and g.defOff == g.maxHpOff + 4
			and g.spaOff == g.defOff + 4 and g.monSize == g.spaOff + 4
			and g.subOff >= g.checksumOff + 4
		if not layoutOk then
			log("Pokemon data layout didn't pass sanity checks. Effects are disabled.")
			return nil
		end
		g.romOk = read8(g.baseStats) == 0 and read8(g.baseStats + g.speciesSize) > 0
			and read8(g.baseStats + g.speciesSize + g.growthOff) <= 5
			and read8(g.moves + 4) == 0 and read8(g.moves + g.moveSize + 4) > 0
		if not g.romOk then
			log("ROM tables didn't pass sanity checks. Effects that need ROM data are disabled.")
		end
		-- Level-up extras (evolution, new moves) are only used if their tables check out
		if not (g.romOk and g.evos and looksLikeEvoTable(g.evos, g.evoEntrySize, g.evosPerMon)) then
			g.evos = nil
			log("Evolution data not found in this ROM: gift level-ups won't evolve.")
		end
		if not (g.romOk and g.learnsets and looksLikeLearnsets(g.learnsets, g.learnsetWide, g.maxMove)) then
			g.learnsets = nil
			log("Learnset data not found in this ROM: gift level-ups won't teach moves.")
		end
		log("Detected " .. g.label)
		return g
	end

	local function readBaseStats(speciesId)
		if not (G and G.romOk) then return nil end
		local a = G.baseStats + speciesId * G.speciesSize
		local function ability(slot)
			local p = a + G.abilityOff + slot * G.abilitySize
			return G.abilitySize == 2 and read16(p) or read8(p)
		end
		return {
			addr = a,
			hp = read8(a), atk = read8(a + 1), def = read8(a + 2),
			spe = read8(a + 3), spa = read8(a + 4), spd = read8(a + 5),
			type1 = read8(a + G.typeOff), type2 = read8(a + G.typeOff + 1),
			friendship = read8(a + G.friendOff), growth = read8(a + G.growthOff),
			ability1 = ability(0), ability2 = ability(1),
		}
	end

	local function readMove(moveId)
		local a = G.moves + moveId * G.moveSize
		return { power = read8(a + 1), type = read8(a + 2), accuracy = read8(a + 3), pp = read8(a + 4) }
	end

	-- Gen 3 text decoding (enough for names in log messages)
	local function decodeText(addr, len)
		local out = {}
		for i = 0, len - 1 do
			local c = read8(addr + i)
			if c == 0xFF then break
			elseif c >= 0xBB and c <= 0xD4 then out[#out + 1] = string.char(65 + c - 0xBB)
			elseif c >= 0xD5 and c <= 0xEE then out[#out + 1] = string.char(97 + c - 0xD5)
			elseif c >= 0xA1 and c <= 0xAA then out[#out + 1] = string.char(48 + c - 0xA1)
			elseif c == 0x00 then out[#out + 1] = " "
			elseif c == 0x2D then out[#out + 1] = "&"
			elseif c == 0xAD then out[#out + 1] = "."
			elseif c == 0xAE then out[#out + 1] = "-"
			elseif c == 0xB4 then out[#out + 1] = "'"
			elseif c == 0xB5 then out[#out + 1] = "(M)"
			elseif c == 0xB6 then out[#out + 1] = "(F)"
			end
		end
		return table.concat(out)
	end

	local function speciesNameAddr(id) return G.names + id * (G.nameLen + 1) end
	local function speciesName(id)
		if G and G.romOk then
			local name = decodeText(speciesNameAddr(id), G.nameLen + 1)
			if name ~= "" then return name end
		end
		return "species #" .. id
	end

	local function moveName(id)
		local ok, name = pcall(function() return MoveData.Moves[id].name end)
		if ok and type(name) == "string" then return name end
		return "move #" .. id
	end

	local function abilityName(id)
		local ok, name = pcall(function() return AbilityData.Abilities[id].name end)
		if ok and type(name) == "string" then return name end
		return "ability #" .. id
	end

	-- ======================= GEN 3 POKEMON DATA ======================
	-- Every party Pokemon holds four 12-byte substructures (G)rowth,
	-- (A)ttacks, (E)Vs, (M)isc, shuffled by personality % 24 and encrypted
	-- with (personality XOR OT ID).
	local SUB_ORDERS = {
		"GAEM","GAME","GEAM","GEMA","GMAE","GMEA","AGEM","AGME","AEGM","AEMG","AMGE","AMEG",
		"EGAM","EGMA","EAGM","EAMG","EMGA","EMAG","MGAE","MGEA","MAGE","MAEG","MEGA","MEAG",
	}

	local function monView(base, pid, otid)
		local mon = { base = base, pid = pid, otid = otid, key = bxor(pid, otid), sub = {} }
		local order = SUB_ORDERS[(pid % 24) + 1]
		for i = 1, 4 do
			mon.sub[order:sub(i, i)] = base + G.subOff + (i - 1) * 12
		end
		return mon
	end

	local function computeChecksum(mon)
		local sum = 0
		for i = 0, 11 do
			local w = bxor(read32(mon.base + G.subOff + i * 4), mon.key)
			sum = sum + (w % 65536) + math.floor(w / 65536)
		end
		return sum % 65536
	end
	local function commit(mon) write16(mon.base + G.checksumOff, computeChecksum(mon)) end

	local function readMon(slot)
		local base = G.party + (slot - 1) * G.monSize
		local pid, otid = read32(base), read32(base + 4)
		if pid == 0 and otid == 0 then return nil end
		local mon = monView(base, pid, otid)
		if computeChecksum(mon) ~= read16(base + G.checksumOff) then return nil end
		return mon
	end

	local function getSub32(mon, letter, w) return bxor(read32(mon.sub[letter] + w * 4), mon.key) end
	local function setSub32(mon, letter, w, value) write32(mon.sub[letter] + w * 4, bxor(value, mon.key)) end
	local function setSubBits(mon, letter, w, start, count, value)
		setSub32(mon, letter, w, setBits(getSub32(mon, letter, w), start, count, value))
	end

	local function species(mon) return getSub32(mon, "G", 0) % 65536 end
	local function isEgg(mon) return bits(getSub32(mon, "M", 1), 30, 1) == 1 end
	local function getMoves(mon)
		local w0, w1 = getSub32(mon, "A", 0), getSub32(mon, "A", 1)
		return { w0 % 65536, math.floor(w0 / 65536), w1 % 65536, math.floor(w1 / 65536) }
	end
	local function level(mon) return read8(mon.base + G.levelOff) end

	local function getLead()
		if not G then return nil, "game not supported" end
		local mon = readMon(1)
		if not mon or isEgg(mon) then return nil, "first party slot is empty or an egg" end
		return mon
	end

	-- Total experience needed to reach level n, for each of the 6 growth rates
	local function expForLevel(growth, n)
		local n3 = n * n * n
		if n <= 1 then return 0 end
		if growth == 0 then return n3 -- Medium Fast
		elseif growth == 1 then -- Erratic
			if n <= 50 then return math.floor(n3 * (100 - n) / 50)
			elseif n <= 68 then return math.floor(n3 * (150 - n) / 100)
			elseif n <= 98 then return math.floor(n3 * math.floor((1911 - 10 * n) / 3) / 500)
			else return math.floor(n3 * (160 - n) / 100) end
		elseif growth == 2 then -- Fluctuating
			if n <= 15 then return math.floor(n3 * (math.floor((n + 1) / 3) + 24) / 50)
			elseif n <= 36 then return math.floor(n3 * (n + 14) / 50)
			else return math.floor(n3 * (math.floor(n / 2) + 32) / 50) end
		elseif growth == 3 then return math.floor(6 * n3 / 5) - 15 * n * n + 100 * n - 140 -- Medium Slow
		elseif growth == 4 then return math.floor(4 * n3 / 5) -- Fast
		elseif growth == 5 then return math.floor(5 * n3 / 4) -- Slow
		end
		return n3
	end

	-- Recalculate the stats stored in the party struct from base stats in the
	-- ROM, so randomized stats are respected.
	local function recalcStats(mon)
		local bs = readBaseStats(species(mon))
		if not bs then return end
		local lv = level(mon)
		local ivWord, ev0, ev1 = getSub32(mon, "M", 1), getSub32(mon, "E", 0), getSub32(mon, "E", 1)
		local iv = {
			hp = bits(ivWord, 0, 5), atk = bits(ivWord, 5, 5), def = bits(ivWord, 10, 5),
			spe = bits(ivWord, 15, 5), spa = bits(ivWord, 20, 5), spd = bits(ivWord, 25, 5),
		}
		local ev = {
			hp = bits(ev0, 0, 8), atk = bits(ev0, 8, 8), def = bits(ev0, 16, 8),
			spe = bits(ev0, 24, 8), spa = bits(ev1, 0, 8), spd = bits(ev1, 8, 8),
		}
		local nature = mon.pid % 25
		local up, down = math.floor(nature / 5), nature % 5 -- 0=Atk 1=Def 2=Spe 3=SpA 4=SpD
		local function core(stat)
			return math.floor((2 * bs[stat] + iv[stat] + math.floor(ev[stat] / 4)) * lv / 100)
		end
		local function other(stat, idx)
			local v = core(stat) + 5
			if up ~= down then
				if idx == up then v = math.floor(v * 110 / 100)
				elseif idx == down then v = math.floor(v * 90 / 100) end
			end
			return v
		end

		local newMaxHP = core("hp") + lv + 10
		if species(mon) == G.shedinja then newMaxHP = 1 end
		local oldMaxHP, curHP = read16(mon.base + G.maxHpOff), read16(mon.base + G.hpOff)
		-- Same rule the game uses: a fainted Pokemon stays fainted
		if curHP == 0 and oldMaxHP == 0 then
			curHP = newMaxHP
		elseif curHP ~= 0 then
			curHP = math.max(1, math.min(newMaxHP, curHP + newMaxHP - oldMaxHP))
		end
		write16(mon.base + G.maxHpOff, newMaxHP)
		write16(mon.base + G.hpOff, curHP)
		write16(mon.base + G.maxHpOff + 2, other("atk", 0))
		write16(mon.base + G.defOff, other("def", 1))
		write16(mon.base + G.defOff + 2, other("spe", 2))
		write16(mon.base + G.spaOff, other("spa", 3))
		write16(mon.base + G.spaOff + 2, other("spd", 4))
	end

	local function setLevel(mon, newLevel)
		local bs = readBaseStats(species(mon))
		if not bs or bs.growth > 5 then return false end
		setSub32(mon, "G", 1, expForLevel(bs.growth, newLevel))
		commit(mon)
		write8(mon.base + G.levelOff, newLevel)
		recalcStats(mon)
		return true
	end

	local function applyMaxIVs(mon)
		local w = getSub32(mon, "M", 1)
		for i = 0, 5 do w = setBits(w, i * 5, 5, 31) end -- keeps egg & ability bits
		setSub32(mon, "M", 1, w)
		commit(mon)
	end

	local function applyEVs(mon, ev)
		setSub32(mon, "E", 0, ev.hp + ev.atk * 256 + ev.def * 65536 + ev.spe * 16777216)
		setSubBits(mon, "E", 1, 0, 16, ev.spa + ev.spd * 256) -- keeps contest stats
		commit(mon)
	end

	local function maxEVSpread(mon)
		if SETTINGS.maxEVsMode == "legal" then
			local bs = readBaseStats(species(mon))
			local physical = not bs or bs.atk >= bs.spa
			return { hp = 4, atk = physical and 252 or 0, def = 0, spe = 252, spa = physical and 0 or 252, spd = 0 }
		end
		return { hp = 252, atk = 252, def = 252, spe = 252, spa = 252, spd = 252 }
	end

	-- 3 PP Ups on every move (= PP Max), and refill PP to the new maximum
	local function applyMaxPP(mon)
		local moves = getMoves(mon)
		local pp = 0
		for i = 1, 4 do
			if moves[i] ~= 0 then
				local base = readMove(moves[i]).pp
				pp = pp + (base + math.floor(base * 3 / 5)) * (256 ^ (i - 1))
			end
		end
		setSubBits(mon, "G", 2, 0, 8, 0xFF) -- PP Up count: 3 for each of the 4 slots
		setSub32(mon, "A", 2, pp)
		commit(mon)
	end

	-- Put a move in an empty slot, or over a random existing move
	-- forceSlot: replace the move in that slot (1-4) even if another slot is empty
	local function teachMove(mon, moveId, forceSlot)
		local moves = getMoves(mon)
		local slot = forceSlot
		if not slot then
			for i = 1, 4 do if moves[i] == 0 then slot = i break end end
		end
		slot = slot or math.random(1, 4)
		local replaced = moves[slot]
		local word, half = math.floor((slot - 1) / 2), (slot - 1) % 2
		setSubBits(mon, "A", word, half * 16, 16, moveId)
		setSubBits(mon, "A", 2, (slot - 1) * 8, 8, readMove(moveId).pp)
		setSubBits(mon, "G", 2, (slot - 1) * 2, 2, 0) -- clear PP Ups for that slot
		commit(mon)
		return replaced
	end

	local function knows(moves, id)
		for i = 1, 4 do if moves[i] == id then return true end end
		return false
	end

	-- ======================= GENERATION LIMIT ===============
	-- Highest ID of each generation, for the two ID layouts the extension knows
	local GEN_LAST = {
		vanilla = {
			pokemon = { 151, 251, 411 },
			moves = { 165, 251, 354 },
			abilities = { 77, 77, 77 },
		},
		natdex = {
			pokemon = { 151, 251, 411, 518, 674, 746, 834, 930, 1050 },
			moves = { 165, 251, 354, 467, 559, 621, 689, 778, 847 },
			abilities = { 77, 77, 77, 124, 165, 192, 234, 268, 320 },
		},
	}
	-- The Pokemon that closes each generation, to confirm the ROM uses this layout
	local GEN_LAST_NAMES = { "mew", "celebi", "chimecho", "arceus", "genesect", "volcanion", "melmetal", "enamorus", "pecharunt" }

	local function generationSetting(kind)
		local limits = SETTINGS.generationLimit
		local n = limits and tonumber(limits[kind]) or 9
		return math.max(1, math.floor(n))
	end

	-- Highest ID a random pick may use for "pokemon", "moves" or "abilities"
	local function generationCap(kind)
		local top = (kind == "pokemon" and G.maxSpecies) or (kind == "moves" and G.maxMove) or G.maxAbility
		local lasts = GEN_LAST[G.natdex and "natdex" or "vanilla"][kind]
		local n = generationSetting(kind)
		if n >= #lasts or G.genLayoutUnknown then return top end
		return math.min(top, lasts[n])
	end

	-- Nat. Dex Megas and other forms (IDs above G.maxSpecies), in blocks:
	-- { last ID of the block, generation that introduced those forms }
	local FORM_GENS = {
		{ 1100, 6 }, -- Megas, Primal Kyogre/Groudon
		{ 1118, 7 }, -- Alolan forms
		{ 1153, 8 }, -- Galarian and Hisuian forms
		{ 1155, 9 }, -- Paldean Tauros, Wooper
		{ 1157, 7 }, -- Pikachu (cap, partner)
		{ 1159, 9 }, -- Paldean Tauros breeds
		{ 1160, 7 }, -- partner Eevee
		{ 1161, 4 }, -- spiky-eared Pichu
		{ 1167, 3 }, -- Castform, Deoxys
		{ 1177, 4 }, -- Burmy, Wormadam, Cherrim, Rotom
		{ 1179, 8 }, -- Origin Dialga, Palkia
		{ 1181, 4 }, -- Origin Giratina, Sky Shaymin
		{ 1182, 5 }, { 1183, 8 }, -- Basculin: blue-striped, white-striped
		{ 1184, 5 }, { 1185, 8 }, -- Darmanitan Zen Mode: Unovan, Galarian
		{ 1191, 5 }, -- Therian forms, Kyurem, Meloetta
		{ 1192, 7 }, -- Ash-Greninja
		{ 1204, 6 }, -- Floette, Meowstic, Aegislash, Pumpkaboo, Gourgeist, Zygarde, Hoopa
		{ 1214, 7 }, -- Oricorio, Lycanroc, Wishiwashi, Minior, Necrozma
		{ 1224, 8 }, -- Toxtricity ... Calyrex riders
		{ 1225, 9 }, -- Bloodmoon Ursaluna
		{ 1227, 8 }, -- Basculegion, Therian Enamorus
		{ 1235, 9 }, -- Oinkologne ... Terapagos
		{ 1236, 7 }, -- Battle Bond Greninja
		{ 1283, 9 }, -- Squawkabilly, the newest Megas
	}
	-- A few slots by name, to confirm the ROM keeps its forms in this order
	local FORM_ANCHORS = {
		[1051] = "venusaur", [1100] = "groudon", [1118] = "marowak", [1153] = "decidueye",
		[1161] = "pichu", [1204] = "hoopa", [1237] = "squawkabilly", [1283] = "meowstic",
	}

	local function formGeneration(id)
		for _, block in ipairs(FORM_GENS) do
			if id <= block[1] then return block[2] end
		end
		return 9
	end

	-- First and last ID of the Megas/forms, or nil if this game has none
	local function formRange()
		if not (G and G.natdex and G.speciesCount) then return nil end
		return G.maxSpecies + 1, G.speciesCount - 1
	end

	-- What to call a species in messages. Forms share their base species' name
	-- in the ROM, so say which form it is ("Mega Charizard X", "Alolan Vulpix").
	local FORM_LABELS = {
		{ 1098, "Mega %s" }, { 1100, "Primal %s" }, { 1118, "Alolan %s" }, { 1137, "Galarian %s" },
		{ 1153, "Hisuian %s" }, { 1155, "Paldean %s" }, { 1157, "%s (alternate form)" }, { 1159, "Paldean %s" },
		{ 1237, "%s (alternate form)" }, { 1283, "Mega %s" },
	}
	local FORM_SUFFIXES = {
		[1052] = " X", [1053] = " Y", [1064] = " X", [1065] = " Y",
		[1264] = " X", [1265] = " Y", [1267] = " Z", [1269] = " Z", [1270] = " Z",
	}
	local function speciesLabel(id)
		local name = speciesName(id)
		local first, last = formRange()
		if not first or id < first or id > last then return name end
		if not G.formLayoutUnknown then
			for _, block in ipairs(FORM_LABELS) do
				if id <= block[1] then return string.format(block[2], name) .. (FORM_SUFFIXES[id] or "") end
			end
		end
		return name .. " (alternate form)"
	end

	-- The Megas and other forms a random pick may use right now: finished
	-- entries only, within the generation limit. Empty when switched off.
	local function formSpecies()
		local list = {}
		local first, last = formRange()
		if not first or SETTINGS.alternateForms == false then return list end
		local gen = generationSetting("pokemon")
		local limited = gen < #GEN_LAST.natdex.pokemon and not G.genLayoutUnknown
		if limited and G.formLayoutUnknown then return list end
		for id = first, last do
			if not limited or formGeneration(id) <= gen then
				local bs = readBaseStats(id)
				-- growth 0-5 and an exp. yield of 2+ mark a finished entry
				if bs and bs.hp > 0 and bs.growth <= 5 and read16(bs.addr + 0x1E) >= 2 then
					list[#list + 1] = id
				end
			end
		end
		return list
	end

	-- Called once the ROM is known: checks where the forms are and says so
	local function reportForms()
		local first, last = formRange()
		if not first then return end
		G.formLayoutUnknown = nil
		if G.romOk then
			for id, name in pairs(FORM_ANCHORS) do
				if id > last or string.lower(speciesName(id)) ~= name then G.formLayoutUnknown = true end
			end
		end
		if SETTINGS.alternateForms == false then
			log("Megas and other forms: off (alternateForms = false)")
			return
		end
		local count = #formSpecies()
		if count > 0 then
			log(string.format("Megas and other forms: %d in the pool for replaceLead (ruleset permitting) and Gym Leader teams", count))
		elseif G.formLayoutUnknown then
			log("Megas and other forms are left out while generationLimit is set: this ROM orders them differently than expected.")
		end
	end

	-- Called once the ROM is known: checks the layout and says what is limited
	local function reportGenerationLimit()
		local lasts = GEN_LAST[G.natdex and "natdex" or "vanilla"].pokemon
		local limited = {}
		for _, kind in ipairs({ "pokemon", "moves", "abilities" }) do
			if generationSetting(kind) < #lasts then
				limited[#limited + 1] = string.format("%s Gen 1-%d", kind, generationSetting(kind))
			end
		end
		if generationSetting("items") < 8 and G.expCandyItems and next(G.expCandyItems) then
			limited[#limited + 1] = "items Gen 1-" .. generationSetting("items")
		end
		if #limited == 0 then return end
		if G.romOk then
			for gen, last in ipairs(lasts) do
				if string.lower(speciesName(last)) ~= GEN_LAST_NAMES[gen] then
					G.genLayoutUnknown = true
					log("generationLimit is ignored: this ROM orders its Pokemon differently than expected.")
					return
				end
			end
		end
		log("Ruleset limit: " .. table.concat(limited, ", "))
	end

	-- ======================= IRONMON RULESETS ===============
	-- Source: ironmon.gg (the IronMon rules) and its linked banned-move list.
	-- IDs are the same in the original games and in Nat. Dex FireRed.
	-- Cut, Fly, Surf, Strength, Flash, Rock Smash, Waterfall, Dive, Whirlpool, Rock Climb, Defog
	local MOVES_HM = { 15, 19, 57, 70, 148, 249, 127, 291, 250, 431, 432 }
	local MOVES_HM_NO_CUT = { 19, 57, 70, 148, 249, 127, 291, 250, 431, 432 }
	-- Healing, status-healing, pivoting and party-reliant moves banned in Kaizo, Super Kaizo and Survival:
	-- Leech Seed, Teleport, Recover, Soft-Boiled, Rest, Milk Drink, Pain Split, Baton Pass, Morning Sun,
	-- Synthesis, Moonlight, Swallow, Wish, Assist, Ingrain, Slack Off, Roost, U-turn, Aqua Ring,
	-- Heal Order, Heal Pulse, Volt Switch, Parting Shot, Grassy Terrain, Floral Healing, Pollen Puff,
	-- Purify, Shore Up
	local MOVES_HEAL_PIVOT = { 73, 100, 105, 135, 156, 208, 220, 226, 234, 235, 236, 256, 273, 274, 275,
		303, 355, 369, 392, 456, 505, 521, 575, 580, 622, 629, 639, 648 }
	-- Also banned in Kaizo and Super Kaizo: Spore, Heal Bell, Refresh, Aromatherapy, Psycho Shift
	local MOVES_SPORE_STATUS_HEAL = { 147, 215, 287, 312, 375 }
	-- Also banned in Kaizo (draining attacks): Absorb, Mega Drain, Dream Eater, Leech Life, Giga Drain,
	-- Drain Punch, Horn Leech, Parabolic Charge, Draining Kiss, Oblivion Wing
	local MOVES_DRAIN = { 71, 72, 138, 141, 202, 409, 532, 570, 577, 613 }
	-- Not on the published lists (they stop at Gen 7), same kinds of move. Used if rulesetNewerMoves:
	-- Strength Sap, Life Dew, Jungle Healing, Lunar Blessing, Flip Turn, Shed Tail, Chilly Reception
	local MOVES_NEWER_HEAL_PIVOT = { 631, 719, 744, 777, 740, 806, 807 }
	local MOVES_NEWER_STATUS_HEAL = { 778 }      -- Take Heart
	local MOVES_NEWER_DRAIN = { 680, 817, 830 }  -- Bouncy Bubble, Bitter Blade, Matcha Gotcha

	-- moves: always banned.  hmMoves: banned on the original games only (Nat. Dex
	-- allows HM moves in battle unless they were taught with the HM item).
	-- abilities: "bst" = banned only above the ability BST limit, "always" = banned outright.
	local RULESETS = {
		standard = { label = "Standard" },
		ultimate = { label = "Ultimate", hmMoves = MOVES_HM },
		kaizo = { label = "Kaizo", bstLimit = true, hmMoves = MOVES_HM,
			moves = { MOVES_HEAL_PIVOT, MOVES_SPORE_STATUS_HEAL, MOVES_DRAIN },
			newerMoves = { MOVES_NEWER_HEAL_PIVOT, MOVES_NEWER_STATUS_HEAL, MOVES_NEWER_DRAIN },
			abilities = { [37] = "bst", [74] = "bst" } },  -- Huge Power, Pure Power
		superkaizo = { label = "Super Kaizo", bstLimit = true, hmMoves = MOVES_HM,
			moves = { MOVES_HEAL_PIVOT, MOVES_SPORE_STATUS_HEAL },
			newerMoves = { MOVES_NEWER_HEAL_PIVOT, MOVES_NEWER_STATUS_HEAL },
			-- + Battle Armor, Shell Armor, Magic Guard (banned outright)
			abilities = { [37] = "bst", [74] = "bst", [4] = "always", [75] = "always", [99] = "always" } },
		survival = { label = "Survival", bstLimit = true, hmMoves = MOVES_HM_NO_CUT,
			moves = { MOVES_HEAL_PIVOT },
			newerMoves = { MOVES_NEWER_HEAL_PIVOT },
			-- Huge Power, Pure Power, Battle Armor, Shell Armor, Parental Bond, Protean, Fur Coat, Magic Guard
			abilities = { [37] = "bst", [74] = "bst", [4] = "bst", [75] = "bst", [186] = "bst", [169] = "bst",
				[170] = "bst", [99] = "bst" } },
	}
	-- Pokemon a banned ability is still fine on: BST up to this number
	local ABILITY_FREE_BST = { vanilla = 399, natdex = 420 }

	-- From the Legendary Pokemon list both rule pages point to. Matched by name,
	-- so it works whatever the ROM's order is.
	-- "Strong" legendaries and mythicals: banned in every ruleset, on every ROM.
	local STRONG_LEGENDARY_NAMES = {
		"mewtwo", "lugia", "hooh", "kyogre", "groudon", "rayquaza", "dialga", "palkia", "giratina", "reshiram",
		"zekrom", "kyurem", "xerneas", "yveltal", "zygarde", "cosmog", "cosmoem", "solgaleo", "lunala", "necrozma",
		"zacian", "zamazenta", "eternatus", "calyrex", "koraidon", "miraidon", "terapagos",
		"mew", "celebi", "jirachi", "deoxys", "phione", "manaphy", "darkrai", "shaymin", "arceus", "victini",
		"keldeo", "meloetta", "genesect", "diancie", "hoopa", "volcanion", "magearna", "marshadow", "zeraora",
		"meltan", "melmetal", "zarude", "pecharunt",
	}
	-- Sub-legendaries (Ultra Beasts included): banned on the original games, allowed on Nat. Dex.
	local SUB_LEGENDARY_NAMES = {
		"articuno", "zapdos", "moltres", "raikou", "entei", "suicune", "regirock", "regice", "registeel", "latias",
		"latios", "uxie", "mesprit", "azelf", "heatran", "regigigas", "cresselia", "cobalion", "terrakion",
		"virizion", "tornadus", "thundurus", "landorus", "typenull", "silvally", "tapukoko", "tapulele",
		"tapubulu", "tapufini", "nihilego", "buzzwole", "pheromosa", "xurkitree", "celesteela", "kartana",
		"guzzlord", "poipole", "naganadel", "stakataka", "blacephalon", "kubfu", "urshifu", "regieleki",
		"regidrago", "glastrier", "spectrier", "enamorus", "wochien", "chienpao", "tinglu", "chiyu", "okidogi",
		"munkidori", "fezandipiti", "ogerpon",
	}

	local rules = nil -- the active ruleset, built once the ROM is known (nil = no ruleset)

	local function setupRuleset()
		rules = nil
		local name = string.lower(tostring(SETTINGS.ruleset or "none")):gsub("[^%a]", "")
		if name == "none" or name == "" then return end
		-- "natdexKaizo" and friends: the same ruleset with the Nat. Dex rule changes
		local natdexRules = name:match("^natdex(.+)$") ~= nil
		local def = RULESETS[natdexRules and name:match("^natdex(.+)$") or name]
		if not def then
			log('Unknown ruleset "' .. tostring(SETTINGS.ruleset) .. '". Use none, standard, ultimate, kaizo, superKaizo or survival,'
				.. ' or put "Nat. Dex" in front (for example "Nat. Dex Kaizo").')
			return
		end
		local r = { label = def.label, moves = {}, abilities = {}, legendary = {}, moveCount = 0 }
		for _, list in ipairs(def.moves or {}) do
			for _, id in ipairs(list) do r.moves[id] = true end
		end
		if not natdexRules then
			for _, id in ipairs(def.hmMoves or {}) do r.moves[id] = true end
		end
		if SETTINGS.rulesetNewerMoves then
			for _, list in ipairs(def.newerMoves or {}) do
				for _, id in ipairs(list) do r.moves[id] = true end
			end
		end
		for id in pairs(r.moves) do if id <= G.maxMove then r.moveCount = r.moveCount + 1 end end
		for id, kind in pairs(def.abilities or {}) do r.abilities[id] = kind end
		r.abilityFreeBST = ABILITY_FREE_BST[natdexRules and "natdex" or "vanilla"]
		if def.bstLimit then r.maxBST = tonumber(SETTINGS.rulesetMaxBST) or (natdexRules and 599 or 598) end

		local wanted, found = {}, 0
		for _, n in ipairs(STRONG_LEGENDARY_NAMES) do wanted[n] = true end
		if not natdexRules then
			for _, n in ipairs(SUB_LEGENDARY_NAMES) do wanted[n] = true end
		end
		if G.romOk then
			-- Megas and other forms carry their base species' name, so a
			-- legendary's forms are excluded with it
			local _, lastForm = formRange()
			for id = 1, lastForm or G.maxSpecies do
				local key = string.lower(speciesName(id)):gsub("[^%a]", "")
				if wanted[key] then
					r.legendary[id] = true
					if id <= G.maxSpecies then found = found + 1 end
				end
			end
		end
		rules = r
		if natdexRules then r.label = "Nat. Dex " .. r.label end
		local parts = { found .. " legendary Pokemon excluded" }
		if r.maxBST then parts[#parts + 1] = "BST " .. r.maxBST .. " or less" end
		if r.moveCount > 0 then parts[#parts + 1] = r.moveCount .. " banned moves skipped" end
		if next(r.abilities) then parts[#parts + 1] = "banned abilities skipped" end
		log("Ruleset: " .. r.label .. " (" .. table.concat(parts, ", ") .. ")")
		if G.natdex and not natdexRules then
			log("This is a Nat. Dex ROM. Pick \"Nat. Dex " .. def.label .. "\" in Options if you play by the Nat. Dex rules.")
		end
	end

	-- May a gift hand this species to the player?
	local function rulesetAllowsSpecies(id, bs)
		if not rules then return true end
		if rules.legendary[id] then return false end
		if rules.maxBST and bs.hp + bs.atk + bs.def + bs.spe + bs.spa + bs.spd > rules.maxBST then return false end
		return true
	end
	-- Is this ability banned for a Pokemon with these base stats?
	local function rulesetBansAbility(id, bs)
		if not rules then return false end
		local kind = rules.abilities[id]
		if kind == "always" then return true end
		if kind == "bst" then
			return not bs or bs.hp + bs.atk + bs.def + bs.spe + bs.spa + bs.spd > rules.abilityFreeBST
		end
		return false
	end

	-- forPlayer: the move is for the player's Pokemon, so the ruleset applies.
	-- (Opposing teams built by gifts are not bound by the player's rules.)
	local function randomMove(filter, forPlayer)
		local options = {}
		local banned = forPlayer and rules and rules.moves or nil
		for id = 1, generationCap("moves") do
			if id ~= 165 and not (banned and banned[id]) then -- 165 = Struggle
				local m = readMove(id)
				-- Skip empty entries (e.g. Nat. Dex moves without battle data) and garbled ones
				if m.pp > 0 and m.type <= 18 and (not filter or filter(id, m)) then options[#options + 1] = id end
			end
		end
		if #options == 0 then return nil end
		return options[math.random(1, #options)]
	end

	local function randomSpecies(forPlayer)
		local top = generationCap("pokemon")
		-- IDs 252-276 are placeholder slots in Gen 3 (and in the Nat. Dex hack)
		local baseCount = top <= 251 and top or top - 25
		-- Nat. Dex: Megas and other forms are picked like any other species
		local forms = formSpecies()
		for _ = 1, 1000 do
			local id = math.random(1, baseCount + #forms)
			if id > baseCount then
				id = forms[id - baseCount]
			elseif id > 251 then
				id = id + 25
			end
			local bs = readBaseStats(id)
			if bs and bs.hp > 0 and bs.growth <= 5 and (not forPlayer or rulesetAllowsSpecies(id, bs)) then
				return id, bs
			end
		end
		return nil
	end

	local function nameLead(mon) return speciesLabel(species(mon)) end

	-- ======================= LEVEL-UP RULES =================
	-- What the game does after a Rare Candy, done directly on the data:
	-- friendship gain, level-up moves, and evolution. (The game's own routine
	-- lives inside the bag menu, so it can't be started from here.)
	-- Where the save data is right now: a fixed address in Ruby/Sapphire, behind
	-- a pointer (that the game moves around) everywhere else
	local function saveBlock1() return G.sb1 or read32(G.sb1Ptr) end
	local function saveBlock2() return G.sb2 or read32(G.sb2Ptr) end

	local function flagIsSet(flag)
		if not ((G.sb1 or G.sb1Ptr) and G.flagsOff) then return false end
		return bits(read8(saveBlock1() + G.flagsOff + math.floor(flag / 8)), flag % 8, 1) == 1
	end

	local function heldItem(mon) return math.floor(getSub32(mon, "G", 0) / 65536) end
	local function friendship(mon) return bits(getSub32(mon, "G", 2), 8, 8) end

	local function addCandyFriendship(mon)
		local f = friendship(mon)
		local gain = (f < 100 and 5) or (f < 200 and 3) or 2
		setSubBits(mon, "G", 2, 8, 8, math.min(255, f + gain))
		commit(mon)
	end

	-- "male", "female" or nil (genderless), from the species' gender ratio
	local function gender(mon, speciesId)
		local ratio = read8(G.baseStats + speciesId * G.speciesSize + 0x10)
		if ratio == 0 then return "male" end
		if ratio == 254 then return "female" end
		if ratio == 255 then return nil end
		return ratio > (mon.pid % 256) and "female" or "male"
	end

	local LOW_KEY_NATURES = { [1] = true, [5] = true, [7] = true, [10] = true, [12] = true, [15] = true,
		[16] = true, [17] = true, [18] = true, [20] = true, [21] = true, [23] = true }

	local function validSpecies(id)
		if id == 0 then return false end
		local bs = readBaseStats(id)
		return bs ~= nil and bs.hp > 0 and bs.growth <= 5
	end

	-- The species this Pokemon evolves into at its current level, or nil.
	-- Follows GetEvolutionTargetSpecies (level-up mode): a later matching
	-- entry wins over an earlier one.
	local function evolutionTarget(mon)
		if not G.evos then return nil end
		local sp = species(mon)
		if heldItem(mon) == 195 then return nil end -- Everstone

		-- Nat. Dex "evolve every level" mode, the same roll the game makes: any
		-- species slot in the ROM (Megas and forms included, and it can land on
		-- the same species) with the same growth rate and an exp. yield of 2+.
		if G.evoEveryLevelFlag and flagIsSet(G.evoEveryLevelFlag) then
			local mine = readBaseStats(sp)
			local count = G.speciesCount or (G.maxSpecies + 1)
			for _ = 1, 5000 do
				local id = math.random(0, count - 1)
				local bs = readBaseStats(id)
				if bs and bs.hp > 0 and bs.growth == mine.growth
					and read16(bs.addr + 0x1E) >= 2 then -- exp yield (skips unfinished entries)
					return id
				end
			end
			return nil
		end

		local lv = level(mon)
		local atk, def = read16(mon.base + G.maxHpOff + 2), read16(mon.base + G.defOff)
		local pidHigh = math.floor(mon.pid / 65536) % 10
		-- Hour of the game's clock (Emerald/Ruby/Sapphire), as the game last read it
		local hour = G.localTime and read8(G.localTime + 2) or nil
		local target
		local row = G.evos + sp * G.evoEntrySize * G.evosPerMon
		for e = 0, G.evosPerMon - 1 do
			local a = row + e * G.evoEntrySize
			local method, param, to = read16(a), read16(a + 2), read16(a + 4)
			local ok = false
			if method == 1 then ok = friendship(mon) >= 220                    -- friendship
			elseif method == 2 then ok = hour ~= nil and hour >= 12 and hour < 24 and friendship(mon) >= 220 -- by day
			elseif method == 3 then ok = hour ~= nil and hour < 12 and friendship(mon) >= 220                -- by night
			elseif method == 4 or method == 13 then ok = param <= lv           -- level (13 = Ninjask)
			elseif method == 8 then ok = param <= lv and atk > def
			elseif method == 9 then ok = param <= lv and atk == def
			elseif method == 10 then ok = param <= lv and atk < def
			elseif method == 11 then ok = param <= lv and pidHigh <= 4         -- Silcoon
			elseif method == 12 then ok = param <= lv and pidHigh > 4          -- Cascoon
			elseif method == 15 then ok = param <= bits(getSub32(mon, "E", 1), 24, 8) -- beauty
			elseif G.natdex then
				if method == 16 then ok = param <= lv and gender(mon, sp) == "female"
				elseif method == 17 then ok = param <= lv and gender(mon, sp) == "male"
				elseif method == 20 then ok = param <= lv and LOW_KEY_NATURES[mon.pid % 25] == true
				elseif method == 22 then ok = param <= lv and heldItem(mon) == G.regionalRock
				elseif method == 24 then
					ok = param <= lv and G.mapHeader and G.mapHeader >= 0x02000000 and G.mapHeader < 0x04000000
						and read8(G.mapHeader + 0x17) == 4 -- underground map
				end
			end
			if ok then target = to end
		end
		if not target or target == sp or not validSpecies(target) then return nil end
		return target
	end

	-- Changes the species the way the evolution scene does: the name follows
	-- if it wasn't a nickname, and stats are recalculated. The level is kept
	-- even if the new species uses a different experience curve.
	local function evolveInto(mon, target)
		local old = species(mon)
		local oldName, newName = speciesNameAddr(old), speciesNameAddr(target)
		local sameName = true
		for i = 0, G.nameLen - 1 do
			local c = read8(oldName + i)
			if c ~= read8(mon.base + 8 + i) then sameName = false break end
			if c == 0xFF then break end
		end
		local oldGrowth = readBaseStats(old).growth
		setSubBits(mon, "G", 0, 0, 16, target)
		local bs = readBaseStats(target)
		if bs.growth ~= oldGrowth then
			setSub32(mon, "G", 1, expForLevel(bs.growth, level(mon)))
		end
		commit(mon)
		if sameName then
			for i = 0, G.nameLen - 1 do write8(mon.base + 8 + i, read8(newName + i)) end
		end
		recalcStats(mon)
	end

	-- Moves the species learns at exactly this level
	local function movesLearnedAt(speciesId, lv)
		local list = {}
		if not G.learnsets then return list end
		local p = read32(G.learnsets + speciesId * 4)
		if not isRomAddr(p) then return list end
		for i = 0, 99 do
			local moveLv, move
			if G.learnsetWide then
				local v = read32(p + i * 4)
				if v == 0xFFFFFFFF then break end
				moveLv, move = math.floor(v / 65536), v % 65536
			else
				local v = read16(p + i * 2)
				if v == 0xFFFF then break end
				moveLv, move = math.floor(v / 512), v % 512
			end
			if moveLv == lv and move ~= 0 and move <= G.maxMove and readMove(move).pp > 0 then
				list[#list + 1] = move
			end
		end
		return list
	end

	-- Level-up moves go into empty slots only (the game would ask which move
	-- to forget; a gift never overwrites a move). Adds to the two name lists.
	local function learnLevelMoves(mon, lv, learned, skipped)
		for _, move in ipairs(movesLearnedAt(species(mon), lv)) do
			local moves = getMoves(mon)
			local known, free = false, false
			for i = 1, 4 do
				if moves[i] == move then known = true end
				if moves[i] == 0 then free = true end
			end
			if not known then
				if free then
					teachMove(mon, move)
					learned[#learned + 1] = moveName(move)
				elseif not MoveChoice.request(mon, move) then
					skipped[#skipped + 1] = moveName(move)
				end
			end
		end
	end

	-- ======================= ELITE FOUR WARP ================
	-- sWarpDestination {s8 group, s8 num, s8 warpId, pad, s16 x, s16 y} is where
	-- the next warp leads. Its address is known for the original games. For
	-- Nat. Dex it's found at runtime: while you're standing in a map it always
	-- holds the same 8 bytes as the saved current location.
	local FRAME_EVENT_NAME = "TikTokGiftsEliteFourWarp"
	local warp = { armed = false, candidates = {}, snaps = {}, lastLoc = nil, frames = 0 }

	local function sb1() return saveBlock1() end
	local function currentLocation() return readBytes(sb1() + 4, 8) end

	local function findWarpDestCandidates()
		local loc = currentLocation()
		if G.warpDest then
			-- Right after a save is loaded the destination is still blank; it is
			-- filled in by the first door you take
			local dest = readBytes(G.warpDest, 8)
			local blank = true
			for i = 1, 8 do if dest[i] ~= 0 then blank = false end end
			if blank or sameBytes(dest, loc) then return { G.warpDest } end
		end

		local ok, data = pcall(memory.readbyterange, 0, 0x40000, "EWRAM")
		if not ok or type(data) ~= "table" then return {} end
		local first = (data[0] ~= nil) and 0 or 1 -- BizHawk returns a 0-indexed table
		local sbStart = sb1() - 0x02000000
		local found = {}
		for off = 0, 0x40000 - 8, 2 do
			if data[off + first] == loc[1] and (off < sbStart or off >= sbStart + 0x4000) then
				local match = true
				for i = 2, 8 do
					if data[off + first + i - 1] ~= loc[i] then match = false break end
				end
				if match then found[#found + 1] = 0x02000000 + off end
			end
		end
		return found
	end

	local function setFlag(flag, on)
		local addr = sb1() + G.flagsOff + math.floor(flag / 8)
		local byte, bit = read8(addr), flag % 8
		local isSet = bits(byte, bit, 1) == 1
		if on and not isSet then write8(addr, byte + 2 ^ bit)
		elseif not on and isSet then write8(addr, byte - 2 ^ bit) end
	end
	local function setVar(var, value)
		write16(sb1() + G.varsOff + (var - 0x4000) * 2, value)
	end

	-- Same resets the game runs itself after the Hall of Fame or a whiteout,
	-- so the whole League can be fought fresh (see the League tables above).
	local function resetEliteFour()
		local league = G.league
		for _, flag in ipairs(league.flags) do setFlag(flag, false) end
		for _, trainer in ipairs(league.trainerFlags) do
			setFlag(0x500 + trainer, false) -- TRAINER_FLAGS_START + id
		end
		setVar(league.sceneVar, 0)
	end

	-- Raises the Pokemon from one level to another the way the game would:
	-- one level at a time, each with its friendship gain, its level-up moves
	-- and an evolution check (all three follow the levelUp settings).
	-- Returns false if the ROM data couldn't be read, else true and a report.
	local function gainLevels(mon, fromLevel, toLevel)
		local report = { learned = {}, skipped = {}, evolved = {} }
		for l = fromLevel + 1, toLevel do
			if not setLevel(mon, l) then return false, report end
			if SETTINGS.levelUpFriendship then addCandyFriendship(mon) end
			if SETTINGS.levelUpLearnsMoves then learnLevelMoves(mon, l, report.learned, report.skipped) end
			local target = SETTINGS.levelUpEvolves and evolutionTarget(mon)
			if target then
				evolveInto(mon, target)
				report.evolved[#report.evolved + 1] = speciesLabel(target)
				if SETTINGS.levelUpLearnsMoves then learnLevelMoves(mon, l, report.learned, report.skipped) end
			end
		end
		return true, report
	end
	-- " evolved into X! Learned A, B. ..." for a gainLevels report
	local function describeLevelGains(report)
		local msg = ""
		if #report.evolved > 0 then msg = msg .. ", evolved into " .. table.concat(report.evolved, ", then ") .. "!" end
		if #report.learned > 0 then msg = msg .. " Learned " .. table.concat(report.learned, ", ") .. "." end
		if #report.skipped > 0 then
			msg = msg .. " Didn't learn " .. table.concat(report.skipped, ", ") .. " (no empty move slot)."
		end
		if #MoveChoice.justAsked > 0 then
			msg = msg .. " Wants to learn " .. table.concat(MoveChoice.justAsked, ", ") .. ": choose in the pop-up."
		end
		return msg
	end

	-- Elite Four warp boost: the lead reaches Lv.100 as if it had earned the
	-- experience, so it learns its moves (and evolves) on the way up, then
	-- gets max IVs, EVs and PP.
	local function boostLeadForLeague()
		local mon = getLead()
		if not mon then return "no lead to boost" end
		local startLevel = level(mon)
		MoveChoice.justAsked = {}
		MoveChoice.maxPPForNew = true -- moves chosen in the pop-up later get max PP too
		local ok, report = gainLevels(mon, startLevel, 100)
		MoveChoice.maxPPForNew = false
		applyMaxIVs(mon)
		applyEVs(mon, maxEVSpread(mon))
		applyMaxPP(mon)
		recalcStats(mon)
		local msg = nameLead(mon) .. " is now Lv." .. level(mon) .. " with max IVs, EVs and PP"
		if ok then msg = msg .. describeLevelGains(report) end
		return msg
	end

	local function stopWarpWatch()
		warp.armed = false
		warp.candidates, warp.snaps = {}, {}
		if event and event.unregisterbyname then pcall(event.unregisterbyname, FRAME_EVENT_NAME) end
	end

	local function isLeagueRoom(dest)
		return dest[1] == G.league.group and G.league.rooms[dest[2]] == true
	end

	local function fireWarp(addr)
		resetEliteFour()
		local boostMsg = SETTINGS.eliteFourBoostLead and boostLeadForLeague() or nil
		write8(addr, G.league.group)
		write8(addr + 1, G.league.firstRoom)
		write8(addr + 2, 0)          -- warp 0 = the room's entrance
		write16(addr + 4, 0xFFFF)    -- x = -1
		write16(addr + 6, 0xFFFF)    -- y = -1
		stopWarpWatch()
		log("The door leads to... the Elite Four! Good luck." .. (boostMsg and (" " .. boostMsg .. ".") or ""))
		if Program and Program.redraw then pcall(Program.redraw, true) end
	end

	-- Runs every frame while armed. Stepping on a door, staircase, cave
	-- entrance or warp tile writes a destination with warpId >= 0 several
	-- frames BEFORE the map changes. Walking between outdoor maps changes the
	-- destination and the location in the same frame, and Fly/whiteout use
	-- warpId -1, so those are ignored.
	local function watchWarp()
		if not warp.armed then return end
		local loc = currentLocation()

		if #warp.candidates == 0 then
			warp.frames = warp.frames + 1
			if warp.frames % 60 ~= 1 then return end -- retry the search about once a second
			warp.candidates = findWarpDestCandidates()
			warp.snaps, warp.lastLoc = {}, loc
			for _, a in ipairs(warp.candidates) do warp.snaps[a] = readBytes(a, 8) end
			return
		end

		local locChanged = not sameBytes(loc, warp.lastLoc)
		for _, a in ipairs(warp.candidates) do
			local now = readBytes(a, 8)
			if not locChanged and not sameBytes(now, warp.snaps[a]) then
				if now[3] < 128 and not isLeagueRoom(now) then
					fireWarp(a)
					return
				end
				warp.snaps[a] = now
			end
		end

		if locChanged then
			-- After any map change the real destination equals the new location,
			-- so drop candidates that don't (they were coincidental matches)
			local keep = {}
			for _, a in ipairs(warp.candidates) do
				local now = readBytes(a, 8)
				if sameBytes(now, loc) then keep[#keep + 1] = a end
				warp.snaps[a] = now
			end
			if #keep > 0 then warp.candidates = keep end
			warp.lastLoc = loc
		end
	end

	-- ======================= EFFECTS ========================
	-- Each returns success (bool), message (string)
	local Effects = {}

	function Effects.eliteFourWarp()
		if not G.league then return false, "the Pokemon League of this game isn't known", "permanent" end
		if warp.armed then return false, "the Elite Four warp is already waiting for the next door" end
		if not (event and event.onframeend) then return false, "needs BizHawk's per-frame Lua events", "permanent" end
		warp.armed, warp.frames = true, 0
		warp.candidates = findWarpDestCandidates()
		warp.snaps, warp.lastLoc = {}, currentLocation()
		for _, a in ipairs(warp.candidates) do warp.snaps[a] = readBytes(a, 8) end
		pcall(event.unregisterbyname, FRAME_EVENT_NAME)
		event.onframeend(watchWarp, FRAME_EVENT_NAME)
		return true, "the next door you go through leads to the Elite Four!"
	end

	function Effects.levelUp(amount)
		local mon, err = getLead()
		if not mon then return false, err end
		local lv = level(mon)
		local newLevel = math.min(100, lv + (amount or 1))
		if newLevel <= lv then return false, "lead is already level 100" end
		local startName = nameLead(mon)
		MoveChoice.justAsked = {}
		-- One level at a time, like using Rare Candies one after another
		local ok, report = gainLevels(mon, lv, newLevel)
		if not ok then return false, "couldn't read ROM data", "permanent" end
		return true, string.format("%s Lv.%d -> Lv.%d", startName, lv, newLevel) .. describeLevelGains(report)
	end

	function Effects.lowerLevel(amount)
		local mon, err = getLead()
		if not mon then return false, err end
		local lv = level(mon)
		local newLevel = math.max(1, lv - (amount or 1))
		if newLevel >= lv then return false, "lead is already level 1" end
		if not setLevel(mon, newLevel) then return false, "couldn't read ROM data", "permanent" end
		return true, string.format("%s Lv.%d -> Lv.%d", nameLead(mon), lv, newLevel)
	end

	-- In battle, the active Pokemon have a second copy of their HP/status in
	-- gBattleMons that the battle actually uses. Find it by personality value.
	local function battleCopiesOf(mon)
		local found = {}
		if not (currentlyInBattle and G.battleMons and G.battleMons > 0) then return found end
		for _, battler in ipairs({ 0, 2 }) do -- the player's side (2 = doubles partner slot)
			local a = G.battleMons + battler * G.battleMonSize
			if read32(a + G.bmPidOff) == mon.pid then found[#found + 1] = a end
		end
		return found
	end

	function Effects.healParty()
		local healed = 0
		for slot = 1, 6 do
			local mon = readMon(slot)
			if mon and not isEgg(mon) then
				local hp, maxHp = read16(mon.base + G.hpOff), read16(mon.base + G.maxHpOff)
				local status = read32(mon.base + G.statusOff)
				local fainted = hp == 0
				-- Don't revive mid-battle; fainted Pokemon are healed after the battle instead
				if (hp < maxHp or status ~= 0) and not (fainted and currentlyInBattle) then
					write16(mon.base + G.hpOff, maxHp)
					write32(mon.base + G.statusOff, 0)
					for _, b in ipairs(battleCopiesOf(mon)) do
						write16(b + G.bmHpOff, read16(b + G.bmMaxHpOff))
						write32(b + G.bmStatusOff, 0)
					end
					healed = healed + 1
				end
			end
		end
		if healed == 0 then
			return false, currentlyInBattle and "no one needs healing (fainted Pokemon are revived after battle)"
				or "everyone is already at full health"
		end
		return true, string.format("healed %d Pokemon (HP + status)%s", healed,
			currentlyInBattle and " mid-battle; the HP bar updates on the next turn" or "")
	end

	function Effects.maxIVs()
		local mon, err = getLead()
		if not mon then return false, err end
		applyMaxIVs(mon)
		recalcStats(mon)
		return true, nameLead(mon) .. " now has perfect IVs (31 in every stat)"
	end

	function Effects.maxEVs()
		local mon, err = getLead()
		if not mon then return false, err end
		applyEVs(mon, maxEVSpread(mon))
		recalcStats(mon)
		return true, nameLead(mon) .. " got max EVs (" .. SETTINGS.maxEVsMode .. ")"
	end

	function Effects.randomizeIVs()
		local mon, err = getLead()
		if not mon then return false, err end
		local w = getSub32(mon, "M", 1)
		local ivs = {}
		for i = 0, 5 do
			ivs[i + 1] = math.random(0, 31)
			w = setBits(w, i * 5, 5, ivs[i + 1]) -- keeps egg & ability bits
		end
		setSub32(mon, "M", 1, w)
		commit(mon)
		recalcStats(mon)
		return true, string.format("%s's IVs are now %s (HP/Atk/Def/Spe/SpA/SpD)", nameLead(mon), table.concat(ivs, "/"))
	end

	function Effects.randomizeEVs()
		local mon, err = getLead()
		if not mon then return false, err end
		local ev = { 0, 0, 0, 0, 0, 0 }
		if SETTINGS.randomEVsMode == "wild" then
			for i = 1, 6 do ev[i] = math.random(0, 255) end
		else
			for _ = 1, 510 do
				local i = math.random(1, 6)
				if ev[i] < 255 then ev[i] = ev[i] + 1 end
			end
		end
		applyEVs(mon, { hp = ev[1], atk = ev[2], def = ev[3], spe = ev[4], spa = ev[5], spd = ev[6] })
		recalcStats(mon)
		return true, string.format("%s's EVs are now %s (HP/Atk/Def/Spe/SpA/SpD)", nameLead(mon), table.concat(ev, "/"))
	end

	function Effects.resetEVs()
		local mon, err = getLead()
		if not mon then return false, err end
		applyEVs(mon, { hp = 0, atk = 0, def = 0, spe = 0, spa = 0, spd = 0 })
		recalcStats(mon)
		return true, nameLead(mon) .. " lost all its EVs"
	end

	function Effects.randomizeAbility()
		local mon, err = getLead()
		if not mon then return false, err end
		local bs = readBaseStats(species(mon))
		if not bs then return false, "couldn't read ROM data", "permanent" end
		local slot = bits(getSub32(mon, "M", 1), 31, 1)

		if SETTINGS.abilityMode == "rom" then
			local useSecond = slot == 1 and bs.ability2 ~= 0
			local current = useSecond and bs.ability2 or bs.ability1
			local new
			-- Only abilities that actually work in battle in this ROM
			local choices = {}
			for id = 1, generationCap("abilities") do
				if id ~= current and not SETTINGS.bannedAbilities[id] and not rulesetBansAbility(id, bs) and abilityWorks(id) then
					choices[#choices + 1] = id
				end
			end
			if #choices == 0 then return false, "no working abilities found in this ROM", "permanent" end
			new = choices[math.random(1, #choices)]
			local addr = bs.addr + G.abilityOff + (useSecond and G.abilitySize or 0)
			if G.abilitySize == 2 then pcall(write16, addr, new) else pcall(write8, addr, new) end
			local check = G.abilitySize == 2 and read16(addr) or read8(addr)
			if check ~= new then return false, "BizHawk didn't allow the ROM edit; try abilityMode = \"slot\"", "permanent" end
			-- The Tracker loads each species' abilities once at startup, so update its
			-- copy too, or it keeps showing the old ability
			pcall(function()
				local entry = PokemonData.Pokemon[species(mon)]
				if entry and entry.abilities then entry.abilities[useSecond and 2 or 1] = new end
			end)
			return true, string.format("%s's ability: %s -> %s", nameLead(mon), abilityName(current), abilityName(new))
		end

		if bs.ability2 == 0 or bs.ability2 == bs.ability1 then
			return false, nameLead(mon) .. " only has one possible ability"
		end
		local newSlot = 1 - slot
		if rulesetBansAbility(newSlot == 1 and bs.ability2 or bs.ability1, bs) then
			return false, nameLead(mon) .. "'s other ability is banned by the ruleset", "permanent"
		end
		setSubBits(mon, "M", 1, 31, 1, newSlot)
		commit(mon)
		local from = slot == 1 and bs.ability2 or bs.ability1
		local to = newSlot == 1 and bs.ability2 or bs.ability1
		return true, string.format("%s's ability: %s -> %s", nameLead(mon), abilityName(from), abilityName(to))
	end

	local STATUSES = {
		{ value = 0x03, name = "fell asleep" },  -- sleep for 3 turns
		{ value = 0x08, name = "was poisoned" },
		{ value = 0x10, name = "was burned" },
		{ value = 0x40, name = "was paralyzed" },
	}
	local function inflictStatus(status)
		local mon, err = getLead()
		if not mon then return false, err end
		if read16(mon.base + G.hpOff) == 0 then return false, "lead has fainted" end
		if read32(mon.base + G.statusOff) ~= 0 then return false, "lead already has a status" end
		write32(mon.base + G.statusOff, status.value)
		return true, nameLead(mon) .. " " .. status.name
	end
	function Effects.randomStatus() return inflictStatus(STATUSES[math.random(1, #STATUSES)]) end
	function Effects.poisonLead() return inflictStatus(STATUSES[2]) end

	function Effects.stealItem()
		local mon, err = getLead()
		if not mon then return false, err end
		if math.floor(getSub32(mon, "G", 0) / 65536) == 0 then return false, "lead isn't holding an item" end
		setSubBits(mon, "G", 0, 16, 16, 0)
		commit(mon)
		return true, nameLead(mon) .. "'s held item was stolen"
	end

	function Effects.teachStabMove()
		local mon, err = getLead()
		if not mon then return false, err end
		local bs = readBaseStats(species(mon))
		local moves = getMoves(mon)
		local id = randomMove(function(mid, m)
			return (m.type == bs.type1 or m.type == bs.type2)
				and m.power >= SETTINGS.stabMinPower and m.power <= SETTINGS.stabMaxPower
				and not knows(moves, mid)
		end, true)
		if not id then return false, "no new STAB move found for " .. nameLead(mon) end
		local replaced = teachMove(mon, id)
		return true, string.format("%s learned %s%s", nameLead(mon), moveName(id),
			replaced ~= 0 and (" (forgot " .. moveName(replaced) .. ")") or "")
	end

	function Effects.teachRandomMove()
		local mon, err = getLead()
		if not mon then return false, err end
		local moves = getMoves(mon)
		local id = randomMove(function(mid) return not knows(moves, mid) end, true)
		if not id then return false, "no new move found for " .. nameLead(mon) end
		local replaced = teachMove(mon, id)
		return true, string.format("%s learned %s%s", nameLead(mon), moveName(id),
			replaced ~= 0 and (" (forgot " .. moveName(replaced) .. ")") or "")
	end

	-- Adds one item to the bag's Items pocket (stacking with an existing stack),
	-- the same way the game does: quantities are XOR'd with the save's key
	-- (Ruby and Sapphire have no key and store them as they are).
	local function addBagItem(itemId)
		local pocket = saveBlock1() + G.bagItemsOff
		local key = G.encKeyOff and (read32(saveBlock2() + G.encKeyOff) % 65536) or 0
		local emptySlot
		for i = 0, G.bagItemsCount - 1 do
			local slot = pocket + i * 4
			local id = read16(slot)
			if id == itemId then
				local qty = bxor(read16(slot + 2), key)
				if qty >= 999 then return false, "already has 999" end
				write16(slot + 2, bxor(qty + 1, key))
				return true, qty + 1
			elseif id == 0 and not emptySlot then
				emptySlot = slot
			end
		end
		if not emptySlot then return false, "the Items pocket is full" end
		write16(emptySlot, itemId)
		write16(emptySlot + 2, bxor(1, key))
		return true, 1
	end

	local function pickHealingItem()
		local total = 0
		for _, it in ipairs(SETTINGS.healingItems) do total = total + math.max(0, it.weight or 0) end
		if total <= 0 then return nil end
		local roll = math.random() * total
		for _, it in ipairs(SETTINGS.healingItems) do
			roll = roll - math.max(0, it.weight or 0)
			if roll < 0 then return it end
		end
		return SETTINGS.healingItems[#SETTINGS.healingItems]
	end

	function Effects.giveHealingItem(amount)
		local given, reason = {}, nil
		for _ = 1, math.max(1, amount or 1) do
			local item = pickHealingItem()
			if not item then reason = "healingItems is empty" break end
			local ok, result = addBagItem(item.id)
			if ok then
				given[#given + 1] = string.format("%s (now x%d)", item.name, result)
			else
				reason = item.name .. ": " .. result
			end
		end
		if #given == 0 then
			return false, "no item added (" .. tostring(reason) .. ")", reason == "healingItems is empty" and "permanent" or nil
		end
		return true, "added " .. table.concat(given, ", ") .. " to the bag"
	end

	-- ======================= EXP. CANDIES ====================
	local EXP_CANDIES = {
		XS = { exp = 100, key = "xs" }, S = { exp = 800, key = "s" }, M = { exp = 3000, key = "m" },
		L = { exp = 10000, key = "l" }, XL = { exp = 30000, key = "xl" },
	}

	local function expCandyItemId(size)
		return G and G.expCandyItems and G.expCandyItems[EXP_CANDIES[size].key] or nil
	end
	-- true if this gift will be handed over as a bag item on this ROM
	local function expCandyAsItem(size)
		if SETTINGS.expCandyMode == "direct" then return false end
		if generationSetting("items") < 8 then return false end -- Exp. Candies are Gen 8 items
		return expCandyItemId(size) ~= nil
	end

	-- One candy's worth of Exp. Points straight to the lead, the way the item
	-- works: every level passed teaches its moves, then one evolution check.
	local function feedExpCandy(mon, amount, learned, skipped, evolved)
		local bs = readBaseStats(species(mon))
		if not bs or bs.growth > 5 then return nil, "couldn't read ROM data", "permanent" end
		local lv = level(mon)
		local maxExp = expForLevel(bs.growth, 100)
		local exp = getSub32(mon, "G", 1)
		if lv >= 100 or exp >= maxExp then return nil, "lead is already level 100" end
		local newExp = math.min(maxExp, exp + amount)
		local newLevel = lv
		while newLevel < 100 and expForLevel(bs.growth, newLevel + 1) <= newExp do newLevel = newLevel + 1 end

		setSub32(mon, "G", 1, newExp)
		commit(mon)
		if SETTINGS.levelUpFriendship then addCandyFriendship(mon) end
		if newLevel > lv then
			write8(mon.base + G.levelOff, newLevel)
			recalcStats(mon)
			if SETTINGS.levelUpLearnsMoves then
				for l = lv + 1, newLevel do learnLevelMoves(mon, l, learned, skipped) end
			end
			local target = SETTINGS.levelUpEvolves and evolutionTarget(mon)
			if target then
				evolveInto(mon, target)
				evolved[#evolved + 1] = speciesLabel(target)
				if SETTINGS.levelUpLearnsMoves then learnLevelMoves(mon, newLevel, learned, skipped) end
			end
		end
		return newExp - exp
	end

	local function giveExpCandy(size, amount)
		local candy = EXP_CANDIES[size]
		local count = math.max(1, amount or 1)
		local itemId = expCandyItemId(size)
		if SETTINGS.expCandyMode == "item" and not itemId then
			return false, "this ROM has no Exp. Candy " .. size .. " item", "permanent"
		end
		if SETTINGS.expCandyMode == "item" and generationSetting("items") < 8 then
			return false, "Exp. Candy items are above your generationLimit for items", "permanent"
		end

		if expCandyAsItem(size) then
			local given, total, reason = 0, 0, nil
			for _ = 1, count do
				local ok, result = addBagItem(itemId)
				if ok then given, total = given + 1, result else reason = result break end
			end
			if given == 0 then return false, "no Exp. Candy added (" .. tostring(reason) .. ")" end
			return true, string.format("added %dx Exp. Candy %s to the bag (now x%d)", given, size, total)
		end

		local mon, err = getLead()
		if not mon then return false, err end
		local startName, startLevel = nameLead(mon), level(mon)
		local learned, skipped, evolved = {}, {}, {}
		MoveChoice.justAsked = {}
		local gained, used = 0, 0
		for _ = 1, count do
			local got, reason, kind = feedExpCandy(mon, candy.exp, learned, skipped, evolved)
			if not got then
				if used == 0 then return false, reason, kind end
				break
			end
			gained, used = gained + got, used + 1
		end
		local msg = string.format("%s got %dx Exp. Candy %s (+%d Exp.)", startName, used, size, gained)
		if level(mon) > startLevel then msg = msg .. string.format(", Lv.%d -> Lv.%d", startLevel, level(mon)) end
		if #evolved > 0 then msg = msg .. ", evolved into " .. table.concat(evolved, ", then ") .. "!" end
		if #learned > 0 then msg = msg .. " Learned " .. table.concat(learned, ", ") .. "." end
		if #skipped > 0 then
			msg = msg .. " Didn't learn " .. table.concat(skipped, ", ") .. " (no empty move slot)."
		end
		if #MoveChoice.justAsked > 0 then
			msg = msg .. " Wants to learn " .. table.concat(MoveChoice.justAsked, ", ") .. ": choose in the pop-up."
		end
		return true, msg
	end

	function Effects.expCandyXS(amount) return giveExpCandy("XS", amount) end
	function Effects.expCandyS(amount) return giveExpCandy("S", amount) end
	function Effects.expCandyM(amount) return giveExpCandy("M", amount) end
	function Effects.expCandyL(amount) return giveExpCandy("L", amount) end
	function Effects.expCandyXL(amount) return giveExpCandy("XL", amount) end
	local EXP_CANDY_EFFECTS = { expCandyXS = "XS", expCandyS = "S", expCandyM = "M", expCandyL = "L", expCandyXL = "XL" }

	-- Releases the lead and builds a brand-new random Pokemon in its slot:
	-- random species, personality (nature/gender), IVs, EVs, ability and moves.
	-- Writes a complete, valid Pokemon into a party slot (yours or the enemy's).
	-- spec: species, level, pid, otid, moves{4}, ivs{6}, evs{6}, abilityBit,
	--       metLocation, origins, optional language and otName (byte table).
	local function writeNewMon(base, spec)
		local bs = readBaseStats(spec.species)
		local mon = monView(base, spec.pid, spec.otid)
		write32(base, spec.pid)
		write32(base + 4, spec.otid)

		-- Nickname = species name
		local nameAddr = speciesNameAddr(spec.species)
		for i = 0, G.nameLen - 1 do write8(base + 0x08 + i, read8(nameAddr + i)) end
		if spec.language then write8(base + G.langOff, spec.language) end
		write8(base + G.flagsByteOff, 0x02) -- has species, not an egg
		if spec.otName then
			for i = 0, 6 do write8(base + G.langOff + 2 + i, spec.otName[i + 1] or 0xFF) end
		end
		write8(base + G.markingsOff, 0)
		write16(base + G.checksumOff + 2, 0)

		local m, pp = spec.moves, {}
		for i = 1, 4 do pp[i] = m[i] ~= 0 and readMove(m[i]).pp or 0 end
		local ivWord = 0
		for i = 0, 5 do ivWord = ivWord + spec.ivs[i + 1] * (2 ^ (i * 5)) end
		ivWord = math.floor(ivWord + (spec.abilityBit or 0) * (2 ^ 31))
		local ev = spec.evs

		setSub32(mon, "G", 0, spec.species)                       -- species, no item
		setSub32(mon, "G", 1, expForLevel(bs.growth, spec.level))
		setSub32(mon, "G", 2, bs.friendship * 256)                -- no PP Ups, base friendship
		setSub32(mon, "A", 0, m[1] + m[2] * 65536)
		setSub32(mon, "A", 1, m[3] + m[4] * 65536)
		setSub32(mon, "A", 2, pp[1] + pp[2] * 256 + pp[3] * 65536 + pp[4] * 16777216)
		setSub32(mon, "E", 0, ev[1] + ev[2] * 256 + ev[3] * 65536 + ev[4] * 16777216)
		setSub32(mon, "E", 1, ev[5] + ev[6] * 256)
		setSub32(mon, "E", 2, 0)
		setSub32(mon, "M", 0, (spec.metLocation or 0) * 256 + (spec.origins or 0) * 65536)
		setSub32(mon, "M", 1, ivWord)
		setSub32(mon, "M", 2, 0x80000000) -- obedience flag (needed for Mew/Deoxys)
		commit(mon)

		write32(base + G.statusOff, 0)
		write8(base + G.levelOff, spec.level)
		write8(base + G.levelOff + 1, 0xFF)  -- no mail
		write16(base + G.hpOff, 0)
		write16(base + G.maxHpOff, 0)        -- 0/0 HP so recalcStats fills HP to max
		recalcStats(mon)
		return mon
	end

	local function fourRandomMoves(forPlayer)
		local moves = {}
		while #moves < 4 do
			local id = randomMove(function(mid) return not knows(moves, mid) end, forPlayer)
			if not id then break end
			moves[#moves + 1] = id
		end
		while #moves < 4 do moves[#moves + 1] = 0 end
		return moves
	end

	local function randomEVSpread()
		local ev = { 0, 0, 0, 0, 0, 0 }
		for _ = 1, 510 do
			local i = math.random(1, 6)
			if ev[i] < 255 then ev[i] = ev[i] + 1 end
		end
		return ev
	end

	-- Releases the lead and builds a brand-new random Pokemon in its slot:
	-- random species, personality (nature/gender), IVs, EVs, ability and moves.
	function Effects.replaceLead()
		local old, err = getLead()
		if not old then return false, err end
		local sp, spStats = randomSpecies(true)
		if not sp then return false, "couldn't pick a random Pokemon" end
		local base = old.base
		local oldName = nameLead(old)

		-- Back up the released Pokemon's raw bytes, just in case
		if backupFilePath then
			local bytes = {}
			for i = 0, G.monSize - 1 do bytes[#bytes + 1] = string.format("%02X", read8(base + i)) end
			local f = io.open(backupFilePath, "a")
			if f then
				f:write(string.format("%s\t%s\t%s\n", os.date("%Y-%m-%d %H:%M:%S"), oldName, table.concat(bytes)))
				f:close()
			end
		end

		local oldMisc0 = getSub32(old, "M", 0)
		local oldOrigins = math.floor(oldMisc0 / 65536)
		local lv = SETTINGS.replaceLevel
		local ivs = {}
		for i = 1, 6 do ivs[i] = math.random(0, 31) end
		local moves = fourRandomMoves(true)
		-- Prefer an ability the ruleset allows, if the species has one
		local abilityBit = math.random(0, 1)
		if spStats.ability2 and spStats.ability2 ~= 0 then
			local chosen = abilityBit == 1 and spStats.ability2 or spStats.ability1
			local other = abilityBit == 1 and spStats.ability1 or spStats.ability2
			if rulesetBansAbility(chosen, spStats) and not rulesetBansAbility(other, spStats) then abilityBit = 1 - abilityBit end
		end
		-- Same trainer ID and OT name as before, so it obeys you
		writeNewMon(base, {
			species = sp, level = lv, pid = rand32(), otid = old.otid,
			moves = moves, ivs = ivs, evs = randomEVSpread(), abilityBit = abilityBit,
			metLocation = bits(oldMisc0, 8, 8),
			origins = oldOrigins - (oldOrigins % 128) + math.min(lv, 127), -- met level
		})

		local moveNames = {}
		for i = 1, 4 do moveNames[i] = moveName(moves[i]) end
		return true, string.format("%s was released! Say hi to Lv.%d %s (%s)",
			oldName, lv, speciesLabel(sp), table.concat(moveNames, ", "))
	end

	-- ======================= GYM LEADER AMBUSH ==============
	-- A random Gym Leader of the game's region walks up and battles you with 6 Pokemon of
	-- their type (by the ROM's current types, so randomized types count).
	-- It works like any trainer fight: no badge, and the leader's "defeated"
	-- flag is put back afterwards, so their real Gym battle still happens.
	--
	-- How: a tiny event script (kept in the script engine's unused call
	-- stack) is started on the game's own script engine. It shows a message and
	-- runs "trainerbattle_no_intro" with that leader. A per-frame watcher swaps
	-- in the custom team right after the game builds the leader's normal team
	-- and before the battle reads it.
	local GYM_LEADERS = {
		{ id = 414, name = "BROCK",     types = { 5, 4 } }, -- Rock / Ground
		{ id = 415, name = "MISTY",     types = { 11 } },   -- Water
		{ id = 416, name = "LT. SURGE", types = { 13 } },   -- Electric
		{ id = 417, name = "ERIKA",     types = { 12 } },   -- Grass
		{ id = 418, name = "KOGA",      types = { 3 } },    -- Poison
		{ id = 420, name = "SABRINA",   types = { 14 } },   -- Psychic
		{ id = 419, name = "BLAINE",    types = { 10 } },   -- Fire
		{ id = 350, name = "GIOVANNI",  types = { 4 } },    -- Ground
	}
	-- Emerald, Ruby and Sapphire use the same trainer numbers. The eighth leader
	-- is Juan in Emerald and Wallace in Ruby/Sapphire; the name shown comes from
	-- the ROM. Tate & Liza fight a double battle, so they only show up when you
	-- have two Pokemon able to fight.
	local HOENN_GYM_LEADERS = {
		{ id = 265, name = "ROXANNE",   types = { 5 } },    -- Rock
		{ id = 266, name = "BRAWLY",    types = { 1 } },    -- Fighting
		{ id = 267, name = "WATTSON",   types = { 13 } },   -- Electric
		{ id = 268, name = "FLANNERY",  types = { 10 } },   -- Fire
		{ id = 269, name = "NORMAN",    types = { 0 } },    -- Normal
		{ id = 270, name = "WINONA",    types = { 2 } },    -- Flying
		{ id = 271, name = "TATE&LIZA", types = { 14 }, double = true }, -- Psychic
		{ id = 272, name = "JUAN", nameRS = "WALLACE", types = { 11 } }, -- Water
	}
	local GYM_EVENT_NAME = "TikTokGiftsGymLeader"
	local gym = { active = false }

	local function encodeText(str)
		local map = { [" "] = 0x00, ["!"] = 0xAB, ["?"] = 0xAC, ["."] = 0xAD, ["-"] = 0xAE,
			["'"] = 0xB4, [","] = 0xB8, ["\n"] = 0xFE }
		local out = {}
		for i = 1, #str do
			local c = str:sub(i, i)
			local b = c:byte()
			if b >= 65 and b <= 90 then out[#out + 1] = 0xBB + b - 65
			elseif b >= 97 and b <= 122 then out[#out + 1] = 0xD5 + b - 97
			elseif b >= 48 and b <= 57 then out[#out + 1] = 0xA1 + b - 48
			elseif map[c] then out[#out + 1] = map[c] end
		end
		out[#out + 1] = 0xFF
		return out
	end

	-- ======================= WORKING ABILITIES =============
	-- Which abilities actually work in this ROM. Nat. Dex 1.2.x only implements
	-- the first 77; the rest point at the "Not implemented yet." placeholder.
	-- A ROM hack that adds real abilities (with real descriptions) is picked up
	-- automatically.
	local workingAbilities = nil
	function abilityWorks(id)
		if not (G and G.natdex and G.abilityDescs and G.abilityDescs > 0) then return true end
		if not workingAbilities then
			workingAbilities = {}
			for i = 1, G.maxAbility do
				local text = decodeText(read32(G.abilityDescs + i * 4), 24):lower()
				workingAbilities[i] = text ~= "" and not text:find("implemented", 1, true)
			end
		end
		return workingAbilities[id] == true
	end

	-- Any 0xFF byte in the ROM is an empty string (the ROM itself is never changed)
	local romEmptyString = nil
	local function findRomEmptyString()
		if romEmptyString then return romEmptyString end
		for a = 0x08000200, 0x08001000 do
			if read8(a) == 0xFF then romEmptyString = a return a end
		end
		return nil
	end

	local function u16le(v) return v % 256, math.floor(v / 256) % 256 end
	local function u32le(v)
		return v % 256, math.floor(v / 256) % 256, math.floor(v / 65536) % 256, math.floor(v / 16777216) % 256
	end

	-- The game's global script context, its status byte and the field-controls
	-- lock. Known for the original games; found by its shape for Nat. Dex.
	local function looksLikeContext(ctx)
		local t, e = read32(ctx + 0x5C), read32(ctx + 0x60)
		if not (t >= 0x08000000 and t < 0x0A000000 and e > t and (e - t) % 4 == 0 and e - t <= 0x1000) then return false end
		-- The second context right behind it uses the same command table, or
		-- is still blank if the game hasn't needed it yet
		local t2, e2 = read32(ctx + 0x78 + 0x5C), read32(ctx + 0x78 + 0x60)
		return (t2 == t and e2 == e) or (t2 == 0 and e2 == 0)
	end
	local function findScriptContext()
		if G.scriptCtx and looksLikeContext(G.scriptCtx) then
			return { ctx = G.scriptCtx, status = G.scriptCtx - 8, lock = G.scriptCtx + 0x78 + 0x74 }
		end
		local ok, data = pcall(memory.readbyterange, 0, 0x8000, "IWRAM")
		if not ok or type(data) ~= "table" then return nil end
		local first = (data[0] ~= nil) and 0 or 1
		local function u32(off) return (data[off + first] or 0) + (data[off + first + 1] or 0) * 256
			+ (data[off + first + 2] or 0) * 65536 + (data[off + first + 3] or 0) * 16777216 end
		for off = 8, 0x8000 - 0x78 - 0x68, 4 do
			local t, e = u32(off + 0x5C), u32(off + 0x60)
			if t >= 0x08000000 and t < 0x0A000000 and e > t and (e - t) % 4 == 0 and e - t <= 0x1000
				and u32(off + 0x78 + 0x5C) == t and u32(off + 0x78 + 0x60) == e then
				G.scriptCtx = 0x03000000 + off
				return { ctx = G.scriptCtx, status = G.scriptCtx - 8, lock = G.scriptCtx + 0x78 + 0x74 }
			end
		end
		return nil
	end

	-- The trainer's class and name straight from the ROM (e.g. "Gym Leader" +
	-- "Koga" on Nat. Dex, "LEADER" + "KOGA" on the original), so the intro
	-- message matches what the battle itself shows.
	local function readGameText(addr, maxLen)
		local bytes = {}
		for i = 0, maxLen - 1 do
			local c = read8(addr + i)
			if c == 0xFF then break end
			bytes[#bytes + 1] = c
		end
		return bytes
	end
	local function trainerTitle(trainerId)
		if not (G.trainers and G.trainers > 0 and G.trainerSize and G.trainerSize > 0) then return nil end
		local t = G.trainers + trainerId * G.trainerSize
		local name = readGameText(t + G.trainerNameOff, G.trainerNameLen)
		local class = readGameText(G.classNames + read8(t + 1) * G.classNameSize, G.classNameSize)
		if #name == 0 or #name >= G.trainerNameLen or #class >= G.classNameSize then return nil end
		local bytes = {}
		for _, c in ipairs(class) do bytes[#bytes + 1] = c end
		if #class > 0 then bytes[#bytes + 1] = 0x00 end -- space
		for _, c in ipairs(name) do bytes[#bytes + 1] = c end
		return bytes, decodeText(t + G.trainerNameOff, G.trainerNameLen),
			(#class > 0 and decodeText(G.classNames + read8(t + 1) * G.classNameSize, G.classNameSize) .. " " or "")
	end

	local function isFlagSet(flag)
		return bits(read8(sb1() + G.flagsOff + math.floor(flag / 8)), flag % 8, 1) == 1
	end

	local function highestPartyLevel()
		local best = 1
		for slot = 1, 6 do
			local m = readMon(slot)
			if m and not isEgg(m) then best = math.max(best, level(m)) end
		end
		return best
	end

	local function themedSpeciesPool(types)
		local pool = {}
		for id = 1, generationCap("pokemon") do
			if id < 252 or id > 276 then
				local bs = readBaseStats(id)
				if bs and bs.hp > 0 and bs.growth <= 5 then
					for _, t in ipairs(types) do
						if bs.type1 == t or bs.type2 == t then pool[#pool + 1] = id break end
					end
				end
			end
		end
		-- Nat. Dex: Megas and other forms of the leader's type
		for _, id in ipairs(formSpecies()) do
			local bs = readBaseStats(id)
			for _, t in ipairs(types) do
				if bs.type1 == t or bs.type2 == t then pool[#pool + 1] = id break end
			end
		end
		return pool
	end

	local function stopGymWatch()
		gym.active = false
		if event and event.unregisterbyname then pcall(event.unregisterbyname, GYM_EVENT_NAME) end
	end

	-- Every frame until the battle starts: once the game has built the leader's
	-- normal team (enemy slot 1 no longer blank), replace it with ours.
	local function watchGym()
		if not gym.active then return end
		gym.frames = gym.frames + 1
		if read16(G.opponentA) == gym.leader.id and read32(G.enemyParty) ~= 0 then
			-- The game builds the leader's normal team over several frames (Nat. Dex
			-- especially), then copies it into the battle ~40 frames later. Swap
			-- only once the team is complete (valid data) and unchanged for 3
			-- frames, so the game can't write over ours.
			local base = G.enemyParty
			local first = monView(base, read32(base), read32(base + 4))
			local complete = computeChecksum(first) == read16(base + G.checksumOff) and read8(base + G.levelOff) > 0
			local sig = 0
			for off = 0, 6 * G.monSize - 4, 4 do sig = (sig * 31 + read32(base + off)) % 4294967296 end
			if complete and sig == gym.lastSig then gym.stable = (gym.stable or 0) + 1 else gym.stable = 0 end
			gym.lastSig = sig
			if gym.stable >= 3 then
				local copied = G.battleMons and G.battleMons > 0
					and read32(G.battleMons + G.battleMonSize + G.bmPidOff) == read32(base)
				for i, spec in ipairs(gym.team) do
					writeNewMon(base + (i - 1) * G.monSize, spec)
				end
				stopGymWatch()
				if copied then
					log("Warning: the battle had already loaded the leader's normal team, so their first Pokemon may be the original one.")
				else
					log(gym.leader.display .. "'s team is ready. Good luck!")
				end
			end
			return
		end
		local status, ptr = read8(gym.sc.status), read32(gym.sc.ctx + 8)
		if not gym.ran and ptr ~= gym.scriptAddr then
			gym.ran = true
		end
		if status == 2 and gym.frames > 2 then
			-- The script finished (or was stopped) without a battle starting
			stopGymWatch()
			log(string.format("The Gym Leader battle didn't start. Diagnostics: script %s, stopped at byte %d of %d, frame %d. Please send this line to get it fixed.",
				gym.ran and "ran" or "never ran", ptr - gym.scriptAddr, gym.scriptLen, gym.frames))
		elseif gym.frames > 60 * 60 * 5 then
			stopGymWatch()
			log(string.format("Gave up waiting for the Gym Leader battle after 5 minutes (script at byte %d, status %d).",
				ptr - gym.scriptAddr, status))
		end
	end

	function Effects.spawnGymLeader()
		if gym.active then return false, "a Gym Leader is already on the way" end
		if not (event and event.onframeend) then return false, "needs BizHawk's per-frame Lua events", "permanent" end
		if not (G.enemyParty and G.enemyParty > 0 and G.opponentA and G.opponentA > 0) then
			return false, "battle addresses for this game aren't known", "permanent"
		end
		local sc = findScriptContext()
		if not sc then return false, "couldn't find the game's script engine", "permanent" end
		-- Only start when you're free to walk around (no menu, cutscene or text box)
		if read8(sc.status) ~= 2 or read8(sc.lock) ~= 0 then
			return false, "waiting until you're free to move (not in a menu, text box or cutscene)"
		end

		local able = 0
		for slot = 1, 6 do
			local m = readMon(slot)
			if m and not isEgg(m) and read16(m.base + G.hpOff) > 0 then able = able + 1 end
		end
		local leaders = {}
		for _, l in ipairs(G.hoenn and HOENN_GYM_LEADERS or GYM_LEADERS) do
			if not l.double or able >= 2 then leaders[#leaders + 1] = l end
		end
		local leader = leaders[math.random(1, #leaders)]
		if leader.nameRS and G.originGame ~= 3 then -- Ruby/Sapphire
			leader = { id = leader.id, name = leader.nameRS, types = leader.types }
		end
		local pool = themedSpeciesPool(leader.types)
		if #pool == 0 then return false, "no Pokemon of " .. leader.name .. "'s type were found", "permanent" end
		local lv = math.max(1, math.min(100, highestPartyLevel() + (SETTINGS.gymLeaderLevelBonus or 0)))
		local evAmount = SETTINGS.gymLeaderEVs == "legal" and nil or 252
		local otName = encodeText(leader.name:gsub("[^%a]", ""):sub(1, 7))
		local team, names, used = {}, {}, {}
		for i = 1, 6 do
			local sp
			for _ = 1, 20 do -- prefer 6 different species
				sp = pool[math.random(1, #pool)]
				if not used[sp] then break end
			end
			used[sp] = true
			local evs = evAmount and { evAmount, evAmount, evAmount, evAmount, evAmount, evAmount } or randomEVSpread()
			team[i] = {
				species = sp, level = lv, pid = rand32(), otid = rand32(),
				moves = fourRandomMoves(), ivs = { 31, 31, 31, 31, 31, 31 }, evs = evs,
				abilityBit = math.random(0, 1), language = 2, otName = otName,
				origins = math.min(lv, 127) + (G.originGame or 4) * 128 + 4 * 2048, -- met level, game, Poke Ball
			}
			names[i] = speciesLabel(sp)
		end

		-- The event script lives in the upper part of the script engine's own call
		-- stack (stack[4..19], 64 bytes). This script and the battle scripts it
		-- runs never use "call", so nothing overwrites it, and it survives the
		-- battle (unlike most RAM, which the battle reuses).
		local ctx = sc.ctx
		local SCRIPT_LEN = 31
		local textAddr = ctx + 0x0C                    -- stack[0..]: only needed until the message is shown
		local scriptAddr = ctx + 0x0C + 0x50 - SCRIPT_LEN -- top of stack[]: survives the battle
		local wasDefeated = isFlagSet(0x500 + leader.id) -- TRAINER_FLAGS_START + id
		local idLo, idHi = u16le(leader.id)
		local loseText = findRomEmptyString()
		if not loseText then return false, "couldn't find an empty text in the ROM", "permanent" end
		local l1, l2, l3, l4 = u32le(loseText)
		local i1, i2, i3, i4 = u32le(textAddr)
		local script = {
			0x16, 0x0F, 0x80, 0x00, 0x00,       -- setvar VAR_LAST_TALKED, 0 (no NPC to animate)
			0x69,                               -- lockall
			0x67, i1, i2, i3, i4,               -- message
			0x66,                               -- waitmessage
			0x28, 90, 0,                        -- delay 90 frames (~1.5s, no button press needed)
			0x68,                               -- closemessage
			0x5C, 0x03, idLo, idHi, 0x00, 0x00, l1, l2, l3, l4, -- trainerbattle_no_intro leader, defeat text
			wasDefeated and 0x61 or 0x62, idLo, idHi, -- settrainerflag/cleartrainerflag: put it back as it was
			0x6B,                               -- releaseall
			0x02,                               -- end
		}
		assert(#script == SCRIPT_LEN)
		-- Intro message, e.g. "Gym Leader Koga\nwants to battle!", using the
		-- ROM's own class and name so it matches the battle exactly
		local title, romName, romClass = trainerTitle(leader.id)
		local intro
		if title then
			intro = title
			for _, c in ipairs(encodeText("\nwants to battle!")) do intro[#intro + 1] = c end
		end
		if not intro or #intro > 0x50 - SCRIPT_LEN then intro = encodeText(leader.name .. "\nwants to battle!") end
		leader = { id = leader.id, name = romName and romName ~= "" and romName or leader.name, types = leader.types,
			display = (romClass or "Gym Leader ") .. (romName and romName ~= "" and romName or leader.name) }

		-- Blank enemy slot 1 so the watcher can tell when the game builds the team
		write32(G.enemyParty, 0)
		write32(G.enemyParty + 4, 0)

		-- Start the script, the same way ScriptContext_SetupScript does
		write8(ctx, 0)                -- stackDepth
		write8(ctx + 1, 1)            -- mode = bytecode
		write8(ctx + 2, 0)
		write32(ctx + 4, 0)           -- nativePtr
		for i = 0, 19 do write32(ctx + 0x0C + i * 4, 0) end
		for i = 0, 3 do write32(ctx + 0x64 + i * 4, 0) end
		for i, b in ipairs(script) do write8(scriptAddr + i - 1, b) end
		for i, b in ipairs(intro) do write8(textAddr + i - 1, b) end
		write32(ctx + 8, scriptAddr)  -- scriptPtr
		write8(sc.lock, 1)            -- lock the player's controls
		write8(sc.status, 0)          -- CONTEXT_RUNNING: the game runs it next frame

		gym.sc, gym.scriptAddr, gym.scriptLen, gym.ran = sc, scriptAddr, SCRIPT_LEN, false
		gym.active, gym.frames, gym.leader, gym.team = true, 0, leader, team
		pcall(event.unregisterbyname, GYM_EVENT_NAME)
		event.onframeend(watchGym, GYM_EVENT_NAME)
		return true, string.format("%s appears! Lv.%d team: %s", leader.display, lv, table.concat(names, ", "))
	end

	-- Effects that work even if the ROM tables couldn't be read
	local ROM_FREE_EFFECTS = { healParty = true, randomStatus = true, poisonLead = true, stealItem = true, eliteFourWarp = true, giveHealingItem = true }

	-- ======================= GIFT INTAKE ====================
	local function ruleFor(giftName, coins)
		local rule = GIFT_RULES.byName[string.lower(giftName)]
		if rule then return rule end
		rule = GIFT_RULES.byExactCoins and GIFT_RULES.byExactCoins[coins]
		if rule then return rule end
		for _, tier in ipairs(GIFT_RULES.byCoins) do
			if coins >= tier.minCoins then return tier end
		end
		return nil
	end

	local function enqueue(entry)
		if #queue >= SETTINGS.maxQueueSize then
			log("Queue full, dropping gift from " .. entry.user)
			return
		end
		table.insert(queue, entry)
	end

	-- Line format written by the bridge: user<TAB>giftName<TAB>coinsEach<TAB>count
	local function handleLine(line)
		if line:match("^!retry") then retryHeldNow() return end
		local user, giftName, coins, count = line:match("^([^\t]*)\t([^\t]*)\t(%d+)\t(%d+)")
		if not user then return end
		coins, count = tonumber(coins), tonumber(count)
		local rule = ruleFor(giftName, coins)
		if not rule or rule.effect == "none" then return end
		if not Effects[rule.effect] then
			log("Unknown effect in GIFT_RULES: " .. tostring(rule.effect))
			return
		end

		if rule.effect == "levelUp" or rule.effect == "lowerLevel" then
			local levels = math.min(SETTINGS.maxLevelsPerGift, (rule.amount or 1) * count)
			enqueue({ user = user, gift = giftName, effect = rule.effect, amount = levels })
		elseif rule.effect == "giveHealingItem" or EXP_CANDY_EFFECTS[rule.effect] then
			-- one item per gift, so a 5x streak gives 5 items
			local items = math.min(SETTINGS.maxItemsPerGift, (rule.amount or 1) * count)
			enqueue({ user = user, gift = giftName, effect = rule.effect, amount = items })
		else
			for _ = 1, math.min(count, SETTINGS.repeatOtherEffects) do
				enqueue({ user = user, gift = giftName, effect = rule.effect, amount = rule.amount })
			end
		end
		log(string.format("Queued: %s sent %dx %s -> %s", user, count, giftName, rule.effect))
	end

	local function pollGiftsFile()
		if not giftsFilePath then return end
		local f = io.open(giftsFilePath, "r")
		if not f then return end
		local size = f:seek("end")
		if size < filePos then filePos = 0 end -- file was reset
		if size == filePos then f:close() return end
		f:seek("set", filePos)
		local chunk = f:read("*a") or ""
		f:close()

		-- Only consume complete lines; a half-written line waits for the next poll
		local lastNewline = chunk:match(".*()\n")
		if not lastNewline then return end
		filePos = filePos + lastNewline
		for line in chunk:sub(1, lastNewline):gmatch("([^\r\n]+)") do
			handleLine(line)
		end
	end

	-- Effects that can safely run while a battle is going on
	local BATTLE_SAFE = { healParty = true, giveHealingItem = true }

	local function holdEntry(entry, reason)
		local now = os.time()
		entry.attempts = (entry.attempts or 0) + 1
		entry.heldSince = entry.heldSince or now
		entry.retryAt = now + SETTINGS.retryEverySeconds
		entry.reason = reason
		table.insert(queue, entry)
		if entry.attempts == 1 then -- say it once, not on every retry
			log(string.format("Holding %s's %s: %s. Retrying every %ds%s.", entry.user, entry.gift, reason,
				SETTINGS.retryEverySeconds, SETTINGS.retryHotkey and (" (press " .. SETTINGS.retryHotkey .. " in BizHawk to retry now)") or ""))
		end
	end

	local function runEntry(entry)
		if not G then
			log(string.format("Skipped %s's %s: this game isn't supported", entry.user, entry.gift))
			return
		end
		if not G.romOk and not ROM_FREE_EFFECTS[entry.effect] then
			log(string.format("Skipped %s's %s: %s needs ROM data that couldn't be read", entry.user, entry.gift, entry.effect))
			return
		end
		local ok, success, msg, kind = pcall(Effects[entry.effect], entry.amount)
		lastEffectTime = os.time()
		if not ok then
			-- Unexpected error: retry a few times in case the game was mid-update
			if (entry.attempts or 0) < 3 then holdEntry(entry, "error: " .. tostring(success))
			else log("Gave up on " .. entry.effect .. " after errors: " .. tostring(success)) end
		elseif success then
			log(string.format("%s's %s: %s%s", entry.user, entry.gift, msg, entry.attempts and " (was held)" or ""))
			if Program and Program.redraw then pcall(Program.redraw, true) end
		elseif kind == "permanent" then
			log(string.format("Skipped %s's %s: %s", entry.user, entry.gift, msg))
		else
			holdEntry(entry, msg)
		end
	end

	-- Retry every held gift right away (hotkey or a "!retry" line from the bridge)
	function retryHeldNow()
		local held = 0
		for _, entry in ipairs(queue) do
			if entry.retryAt then entry.retryAt = 0 held = held + 1 end
		end
		log(held > 0 and string.format("Retrying %d held gift(s) now.", held) or "No held gifts to retry.")
		lastEffectTime = 0
	end

	local function processQueue()
		if #queue == 0 then return end
		if #MoveChoice.pending > 0 then return end -- a move choice is waiting: nothing else happens first
		local now = os.time()

		-- Drop held gifts that have waited too long
		if SETTINGS.retryForMinutes and SETTINGS.retryForMinutes > 0 then
			for i = #queue, 1, -1 do
				local e = queue[i]
				if e.heldSince and now - e.heldSince > SETTINGS.retryForMinutes * 60 then
					table.remove(queue, i)
					log(string.format("Gave up on %s's %s after %d min: %s", e.user, e.gift, SETTINGS.retryForMinutes, e.reason or "?"))
				end
			end
		end
		if now - lastEffectTime < SETTINGS.secondsBetweenEffects then return end

		currentlyInBattle = inBattle()
		for i, entry in ipairs(queue) do
			if (entry.retryAt or 0) <= now then
				local candySize = EXP_CANDY_EFFECTS[entry.effect]
				if not currentlyInBattle or BATTLE_SAFE[entry.effect] or (candySize and expCandyAsItem(candySize)) then
					table.remove(queue, i)
					runEntry(entry)
					MoveChoice.showNext() -- if the effect left a move to choose, ask right away
					return
				elseif not entry.battleWaitLogged then
					entry.battleWaitLogged = true
					log(string.format("%s's %s will apply when the battle ends.", entry.user, entry.gift))
				end
			end
		end
	end

	-- Hotkey: checked every frame so a quick tap isn't missed
	local HOTKEY_EVENT_NAME = "TikTokGiftsRetryHotkey"
	local hotkeyWasDown = false
	local function checkHotkey()
		if not SETTINGS.retryHotkey or not input or not input.get then return end
		local ok, keys = pcall(input.get)
		local down = ok and keys and keys[SETTINGS.retryHotkey] == true
		if down and not hotkeyWasDown then retryHeldNow() end
		hotkeyWasDown = down
	end

	-- ======================= UPDATES ========================
	-- "Check for Updates" in the Tracker's extension screen compares this
	-- version with the latest release on GitHub.
	function self.checkForUpdates()
		local versionResponsePattern = '"tag_name":%s+"%w+(%d+%.%d+%.%d+)"' -- matches "1.7.0" in "tag_name": "v1.7.0"
		local versionCheckUrl = string.format("https://api.github.com/repos/%s/releases/latest", self.github or "")
		local downloadUrl = string.format("%s/releases/latest", self.url or "")
		local compareFunc = function(a, b) return a ~= b and not Utils.isNewerVersion(a, b) end
		local isUpdateAvailable = Utils.checkForVersionUpdate(versionCheckUrl, self.version, versionResponsePattern, compareFunc)
		return isUpdateAvailable, downloadUrl
	end

	-- Updating replaces TikTokGifts.lua, which is also where your gift rules
	-- live. The current file is saved first so your rules can be copied back.
	function self.downloadAndInstallUpdate()
		local dir = getExtensionDir()
		local backupName = "TikTokGifts/TikTokGifts-before-update.lua.txt"
		local src = io.open(dir .. "TikTokGifts.lua", "rb")
		if src then
			local contents = src:read("*a")
			src:close()
			local dst = io.open(dir .. backupName, "wb")
			if dst then
				dst:write(contents)
				dst:close()
				log("Saved your current file (with your gift rules) as extensions/" .. backupName)
			end
		end
		local success = TrackerAPI.updateExtension("TikTokGifts")
		if success then
			log("Updated. If you had changed GIFT_RULES or SETTINGS, copy them back from " .. backupName)
		end
		return success
	end

	-- ======================= OPTIONS WINDOW =================
	-- Tracker > Extensions > TikTok Gifts > Options. Everything set there is
	-- saved to TikTokGifts/config.txt, which an update never replaces. The
	-- values in this file are only the defaults.
	local Options = { configPath = nil, customRules = false }

	-- Every setting the window can change. kind: "bool", "choice", "int" or "bst".
	Options.FIELDS = {
		{ key = "ruleset", kind = "choice", label = "Ruleset", width = 140,
			choices = { "None", "Standard", "Ultimate", "Kaizo", "Super Kaizo", "Survival",
				"Nat. Dex Standard", "Nat. Dex Ultimate", "Nat. Dex Kaizo", "Nat. Dex Super Kaizo", "Nat. Dex Survival" } },
		{ key = "rulesetMaxBST", kind = "bst", label = "BST limit (auto or a number)" },
		{ key = "rulesetNewerMoves", kind = "bool", label = "Also skip newer (Gen 7-9) healing, draining, pivot moves" },
		{ key = "generationLimit.pokemon", kind = "int", min = 1, max = 9, label = "Pokemon up to Gen" },
		{ key = "generationLimit.moves", kind = "int", min = 1, max = 9, label = "Moves up to Gen" },
		{ key = "generationLimit.abilities", kind = "int", min = 1, max = 9, label = "Abilities up to Gen" },
		{ key = "generationLimit.items", kind = "int", min = 1, max = 9, label = "Items up to Gen" },
		{ key = "levelUpEvolves", kind = "bool", label = "Level-ups can evolve the Pokemon" },
		{ key = "levelUpLearnsMoves", kind = "bool", label = "Level-ups teach moves" },
		{ key = "levelUpFullMoves", kind = "choice", label = "New move with 4 moves known", choices = { "ask", "skip" } },
		{ key = "levelUpFriendship", kind = "bool", label = "Level-ups raise friendship" },
		{ key = "expCandyMode", kind = "choice", label = "Exp. Candy gifts", choices = { "auto", "direct", "item" } },
		{ key = "maxLevelsPerGift", kind = "int", min = 1, max = 99, label = "Most levels from one gift/streak" },
		{ key = "maxItemsPerGift", kind = "int", min = 1, max = 99, label = "Most items from one gift/streak" },
		{ key = "repeatOtherEffects", kind = "int", min = 1, max = 99, label = "Other effects per streak" },
		{ key = "secondsBetweenEffects", kind = "int", min = 0, max = 60, label = "Seconds between effects" },
		{ key = "retryEverySeconds", kind = "int", min = 1, max = 600, label = "Retry held gifts every (seconds)" },
		{ key = "retryForMinutes", kind = "int", min = 0, max = 600, label = "Drop held gifts after (minutes, 0 = never)" },
		{ key = "skipOldGiftsOnStartup", kind = "bool", label = "Ignore gifts sent before the extension started" },
		{ key = "abilityMode", kind = "choice", label = "randomizeAbility mode", choices = { "rom", "slot" } },
		{ key = "maxEVsMode", kind = "choice", label = "maxEVs mode", choices = { "all", "legal" } },
		{ key = "randomEVsMode", kind = "choice", label = "randomizeEVs mode", choices = { "wild", "legal" } },
		{ key = "replaceLevel", kind = "int", min = 1, max = 100, label = "replaceLead: level of the new Pokemon" },
		{ key = "stabMinPower", kind = "int", min = 0, max = 255, label = "teachStabMove: lowest move power" },
		{ key = "stabMaxPower", kind = "int", min = 1, max = 255, label = "teachStabMove: highest move power" },
		{ key = "eliteFourBoostLead", kind = "bool", label = "Elite Four warp boosts your lead" },
		{ key = "gymLeaderLevelBonus", kind = "int", min = -50, max = 50, label = "Gym Leader: levels above your best" },
		{ key = "gymLeaderEVs", kind = "choice", label = "Gym Leader EVs", choices = { "all", "legal" } },
		{ key = "alternateForms", kind = "bool", label = "Nat. Dex: random picks include Megas and other forms" },
	}

	function Options.get(key)
		local a, b = key:match("^([^.]+)%.(.+)$")
		if a then return SETTINGS[a] and SETTINGS[a][b] end
		return SETTINGS[key]
	end
	function Options.set(key, value)
		local a, b = key:match("^([^.]+)%.(.+)$")
		if a then
			if type(SETTINGS[a]) == "table" then SETTINGS[a][b] = value end
		else
			SETTINGS[key] = value
		end
	end

	-- Turns text (from the window or the config file) into a valid value for
	-- the field, or returns nil plus a reason.
	function Options.parse(field, text)
		text = tostring(text or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if field.kind == "bool" then
			if text == "true" then return true end
			if text == "false" then return false end
			return nil, "needs true or false"
		elseif field.kind == "choice" then
			local want = string.lower(text):gsub("[^%a]", "")
			for _, choice in ipairs(field.choices) do
				if string.lower(choice):gsub("[^%a]", "") == want then return choice end
			end
			return nil, "isn't one of the choices"
		elseif field.kind == "bst" then
			if string.lower(text) == "auto" or text == "" then return "auto" end
			local n = tonumber(text)
			if n and n >= 1 and n <= 999 then return math.floor(n) end
			return nil, "needs \"auto\" or a number from 1 to 999"
		else
			local n = tonumber(text)
			if not n then return nil, "needs a number" end
			n = math.floor(n)
			if n < field.min or n > field.max then
				return nil, string.format("needs a number from %d to %d", field.min, field.max)
			end
			return n
		end
	end

	local function copyRule(rule)
		local c = {}
		for k, v in pairs(rule) do c[k] = v end
		return c
	end
	local function copyRules(rules)
		local c = { byName = {}, byExactCoins = {}, byCoins = {} }
		for k, r in pairs(rules.byName or {}) do c.byName[k] = copyRule(r) end
		for k, r in pairs(rules.byExactCoins or {}) do c.byExactCoins[k] = copyRule(r) end
		for i, r in ipairs(rules.byCoins or {}) do c.byCoins[i] = copyRule(r) end
		return c
	end
	local function useRules(rules)
		GIFT_RULES.byName, GIFT_RULES.byExactCoins, GIFT_RULES.byCoins = rules.byName, rules.byExactCoins, rules.byCoins
		table.sort(GIFT_RULES.byCoins, function(x, y) return x.minCoins > y.minCoins end)
	end

	-- What this file ships with, kept so "Reset" can bring it back
	Options.defaultRules = copyRules(GIFT_RULES)
	Options.defaultSettings = {}
	for _, field in ipairs(Options.FIELDS) do Options.defaultSettings[field.key] = Options.get(field.key) end

	function Options.validEffect(name)
		return name == "none" or type(Effects[name]) == "function"
	end

	-- Adds or replaces one rule. matchBy: "name", "coins" (exact) or "tier" (this many or more).
	function Options.putRule(matchBy, value, effect, amount, target)
		target = target or GIFT_RULES
		if not Options.validEffect(effect) then return false, "unknown effect \"" .. tostring(effect) .. "\"" end
		local rule = { effect = effect }
		amount = tonumber(amount)
		if amount and amount >= 1 then rule.amount = math.floor(amount) end
		if matchBy == "name" then
			local name = string.lower(tostring(value or "")):gsub("\t", " "):gsub("^%s+", ""):gsub("%s+$", "")
			if name == "" then return false, "type the gift's name" end
			target.byName[name] = rule
			return true, "\"" .. name .. "\""
		end
		local coins = tonumber(value)
		if not coins or coins < 1 then return false, "type a coin value (a number of 1 or more)" end
		coins = math.floor(coins)
		if matchBy == "coins" then
			target.byExactCoins[coins] = rule
			return true, "exactly " .. coins .. " coins"
		end
		rule.minCoins = coins
		for i = #target.byCoins, 1, -1 do
			if target.byCoins[i].minCoins == coins then table.remove(target.byCoins, i) end
		end
		table.insert(target.byCoins, rule)
		table.sort(target.byCoins, function(x, y) return x.minCoins > y.minCoins end)
		return true, coins .. " coins or more"
	end

	function Options.removeRule(matchBy, value)
		if matchBy == "name" then
			local name = string.lower(tostring(value or ""))
			if GIFT_RULES.byName[name] == nil then return false end
			GIFT_RULES.byName[name] = nil
			return true
		end
		local coins = tonumber(value)
		if not coins then return false end
		if matchBy == "coins" then
			if GIFT_RULES.byExactCoins[coins] == nil then return false end
			GIFT_RULES.byExactCoins[coins] = nil
			return true
		end
		for i = #GIFT_RULES.byCoins, 1, -1 do
			if GIFT_RULES.byCoins[i].minCoins == coins then
				table.remove(GIFT_RULES.byCoins, i)
				return true
			end
		end
		return false
	end

	-- Every rule as { matchBy, value, effect, amount, text }, in the order gifts are checked
	function Options.listRules()
		local list = {}
		local function add(matchBy, value, rule, text)
			local label = text .. "  ->  " .. rule.effect
			if rule.amount then label = label .. " x" .. rule.amount end
			list[#list + 1] = { matchBy = matchBy, value = value, effect = rule.effect, amount = rule.amount, text = label }
		end
		local names = {}
		for name in pairs(GIFT_RULES.byName) do names[#names + 1] = name end
		table.sort(names)
		for _, name in ipairs(names) do add("name", name, GIFT_RULES.byName[name], "Gift \"" .. name .. "\"") end
		local coins = {}
		for c in pairs(GIFT_RULES.byExactCoins or {}) do coins[#coins + 1] = c end
		table.sort(coins)
		for _, c in ipairs(coins) do add("coins", c, GIFT_RULES.byExactCoins[c], "Exactly " .. c .. " coins") end
		for _, tier in ipairs(GIFT_RULES.byCoins) do add("tier", tier.minCoins, tier, tier.minCoins .. " coins or more") end
		return list
	end

	function Options.save()
		if not Options.configPath then return false end
		local f = io.open(Options.configPath, "w")
		if not f then
			log("Couldn't save options to " .. Options.configPath)
			return false
		end
		f:write("# TikTok Gifts options, saved by the Options window in the Tracker\n")
		f:write("# (Extensions > TikTok Gifts > Options). One entry per line, parts separated by TAB.\n")
		f:write("# Delete this file to go back to the defaults in TikTokGifts.lua.\n")
		for _, field in ipairs(Options.FIELDS) do
			f:write(string.format("setting\t%s\t%s\n", field.key, tostring(Options.get(field.key))))
		end
		for name, pos in pairs(Options.windowPos or {}) do
			f:write(string.format("window\t%s\t%d\t%d\n", name, pos[1], pos[2]))
		end
		if Options.customRules then
			f:write("rules\tcustom\n")
			for _, r in ipairs(Options.listRules()) do
				f:write(string.format("rule\t%s\t%s\t%s\t%s\n", r.matchBy, tostring(r.value), r.effect, tostring(r.amount or "")))
			end
		end
		f:close()
		return true
	end

	function Options.load()
		-- Start from this file's defaults, so a deleted config.txt really resets things
		Options.resetSettings()
		Options.resetRules()
		if not Options.configPath then return end
		local f = io.open(Options.configPath, "r")
		if not f then return end
		local byKey = {}
		for _, field in ipairs(Options.FIELDS) do byKey[field.key] = field end
		local fileRules, problems = nil, 0
		for rawLine in f:lines() do
			local line = rawLine:gsub("\r$", "")
			local kind, a, b, c, d = line:match("^(%a+)\t([^\t]*)\t?([^\t]*)\t?([^\t]*)\t?([^\t]*)")
			if kind == "setting" and byKey[a] then
				local value = Options.parse(byKey[a], b)
				if value ~= nil then Options.set(a, value) else problems = problems + 1 end
			elseif kind == "window" and tonumber(b) and tonumber(c) then
				Options.windowPos[a] = { tonumber(b), tonumber(c) }
			elseif kind == "rules" and a == "custom" then
				fileRules = { byName = {}, byExactCoins = {}, byCoins = {} }
			elseif kind == "rule" and fileRules then
				if not Options.putRule(a, b, c, d, fileRules) then problems = problems + 1 end
			end
		end
		f:close()
		if fileRules then
			useRules(fileRules)
			Options.customRules = true
		end
		log("Loaded your options from config.txt" .. (fileRules and " (with your own gift rules)" or ""))
		if problems > 0 then log(problems .. " line(s) in config.txt couldn't be read and were skipped.") end
	end

	-- Settings changed while playing: refresh everything built from them
	function Options.applied()
		if G then
			G.genLayoutUnknown = nil
			reportGenerationLimit()
			reportForms()
			setupRuleset()
		end
	end

	function Options.resetSettings()
		for _, field in ipairs(Options.FIELDS) do Options.set(field.key, Options.defaultSettings[field.key]) end
	end
	function Options.resetRules()
		useRules(copyRules(Options.defaultRules))
		Options.customRules = false
	end

	local function haveForms()
		return ExternalUI ~= nil and ExternalUI.BizForms ~= nil and type(ExternalUI.BizForms.createForm) == "function"
	end

	-- While one of its pop-up windows is open, the Tracker ignores clicks on
	-- itself, which would leave it stuck on the Extensions page. The Options
	-- windows are meant to stay open while you play and test, so hand the
	-- Tracker its mouse back. Only on BizHawk 2.9 and newer: there the window
	-- itself keeps your typing and clicks from reaching the game underneath.
	function Options.keepTrackerClickable()
		if not (Input and Main and Main.EMU) then return end
		if Main.emulator ~= Main.EMU.BIZHAWK29 and Main.emulator ~= Main.EMU.BIZHAWK_FUTURE then return end
		Input.allowMouse = true
		Input.resumeMouse = false
	end
	-- Back to the main Pokemon screen, so changes can be seen as they happen
	function Options.showPokemonScreen()
		if Program and type(Program.changeScreenView) == "function" and TrackerScreen ~= nil
			and Program.currentScreen ~= TrackerScreen then
			pcall(Program.changeScreenView, TrackerScreen)
		end
	end

	-- ---- Where the windows sit ----
	-- A window that was dragged somewhere stays there: its place is remembered
	-- (also across restarts, in config.txt) and used whenever it opens again.
	-- "options" is shared by the settings, gift rules and credits windows;
	-- "move" is the level-up move question.
	Options.windowPos = {}
	function Options.rememberWindow(name, form)
		if not haveForms() or not form or (form.ControlId or 0) == 0 then return end
		local F = ExternalUI.BizForms
		if type(F.getProperty) ~= "function" or not F.Properties then return end
		local okLeft, left = pcall(F.getProperty, form.ControlId, F.Properties.LEFT)
		local okTop, top = pcall(F.getProperty, form.ControlId, F.Properties.TOP)
		left, top = okLeft and tonumber(left) or nil, okTop and tonumber(top) or nil
		-- (a minimized window reports a far-away position; don't remember that)
		if not left or not top or left < -10000 or top < -10000 then return end
		local old = Options.windowPos[name]
		if old and old[1] == left and old[2] == top then return end
		Options.windowPos[name] = { left, top }
		Options.save()
	end
	function Options.placeWindow(name, form)
		local pos = Options.windowPos[name]
		if not pos or not form or (form.ControlId or 0) == 0 then return end
		local F = ExternalUI.BizForms
		if type(F.setProperty) ~= "function" or not F.Properties then return end
		pcall(F.setProperty, form.ControlId, F.Properties.LEFT, pos[1])
		pcall(F.setProperty, form.ControlId, F.Properties.TOP, pos[2])
	end
	-- Opens one of the Options windows where the last one was
	function Options.openWindow(title, width, height)
		if Options.currentForm then Options.rememberWindow("options", Options.currentForm) end
		local form
		form = ExternalUI.BizForms.createForm(title, width, height, 20, 10, function()
			Options.rememberWindow("options", form) -- closed with the X
			if Options.currentForm == form then Options.currentForm = nil end
		end)
		Options.currentForm = form
		Options.placeWindow("options", form)
		Options.keepTrackerClickable()
		return form
	end
	function Options.closeWindow(form)
		Options.rememberWindow("options", form)
		if Options.currentForm == form then Options.currentForm = nil end
		form:destroy()
	end
	-- Swaps a dropdown's list without rebuilding the window. false = not possible here.
	local function setDropdownItems(id, items)
		if (id or 0) == 0 then return true end
		if type(forms) ~= "table" or type(forms.setdropdownitems) ~= "function" then return false end
		local ok = pcall(forms.setdropdownitems, id, items, false)
		return ok
	end

	-- ---- Window 2: gift rules ----
	-- Buttons change this window in place, so it never jumps back to its start position.
	function Options.openRules(status, draft)
		if not haveForms() then return end
		local F = ExternalUI.BizForms
		local form = Options.openWindow("TikTok Gifts - Gift Rules", 720, 455)
		local rules = Options.listRules()
		draft = draft or {}
		local function ruleItems()
			local items = {}
			for i, r in ipairs(rules) do items[i] = string.format("%02d.  %s", i, r.text) end
			if #items == 0 then items[1] = "(no rules yet)" end
			return items
		end

		form:createLabel("A gift uses the first rule that fits: gift name, then exact coins, then \"coins or more\".", 10, 10)
		local countLabel = form:createLabel(string.format("Your rules (%d):", #rules), 10, 38)
		local items = ruleItems()
		local ruleList = form:createDropdown(items, 110, 35, 580, 30, items[1], false)
		local statusLabel -- created further down
		local function say(text) F.setText(statusLabel, text) end
		-- After the rules changed: refresh the list, or rebuild the window if that isn't possible
		local function rulesChanged(text)
			rules = Options.listRules()
			local newItems = ruleItems()
			if not setDropdownItems(ruleList, newItems) then
				Options.openRules(text)
				return
			end
			F.setText(ruleList, newItems[1])
			F.setText(countLabel, string.format("Your rules (%d):", #rules))
			say(text)
		end
		local function selectedRule()
			local index = tonumber((F.getText(ruleList) or ""):match("^(%d+)%."))
			return index and rules[index] or nil
		end

		form:createLabel("ADD OR CHANGE A RULE", 10, 110)
		form:createLabel("Match the gift by:", 10, 138)
		local MATCH_LABELS = { name = "Gift name", coins = "Exact coin value", tier = "Coins or more" }
		local matchList = form:createDropdown({ "Gift name", "Exact coin value", "Coins or more" }, 150, 135, 160, 30,
			MATCH_LABELS[draft.matchBy or "name"], false)
		form:createLabel("Gift name or coins:", 10, 168)
		local valueBox = form:createTextBox(tostring(draft.value or ""), 150, 165, 250, 22)
		form:createLabel("(the bridge window shows each gift's exact name and coin value)", 150, 190)
		form:createLabel("What it does:", 10, 220)
		local effectNames = { "none" }
		for name in pairs(Effects) do effectNames[#effectNames + 1] = name end
		table.sort(effectNames)
		local effectList = form:createDropdown(effectNames, 150, 217, 250, 30, draft.effect or "levelUp", false)
		form:createLabel("Amount:", 10, 250)
		local amountBox = form:createTextBox(tostring(draft.amount or ""), 150, 247, 60, 22)
		form:createLabel("(levels for levelUp/lowerLevel, items for giveHealingItem and Exp. Candies. Blank = 1)", 150, 274)

		form:createButton("Edit selected", 110, 65, function()
			local r = selectedRule()
			if not r then return end
			F.setText(matchList, MATCH_LABELS[r.matchBy])
			F.setText(valueBox, tostring(r.value))
			F.setText(effectList, r.effect)
			F.setText(amountBox, tostring(r.amount or ""))
			say("Editing: " .. r.text)
		end, 120, 25)
		form:createButton("Remove selected", 240, 65, function()
			local r = selectedRule()
			if not r then return end
			Options.removeRule(r.matchBy, r.value)
			Options.customRules = true
			Options.save()
			rulesChanged("Removed: " .. r.text)
		end, 120, 25)

		local function readDraft()
			local matchText = F.getText(matchList)
			local matchBy = (matchText == "Exact coin value" and "coins") or (matchText == "Coins or more" and "tier") or "name"
			return { matchBy = matchBy, value = F.getText(valueBox), effect = F.getText(effectList), amount = F.getText(amountBox) }
		end
		form:createButton("Save this rule", 150, 305, function()
			local d = readDraft()
			local ok, result = Options.putRule(d.matchBy, d.value, d.effect, d.amount)
			if not ok then
				say("Not saved: " .. result)
				return
			end
			Options.customRules = true
			Options.save()
			rulesChanged("Saved the rule for " .. result .. ".")
		end, 120, 25)
		form:createButton("Test this effect now", 280, 305, function()
			local d = readDraft()
			if not Options.validEffect(d.effect) or d.effect == "none" then
				say("Pick an effect to test.")
				return
			end
			local amount = math.max(1, math.floor(tonumber(d.amount) or 1))
			enqueue({ user = "Options test", gift = "test", effect = d.effect, amount = amount })
			say("Test sent: " .. d.effect .. ". Watch the game and the Lua Console.")
		end, 150, 25)

		statusLabel = form:createLabel(status or "Changes are saved as you make them.", 10, 348)
		form:createButton("Back to options", 10, 378, function() Options.openMain() end, 120, 25)
		form:createButton("Reset rules to defaults", 140, 378, function()
			Options.resetRules()
			Options.save()
			rulesChanged("Gift rules are back to the defaults.")
		end, 160, 25)
		form:createButton("Close", 600, 378, function() Options.closeWindow(form) end, 95, 25)
	end

	-- ---- Window 3: credits ----
	Options.CREDITS = {
		"TikTok Gifts was made by Demon_Quingar91.",
		"",
		"It only exists because of other people's work:",
		"",
		"The IronMon Challenge",
		"     Created by iateyourpie. Rules kept by the IronMon community at ironmon.gg.",
		"The Ironmon Tracker",
		"     Created by Besteon, with UTDZac and the Tracker's contributors.",
		"The Nat. Dex ROM hack and NatDexExtension",
		"     By CyanSMP64 and that project's contributors.",
		"",
		"Special thanks",
		"     Trip (@tripc423 on TikTok) and Nino (@ninopokebros on TikTok),",
		"     for the inspiration and for being sounding boards.",
	}
	function Options.openCredits()
		if not haveForms() then return end
		local form = Options.openWindow("TikTok Gifts - Credits", 580, 370)
		for i, line in ipairs(Options.CREDITS) do
			if line ~= "" then form:createLabel(line, 15, 12 + (i - 1) * 19) end
		end
		form:createButton("Back to options", 15, 295, function() Options.openMain() end, 120, 25)
		form:createButton("Close", 460, 295, function() Options.closeWindow(form) end, 95, 25)
	end

	-- ---- Window 1: settings ----
	function Options.openMain(status)
		if not haveForms() then
			log("The Options window needs a newer Ironmon Tracker. You can still edit SETTINGS in TikTokGifts.lua.")
			return
		end
		local F = ExternalUI.BizForms
		local form = Options.openWindow("TikTok Gifts - Options (v" .. self.version .. ")", 820, 590)
		local controls = {}
		local COLUMN_X, LABEL_WIDTH = { 10, 415 }, 270
		local function header(text, column, y) form:createLabel(text, COLUMN_X[column], y) end
		local function fieldFor(key)
			for _, f in ipairs(Options.FIELDS) do if f.key == key then return f end end
		end
		-- What a control should show for the field's current value
		local function shown(field)
			local value = Options.get(field.key)
			if field.kind == "choice" then return Options.parse(field, value) or field.choices[1] end
			return tostring(value)
		end
		local function control(key, column, y)
			local field = fieldFor(key)
			local x = COLUMN_X[column]
			if field.kind == "bool" then
				controls[key] = form:createCheckbox(field.label, x, y, nil, Options.get(key) == true)
			else
				form:createLabel(field.label .. ":", x, y + 3)
				if field.kind == "choice" then
					controls[key] = form:createDropdown(field.choices, x + LABEL_WIDTH - (field.width and 30 or 0), y,
						field.width or 110, 30, shown(field), false)
				elseif field.kind == "int" and field.max - field.min <= 8 then
					local numbers = {}
					for n = field.min, field.max do numbers[#numbers + 1] = tostring(n) end
					controls[key] = form:createDropdown(numbers, x + LABEL_WIDTH, y, 60, 30, shown(field), false)
				else
					controls[key] = form:createTextBox(shown(field), x + LABEL_WIDTH, y, 60, 22)
				end
			end
		end

		header("RULESET - keeps what gifts give you legal", 1, 10)
		control("ruleset", 1, 32)
		control("rulesetMaxBST", 1, 60)
		control("rulesetNewerMoves", 1, 88)
		header("GENERATION LIMIT - 9 means everything", 1, 124)
		control("generationLimit.pokemon", 1, 146)
		control("generationLimit.moves", 1, 174)
		control("generationLimit.abilities", 1, 202)
		control("generationLimit.items", 1, 230)
		header("LEVEL-UPS AND EXP. CANDIES", 1, 266)
		control("levelUpEvolves", 1, 288)
		control("levelUpLearnsMoves", 1, 312)
		control("levelUpFriendship", 1, 336)
		control("levelUpFullMoves", 1, 364)
		control("expCandyMode", 1, 392)
		control("maxLevelsPerGift", 1, 420)
		control("maxItemsPerGift", 1, 448)

		header("GIFT HANDLING", 2, 10)
		control("repeatOtherEffects", 2, 32)
		control("secondsBetweenEffects", 2, 60)
		control("retryEverySeconds", 2, 88)
		control("retryForMinutes", 2, 116)
		control("skipOldGiftsOnStartup", 2, 144)
		header("EFFECT DETAILS", 2, 180)
		control("abilityMode", 2, 202)
		control("maxEVsMode", 2, 230)
		control("randomEVsMode", 2, 258)
		control("replaceLevel", 2, 286)
		control("stabMinPower", 2, 314)
		control("stabMaxPower", 2, 342)
		control("gymLeaderLevelBonus", 2, 370)
		control("gymLeaderEVs", 2, 398)
		control("eliteFourBoostLead", 2, 426)
		control("alternateForms", 2, 450)

		-- Reads the window; returns the number of values that were rejected and the first reason
		local function readAll()
			local rejected, reason = 0, nil
			for _, field in ipairs(Options.FIELDS) do
				local id = controls[field.key]
				if id then
					local text
					if field.kind == "bool" then text = tostring(F.isChecked(id) == true) else text = F.getText(id) end
					local value, why = Options.parse(field, text)
					if value ~= nil then
						Options.set(field.key, value)
					else
						rejected = rejected + 1
						reason = reason or (field.label .. " " .. why)
					end
				end
			end
			return rejected, reason
		end
		-- Puts the values in use back into the controls (after a refused value or a reset)
		local function showAll()
			for _, field in ipairs(Options.FIELDS) do
				local id = controls[field.key]
				if id then
					if field.kind == "bool" then
						F.setChecked(id, Options.get(field.key) == true)
					else
						F.setText(id, shown(field))
					end
				end
			end
		end
		local function saveAll()
			local rejected, reason = readAll()
			Options.save()
			Options.applied()
			showAll()
			if rejected > 0 then return "Saved, except: " .. reason .. "." end
			return "Saved. The new settings are in use now."
		end

		local statusLabel = form:createLabel(
			status or "Pick your settings, then Save. Nothing needs a restart, and the Tracker stays usable behind this window.", 10, 490)
		form:createButton("Save", 10, 516, function() F.setText(statusLabel, saveAll()) end, 90, 25)
		form:createButton("Save && Close", 110, 516, function()
			local result = saveAll()
			if result:sub(1, 6) == "Saved." then Options.closeWindow(form) else F.setText(statusLabel, result) end
		end, 110, 25)
		form:createButton("Edit gift rules...", 250, 516, function()
			saveAll()
			Options.openRules()
		end, 140, 25)
		form:createButton("Reset settings to defaults", 400, 516, function()
			Options.resetSettings()
			Options.save()
			Options.applied()
			showAll()
			F.setText(statusLabel, "Settings are back to the defaults. Your gift rules were not changed.")
		end, 190, 25)
		form:createButton("Credits", 610, 516, function() Options.openCredits() end, 90, 25)
		form:createButton("Cancel", 710, 516, function() Options.closeWindow(form) end, 85, 25)
	end

	-- The Tracker shows an "Options" button on the extension's page when this exists
	function self.configureOptions()
		Options.openMain()
		if haveForms() then Options.showPokemonScreen() end
	end

	-- ======================= MOVE CHOICE POP-UP =============
	-- A level-up move with four moves already known: ask which move to forget.
	-- The game is paused and no other gift is applied until the choice is made.
	local TYPE_NAMES = { [0] = "Normal", "Fighting", "Flying", "Poison", "Ground", "Rock", "Bug", "Ghost", "Steel",
		"???", "Fire", "Water", "Grass", "Electric", "Psychic", "Ice", "Dragon", "Dark", "Fairy" }
	local function moveDetails(id)
		local m = readMove(id)
		local parts = { TYPE_NAMES[m.type] or "?" }
		parts[#parts + 1] = m.power > 1 and ("power " .. m.power) or (m.power == 1 and "power varies" or "no damage")
		parts[#parts + 1] = m.accuracy > 0 and ("accuracy " .. m.accuracy) or "never misses"
		parts[#parts + 1] = "PP " .. m.pp
		return table.concat(parts, ", ")
	end
	local function findMonByPid(pid)
		for slot = 1, 6 do
			local mon = readMon(slot)
			if mon and mon.pid == pid and not isEgg(mon) then return mon end
		end
		return nil
	end
	local function pauseGame()
		if client and client.pause then pcall(client.pause) end
	end

	-- Called when a level-up move finds no empty slot. Returns true if the
	-- player will be asked (false = just skip the move, the old behaviour).
	function MoveChoice.request(mon, move)
		if SETTINGS.levelUpFullMoves ~= "ask" or not haveForms() then return false end
		for _, p in ipairs(MoveChoice.pending) do
			if p.pid == mon.pid and p.move == move then return true end
		end
		MoveChoice.pending[#MoveChoice.pending + 1] = { pid = mon.pid, move = move, maxPP = MoveChoice.maxPPForNew == true }
		MoveChoice.justAsked[#MoveChoice.justAsked + 1] = moveName(move)
		return true
	end

	-- slot 1-4 = forget that move and learn the new one; nil = don't learn it
	function MoveChoice.answer(choice, slot)
		if choice.answered then return end
		choice.answered = true
		for i, p in ipairs(MoveChoice.pending) do
			if p == choice then table.remove(MoveChoice.pending, i) break end
		end
		MoveChoice.open = false
		local mon = findMonByPid(choice.pid)
		if not mon then return end
		if slot then
			local forgotten = teachMove(mon, choice.move, slot)
			if choice.maxPP then applyMaxPP(mon) end
			log(string.format("%s forgot %s and learned %s.", nameLead(mon), moveName(forgotten), moveName(choice.move)))
		else
			log(string.format("%s did not learn %s.", nameLead(mon), moveName(choice.move)))
		end
	end

	function MoveChoice.showNext()
		if MoveChoice.open then return end
		local choice = MoveChoice.pending[1]
		while choice do
			-- Nothing to ask if the Pokemon is gone, knows the move by now, or has room after all
			local mon = findMonByPid(choice.pid)
			local moves = mon and getMoves(mon)
			local known, free = false, false
			for i = 1, 4 do
				if moves and moves[i] == choice.move then known = true end
				if moves and moves[i] == 0 then free = true end
			end
			if mon and not known and not free and haveForms() then break end
			if mon and not known and free then
				teachMove(mon, choice.move)
				if choice.maxPP then applyMaxPP(mon) end
				log(string.format("%s learned %s.", nameLead(mon), moveName(choice.move)))
			end
			table.remove(MoveChoice.pending, 1)
			choice = MoveChoice.pending[1]
		end
		if not choice then return end

		local mon = findMonByPid(choice.pid)
		local moves = getMoves(mon)
		local newName = moveName(choice.move)
		local form
		form = ExternalUI.BizForms.createForm("TikTok Gifts - New move", 560, 345, 100, 30, function()
			-- Window closed with the X: same as choosing not to learn the move
			Options.rememberWindow("move", form)
			MoveChoice.answer(choice, nil)
		end)
		Options.placeWindow("move", form)
		MoveChoice.open = true
		form:createLabel(string.format("%s wants to learn %s!", nameLead(mon), newName), 10, 10)
		form:createLabel(string.format("%s:  %s", newName, moveDetails(choice.move)), 10, 32)
		form:createLabel("It already knows four moves. Choose one to forget, or keep all four:", 10, 62)
		for i = 1, 4 do
			local y = 88 + (i - 1) * 32
			form:createButton("Forget " .. moveName(moves[i]), 10, y, function()
				Options.rememberWindow("move", form)
				MoveChoice.answer(choice, i)
				form:destroy()
				MoveChoice.showNext()
			end, 210, 26)
			form:createLabel(moveDetails(moves[i]), 230, y + 6)
		end
		form:createButton("Keep all four (don't learn " .. newName .. ")", 10, 224, function()
			Options.rememberWindow("move", form)
			MoveChoice.answer(choice, nil)
			form:destroy()
			MoveChoice.showNext()
		end, 330, 26)
		local more = #MoveChoice.pending - 1
		form:createLabel("The game is paused until you choose."
			.. (more > 0 and string.format("  %d more move%s after this one.", more, more == 1 and "" or "s") or ""), 10, 268)
		pauseGame()
	end

	-- Every Tracker update: open the next question if one is waiting, and keep
	-- the game paused while a question is on screen.
	function MoveChoice.tick()
		if #MoveChoice.pending == 0 then return end
		if not MoveChoice.open then
			MoveChoice.showNext()
		elseif client and client.ispaused and client.pause then
			local ok, paused = pcall(client.ispaused)
			if ok and paused == false then pcall(client.pause) end
		end
	end

	-- ======================= TRACKER CALLBACKS ==============
	function self.startup()
		math.randomseed(os.time())
		local dir = getExtensionDir() .. "TikTokGifts/"
		giftsFilePath = dir .. "gifts.txt"
		backupFilePath = dir .. "released_pokemon.txt"
		Options.configPath = dir .. "config.txt"
		Options.load()

		-- Create the file if needed so the bridge and extension agree on it
		local f = io.open(giftsFilePath, "a")
		if not f then
			log("Couldn't open " .. giftsFilePath .. ". Is the TikTokGifts folder next to TikTokGifts.lua?")
			giftsFilePath = nil
			return
		end
		f:close()

		filePos = 0
		if SETTINGS.skipOldGiftsOnStartup then
			local rf = io.open(giftsFilePath, "r")
			if rf then filePos = rf:seek("end") rf:close() end
		end
		queue = {}
		workingAbilities = nil
		G = detectGame()
		if G then
			reportGenerationLimit()
			reportForms()
			setupRuleset()
		end
		if SETTINGS.retryHotkey and event and event.onframeend then
			pcall(event.unregisterbyname, HOTKEY_EVENT_NAME)
			event.onframeend(checkHotkey, HOTKEY_EVENT_NAME)
		end
		log("Listening for gifts in " .. giftsFilePath)
	end

	function self.unload()
		stopWarpWatch()
		stopGymWatch()
		if event and event.unregisterbyname then pcall(event.unregisterbyname, HOTKEY_EVENT_NAME) end
		queue = {}
		MoveChoice.pending, MoveChoice.open = {}, false
		giftsFilePath = nil
	end

	-- Runs roughly every 30 frames (~2x per second)
	function self.afterProgramDataUpdate()
		pollGiftsFile()
		MoveChoice.tick()
		processQueue()
	end

	return self
end

return TikTokGifts
