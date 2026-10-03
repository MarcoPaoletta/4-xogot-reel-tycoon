"""Assemble the fisherman and the ten customers used by Reel Tycoon.

Run it headless with Blender (tested with 5.2, needs 4.2 or newer for the exporter options):

    blender -b "<path to Creative_Characters_Free.blend>" -P tools/build_characters.py -- --out "assets/itHappy Characters GLB"

Optional: add  --only "Pescador" "Cliente 3"  to build a subset.

Input: the .blend that ships with the official itHappy Creative Characters FREE pack.
Output: Pescador.glb and Cliente 1.glb to Cliente 10.glb in the folder given by --out.

The script only reads the path you pass on the command line and only writes to --out.
It never changes the .blend on disk. The generated GLBs are derivatives of the itHappy
assets: keep them out of Git and do not redistribute them (see docs/CHARACTERS_SETUP.md).

What it does for each character:
  1. Copies the shared rig ("Skeleton", 44 bones, 30 NLA animation tracks) and the listed parts.
  2. Resets the part transforms (in the pack they sit in a display lineup) and binds each part
     to the copied rig.
  3. Applies the per character colour tints (hue and value shifts of the texture atlas). The
     glTF exporter cannot follow a Hue/Saturation node, so the tint is baked into a copy of the
     atlas texture, using the same maths as the Hue/Saturation/Value node of Blender.
  4. Exports a GLB with the rig, the skin and every NLA track as an animation (30 clips), Y up.
"""
import argparse
import os
import sys

import bpy
import numpy as np
from mathutils import Matrix

RIG = "Skeleton"
ATLAS = "Textures_4.png"
BASE_MATERIAL = "Color"
REQUIRED_CLIPS = ["Idle_Breathing", "Walk_Forward", "Run_Forward"]

# Parts per character, and the (hue, value) tint of each tinted part. Hue 0.5 is neutral.
# Saturation is never changed. Parts that are not listed under "tints" keep the original atlas.
CHARACTERS = {
	"Pescador": {
		"parts": ["Body_010", "Hat_010", "Male_emotion_happy_002", "Moustache_002", "Outerwear_036", "Pants_010", "Shoe_Slippers_002", "Socks_008", "T_Shirt_009"],
		"tints": {},
	},
	"Cliente 1": {
		"parts": ["Body_010", "Glasses_004", "Hairstyle_male_010", "Male_emotion_usual_001", "Pants_014", "Shoe_Sneakers_009", "T_Shirt_009"],
		"tints": {},
	},
	"Cliente 2": {
		"parts": ["Body_010", "Glasses_006", "Hairstyle_male_012", "Male_emotion_happy_002", "Outerwear_029", "Shoe_Slippers_005", "Shorts_003"],
		"tints": {"Body_010": (0.5, 0.55)},
	},
	"Cliente 3": {
		"parts": ["Body_010", "Hairstyle_male_012", "Male_emotion_angry_003", "Moustache_001", "Outerwear_036", "Pants_014", "Shoe_Sneakers_009"],
		"tints": {"Body_010": (0.5, 1.15), "Outerwear_036": (0.75, 1.0), "Pants_014": (0.75, 1.0), "Shoe_Sneakers_009": (0.75, 1.0)},
	},
	"Cliente 4": {
		"parts": ["Body_010", "Hairstyle_male_010", "Headphones_002", "Male_emotion_happy_002", "Shoe_Slippers_002", "Shorts_003", "T_Shirt_009"],
		"tints": {"Body_010": (0.5, 0.8), "T_Shirt_009": (0.2, 1.0), "Shorts_003": (0.2, 1.0), "Shoe_Slippers_002": (0.2, 1.0)},
	},
	"Cliente 5": {
		"parts": ["Body_010", "Glasses_004", "Hairstyle_male_012", "Male_emotion_usual_001", "Outerwear_029", "Pants_010", "Shoe_Slippers_005"],
		"tints": {"Outerwear_029": (0.9, 1.0), "Pants_010": (0.9, 1.0), "Shoe_Slippers_005": (0.9, 1.0)},
	},
	"Cliente 6": {
		"parts": ["Body_010", "Hairstyle_male_010", "Male_emotion_happy_002", "Outerwear_036", "Pants_010", "Shoe_Sneakers_009"],
		"tints": {"Body_010": (0.5, 0.5), "Outerwear_036": (0.1, 1.0), "Pants_010": (0.1, 1.0), "Shoe_Sneakers_009": (0.1, 1.0)},
	},
	"Cliente 7": {
		"parts": ["Body_010", "Hairstyle_male_012", "Male_emotion_usual_001", "Moustache_002", "Pants_014", "Shoe_Slippers_002", "T_Shirt_009"],
		"tints": {"Body_010": (0.5, 1.15), "T_Shirt_009": (0.85, 1.0), "Pants_014": (0.85, 1.0), "Shoe_Slippers_002": (0.85, 1.0)},
	},
	"Cliente 8": {
		"parts": ["Body_010", "Glasses_006", "Hairstyle_male_010", "Male_emotion_happy_002", "Shoe_Sneakers_009", "Shorts_003", "T_Shirt_009"],
		"tints": {"Body_010": (0.5, 0.6), "T_Shirt_009": (0.35, 1.0), "Shorts_003": (0.35, 1.0), "Shoe_Sneakers_009": (0.35, 1.0)},
	},
	"Cliente 9": {
		"parts": ["Body_010", "Hairstyle_male_012", "Male_emotion_angry_003", "Outerwear_029", "Shoe_Slippers_005", "Shorts_003"],
		"tints": {"Body_010": (0.5, 0.85), "Outerwear_029": (0.65, 1.0), "Shorts_003": (0.65, 1.0), "Shoe_Slippers_005": (0.65, 1.0)},
	},
	"Cliente 10": {
		"parts": ["Body_010", "Glasses_004", "Hairstyle_male_010", "Male_emotion_usual_001", "Moustache_001", "Outerwear_036", "Pants_014", "Shoe_Sneakers_009"],
		"tints": {"Body_010": (0.5, 1.1), "Outerwear_036": (0.3, 1.0), "Pants_014": (0.3, 1.0), "Shoe_Sneakers_009": (0.3, 1.0)},
	},
}


def fail(message: str) -> None:
	print("ERROR: " + message)
	sys.exit(1)


def parse_args() -> argparse.Namespace:
	argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
	parser = argparse.ArgumentParser(prog="build_characters.py")
	parser.add_argument("--out", required=True, help="Output folder for the GLB files")
	parser.add_argument("--only", nargs="*", default=[], help="Build only these characters, for example: Pescador \"Cliente 3\"")
	return parser.parse_args(argv)


def check_input() -> None:
	missing = []
	if RIG not in bpy.data.objects:
		missing.append("rig object " + RIG)
	for name in REQUIRED_CLIPS:
		if name not in bpy.data.actions:
			missing.append("action " + name)
	if BASE_MATERIAL not in bpy.data.materials:
		missing.append("material " + BASE_MATERIAL)
	if ATLAS not in bpy.data.images:
		missing.append("image " + ATLAS)
	for character, spec in CHARACTERS.items():
		for part in spec["parts"]:
			if part not in bpy.data.objects:
				missing.append("part %s (needed by %s)" % (part, character))
	if missing:
		fail("This .blend does not match the expected itHappy Creative Characters FREE layout. Missing: " + ", ".join(sorted(set(missing))))


def srgb_to_linear(c: np.ndarray) -> np.ndarray:
	return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def linear_to_srgb(c: np.ndarray) -> np.ndarray:
	c = np.clip(c, 0.0, 1.0)
	return np.where(c <= 0.0031308, c * 12.92, 1.055 * (c ** (1 / 2.4)) - 0.055)


def rgb_to_hsv(rgb: np.ndarray) -> np.ndarray:
	r, g, b = rgb[:, 0], rgb[:, 1], rgb[:, 2]
	mx = rgb.max(axis=1)
	mn = rgb.min(axis=1)
	delta = mx - mn
	safe = np.where(delta > 1e-8, delta, 1.0)
	h = np.where(mx == r, ((g - b) / safe) % 6.0, np.where(mx == g, (b - r) / safe + 2.0, (r - g) / safe + 4.0)) / 6.0
	h = np.where(delta > 1e-8, h, 0.0)
	s = np.where(mx > 1e-8, delta / np.where(mx > 1e-8, mx, 1.0), 0.0)
	return np.stack([h, s, mx], axis=1)


def hsv_to_rgb(hsv: np.ndarray) -> np.ndarray:
	h, s, v = hsv[:, 0], hsv[:, 1], hsv[:, 2]
	h6 = (h % 1.0) * 6.0
	i = np.floor(h6).astype(np.int32) % 6
	f = h6 - np.floor(h6)
	p = v * (1.0 - s)
	q = v * (1.0 - s * f)
	t = v * (1.0 - s * (1.0 - f))
	r = np.choose(i, [v, q, p, p, t, v])
	g = np.choose(i, [t, v, v, q, p, p])
	b = np.choose(i, [p, p, t, v, v, q])
	return np.stack([r, g, b], axis=1)


tinted_materials = {}


def tinted_material(hue: float, value: float) -> bpy.types.Material:
	"""A copy of the base material whose atlas is shifted like a Hue/Saturation/Value node (saturation 1)."""
	name = "Color_h%.2f_v%.2f" % (hue, value)
	if name in tinted_materials:
		return tinted_materials[name]
	source = bpy.data.images[ATLAS]
	width, height = source.size
	pixels = np.empty(width * height * 4, dtype=np.float32)
	source.pixels.foreach_get(pixels)
	pixels = pixels.reshape(-1, 4)
	linear = srgb_to_linear(pixels[:, :3])
	hsv = rgb_to_hsv(linear)
	hsv[:, 0] = (hsv[:, 0] + hue - 0.5) % 1.0
	hsv[:, 2] = hsv[:, 2] * value
	tinted = linear_to_srgb(np.maximum(hsv_to_rgb(hsv), 0.0))
	result = np.concatenate([tinted, pixels[:, 3:4]], axis=1).astype(np.float32)
	image = bpy.data.images.new("Textures_4_h%.2f_v%.2f" % (hue, value), width, height, alpha=True)
	image.colorspace_settings.name = "sRGB"
	image.pixels.foreach_set(result.ravel())
	image.pack()
	material = bpy.data.materials[BASE_MATERIAL].copy()
	material.name = name
	for node in material.node_tree.nodes:
		if node.type == "TEX_IMAGE":
			node.image = image
	tinted_materials[name] = material
	return material


def build_character(name: str, collection: bpy.types.Collection, out_dir: str) -> None:
	spec = CHARACTERS[name]
	rig = bpy.data.objects[RIG].copy()
	rig.name = "Skeleton_" + name
	rig.location = (0.0, 0.0, 0.0)
	collection.objects.link(rig)
	pose_action = bpy.data.actions.get("A-pose")
	if pose_action is not None and rig.animation_data is not None:
		rig.animation_data.action = pose_action
	created = [rig]
	for part in spec["parts"]:
		source = bpy.data.objects[part]
		clone = source.copy()
		clone.data = source.data.copy()
		clone.name = "%s_%s" % (name, part)
		collection.objects.link(clone)
		clone.parent = rig
		clone.matrix_parent_inverse = Matrix.Identity(4)
		clone.location = (0.0, 0.0, 0.0)
		clone.rotation_euler = (0.0, 0.0, 0.0)
		clone.scale = (1.0, 1.0, 1.0)
		for modifier in clone.modifiers:
			if modifier.type == "ARMATURE":
				modifier.object = rig
		if part in spec["tints"]:
			hue, value = spec["tints"][part]
			clone.material_slots[0].material = tinted_material(hue, value)
		created.append(clone)
	bpy.ops.object.select_all(action="DESELECT")
	for obj in created:
		obj.hide_viewport = False
		obj.hide_set(False)
		obj.select_set(True)
	bpy.context.view_layer.objects.active = rig
	path = os.path.join(out_dir, name + ".glb")
	bpy.ops.export_scene.gltf(
		filepath=path,
		export_format="GLB",
		use_selection=True,
		export_apply=True,
		export_yup=True,
		export_animations=True,
		export_animation_mode="NLA_TRACKS",
		export_skins=True,
	)
	print("BUILT %s (%d bytes)" % (path, os.path.getsize(path)))
	for obj in created:
		data = obj.data
		bpy.data.objects.remove(obj, do_unlink=True)
		if isinstance(data, bpy.types.Mesh) and data.users == 0:
			bpy.data.meshes.remove(data)


def main() -> None:
	args = parse_args()
	check_input()
	names = args.only if args.only else list(CHARACTERS.keys())
	for name in names:
		if name not in CHARACTERS:
			fail("Unknown character %r. Valid names: %s" % (name, ", ".join(CHARACTERS)))
	out_dir = os.path.abspath(args.out)
	os.makedirs(out_dir, exist_ok=True)
	collection = bpy.data.collections.new("_reel_tycoon_build")
	bpy.context.scene.collection.children.link(collection)
	for name in names:
		build_character(name, collection, out_dir)
	print("DONE: %d characters written to %s" % (len(names), out_dir))


main()
