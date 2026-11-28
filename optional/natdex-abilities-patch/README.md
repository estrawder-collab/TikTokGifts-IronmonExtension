# Nat. Dex Abilities patch (optional)

An optional add-on for people who play Nat. Dex FireRed 1.2.2 or Nat. Dex Emerald 1.2.2. The TikTok Gifts extension does not need any of it.

What it changes, how to set it up and what to know first: see [Optional: Nat. Dex Abilities patch](../../README.md#optional-nat-dex-abilities-patch) in the main README.

## Files

| File | What it is |
| --- | --- |
| `pokefirered_natdex_1.2.2_abilities.bps` | The ROM patch for FireRed. Apply it to a Nat. Dex FireRed 1.2.2 ROM (CRC32 `34AAFED7`). The patched ROM has CRC32 `1F90D684`. |
| `pokeemerald_natdex_1.2.2_abilities.bps` | The ROM patch for Emerald. Apply it to a Nat. Dex Emerald 1.2.2 ROM (CRC32 `7B4291C4`). The patched ROM has CRC32 `46D3F144`. |
| `randomizer_natdex_1.2.2_abilities.jar` | The randomizer that matches the patched ROMs. One file for both games. Use it only with the patched ROMs. |
| `NatDexSplitCategories.lua` | An Ironmon Tracker extension that makes the Tracker show the patched FireRed ROM's moves, abilities and items correctly. Not tried on Emerald yet. |
| `randomizer-license-GPL-3.0.txt` | The randomizer's license. |
| `randomizer-offsets-fire-red-1.1.ini`, `randomizer-offsets-emerald.ini` | The randomizer settings that were regenerated for the patched ROMs, for anyone who wants to see or reuse them. |

No ROM is included. You supply your own game file.

The FireRed patch was updated on 28 November 2026 (five move animations now use battle backgrounds the game has). The earlier patch made a ROM with CRC32 `EBD4339B`; that ROM still works with this randomizer.

## About the randomizer

`randomizer_natdex_1.2.2_abilities.jar` is a modified copy of `randomizer_natdex_1.2.2.jar`, the randomizer that ships with CyanSMP64's [NatDexExtension](https://github.com/CyanSMP64/NatDexExtension). That is a build of [Universal Pokemon Randomizer ZX](https://github.com/Ajarmar/universal-pokemon-randomizer-zx) by Ajarmar, with significant contributions from darkeye and cleartonic, based on the Universal Pokemon Randomizer by Dabomstew. It is free software under the GNU General Public License, version 3, and this copy is shared under the same license. The source code is available from the project linked above.

It differs from the copy it was made from in four places:

1. **`config/gen3_offsets.ini`:** the `[Fire Red (U) 1.1]` and `[Emerald (U)]` sections were regenerated for the patched ROMs, because the patch moves the game's data. The new sections are in the two `randomizer-offsets-*.ini` files.
2. **`constants/GlobalConstants.class`:** the 482 moves the patch implements were taken off the list of moves the randomizer never hands out.
3. **`constants/Gen3Constants.class`:** the patch's 50 held items and five Exp. Candies were taken off the list of items the randomizer never hands out, and 235 abilities the patch implements were taken off the list of abilities it never hands out. Forecast, Cacophony, Hunger Switch and the seven abilities that are still placeholders stay on that list.
4. **`romhandlers/Gen3RomHandler.class`:** the highest ability number it rolls was raised from 319 to 320, so the last ability in the ROM (Aura Guard) can be handed out.

Because of the first change, this randomizer no longer reads an unpatched FireRed 1.1, Emerald or Nat. Dex 1.2.2 ROM. Keep the original randomizer for those.

It is not made or supported by the Nat. Dex project or the Universal Pokemon Randomizer ZX team. Please don't report problems with it to them.
