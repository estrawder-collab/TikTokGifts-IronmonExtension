# Nat. Dex Abilities patch (optional)

An optional add-on for people who play Nat. Dex FireRed 1.2.2. The TikTok Gifts extension does not need any of it.

What it changes, how to set it up and what to know first: see [Optional: Nat. Dex Abilities patch](../../README.md#optional-nat-dex-abilities-patch) in the main README.

## Files

| File | What it is |
| --- | --- |
| `pokefirered_natdex_1.2.2_abilities.bps` | The ROM patch. Apply it to a Nat. Dex FireRed 1.2.2 ROM (CRC32 `34AAFED7`). The patched ROM has CRC32 `EBD4339B`. |
| `randomizer_natdex_1.2.2_abilities.jar` | The randomizer that matches the patched ROM. Use it only with the patched ROM. |
| `NatDexSplitCategories.lua` | An Ironmon Tracker extension that makes the Tracker show the patched ROM's moves, abilities and items correctly. |
| `randomizer-license-GPL-3.0.txt` | The randomizer's license. |
| `randomizer-offsets-fire-red-1.1.ini` | The randomizer settings that were regenerated for the patched ROM, for anyone who wants to see or reuse them. |

No ROM is included. You supply your own game file.

## About the randomizer

`randomizer_natdex_1.2.2_abilities.jar` is a modified copy of `randomizer_natdex_1.2.2.jar`, the randomizer that ships with CyanSMP64's [NatDexExtension](https://github.com/CyanSMP64/NatDexExtension). That is a build of [Universal Pokemon Randomizer ZX](https://github.com/Ajarmar/universal-pokemon-randomizer-zx) by Ajarmar, with significant contributions from darkeye and cleartonic, based on the Universal Pokemon Randomizer by Dabomstew. It is free software under the GNU General Public License, version 3, and this copy is shared under the same license. The source code is available from the project linked above.

It differs from the copy it was made from in three places:

1. **`config/gen3_offsets.ini`:** the `[Fire Red (U) 1.1]` section was regenerated for the patched ROM, because the patch moves the game's data. The new section is in `randomizer-offsets-fire-red-1.1.ini`.
2. **`constants/GlobalConstants.class`:** the 482 moves the patch implements were taken off the list of moves the randomizer never hands out.
3. **`constants/Gen3Constants.class`:** the patch's 50 held items and five Exp. Candies were taken off the list of items the randomizer never hands out.

Because of the first change, this randomizer no longer reads an unpatched FireRed 1.1 or Nat. Dex 1.2.2 ROM. Keep the original randomizer for those.

It is not made or supported by the Nat. Dex project or the Universal Pokemon Randomizer ZX team. Please don't report problems with it to them.
