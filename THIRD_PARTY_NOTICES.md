# Third-party assets

## Quaternius (CC0, included in this repository)
Cute Fish Pack (Feb 2020), Ultimate Nature Pack (Jun 2019), Medieval Village Pack (Dec 2020) and Ultimate Animated Character Pack (Nov 2019).

Author: Quaternius, https://quaternius.com/

Each pack folder keeps the supplied `License.txt`, which identifies the assets as **CC0 1.0 Universal** (public domain dedication): https://creativecommons.org/publicdomain/zero/1.0/

The game reuses the fish, nature and village models, normalizes instance scales and overrides some fish colors. The cutting blade reuses an existing imported Metal surface without changing its geometry. Original asset files for those three packs were not modified.

### Fallback characters (Ultimate Animated Character Pack)
`assets/Quaternius Ultimate Animated Characters/` holds seven characters from the Ultimate Animated Character Pack: `Casual_Male`, `Casual2_Female`, `Suit_Male`, `Chef_Female`, `Cowboy_Male`, `Doctor_Female_Young` and `OldClassy_Male`. They are the pack's own glTF files, repacked as binary `.glb` (the embedded buffer is moved into the GLB container, nothing else is changed). CC0 allows this, and the supplied `License.txt` sits next to them.

The game uses these characters only when the itHappy models below are not present locally. See the "Characters" section of `README.md`.

Pack page: https://quaternius.com/packs/ultimatedanimatedcharacter.html

## itHappy Creative Characters FREE (not included in this repository)
Publisher: ITHappy Studios, https://ithappystudios.com/

Pack page: https://ithappystudios.com/free/creative-characters-free/

Also listed on the Unity Asset Store under the Standard Unity Asset Store EULA: https://assetstore.unity.com/packages/3d/characters/humanoids/creative-characters-free-animated-pack-304841

The pack is governed by the **ITHappy Studios Free Asset Usage Policy**: https://ithappystudios.com/free-asset-usage-policy/

Summary of that policy (read the original, it is the only authoritative text):

- Personal and commercial projects are allowed, and an unlimited number of final products may be made. No credit is required.
- You may not distribute the assets "as is", not even for free.
- You may not modify the assets or create derivative works, or distribute modified versions, unless the result is part of a Final Product. A Final Product is a completed work that incorporates the assets but does not distribute the assets themselves in their original form.
- The assets may not be used in on demand or build it yourself tools.

What that means here:

- `assets/itHappy Creative Characters Free/` (the original pack) and `assets/itHappy Characters GLB/` (`Pescador.glb` and `Cliente 1.glb` to `Cliente 10.glb`, assembled from the pack's parts in Blender) are modified derivatives of the pack. Both folders are excluded from Git and must never be committed or published as loose files.
- A compiled build of the game (for example a TestFlight build or an exported app) is a Final Product and may contain them.
- Anyone who wants the same characters as the video builds them locally from their own copy of the pack. See `docs/CHARACTERS_SETUP.md`.

## Audio
Gameplay tones and the simple background melody are synthesized by the game's own GDScript. No external recordings or music files were added.

## UI and shaders
The small SVG interface icons, interface styling, ground/wood/water/interaction-zone shaders and primitive board/effect geometry are authored for this project. The customer request-bubble SVG is also original project artwork. No external icon pack or new machine model was introduced. Supplied locomotion is duplicated and made in-place only at runtime; source GLBs and their animation data remain unchanged.
