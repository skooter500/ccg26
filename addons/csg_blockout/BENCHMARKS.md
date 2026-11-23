# Benchmarks

[中文](BENCHMARKS_CN.md)

Three questions come up when a blockout grows:

1. Does the editor stay responsive while you edit?
2. How long does freezing take?
3. What does live CSG cost in the running game, compared with frozen blockout?

All numbers below come from the benchmark in [`benchmarks/`](benchmarks/), which you can run yourself (see [Reproduce](#reproduce)).

## Setup

- AMD Ryzen 7 5700G (16 threads), AMD Radeon RX 6650 XT, 32 GB RAM, Windows 11 (10.0.26200)
- Godot 4.7.2-stable, Forward+ renderer on Direct3D 12, Jolt Physics; game window 1152×648
- Generated levels made of rooms with 8 primitives each: a floor, four walls, a door cut, a window cut and a pillar. Sizes from 3 rooms (24 primitives) to 50 rooms (400 primitives).
- Two layouts of the same level:
  - **One CSG tree**: every room is a combiner under a single `CSGCombiner3D` root.
  - **One tree per room**: every room is its own CSG root under a plain `Node3D`.

## Results

### Editing: rebuild after moving one wall

Milliseconds, median / max of 15 edits on random rooms.

| Primitives | One CSG tree | One tree per room |
| ---: | ---: | ---: |
| 24 | 3.5 / 4.1 | 2.0 / 2.1 |
| 48 | 5.6 / 6.3 | 2.0 / 2.2 |
| 96 | 8.9 / 9.1 | 2.0 / 2.5 |
| 200 | 16.5 / 17.4 | 2.0 / 2.3 |
| 400 | 29.6 / 31.8 | 2.0 / 2.1 |

### Freezing the whole level

Milliseconds, one undo step.

| Primitives | One CSG tree | One tree per room |
| ---: | ---: | ---: |
| 24 | 16 | 10 |
| 48 | 17 | 13 |
| 96 | 24 | 26 |
| 200 | 35 | 47 |
| 400 | 51 | 87 |

### Running game

Startup until the first frame is drawn (ms) / average frame time (ms).

| Primitives | CSG, one tree | CSG, tree per room | Frozen (as exported) |
| ---: | ---: | ---: | ---: |
| 24 | 37 / 0.42 | 37 / 0.42 | 29 / 0.42 |
| 48 | 46 / 0.41 | 44 / 0.43 | 31 / 0.43 |
| 96 | 61 / 0.42 | 59 / 0.44 | 30 / 0.44 |
| 200 | 96 / 0.41 | 90 / 0.48 | 34 / 0.48 |
| 400 | 166 / 0.42 | 158 / 0.54 | 38 / 0.53 |

## What the numbers say

- **Split big levels into one CSG tree per room or area.** Godot rebuilds only the CSG tree that changed. With one tree per room, an edit costs about 2 ms no matter how big the level gets. With the whole level in one tree, every edit rebuilds everything: about 30 ms at 400 primitives, paid on every step of a gizmo drag. To split an existing level, select its level-wide combiner in the Blockout outliner and click **Ungroup**: its rooms become separate trees.
- **Freezing is effectively instant.** Under 0.1 s for 400 primitives, as one undo step.
- **Live CSG costs nothing per frame, but it does cost at startup.** Frame times match frozen blockout with the same number of nodes. The difference is when the scene loads: live CSG runs all its booleans before the first frame (166 ms at 400 primitives here), while frozen blockout loads plain meshes (38 ms), about 4× faster. Bigger levels and slower machines widen the gap. That's the case for freezing before you ship, or for long play sessions while you iterate.
- **Frame time depends on draw calls, not on CSG.** One tree draws in fewer calls than one tree per room (0.42 ms vs 0.53 ms at 400 primitives), for live and frozen blockout alike. On this GPU it doesn't matter at these sizes.

## Method

- **Editing**: after moving one wall by 0.5 m, `CSGShape3D._update_shape()` of the tree it belongs to is timed directly. That is the rebuild Godot defers to the end of the frame after every edit: the booleans (Manifold), mesh surfaces with tangents, and collision faces. Each edit goes to a random room (fixed seed).
- **Freezing**: `CsgBlockoutFreeze.freeze_now()` on every CSG tree of the level, with the CSG already up to date: baked mesh, trimesh collision and the stored CSG source, as one undo step.
- **Running game**: each level is run in a separate game process started from the editor, with vsync off and no frame cap. Startup covers loading the scene (binary `.scn`, like an exported game), instancing it and drawing the first frame. Frame time is the average over 3 seconds after 30 warm-up frames, with a camera that sees the whole level, a shadowed sun and a sky. Frozen levels have the editor-only data stripped, as the export plugin does.
- Not measured: memory use, export size, physics.

## Reproduce

1. Get CSG Blockout from the repository. The Asset Library download leaves out the `benchmarks/` folder.
2. Save your work. The benchmark opens and closes temporary scenes in `res://csg_blockout_benchmark_tmp/` (deleted at the end) and starts the game 15 times. Like pressing Play, starting the game saves open scenes when "Save Before Running" is on.
3. Open `addons/csg_blockout/benchmarks/run_benchmarks.gd` in the script editor and run it with **File > Run** (`Ctrl+Shift+X`).
4. After about 90 seconds the results are printed to the Output panel and written to `user://csg_blockout/benchmarks/results.md` (tables) and `results.json` (all values, machine info).
