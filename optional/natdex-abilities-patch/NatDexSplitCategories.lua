--[[
	Nat. Dex Physical/Special Split - Ironmon Tracker extension (BizHawk)

	For the "FireRed NatDex + Abilities" ROM, where each move is physical or
	special by the move itself instead of by its type (Fire Punch is physical,
	Shadow Ball is special, and so on).

	The Tracker normally works the category out from the move's type. This
	extension reads each move's real category from the ROM and gives it to the
	Tracker, so the physical/special icons and move info match the game.

	It also teaches the Tracker the names of the 50 single-use held items that
	ROM adds (Focus Sash, Weakness Policy, the resist berries and so on), and
	replaces "Not implemented yet." with the real description for every
	ability and move the ROM implements. For those moves it also fills in the
	type, power, accuracy and PP, which the Tracker otherwise shows as blank.

	It does nothing on ROMs without the split, so it is safe to leave enabled.
	Requires CyanSMP64's NatDexExtension to be enabled as well.
]]

local function NatDexSplitCategories()
	local self = {}

	self.version = "1.4.1"
	self.name = "Nat. Dex Phys/Spec Split"
	self.author = "Demon_Quingar91"
	self.description = "For the FireRed NatDex + Abilities ROM: shows each move's real physical/special category, the stats and descriptions of the moves it implements, and the names of its new items."
	self.github = nil
	self.url = "https://github.com/estrawder-collab/TikTokGifts-IronmonExtension"

	-- Move IDs used to recognise a ROM with the per-move split
	local FIRE_PUNCH = 7    -- Fire type, physical only with the split
	local SHADOW_BALL = 247 -- Ghost type, special only with the split

	-- Category values stored in the ROM (top two bits of each move's flags byte)
	local CAT_PHYSICAL, CAT_SPECIAL, CAT_STATUS = 1, 2, 3

	-- Held items the ROM adds in item slots the original game left unused
	local NEW_ITEMS = {
		[53] = "Focus Sash",
		[54] = "Weakness Policy",
		[55] = "Air Balloon",
		[56] = "Power Herb",
		[57] = "Eject Button",
		[58] = "Eject Pack",
		[59] = "Absorb Bulb",
		[60] = "Cell Battery",
		[61] = "Luminous Moss",
		[62] = "Snowball",
		[72] = "Throat Spray",
		[87] = "Blunder Policy",
		[88] = "Room Service",
		[105] = "Adrenaline Orb",
		[112] = "Electric Seed",
		[113] = "Grassy Seed",
		[114] = "Misty Seed",
		[115] = "Psychic Seed",
		[116] = "Berserk Gene",
		[117] = "Normal Gem",
		[118] = "Fire Gem",
		[119] = "Water Gem",
		[120] = "Electric Gem",
		[227] = "Grass Gem",
		[228] = "Flying Gem",
		[229] = "Occa Berry",
		[230] = "Passho Berry",
		[231] = "Wacan Berry",
		[232] = "Rindo Berry",
		[233] = "Yache Berry",
		[234] = "Chople Berry",
		[235] = "Kebia Berry",
		[236] = "Shuca Berry",
		[237] = "Coba Berry",
		[238] = "Payapa Berry",
		[239] = "Tanga Berry",
		[240] = "Charti Berry",
		[241] = "Kasib Berry",
		[242] = "Haban Berry",
		[243] = "Colbur Berry",
		[244] = "Babiri Berry",
		[245] = "Chilan Berry",
		[246] = "Roseli Berry",
		[247] = "Custap Berry",
		[248] = "Jaboca Berry",
		[249] = "Rowap Berry",
		[250] = "Kee Berry",
		[251] = "Maranga Berry",
		[252] = "Micle Berry",
		[253] = "Ice Gem",
		-- Exp. Candies (bag items, used like a Rare Candy)
		[176] = "Exp. Candy XS",
		[177] = "Exp. Candy S",
		[178] = "Exp. Candy M",
		[347] = "Exp. Candy L",
		[348] = "Exp. Candy XL",
	}

	local function itemTables()
		local tables = {}
		if Resources and Resources.Game and Resources.Game.ItemNames then
			table.insert(tables, Resources.Game.ItemNames)
		end
		if Resources and Resources.Default and Resources.Default.Game and Resources.Default.Game.ItemNames
			and Resources.Default.Game.ItemNames ~= (Resources.Game and Resources.Game.ItemNames) then
			table.insert(tables, Resources.Default.Game.ItemNames)
		end
		return tables
	end

	local function syncItemNames()
		for _, names in ipairs(itemTables()) do
			for id, name in pairs(NEW_ITEMS) do
				if names[id] ~= name then names[id] = name end
			end
		end
		if MiscData and MiscData.OtherItems then
			local pocket = MiscData.BagPocket and MiscData.BagPocket.Items
			for id, name in pairs(NEW_ITEMS) do
				if MiscData.OtherItems[id] == nil then
					MiscData.OtherItems[id] = { id = id, name = name, pocket = pocket }
				end
			end
		end
	end

	-- Descriptions of the abilities this ROM implements, as shown in the game
	local ABILITY_TEXT = {
		[78] = "Ups evasion if confused.",
		[79] = "Electric hits raise Speed.",
		[80] = "Stronger vs. same gender.",
		[81] = "Flinching raises Speed.",
		[82] = "Ups evasion in hail.",
		[83] = "Eats Berries at half HP.",
		[84] = "Crits max out its Attack.",
		[85] = "Speed up if item is used.",
		[86] = "Halves Fire damage.",
		[87] = "Doubles stat changes.",
		[88] = "Water heals, Fire hurts.",
		[89] = "Raises Atk or Sp. Atk.",
		[90] = "Boosts punching moves.",
		[91] = "Heals when poisoned.",
		[92] = "Powers up same-type moves.",
		[93] = "Multi-hit moves hit 5 times",
		[94] = "Heals status in rain.",
		[95] = "Sun ups Sp. Atk, costs HP.",
		[96] = "Speed up when statused.",
		[97] = "All moves become Normal.",
		[98] = "Powers up critical hits.",
		[99] = "Only hurt by attacks.",
		[100] = "All moves always hit.",
		[101] = "Always moves last.",
		[102] = "Powers up weak moves.",
		[103] = "No status in sunshine.",
		[104] = "Can't use held items.",
		[105] = "Ignores foe's abilities.",
		[106] = "Raises critical-hit ratio.",
		[107] = "Hurts foe when fainting.",
		[108] = "Senses dangerous moves.",
		[109] = "Reveals foe's best move.",
		[110] = "Ignores foe's stat changes.",
		[111] = "Ups not-very-effective hits",
		[112] = "Softens super-effective hits",
		[113] = "Slow for the first 5 turns.",
		[114] = "Normal, Fighting hit Ghosts",
		[115] = "Absorbs Water, ups Sp. Atk.",
		[116] = "Heals HP in hail.",
		[117] = "Softens super-effective hits",
		[118] = "Summons hail on entry.",
		[120] = "Checks foe's held item.",
		[121] = "Powers up recoil moves.",
		[123] = "Ups ally stats in sunshine.",
		[124] = "Hurts sleeping foes.",
		[125] = "Steals item on contact.",
		[126] = "No side effects, more power",
		[127] = "Reverses stat changes.",
		[128] = "Foes can't eat Berries.",
		[129] = "Stat drops sharply up Atk.",
		[130] = "Weaker at half HP or less.",
		[131] = "May disable foe's move.",
		[132] = "May heal ally's status.",
		[133] = "Reduces damage to allies.",
		[134] = "Hits lower Def, raise Speed",
		[135] = "Doubles its weight.",
		[136] = "Halves its weight.",
		[137] = "Less damage at full HP.",
		[138] = "Ups Attack when poisoned.",
		[139] = "Ups Sp. Atk when burned.",
		[140] = "May restore eaten Berries.",
		[141] = "Dodges allies' attacks.",
		[142] = "Ups one stat, lowers one.",
		[143] = "Blocks weather and powders.",
		[144] = "Contact may poison foe.",
		[145] = "Heals when switching out.",
		[146] = "Defense can't be lowered.",
		[147] = "Doubles Speed in sandstorm.",
		[148] = "Status moves may miss it.",
		[149] = "Ups power if moving last.",
		[150] = "Disguised as a party member",
		[151] = "Transforms into the foe.",
		[152] = "Ignores screens and subs.",
		[153] = "Spreads Mummy on contact.",
		[154] = "KOs raise its Attack.",
		[155] = "Dark hits raise Attack.",
		[156] = "Scary hits raise Speed.",
		[157] = "Reflects status moves.",
		[158] = "Absorbs Grass, ups Attack.",
		[159] = "Status moves go first.",
		[160] = "Stronger in a sandstorm.",
		[161] = "Hurts foes on contact.",
		[162] = "Changes form at half HP.",
		[163] = "Ups accuracy of allies.",
		[164] = "Moves ignore abilities.",
		[165] = "Moves ignore abilities.",
		[166] = "Blocks mental effects.",
		[167] = "Shields Grass allies' stats",
		[168] = "Eating Berries restores HP",
		[169] = "Becomes the type it uses.",
		[170] = "Halves physical damage.",
		[171] = "Steals item when it hits.",
		[172] = "Immune to ball and bombs.",
		[173] = "Stat drops sharply up SpAtk",
		[174] = "Powers up biting moves.",
		[175] = "Normal moves become Ice.",
		[176] = "Prevents sleep for allies.",
		[177] = "Shifts form to attack.",
		[178] = "Flying moves go first.",
		[179] = "Powers up pulse moves.",
		[180] = "Ups Defense on grass field.",
		[181] = "Passes item to an ally.",
		[182] = "Powers up contact moves.",
		[183] = "Normal moves become Fairy.",
		[184] = "Contact lowers foe's Speed",
		[185] = "Normal moves become Flying",
		[186] = "Attacks hit twice.",
		[187] = "Powers up Dark moves.",
		[188] = "Powers up Fairy moves.",
		[189] = "Reverses aura effects.",
		[190] = "Summons heavy rain.",
		[191] = "Summons extreme sunlight.",
		[192] = "Summons strong winds.",
		[193] = "Getting hit ups Defense.",
		[194] = "Flees at half HP.",
		[195] = "Switches out at half HP.",
		[196] = "Water hits sharply up Def.",
		[197] = "Crits on poisoned foes.",
		[198] = "Changes form at half HP.",
		[199] = "Hits switch-ins twice as hard",
		[200] = "Ups Water, halves Fire hits",
		[201] = "Powers up Steel moves.",
		[202] = "Ups Sp. Atk at half HP.",
		[203] = "Doubles Speed in hail.",
		[204] = "Moves don't make contact.",
		[205] = "Sound moves become Water.",
		[206] = "Healing moves go first.",
		[207] = "Normal moves turn Electric",
		[208] = "Fast on Electric Terrain.",
		[209] = "Forms a school when healthy",
		[210] = "Blocks the first hit.",
		[211] = "Changes form after a KO.",
		[212] = "Changes form at half HP.",
		[213] = "Can poison any type.",
		[214] = "Always drowsing, no status",
		[215] = "Blocks priority moves.",
		[216] = "Hurts foe when fainting.",
		[217] = "Copies dance moves.",
		[218] = "Ups allies' special moves.",
		[219] = "Less contact, more Fire dmg",
		[220] = "Blocks priority moves.",
		[221] = "KOs raise its Sp. Atk.",
		[222] = "Contact lowers foe's Speed",
		[223] = "Copies fainted ally ability",
		[224] = "Copies fainted ally ability",
		[225] = "KOs raise its best stat.",
		[227] = "Sets Electric Terrain.",
		[228] = "Sets Psychic Terrain.",
		[229] = "Sets Misty Terrain.",
		[230] = "Sets Grassy Terrain.",
		[231] = "Stats can't be lowered.",
		[232] = "Less damage at full HP.",
		[233] = "Softens super-effective hits",
		[234] = "Ups super-effective hits.",
		[235] = "Ups Attack on entry.",
		[236] = "Ups Defense on entry.",
		[237] = "Becomes the type it uses.",
		[239] = "Hits lower others' Speed.",
		[240] = "Ignores move redirection.",
		[241] = "Reflects stat drops.",
		[242] = "Spits prey when hit.",
		[243] = "Ignores move redirection.",
		[244] = "Fire, Water hits max Speed",
		[245] = "Boosts and resists sound.",
		[246] = "Hits whip up a sandstorm.",
		[247] = "Halves special damage.",
		[248] = "Doubles Berry effects.",
		[249] = "Ice face blocks a hit.",
		[250] = "Powers up allies' moves.",
		[251] = "Type changes with terrain.",
		[252] = "Removes screens on entry.",
		[253] = "Ups allies' Steel moves.",
		[254] = "Contact starts Perish Song",
		[255] = "Swaps abilities on contact",
		[256] = "Ups Attack, locks one move",
		[257] = "Nullifies other abilities.",
		[258] = "Prevents poison for allies",
		[259] = "Changes form each turn.",
		[260] = "May move first.",
		[261] = "Contact hits ignore Protect",
		[262] = "Resets allies' stat changes",
		[263] = "Powers up Electric moves.",
		[264] = "Powers up Dragon moves.",
		[265] = "KOs raise its Attack.",
		[266] = "KOs raise its Sp. Atk.",
		[267] = "Unnerve plus Chilling Neigh.",
		[268] = "Unnerve plus Grim Neigh.",
		[269] = "Spreads its ability on hit",
		[270] = "Hits set Grassy Terrain.",
		[271] = "Fire hits up Atk, no burns.",
		[272] = "At half HP, offense up.",
		[273] = "No status, halves Ghost hit",
		[274] = "Fire hits raise Defense.",
		[275] = "Wind moves up its Attack.",
		[276] = "Intimidate ups its Attack.",
		[277] = "Powers up Rock moves.",
		[278] = "Wind hits charge it up.",
		[279] = "Becomes Hero on switch out.",
		[281] = "Hits charge it up.",
		[282] = "Sun ups its best stat.",
		[283] = "Electric field ups best stat",
		[284] = "Immune to status moves.",
		[285] = "Lowers others' Sp. Atk.",
		[286] = "Lowers others' Defense.",
		[287] = "Lowers others' Attack.",
		[288] = "Lowers others' Sp. Def.",
		[289] = "Sets sun, ups its Attack.",
		[290] = "Electric field, ups Sp. Atk",
		[291] = "Copies foe's stat boosts.",
		[292] = "Eats a Berry twice.",
		[293] = "Powers up slicing moves.",
		[294] = "Fainted allies up its power",
		[295] = "Copies ally's stat changes",
		[296] = "Hits scatter Toxic Spikes.",
		[297] = "Blocks priority moves.",
		[298] = "Ground moves heal it.",
		[299] = "Status moves ignore ability",
		[300] = "Heals ally on entry.",
		[301] = "Hits Ghosts, ignores evasion",
		[302] = "Mask ups its Speed.",
		[303] = "Mask ups its Attack.",
		[304] = "Mask ups its Sp. Def.",
		[305] = "Mask ups its Defense.",
		[306] = "Hits may badly poison.",
		[307] = "Lowers foes' evasion.",
		[308] = "Changes form on entry.",
		[309] = "Full HP hits not effective",
		[310] = "Clears weather and terrain.",
		[311] = "Poisoned foes get confused",
		[312] = "Contact hits through Protect",
		[313] = "Normal moves become Dragon.",
		[314] = "Immune to Ground moves.",
		[316] = "Acts as if it is sunny.",
		[317] = "Powers up Fire moves.",
		[319] = "Burns foes that hit it.",
		[320] = "Halves contact damage.",
	}

	local function syncAbilityText()
		local descriptions = Resources and Resources.Game and Resources.Game.AbilityDescriptions
		local abilities = AbilityData and AbilityData.Abilities
		for id, text in pairs(ABILITY_TEXT) do
			local entry = descriptions and descriptions[id]
			local ability = abilities and abilities[id]
			if type(entry) == "table" and type(entry.Description) == "string"
				and entry.Description:lower():find("not implemented", 1, true) then
				entry.Description = text
			end
			if type(ability) == "table" and type(ability.description) == "string"
				and ability.description:lower():find("not implemented", 1, true) then
				ability.description = text
			end
		end
	end

	-- Descriptions of the Gen 4-9 moves this ROM implements, as shown in the game
	local MOVE_TEXT = {
		[355] = "Restores the user's HP by half of its max HP.",
		[356] = "Gravity is intensified negating levitation.",
		[357] = "Negates evasion and the Dark type's immunities.",
		[358] = "Powerful against a sleeping foe, but also wakes it.",
		[359] = "Swings with a heavy fist. Lowers the user's Speed.",
		[360] = "A high-speed spin that does more damage to faster a foe.",
		[361] = "Faints to restore the HP and status of the next Pokémon.",
		[362] = "Does double damage to a foe with half HP or less.",
		[363] = "The effectiveness varies with the held Berry.",
		[364] = "Hits a protecting foe and lifts those effects.",
		[365] = "Eats the foe's held Berry and gains its effect.",
		[366] = "Whips up a wind that boosts allies' Speed for 4 turns.",
		[367] = "The user sharply raises one of its stats.",
		[368] = "Retaliates against the foe that last damaged the user.",
		[369] = "Attacks and rushes back to switch with a party Pokémon.",
		[370] = "Fights up close. This lowers the user's defensive stats.",
		[371] = "An attack that gains power if the user moves last.",
		[372] = "An attack that gains power if the foe has been hurt.",
		[373] = "Prevents the foe from using any items.",
		[374] = "The effectiveness varies with the held item.",
		[375] = "Transfers status problems to the foe.",
		[376] = "The less PP the move has the more damage it does.",
		[377] = "Prevents the foes from recovering HP for 5 turns.",
		[378] = "The more HP the foe has, the greater the power.",
		[379] = "The user swaps its Attack and Defense stats.",
		[380] = "Stomach acid suppresses the foe's Ability.",
		[381] = "Prevents the foe from landing critical hits.",
		[382] = "Executes the foe's attack with greater power.",
		[383] = "The user mimics the last move used by a foe.",
		[384] = "Swaps changes to Attack and Sp. Atk with the foe.",
		[385] = "Swaps changes to Defense and Sp. Def with the foe.",
		[386] = "Does more damage the more the foe has powered up.",
		[387] = "Can only be used if every other move has been used.",
		[388] = "Plants a seed on the foe giving it Insomnia.",
		[389] = "Attacks first if the foe is readying an attack.",
		[390] = "Sets spikes that poison a foe switching in.",
		[391] = "Swaps any stat changes with the foe.",
		[392] = "Forms a veil of water that restores HP.",
		[393] = "The user levitates with electromagnetism.",
		[394] = "A charge that may burn the foe. Also hurts the user.",
		[395] = "A shock wave attack that may paralyze the foe.",
		[396] = "Attacks with an aura blast that cannot be evaded.",
		[397] = "Polishes the body to sharply raise Speed.",
		[398] = "A stabbing attack that may poison the foe.",
		[399] = "Attacks with a horrible aura. May cause flinching.",
		[400] = "Hits as soon as possible. High critical-hit ratio.",
		[401] = "The user swings its tail like a wave to attack.",
		[402] = "A barrage of hard seeds is fired at the foe.",
		[403] = "The foe is sliced by a blade of air. It may also make the foe flinch.",
		[404] = "Slashes the foe with crossed scythes, claws, etc.",
		[405] = "A damaging sound wave that may lower Sp. Def.",
		[406] = "Generates a shock wave to damage the foe.",
		[407] = "Tackles the foe with menace. May cause flinching.",
		[408] = "Attacks with rays of light that sparkle like diamonds.",
		[409] = "A punch that drains half the damage inflicted.",
		[410] = "Whirls its fists to send a wave that strikes first.",
		[411] = "Attacks at full power. May lower Sp. Def.",
		[412] = "Draws power from nature to attack. May lower Sp. Def.",
		[413] = "A low altitude charge that also hurts the user.",
		[414] = "Makes the ground erupt with power. May lower Sp. Def.",
		[415] = "Swaps items with the foe faster than the eye can see.",
		[416] = "Powerful, but leaves the user immobile the next turn.",
		[417] = "Thinks bad thoughts to sharply raise Sp. Atk.",
		[418] = "Punches as fast as a bul- let. It always hits first.",
		[419] = "An attack that gains power if injured by the foe.",
		[420] = "Hurls a chunk of ice that always strikes first.",
		[421] = "Strikes with a shadow claw. High critical-hit ratio.",
		[422] = "May cause flinching or leave the foe paralyzed.",
		[423] = "May cause flinching or leave the foe with frostbite.",
		[424] = "May cause flinching or leave the foe with a burn.",
		[425] = "The user extends its shadow to attack. It will strike first.",
		[426] = "Throws a blob of mud to damage and cut accuracy.",
		[427] = "Tears with psychic blades. High critical-hit ratio.",
		[428] = "Hits with a strong head- butt. May cause flinching.",
		[429] = "Emits a flash of energy to damage and cut accuracy.",
		[430] = "Releases a blast of light that may lower Sp. Def.",
		[431] = "A charging attack that may confuse the foe.",
		[432] = "Removes obstacles and lowers evasion.",
		[433] = "Slower Pokémon get to move first for 5 turns.",
		[434] = "Summons comets from the sky, but harshly lowers Sp. Atk.",
		[435] = "Zaps all others with electricity. May paralyze.",
		[436] = "Torches all others with scarlet flames. May burn.",
		[437] = "An intense attack that also sharply reduces the user's Sp. Atk stat.",
		[438] = "Violently lashes the foe with vines or tentacles.",
		[439] = "Powerful, but leaves the user immobile the next turn.",
		[440] = "A slash that may poison a foe and do critical damage.",
		[441] = "Shoots filthy garbage at the foe. May also poison.",
		[442] = "Slams the foe with a hard head. May cause flinching.",
		[443] = "Launches a magnet that strikes without fail.",
		[444] = "Stabs the foe with stones. High critical-hit ratio.",
		[445] = "Makes the opposite gender harshly lower its Sp. Atk.",
		[446] = "Sets floating stones that hurt a foe switching in.",
		[447] = "A snare attack that does more damage to a heavier foe.",
		[448] = "Attacks with a sound wave that causes confusion.",
		[449] = "The type varies with the kind of Plate held.",
		[450] = "Eats the foe's held Berry and gains its effect.",
		[451] = "Fires a beam of electricity. May raise Sp. Atk.",
		[452] = "Slams the body into a foe. The user gets hurt too.",
		[453] = "Strikes first by dashing at the foe at a high speed.",
		[454] = "Underlings pummel the foe. High critical-hit ratio.",
		[455] = "Raises Defense and Sp. Def with a living shield.",
		[456] = "The user's underlings heal up to half of its max HP.",
		[457] = "A life-risking headbutt that seriously hurts the user.",
		[458] = "Slams the foe with a tail etc. Strikes twice.",
		[459] = "Powerful, but leaves the user immobile the next turn.",
		[460] = "Tears the foe, and space. High critical-hit ratio.",
		[461] = "Faints to heal the HP, PP, and status of the next Pokémon.",
		[462] = "The more HP the foe has, the greater the power.",
		[463] = "Traps the foe in a vortex of fire for turns.",
		[464] = "Drags the foes into total darkness, inducing Sleep.",
		[465] = "Generates a shock wave that harshly lowers Sp. Def.",
		[466] = "A repulsive attack that may raise all stats.",
		[467] = "Vanishes, then strikes next turn. Ignores protection.",
		[468] = "Sharpens its claws to raise Attack and Accuracy.",
		[469] = "Evades wide- ranging attacks for one turn.",
		[470] = "Averages changes to Defense and Sp. Def with the foe.",
		[471] = "Averages changes to Attack and Sp. Atk with the foe.",
		[472] = "Defense and Sp. Def stats are swapped for 5 turns.",
		[473] = "An odd psychic wave that deals physical damage.",
		[474] = "Does double damage if the foe is poisoned.",
		[475] = "Sheds additional weight to sharply raise Speed.",
		[476] = "Scatters powder to make foes attack only the user.",
		[477] = "Makes the foe float. It is easier to hit for 3 turns.",
		[478] = "Held items lose their effects for 5 turns.",
		[479] = "Throws a rock to knock the foe down to the ground.",
		[480] = "This fierce blow always lands a critical hit.",
		[481] = "A bursting flame that does damage to all foes.",
		[482] = "Swamps all others with a wave of sludge. May also poison.",
		[483] = "Dances to raise Sp. Atk Sp. Def and Speed.",
		[484] = "Greater power the more the user outweighs the foe.",
		[485] = "A shock wave that hurts all Pokémon of the user's type.",
		[486] = "Hurls an orb that does more damage to a slower foe.",
		[487] = "Sprays water at the foe, changing it to a Water- type.",
		[488] = "Attacks in a cloak of flames. Raises Speed.",
		[489] = "Coils up to raise Attack, Defense and Accuracy.",
		[490] = "Attacks the foe's legs lowering its Speed.",
		[491] = "Sprays a hide- melting acid. Harshly lowers Sp. Def.",
		[492] = "The higher the foe's Attack the more damage caused.",
		[493] = "A beam that changes the foe's Ability to Simple.",
		[494] = "Makes the foe mimic the user, gaining its Ability.",
		[495] = "Helps out the target, letting it move next.",
		[496] = "A song that inflicts damage. Others can join in too.",
		[497] = "Does more damage every turn it is used.",
		[498] = "The foe's stat changes don't affect this attack's damage.",
		[499] = "Attacks with white haze that eliminates all stat changes.",
		[500] = "Greater power the more the user's stats are raised.",
		[501] = "Evades priority attacks for one turn.",
		[502] = "The user switches places with its partner.",
		[503] = "Shoots boiling water at the foe. May inflict a burn.",
		[504] = "Sharply raises offenses and Speed, but lowers defenses.",
		[505] = "Restores the target by up to half their max HP.",
		[506] = "Does double damage if the foe has a status problem.",
		[507] = "Takes the foe into the sky then drops it the next turn.",
		[508] = "Rotates its gears to raise Attack and Speed.",
		[509] = "The foe is thrown to switch it out or end wild battles.",
		[510] = "Burns up certain items, Burns up Berries, making them unusable.",
		[511] = "Suppresses the foe, making it move last.",
		[512] = "Does double damage if the user has no item.",
		[513] = "The user reflects the foe's type, copying it.",
		[514] = "An attack that does more damage if an ally fainted.",
		[515] = "The user faints to damage the foe equal to its HP.",
		[516] = "The user gives its held item to the foe.",
		[517] = "Powerful and sure to inflict a burn, but inaccurate.",
		[518] = "Attacks with a column of water. May make a rainbow.",
		[519] = "Attacks with a column of fire. May burn the grass.",
		[520] = "Attacks with a column of grass. May create a swamp.",
		[521] = "Attacks and rushes back to switch with a party Pokémon.",
		[522] = "While resisting, the user attacks the foe, lowering its Sp. Atk stat.",
		[523] = "Stomps down on the ground. Hits all and lowers Speed.",
		[524] = "This cold breath always lands a critical hit.",
		[525] = "Knocks away foe to switch it out or end wild battles.",
		[526] = "The user is roused. Ups Attack and Sp. Atk.",
		[527] = "Snares the foes with an electric net. Lowers Speed.",
		[528] = "An electrical tackle that also hurts the user.",
		[529] = "Spins its body like a drill. High critical-hit ratio.",
		[530] = "Attacks with brutal hits that strike twice.",
		[531] = "A sudden blow after a cute act. May cause flinching.",
		[532] = "Uses horns to drain half the damage inflicted.",
		[533] = "The foe's stat changes don't affect this attack's damage.",
		[534] = "Tears at the foe with sharp shells. May lower Defense.",
		[535] = "Greater power the more the user outweighs the foe.",
		[536] = "Circles the foe with leaves to damage and cut accuracy.",
		[537] = "Crushes the foe with its body. May cause flinching.",
		[538] = "Wraps its body in cotton. Drastically raises Defense.",
		[539] = "Looses a pitch- black shock wave. May lower accuracy.",
		[540] = "An odd psychic wave that deals physical damage.",
		[541] = "Strikes the foe with its tail 2 to 5 times.",
		[542] = "Traps the foe in a fierce wind. May cause confusion.",
		[543] = "A charge using guard hair. It hurts the user a little.",
		[544] = "Throws two steel gears that strike twice.",
		[545] = "Torches all others with scarlet flames. May burn.",
		[546] = "The type varies with the kind of Drive held.",
		[547] = "Attacks with an ancient song. May induce sleep.",
		[548] = "Cuts with a long horn that does physical damage.",
		[549] = "Blows very cold air at the foes. It lowers their Speed.",
		[550] = "Strikes with a great amount of lightning. May paralyze.",
		[551] = "Engulfs the foe in a blue flame. May inflict a burn.",
		[552] = "Dances cloaked in flames. May raise Sp. Atk.",
		[553] = "A powerful 2-turn move that may paralyze the foe.",
		[554] = "A powerful 2-turn move that may inflict a burn.",
		[555] = "Yells and rants at the foe lowering its Sp. Atk.",
		[556] = "Drops large icicles on the foe. May cause flinching.",
		[557] = "Very powerful, but lowers Defense, Sp. Def and Speed.",
		[558] = "Summons a fireball. Works well with a thunderbolt.",
		[559] = "Summons a thunderbolt. Works well with a fireball.",
		[560] = "This attack does Fighting- and Flying-type damage.",
		[561] = "Evades damaging moves. Only works on 1st turn.",
		[562] = "Lets out a loud belch. Must eat a Berry to use it.",
		[563] = "Ups the Attack and Sp. Atk of Grass- type Pokémon.",
		[564] = "Weaves a sticky net that slows foes switching in.",
		[565] = "If the foe is KO'd, Attack is drastically raised.",
		[566] = "Vanishes, then strikes next turn. Ignores protection.",
		[567] = "Goes trick-or- treating, adding Ghost type to foe.",
		[568] = "Intimidates the foe, to cut Attack and Sp. Atk.",
		[569] = "Electrifies Normal-type moves with charged atoms.",
		[570] = "Damages all others and restores by half of it.",
		[571] = "Puts a curse on the foe, adding the Grass type.",
		[572] = "Stirs up a violent storm of petals to attack all.",
		[573] = "Super effective on Water- types. May cause frostbite.",
		[574] = "The user lets out a charming cry that cannot be evaded.",
		[575] = "Lowers the foe's Attack and Sp. Atk, then switches out.",
		[576] = "Swaps all stat changes that affect the target.",
		[577] = "A sweet kiss that absorbs over half the damage inflicted to restore HP.",
		[578] = "Evades status moves for one turn.",
		[579] = "Raises the Defense of Grass-type Pokémon.",
		[580] = "The ground turns to grass for 5 turns. Restores HP.",
		[581] = "Covers the ground with mist for 5 turns. Blocks status.",
		[582] = "Electrifies the foe, making its next move Electric-type.",
		[583] = "The foe is roughed up by the user. This may lower the foe's Attack.",
		[584] = "The user stirs up a fairy wind and strikes the foe with it.",
		[585] = "The foe is attacked with the power of the moon. This may lower its Sp. Atk.",
		[586] = "Attacks everything with a destructive sound wave.",
		[587] = "Locks down the battlefield preventing escape next turn.",
		[588] = "Evades damage and Evades damage and harshly lowers Attack on contact.",
		[589] = "The target loses its will to fight. This lowers its Attack.",
		[590] = "Shares a secret with the foe, lowering Sp. Atk.",
		[591] = "Whips up a storm of diamonds. May up Defense.",
		[592] = "Immerses the foe in heated steam. May inflict a burn.",
		[593] = "Uses a hyperspace hole to attack. Ignores protection.",
		[594] = "Hits 2-5 times with throwing stars. Always goes first.",
		[595] = "Breathes a special, hot fire. Lowers Sp. Atk.",
		[596] = "Evades attack, and damages the foe if struck.",
		[597] = "Raises the Sp. Def of a partner Pokémon.",
		[598] = "Exposes the foe to a pulse that harshly cuts Sp. Atk.",
		[599] = "Lowers the Attack, Sp. Atk and Speed of poisoned foes.",
		[600] = "Damages the foe if it uses a Fire- type move.",
		[601] = "Raises Sp. Atk, Sp. Def and Speed on the 2nd turn.",
		[602] = "Raises the defenses of those with Plus or Minus.",
		[603] = "Doubles the amount of Prize Money received.",
		[604] = "Electrifies the ground for 5 turns. Prevents sleep.",
		[605] = "The user damages opposing Pokémon by emitting a powerful flash.",
		[606] = "Congratulates you on your special day.",
		[607] = "The user and ally hold hands making them happy.",
		[608] = "Lowers the foe's Attack before it can move.",
		[609] = "Rubs its cheeks against the foe, paralyzing it.",
		[610] = "An attack that leaves the foe with at least 1 HP.",
		[611] = "The foe is infested and attacked for turns.",
		[612] = "A hard punch that raises the user's Attack.",
		[613] = "A wave that absorbs over half the damage inflicted.",
		[614] = "Can hit a Flying foe, then knocks it to the ground.",
		[615] = "Those hit by the wave can no longer escape.",
		[616] = "Gathers the energy of the land to attack every foe.",
		[617] = "Fires a great beam of light that also hurts the user.",
		[618] = "Beams of glowing blue light blast both foes.",
		[619] = "Fearsome blades of stone attack both foes.",
		[620] = "Drops out of the sky. This lowers the user's defenses.",
		[621] = "Ignores protection, but lowers the user's Defense.",
		[622] = "Restores the user's HP. More HP in a sandstorm.",
		[623] = "Hits hard and first. Only works first turn.",
		[624] = "Protects user and poisons foes on contact.",
		[625] = "After being hit, a foe can no longer escape.",
		[626] = "Swings the arms to strike It ignores stat changes.",
		[627] = "Sings with bubbles. Cures burns on contact.",
		[628] = "Swings with a heavy fist. Lowers the user's Speed.",
		[629] = "Restores the target's HP. More HP on Grassy Terrain.",
		[630] = "Slams hard into the foe with its entire body.",
		[631] = "Restores HP equal to the foe's Attack and lowers it.",
		[632] = "Charges first turn, then chops with a blade of light.",
		[633] = "Attacks with a flurry of small leaves.",
		[634] = "Makes the foe attack the spotlighted Pokémon.",
		[635] = "Attacks with a thread that poisons and lowers Speed.",
		[636] = "Guarantees the next move will be a critical hit.",
		[637] = "Raises the offenses of those with Plus or Minus.",
		[638] = "Chops the throat to disable sound moves for 2 turns.",
		[639] = "Explodes on a foe, but restores ally's HP.",
		[640] = "Strangles the foe with a chain. The foe can't escape.",
		[641] = "The ground turns weird for 5 turns. Blocks priority.",
		[642] = "Lunges at the foe to lower its Attack stat.",
		[643] = "Whips the foe with fire lowering its Defense.",
		[644] = "Greater power the more the user's stats are raised.",
		[645] = "Burns out the user fully removing the Fire type.",
		[646] = "Swaps user's Speed with the target's.",
		[647] = "Hits with an accurate horn that never misses.",
		[648] = "Cures the foe's status to restore HP.",
		[649] = "Dances with mystical power. Matches user's first type.",
		[650] = "Hits with a ray that nullifies the foe's Ability.",
		[651] = "An intense kick from the tropics. Lowers Attack.",
		[652] = "Orders the target to use its last move again.",
		[653] = "Heats beak to attack last. Burns foe on contact.",
		[654] = "Makes a huge noise to attack, but lowers Defense.",
		[655] = "Swings its whole body like a hammer to damage.",
		[656] = "Violently swings around to hurt everyone nearby.",
		[657] = "Weakens all attacks, but only usable with snow.",
		[658] = "Sets a shell trap that damages on contact.",
		[659] = "Unleashes a strong beam, but harshly lowers Sp. Atk.",
		[660] = "Chomps with psychic fangs. Destroys any barriers.",
		[661] = "Power is doubled if the user's previous move failed.",
		[662] = "Strikes with a haunted bone. May lower Defense.",
		[663] = "Hits with a high- speed rock that always goes first.",
		[664] = "Slams the foe with water. Can lower Defense.",
		[665] = "A high power laser that forces recharge next turn.",
		[666] = "Steals the target's stat boosts, then attacks.",
		[667] = "A sun-fueled strike that ignores Abilities.",
		[668] = "A moon-powered beam that ignores Abilities.",
		[669] = "The user tears up, lowering Attack and Sp. Atk.",
		[670] = "An electrified impact that can cause flinching.",
		[671] = "Halves the foe's HP with the power of nature.",
		[672] = "An attack that changes with Memories.",
		[673] = "It explodes the user's head to damage everything around.",
		[674] = "Hits with electrical fists. Normal moves turn Electric.",
		[675] = "User's highest attack stat determines its category.",
		[676] = "Electric bursts always go first and raise evasion.",
		[677] = "A huge electrified wave that may paralyze the foes.",
		[678] = "Floats in air and dives at angle. May cause flinching.",
		[679] = "Pikachu's love increases its power. It never misses.",
		[680] = "Shoots bubbles that absorb all the damage inflicted.",
		[681] = "Shoots a jolt of electricity. This always paralyzes.",
		[682] = "Cloaks in fire and charges. This always inflicts a burn.",
		[683] = "Force puts up a wall of light to weaken special moves.",
		[684] = "Acts bad and puts up a wall to weaken physical moves.",
		[685] = "A stalk scatters seeds that drain HP every turn.",
		[686] = "Attacks with a crystal. Eliminates all stat changes.",
		[687] = "Wraps foe with a whirlwind of scent. Heals party's status.",
		[688] = "Eevee's love increases its power. It never misses.",
		[689] = "The user spins and hits with its arms. May cause flinch.",
		[690] = "Unleashes core energy. 2x against a Dynamaxed foe.",
		[691] = "The user ignores effects that draw in moves.",
		[692] = "Prevents the user and the target from escaping.",
		[693] = "Consumes the user's Berry, then sharply raises Defense.",
		[694] = "Raises all of the user's stats but prevents escape.",
		[695] = "Lowers the foe's Speed and makes it weak to Fire.",
		[696] = "Magic powder changes the target into a Psychic- type.",
		[697] = "The user attacks twice. Two targets are hit once each.",
		[698] = "All Pokémon have teatime and eat their Berries.",
		[699] = "Prevents the foe's escape. Lowers defenses every turn.",
		[700] = "Power is doubled if the user moves before the foe.",
		[701] = "Power is doubled if the user moves before the foe.",
		[702] = "The user swaps effects on either side of the field.",
		[703] = "The user uses some of its HP to raise all its stats.",
		[704] = "Does more damage the higher the user's Defense.",
		[705] = "The user sharply raises the target's Attack and Sp. Atk.",
		[706] = "Plays a drum to attack. The foe's Speed is lowered.",
		[707] = "Snares the target in a snap trap for four to five turns.",
		[708] = "Launches a fiery ball at the target. It may cause a burn.",
		[709] = "Strikes as a sword. Deals 2x damage to a Dynamaxed foe.",
		[710] = "Attacks as a shield. Deals 2x damage to a Dynamaxed foe.",
		[711] = "Raises Speed to attack. The Type is based on its form.",
		[712] = "Swings its tail and attacks. This lowers Attack stats.",
		[713] = "The user pokes the target with a pointed branch.",
		[714] = "The user twangs its guitar, causing strong vibrations.",
		[715] = "Attacks with tart apple acid to lower the foe's Sp. Def.",
		[716] = "Drops an apple from above. Lowers the foe's Defense.",
		[717] = "Attacks with spirit-breaking force. Lowers Sp. Atk.",
		[718] = "Emits a strange steam to potentially confuse the foe.",
		[719] = "Scatters water to restore the HP of itself and allies.",
		[720] = "Protects itself, harshly lowering Defense on contact.",
		[721] = "Bows to stab the foe with hair. It never misses.",
		[722] = "Attacks with a thick leek. The user must then rest.",
		[723] = "Eternatus' strongest move. The user rests next turn.",
		[724] = "Fires a beam of steel from its body. It hurts the user.",
		[725] = "Power goes up and damages all foes on Psychic Terrain.",
		[726] = "Destroys terrain. Fails if ground isn't terrain.",
		[727] = "Shoots scales 2 to 5 times. Ups Speed, lowers Defense.",
		[728] = "A 2-turn move that raises Sp. Atk before attacking.",
		[729] = "Deals better of physical and special damage. May poison.",
		[730] = "Hit everything and faint. Powers up on Misty Terrain.",
		[731] = "Gliding on ground, hits. Goes first on Grassy Terrain.",
		[732] = "This move's power doubles when on Electric Terrain.",
		[733] = "Type and power changes depending on the terrain.",
		[734] = "User skitters behind foe to attack. Lowers foe's Sp. Atk.",
		[735] = "Foes that have stats upped during the turn get burned.",
		[736] = "If user's stats were lowered this turn, power is doubled.",
		[737] = "Control foe's item to attack. Fails if foe has no item.",
		[738] = "Highly acidic gas melts items held by surrounding Pokémon.",
		[739] = "Properly coaches allies to up their Attack and Defense.",
		[740] = "Attacks and rushes back to switch with a party Pokémon.",
		[741] = "A 3-kick attack that gets more powerful with each hit.",
		[742] = "User slams the target with wings and hits twice in a row.",
		[743] = "Throws scorching sand at the target. May leave a burn.",
		[744] = "Heals HP and status of itself and allies in battle.",
		[745] = "Mastering the Dark style, strikes with a critical hit.",
		[746] = "Mastering the Water style, strikes with 3 critical hits.",
		[747] = "Traps the foe in a cage of electricity for turns.",
		[748] = "The higher the user's HP, the more damage caused.",
		[749] = "Shoots psychic power from the eyes. May frostbite.",
		[750] = "An attack fueled by your wrath. May cause flinching.",
		[751] = "Uses a lightning- like kick to hit. Lowers foe's Defense.",
		[752] = "Hurls a blizzard- cloaked icicle lance at foes.",
		[753] = "Sends a frightful amount of small ghosts at foes.",
		[754] = "Attacks with psychic power. Foe's last move has 3 PP cut.",
		[755] = "High critical-hit ratio. May paralyze, poison or sleep.",
		[756] = "Hits a foe with psychic energy. May raise Defense.",
		[757] = "The user swaps its Attack and Defense stats.",
		[758] = "Swings a stone axe at the foe. Splinters scatter all around.",
		[759] = "Wraps a foe in fierce winds. Varies with the user's form.",
		[760] = "A mysterious power strikes, raising the user's Sp. Atk.",
		[761] = "A rampage of 2 to 3 turns that confuses the user.",
		[762] = "A slam shrouded in water. It also hurts the user.",
		[763] = "A user-hurting blast of amassed chlorophyll.",
		[764] = "Giant chunks of ice damage the foe. It may flinch.",
		[765] = "Dances to raise Attack, Defense and Speed.",
		[766] = "A full-body tackle. Lowers the user's defensive stats.",
		[767] = "Can poison on impact. Powers up against a poisoned foe.",
		[768] = "High critical-hit ratio. Raises the user's Speed.",
		[769] = "A spine-chilling resentment. Lowers the foe's Attack.",
		[770] = "The user hardens their skin, sharply raising its Defense.",
		[771] = "High critical-hit ratio. May lower Defense or flinch.",
		[772] = "Hurts a foe harder if it has an ailment. May leave a burn.",
		[773] = "Leaves spikes under the foe.",
		[774] = "Hits with brutal, cold winds. May lower foes' Speed.",
		[775] = "Hits with a brutal tempest. May inflict paralysis.",
		[776] = "Hits with brutally hot sand. May inflict a burn.",
		[777] = "The user heals and cures itself and its ally.",
		[778] = "Cures status problems and raises offensive stats.",
		[779] = "If the user's Terastallized, it hits with its Tera type.",
		[780] = "Protects itself, lowering Speed on contact.",
		[781] = "May miss and hurt the kicker. May cause confusion.",
		[782] = "This move deals more damage for each defeated ally.",
		[783] = "A mind-affecting light harshly lowers Sp. Def.",
		[784] = "Raises the user's stats depending on Tatsugiri.",
		[785] = "A punch is thrown at blinding speed to strike first.",
		[786] = "Sharply ups target's Attack, harshly lowers its Defense.",
		[787] = "Furiously strains its legs. Harshly lowers user's Speed.",
		[788] = "The user's fellows hit one to ten times in a row.",
		[789] = "Ice-covered feet hit a foe and destroy the terrain.",
		[790] = "Foe attacks next turn can't miss and do double damage.",
		[791] = "Revives a fainted party member and heals half its HP.",
		[792] = "Hurts foe every turn. Double damage to Steel and Water.",
		[793] = "Hits target with splashes of water 3 times in a row.",
		[794] = "Erases trap moves and Leech Seed. Poisons all foes.",
		[795] = "Changes user's and ally's Ability into the target's.",
		[796] = "Sharply raises offenses and Speed by using its own HP.",
		[797] = "User slashes the foe after kowtowing. It never misses.",
		[798] = "Rigged bouquet. Always gets a critical hit, never missing.",
		[799] = "Flames scorch the target. Raises the user's Sp. Atk.",
		[800] = "Hits with light, fluid dance steps. Ups the user's Speed.",
		[801] = "Tackle that breaks barriers. User's form determines type.",
		[802] = "Lowers the user's Sp. Atk. Money is recovered after.",
		[803] = "Summons a ruinous disaster and cuts half the foe's HP.",
		[804] = "Prehistoric explosion that's stronger if super effective.",
		[805] = "Futuristic electricity. It's stronger if super effective.",
		[806] = "Creates a Substitute for itself before switching out.",
		[807] = "Bad joke summons hailstorm. The user also switches out.",
		[808] = "User tidies up hazards and raises its Attack and Speed.",
		[809] = "Summons a hailstorm that strikes every turn.",
		[810] = "The user pounces on the foe, lowering its Speed.",
		[811] = "The user attacks suddenly, raising its Speed.",
		[812] = "A shower with ice- cold water lowers the target's Attack.",
		[813] = "A spinning pointed part bypasses a foe's Protect.",
		[814] = "Mystical eye-beams that hit the target twice in a row.",
		[815] = "The more the user has been hit, the stronger the move.",
		[816] = "Shoots armor. This lowers the user's defensive stats.",
		[817] = "A slash that absorbs half the damage inflicted.",
		[818] = "Discharges all electricity, losing the Electric type.",
		[819] = "Swings a huge hammer. Can't be used twice in a row.",
		[820] = "Retaliates against the foe that last damaged the user.",
		[821] = "Pressurized water cut with a high critical-hit ratio.",
		[822] = "---",
		[823] = "---",
		[824] = "---",
		[825] = "---",
		[826] = "---",
		[827] = "This move's power increases when on Electric Terrain.",
		[828] = "This move's power increases under harsh sunlight.",
		[829] = "Unleashes the blood moon. Can't be used twice in a row.",
		[830] = "Absorbs half the damage inflicted. May cause a burn.",
		[831] = "Lowers the foe's Speed each turn for 3 turns.",
		[832] = "Type changes with held mask. High critical-hit ratio.",
		[833] = "Gathers electricity, then fires a high- voltage shot.",
		[834] = "In Terapagos's Stellar Form, it hits all foes.",
		[835] = "Shoots a beam of light. Sometimes twice as strong.",
		[836] = "Evades attack, and burns the foe if struck.",
		[837] = "Attacks first if the foe is readying an attack.",
		[838] = "Wields light to cleave the foe. Ignores protection.",
		[839] = "Launches particle blades at the target. Strikes twice.",
		[840] = "The more HP the foe has, the greater the power.",
		[841] = "Raises allies' critical-hit ratio, sharply if Dragons.",
		[842] = "Confuses foe if its stats were raised this turn.",
		[843] = "Power is doubled if the user's previous move failed.",
		[844] = "An electrified slam. If it misses, the user is hurt.",
		[845] = "Sound waves that damage and prevent healing for 2 turns.",
		[846] = "Makes the target flinch if readying a priority move.",
		[847] = "A corrosive chain attack that may badly poison.",
	}

	local function isPlaceholderText(text)
		return type(text) == "string" and text:lower():find("not implemented", 1, true) ~= nil
	end

	-- The Tracker lists the Gen 4-9 moves as unfinished ("Not implemented yet.").
	-- This ROM implements them, so show the game's own description instead.
	local function syncMoveText()
		local descriptions = Resources and Resources.Game and Resources.Game.MoveDescriptions
		local moves = MoveData and MoveData.Moves
		-- Quick exit: nothing to do if the last move already has its text
		local lastMove = moves and moves[847]
		local lastDesc = descriptions and descriptions[847]
		if not (lastMove and isPlaceholderText(lastMove.summary))
			and not (type(lastDesc) == "table" and isPlaceholderText(lastDesc.Description)) then
			local first = moves and moves[355]
			if not (first and isPlaceholderText(first.summary)) then return end
		end
		for id, text in pairs(MOVE_TEXT) do
			local entry = descriptions and descriptions[id]
			if type(entry) == "table" and isPlaceholderText(entry.Description) then entry.Description = text end
			local move = moves and moves[id]
			if type(move) == "table" and (isPlaceholderText(move.summary) or move.summary == nil or move.summary == "") then
				move.summary = text
			end
		end
	end

	-- True if the Tracker still has the "unfinished move" blanks for this move
	local function isBlankMove(move)
		return type(move) == "table" and (move.pp == "0" or move.pp == nil)
	end

	-- For those same moves the Tracker has no type, power, accuracy or PP.
	-- Read the real values from the ROM, the same way the Tracker does for
	-- randomized games.
	local function syncMoveStats()
		if not MoveData or not MoveData.Moves or type(MoveData.readMoveInfoFromMemory) ~= "function" then return end
		if not GameSettings or not GameSettings.gBattleMoves or not Memory or not Memory.readbyte then return end
		local moves = MoveData.Moves
		if not (isBlankMove(moves[355]) or isBlankMove(moves[775]) or isBlankMove(moves[847])) then return end
		local addresses = (Program and Program.Addresses) or {}
		local size = addresses.sizeofBattleMove or 0xC
		local flagsOffset = addresses.offsetBattleMoveFlags or 0x8
		local changed = false
		for id = 355, 847 do
			local move = moves[id]
			if isBlankMove(move) then
				local ok, info = pcall(MoveData.readMoveInfoFromMemory, id)
				if ok and type(info) == "table" and tonumber(info.pp) and tonumber(info.pp) > 0 then
					move.type = info.type or move.type
					move.pp = info.pp
					move.accuracy = info.accuracy or move.accuracy
					if info.power == "1" then
						move.power = "VAR" -- power worked out in battle
						move.variablepower = true
					else
						move.power = info.power or move.power
					end
					local base = GameSettings.gBattleMoves + id * size
					local flags = Memory.readbyte(base + flagsOffset)
					if type(flags) == "number" then move.iscontact = (flags % 2) == 1 end
					local priority = Memory.readbyte(base + 7)
					if type(priority) == "number" then
						if priority >= 128 then priority = priority - 256 end
						if priority > 0 then move.priority = "+ " .. priority
						elseif priority < 0 then move.priority = "-- " .. (-priority)
						else move.priority = "0" end
					end
					changed = true
				end
			end
		end
		if changed and Program and Program.redraw then Program.redraw(true) end
	end

	local function categoryName(value)
		if not MoveData or not MoveData.Categories then return nil end
		if value == CAT_PHYSICAL then return MoveData.Categories.PHYSICAL end
		if value == CAT_SPECIAL then return MoveData.Categories.SPECIAL end
		if value == CAT_STATUS then return MoveData.Categories.STATUS end
		return nil
	end

	-- Reads a move's category value (0-3) from the ROM, or nil if it can't be read
	local function readCategory(moveId)
		if not GameSettings or not GameSettings.gBattleMoves or not Memory or not Memory.readbyte then
			return nil
		end
		local addresses = (Program and Program.Addresses) or {}
		local size = addresses.sizeofBattleMove or 0xC
		local flagsOffset = addresses.offsetBattleMoveFlags or 0x8
		local flags = Memory.readbyte(GameSettings.gBattleMoves + moveId * size + flagsOffset)
		if type(flags) ~= "number" then return nil end
		return math.floor(flags / 64) % 4
	end

	local function romHasSplit()
		return readCategory(FIRE_PUNCH) == CAT_PHYSICAL and readCategory(SHADOW_BALL) == CAT_SPECIAL
	end

	local function totalMoves()
		if MoveData.getTotal then
			return MoveData.getTotal()
		end
		return #MoveData.Moves
	end

	-- True if the Tracker already shows the ROM's categories
	local function isSynced()
		if not MoveData.IsRand or MoveData.IsRand.moveCategory ~= true then return false end
		local firePunch = MoveData.Moves[FIRE_PUNCH]
		local shadowBall = MoveData.Moves[SHADOW_BALL]
		local last = MoveData.Moves[totalMoves()]
		if not firePunch or firePunch.category ~= MoveData.Categories.PHYSICAL then return false end
		if not shadowBall or shadowBall.category ~= MoveData.Categories.SPECIAL then return false end
		if last and categoryName(readCategory(totalMoves())) and last.category ~= categoryName(readCategory(totalMoves())) then
			return false
		end
		return true
	end

	local function syncCategories()
		if not MoveData or not MoveData.Moves or not MoveData.Categories then return end
		if not romHasSplit() or isSynced() then return end
		for moveId = 1, totalMoves(), 1 do
			local move = MoveData.Moves[moveId]
			local category = categoryName(readCategory(moveId))
			if move and category then
				move.category = category
			end
		end
		-- Tells the Tracker to use each move's own category instead of its type
		MoveData.IsRand = MoveData.IsRand or {}
		MoveData.IsRand.moveCategory = true
		if Program and Program.redraw then
			Program.redraw(true)
		end
	end

	local function safeSync()
		pcall(syncCategories)
		pcall(function()
			if romHasSplit() then
				syncItemNames()
				syncAbilityText()
			end
		end)
		pcall(function()
			if romHasSplit() then syncMoveText() end
		end)
		pcall(function()
			if romHasSplit() then syncMoveStats() end
		end)
	end

	function self.startup()
		safeSync()
	end

	-- Runs about twice a second. The check is two byte reads, and the full sync
	-- only runs when the Tracker's move data was rebuilt (new ROM, other
	-- extensions starting up after this one).
	function self.afterProgramDataUpdate()
		safeSync()
	end

	function self.unload()
	end

	return self
end
return NatDexSplitCategories
