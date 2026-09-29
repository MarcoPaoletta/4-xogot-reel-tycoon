# xo: 3D Modeler

`xo modeler` inspects and edits meshes with the 3D Modeler.

## Contents

- Commands
- Indices and selection
- Rules and limits
- Walkthrough: build and edit a courtyard
- Lessons from real use

## Commands

- `modeler info [node]` shows the current Modeler state.
- `modeler mesh [node] [--limit N]` shows vertices, records, edges, and faces.
- `modeler shapes` lists shape kinds, parameters, defaults, and ranges.
- `modeler actions [node]` lists action names and explains unavailable actions.
- `modeler create <kind> ...` creates a parametric shape. Run `modeler shapes` for the list.
- `modeler poly create|edit ...` creates or edits a Poly Shape, including holes.
- `modeler bezier create|edit ...` creates or edits an experimental Bezier Shape.
- `modeler recipe set <node> ...` changes a saved shape recipe and rebuilds it.
- `modeler make-editable <node> [--preview] ...` converts a mesh or CSG node.
- `modeler strip <node>` removes editable mesh data.
- `modeler mode <node> <mode>` sets object, vertex, edge, or face mode.
- `modeler select <node> ...` selects elements by index, path, attribute, or ray.
- `modeler transform <node> ...` moves, rotates, scales, extrudes, or insets elements.
- `modeler cut <node> ...` cuts a closed contour into one face.
- `modeler action <node> <action> ...` runs an action from `modeler actions`.
- `modeler paint material|color|smoothing|position ...` changes mesh attributes.
- `modeler slot list|set|match|select|clear ...` manages mesh material slots.
- `modeler smoothing list|select|merge|clear ...` manages smoothing groups.
- `modeler palette show|load|save|reset|set-material|set-color ...` manages the Paint palette.
- `modeler uv ...` selects, groups, projects, transforms, unwraps, and exports UV data.
- `modeler export <node>... --path res://... ...` exports mesh files in the project.
- `modeler boolean <a> <b> --operation ...` runs an experimental Boolean operation.
- `modeler preferences get|set|reset ...` reads or saves Modeler preferences.

## Indices and selection

Face indices start at zero. `--vertices` uses shared vertex indices. One shared position can have more than one vertex record, one for each face. Use `--records` only when a command needs the raw record indices. An edge is two shared vertex indices in the form `a-b`. Before an edit by index, run `xo modeler mesh <node>` to read the current numbers of the faces, edges, shared vertices, and records. A topology change can change these numbers.

A command that names a node operates on that node. It does not change the object selection of the editor. The element selection stays with the target node, also when the editor selects a different node. The CLI does not open confirmation sheets or live previews of action adjustments. Actions commit immediately. `make-editable --preview` does not change the mesh. It only reports the import counts.

An inline selection and its operation are two undo steps. For example, an action with `--faces` first changes the selection, then changes the mesh. Use `xo editor undo [--count N]` and `xo editor redo` to move through these steps.

## Rules and limits

Export paths must start with `res://` and stay in the project. Export does not replace an existing file unless you give `--force`.

Boolean and Bezier commands are experimental, and their results can be rough. They run also when the experimental preference is off.

Action options such as `--bevel-distance` apply to one command only. `xo` does not save them. Only `modeler preferences set` saves a preference.

The `bevel` action applies Bevel Mode once, without the interactive preview. It uses the saved preferences `bevelAmount` (in the units of the amount type), `bevelAmountType` (`offset`, `width`, `depth`, or `percent`), `bevelSegments` (1 to 32), `bevelProfile` (0 to 1), `bevelClamp`, and `bevelHarden`. `bevelEdges` uses `bevel`, an offset in scene units. Bevel Mode changes `bevel` only when its amount type is `offset`. In face mode it bevels the outer edges of the selected faces. It refuses open or non-manifold edges and leaves the mesh unchanged. `modeler create` starts from the shape defaults. It ignores the saved shape settings unless you give `--use-saved-settings`.

## Walkthrough: build and edit a courtyard

This example builds and edits a small courtyard. Read the indices again after each topology change:

```sh
xo scene create --path res://courtyard.tscn --root-type Node3D --root-name Courtyard

xo modeler create plane --name Floor --size 20,0,20 --param widthCuts=2 --param heightCuts=2
xo modeler create cube --name WallNorth --size 20,3,0.5 --position 0,1.5,-10
xo modeler create cube --name WallSouth --size 20,3,0.5 --position 0,1.5,10
xo modeler create cube --name Platform --size 4,1,4 --position 0,0.5,0
xo modeler create cylinder --name PillarA --size 0.6,4,0.6 --position 0,2,0 --param sides=12
xo modeler create cylinder --name PillarB --size 0.6,4,0.6 --position 3,2,3 --param sides=12

xo modeler poly create --name Border --outline '0,0;10,0;10,10;0,10' --hole '4,4;4,6;6,6;6,4' --height 0.25 --position=-5,0,-5

xo modeler create door --name Gate --position 0,1.5,-9.5
xo modeler recipe set /Gate --param pedimentHeight=0.7 --param sideWidth=0.6
xo modeler create arch --name Arch --position 0,3,-9.5
xo modeler recipe set /Arch --param degrees=180 --param sides=12
xo modeler create stairs --name Stairs --position 0,0,4
xo modeler recipe set /Stairs --param steps=8 --param circumference=0
xo modeler create cylinder --name Fountain --position=-3,1,0
xo modeler recipe set /Fountain --kind pipe --param thickness=0.15 --param sides=16

xo modeler mesh /WallNorth --limit 100
xo modeler transform /WallNorth --mode face --faces 0 --translate 0,1.5,0 --extrude
xo modeler transform /WallNorth --scale 0.6,0.6,1 --extrude
xo modeler action /WallNorth extrudeFaces --extrude-distance=-0.3
xo modeler mesh /WallSouth --limit 100
xo modeler action /WallSouth bevelEdges --mode edge --edges 0-1 --bevel-distance 0.1
xo modeler action /WallSouth bevel --mode face --faces 0
xo modeler cut /Platform --face 0 --face-2d='-0.2,-0.2;0.2,-0.2;0.2,0.2;-0.2,0.2'
xo modeler action /Platform deleteFaces

xo modeler action /PillarB mirrorObjects --mode object --mirror-x --mirror-duplicate
xo modeler action /PillarB mergeObjects --mode object --with /PillarBMirror
xo modeler action /PillarB centerPivot

xo modeler paint material /Floor --material builtin:checker --mode face --all
xo modeler paint color /Gate --color 0.65,0.4,0.2,1 --mode face --all
xo modeler paint smoothing /WallSouth --faceted --mode face --all
xo modeler palette save --path res://courtyard_palette.tres

xo modeler uv auto-settings /Floor --mode face --all --scale 0.25,0.25 --world-space
xo modeler uv group /Floor --mode face --all
xo modeler uv project /Floor --projection planar --mode face --all
xo modeler uv fit /Floor --mode face --all
xo modeler uv stitch /Floor --source 0 --target 1
xo modeler uv unwrap /Floor --hard-angle 88 --pack-margin 4 --angle-error 8 --area-error 15
xo modeler uv rebuild-uv2 /Floor
xo modeler uv template /Floor /tmp/courtyard_uv.png --size 1024

xo modeler action /Floor setCollider --mode object
xo modeler action /Border setTrigger --mode object
xo node create /ImportedSphere --type MeshInstance3D
xo resource inline /ImportedSphere mesh --type SphereMesh --set radial_segments=12
xo modeler make-editable /ImportedSphere --preview
xo modeler make-editable /ImportedSphere

xo modeler boolean /Fountain /PillarA --operation subtraction --name FountainCut
xo modeler export /FountainCut --path res://exports/fountain.glb --format gltf --force
xo modeler strip /ImportedSphere
xo scene save
```

## Lessons from real use

These notes come from a full scene that was built with `xo modeler`.

### Coordinates

- **Mesh coordinates are local to the node.** `modeler mesh` reports positions in the node's own space, and `--points`, `--vertices` and position-based selections use that space.
- **`create --rotation` is applied to the mesh itself.** It rotates the vertices and leaves the node's rotation at zero. For example, `create cylinder --rotation 90,0,22.5` lies along Z in mesh coordinates.
- **Extracted faces inherit transforms.** `duplicateFaces` and `detachFaces` with `--detach-to-object` give the new node the source node's transform and report its path in `created_node_paths`. Without the flag, the actions edit the source mesh. A merged mesh keeps the first node's origin, so its coordinates are relative to that node.
- **A Poly Shape's local axes are its drawing frame.** Outline X runs along the tangent, outline Z along tangent × normal, and the height along the normal. With `--normal 0,0,1 --tangent 1,0,0`, outline Z points down (−Y), so pick the tangent, or negate Z, to draw "up".
- **`create --parent` takes a position relative to the parent**, and `node move` keeps the world position. To build something complex (a ship, a cart), create a parent `Node3D` at its final position and angle, then build the parts in its local space.
- **To convert a local point to world space**, use `xo eval 'EditorInterface.get_edited_scene_root().get_node("A/B").global_transform * Vector3(x, y, z)'`.

### Selecting elements

- **Do not hard-code face or vertex numbers.** They change after every topology edit. Read `modeler mesh`, pick elements by position (face center, face normal, vertex position), and pass their persistent IDs.
- **Compute face normals with Newell's method** (a sum over all edges), not from the first three corners. The first three corners give the wrong direction on a concave face. A jq helper:

  ```sh
  JQ='def unit: (map(.*.) | add | sqrt) as $l | if $l > 0 then map(./$l) else . end;
  def newell(V): [range(0; V | length) as $i | [V[$i], V[($i + 1) % (V | length)]]]
    | map([(.[0][1]-.[1][1])*(.[0][2]+.[1][2]), (.[0][2]-.[1][2])*(.[0][0]+.[1][0]), (.[0][0]-.[1][0])*(.[0][1]+.[1][1])])
    | transpose | map(add) | unit;
  def faces: (.vertices | map(.position)) as $P | .faces | map(. as $f | ($f.vertices | map($P[.])) as $V
    | {id: $f.id, nv: ($V | length), c: ($V | transpose | map(add / length)), n: newell($V)});'
  # IDs of the upward-facing faces, as repeated flags:
  xo modeler mesh /Island --limit 100000 | jq -r "$JQ faces[] | select(.n[1] > 0.99) | .id" \
    | while read -r id; do printf -- '--face-id %s ' "$id"; done
  ```

- **Pass several IDs as repeated flags or one comma-separated value** (`--face-id A --face-id B` or `--face-id A,B`).
- **Element selections choose their mode.** For example, `--face-id` selects face mode. Pass `--mode` only when a command has no element selection that implies it.
- **Edge IDs are built from their two endpoint vertex IDs**, so splitting an edge (loop cut, subdivide) retires its ID. Re-read the edges (`modeler mesh`, then `edges[]` with the matching `edge_ids[]`) after any topology change.
- **Many commands leave their result selected**, so the next command can use it with no selection flags:
  - `insetFaces` leaves the inner face selected.
  - `insertEdgeLoop` leaves the new loop's edges selected.
  - `cut` leaves the new face selected.
  - `transform --extrude` leaves the moved faces selected.

  For example, `insetFaces` followed by `transform --extrude --translate 0,-0.5,0` makes a recess. `paint color` with no selection flags paints the current selection, and `select --color r,g,b,a` selects faces by color.
- **To find what an operation created**, compare the vertex IDs before and after the operation.

### Modeling operations

- **`transform --translate` only moves elements. `--extrude` adds walls.** To sink a deck or to recess a doorway, use `--extrude`. Without it, the surrounding faces stretch and slope, and the object loses its thickness.
- **Extruding an open surface leaves its back open**, as in ProBuilder. `poly create --height` makes a closed solid.
- **Inset:** `action insetFaces --inset-width W`. By default, it operates on a connected region. With `--inset-individual-faces`, it operates on each face. The borders are quads. If the width is too large for the shape, the action fails ("The mesh selection is not valid").
- **Cutting a face in two:** `cut` accepts only a closed outline (3 or more points) in one face. To split a face with a line, add points on its boundary with `action subdivideEdges --subdivisions N` (which makes N segments), then join a pair with `action connectVertices --vertex-id A --vertex-id B`. This is ProBuilder's "smart divide / smart connect", and both points must be on the same face.
- **Do flat-face operations first.** `insetFaces` and `cut` need a flat face ("point is off the face"), so inset decks, cut outlines and tear corners before you bend anything with soft selection or vertex moves.
- **Soft selection is per command:** `transform … --soft-radius R --soft-curve smooth --soft-falloff F`. The falloff follows mesh edges, not straight-line distance, and the editor's own soft-select settings are restored afterward.
- **`mergeObjects` enters object mode.** The merged node keeps the first node's origin, and the merged mesh keeps one slot for each distinct material resource.
- **Flat shading:** create shapes with `--param smooth=0`, or run `modeler paint smoothing <node> --faceted --mode face --all`.
- **Placing on a surface:** `create` and `poly create` accept `--on <node> --face-id <id> --at u,v`, where `u,v` is a meter offset from the face center along the face's axes. For surfaces the helpers cannot reach, cast a ray through `xo eval` with `Geometry3D.ray_intersects_triangle` over `mesh.get_faces()` to get the hit point and normal, then set the node's position and rotation from them.
- **Pivot:** `action setPivot` with vertices or edges selected moves the node origin there, for example to a hinge edge or a trunk base.

### Materials

- **Pass `--material res://…tres` to every `create`.** Otherwise each shape gets its own embedded copy of the "Modeler Grid" material and texture, and scene files grow with every object.
- **`poly create` accepts repeatable `--material` options.** If you do not pass one, it uses the Modeler Grid material.
- **A vertex-color workflow** (ProBuilder style): `material create standard res://m.tres --set vertex_color_use_as_albedo=true`, then `modeler paint color`. For one-sided surfaces such as a sail, add `--set cull_mode=2` (double-sided).

### Prefabs and part scenes

- **Make a part scene with `xo scene extract`.** See [xo-editor-and-scenes.md](xo-editor-and-scenes.md#work-with-scenes).
- **Instances are read-only in the Modeler** (the error names the source scene). To change every copy: `scene activate` the part, edit or paint it, `scene close --save`, then `scene activate` the main scene again. For more about closing scenes, see [xo-editor-and-scenes.md](xo-editor-and-scenes.md#work-with-scenes).

### Checking the result

- **Screenshots:** use `--view-target` to put the mesh in the frame. See [xo-editor-and-scenes.md](xo-editor-and-scenes.md#screenshots).
- **After a topology step, check the face and vertex counts in the reply.** This is the fastest way to find an operation that did nothing.
