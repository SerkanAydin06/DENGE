# DENGE — AI Agent Instructions

Read this file before any task. Applies to Claude Code, ChatGPT/Codex and other coding agents.

## User preferences (mandatory)
- Communicate with the user in Turkish, **very briefly**. No long explanations, unsolicited roadmaps or pasted code.
- **Do the work yourself.** For requested fixes, edit the repository files and commit/push directly to GitHub when tooling and authorization permit. Never ask the user to copy/paste code, change files, run routine commands or perform tasks the agent can do.
- If direct write access is unavailable, first attempt connected GitHub tooling; only then report the exact blocker. Do not claim a commit unless the remote confirms it.
- Minimize token use: inspect only relevant files/lines, batch related changes, avoid repeating context or large outputs. Don't repeatedly fetch unchanged content.
- Do not ask for confirmation on routine, reversible implementation work. Ask only if an essential choice is genuinely missing or a risky/irreversible action requires approval.
- After work: reply with **what changed, GitHub status/link, and only essential testing caveats**, preferably 1–3 sentences. No full source code unless asked.
- Verify changes using available tools (Godot headless/import/tests if accessible). If not tested, state that plainly; do not invent success.

## Project facts
- Repository: SerkanAydin06/DENGE (default branch main).
- Engine: Godot 4, GDScript; initial target: Windows, 1920×1080, Forward+ (Vulkan/D3D12).
- Game: original psychological number-selection strategy game inspired by a dramatic balance-game setting. Avoid copying trademarked art or branding.
- Design locked (reference: wide courtroom-style round hall): dark concrete block walls, stepped dome with ring light strips, warm wall sconces, wooden gallery balustrade with arched seats around the hall; **three-tier regular pentagonal central platform** (five segments per tier, aligned to the five 72-degree-spaced inward-facing player stations) with **five angled desks forming a pentagon ring**, office chairs facing center; each desk has an **in-world ray-clickable number-only tablet (101 distinct numbered labels, 0..100, plus TEMIZLE/ONAY)** and a separate **animated 3D results monitor** (reveal, calculations, winners and scores, all five synced); **exactly five balance scales, one directly behind each chair**, with one pan over the seated player's head (ready for tilt/pour animation). **No balance at the center or freestanding extra scales; no judge bench.** A centered, scene-editable double entrance/exit door is cut through the rear wall and gallery; five player stations must remain equally spaced and at the same height. The room shell is enlarged separately from the player ring.
- Camera: player 1's seated eye-level view toward center/host.
- Core files: scenes/game_room.tscn, scenes/room_shell.tscn, scenes/center_platform.tscn, scenes/props/*.tscn, scenes/ui/number_terminal_ui.tscn, scripts/game_room.gd.
- All architecture, furniture, individual screens, materials, camera and lighting must be **serialized and editable in Godot scenes**, not created procedurally from _ready(). Use packed scene instances and Inspector-friendly @export controls.
- Current priority: in-world cinematic display polish and 3D room QA. Do not add networking, menus or new dependencies without request.

## Workflow
1. Check relevant existing source and Git status; identify smallest correct change.
2. Apply the change directly in code; reuse existing patterns.
3. Run appropriate quick validation if possible; check GDScript syntax, node tree usage, scene startup.
4. Commit/push only the intended files to the established repo/branch; avoid unrelated changes.
5. Report a concise result and blocker if any.

## Known traps
- Godot GDScript numeric inference: explicitly annotate floats where needed (e.g. `var x: float = ...`).
- `Node3D.look_at()` requires node to be inside tree; call `add_child()` first or use `look_at_from_position()`.
- Node3D faces local -Z. All player stations must face center.
- Generated room geometry should remain lightweight and work without external assets.
- Avoid pretending procedural meshes are production-quality; first prioritize layout and correct camera.

## Entrance and symmetry
- Door scene: `scenes/props/entrance_door.tscn` (two hinged leaves, frame, centered aisle). Wall and gallery gap must remain open in `scenes/room_shell.tscn`.
- Preserve the user's recent editor-authored transforms and UID metadata; change only what the request requires.

## Screen architecture (user-locked)
- No fullscreen number selection UI or fullscreen results UI in `scenes/game_room.tscn`; do not reconnect the legacy `number_terminal_ui.tscn` or `round_results_ui.tscn` overlay scenes.
- `scripts/player_station.gd` manages scene-authored 101-number touchscreen (`NumberGrid/Number_000..100`) and 3D monitor labels and subtle alpha transitions. `scripts/game_room.gd` maps camera rays to the physical tablet and drives phased monitor reveals.
- All instructions, calculations, results and game animations are displayed **on the suspended ceiling-mounted 3D monitor, never on the tablet or an overlaid popup**. Tablet is exclusively for 0–100 entry and lock indication.
- E picks up the compact physical tablet **only when the seated player looks at it and the physical [E] interaction marker is visible**; clicks select individual numbers 0-100; TEMIZLE clears, ONAY locks; keyboard digits and Enter are optional; Esc sets it back on its desk. After results finish, look back at the desk tablet and press E to continue or restart; the monitor never shows an E instruction.

## Large game monitor (design locked)
- Every station owns a **approximately 2.04m × 1.19m** visible ceiling-suspended blue-and-cyan monitor: `ResultDisplay/ResultMonitor` in `scenes/props/player_station.tscn`. The user moved the monitor higher; preserve that transform. Remove floor bases and attach two scene-authored suspension rods to the ceiling. It is not mounted on desks.
- Scene-authored glowing frame, subtle text fades (no moving scanline) and five player-number readout labels (no HUD/popup). Separate emission materials in `assets/materials/monitor_glass.tres`, `monitor_cyan.tres` and `tablet_selection.tres`.
- The physical desk tablet visibly lists **all 101 values (0..100 individually)** in ten columns and eleven rows, plus TEMIZLE and ONAY. Do not regress to digit keypad, screenspace number picker or modal result screen.

## Tablet pickup / handheld view (user-locked)
- **On the desk:** tablet must be a normal compact device, approximately 33.6 × 20.4 cm: `scenes/props/player_station.tscn` `Desk/TouchConsole` has local scale `Vector3(0.20, 0.20, 0.20)`, a near-flat angle, and rests directly on desktop.
- **Press E:** `scripts/game_room.gd` reparents that **same real 3D object** to `PlayerCamera`, tweens it to 19 cm in front of the eyes (unchanged physical scale), so it fills most of the view as if lifted into the hands. Cursor becomes visible for the 101-number touch surface. No CanvasLayer, duplicate overlay, or screen-space tablet.
- **Esc/confirm:** smoothly return the real tablet to its exact editor-authored desk position, rotation and scale; selection confirmation continues the animated result sequence on the freestanding monitor.
- `tests/test_tablet_pickup.gd` covers held/docked parent transitions, close-up pose and restoration. Do not regress to a permanently giant tablet on the desk.

## Blueprint results monitor reference (user-locked, 2026-10-14)
- User reference screenshots specify the in-world monitor's layout: **deep navy blueprint grid**, subtle large double-pan balance drawing behind content, five portrait/silhouette slots at top, five large pale rectangular number windows aligned directly below, a red outline enclosing all five number windows during average calculation, and a separate centered target value below. Use **original silhouettes and graphics**, not copyrighted screenshots, actors' likenesses, or TV branding.
- Authored graphic scene: `scenes/props/monitor_blueprint.tscn`. Instanced per-player under `ResultDisplay/ResultMonitor/MonitorBlueprint`. The artwork's 3D shapes and text elements are serialized Godot scene nodes and editable in Inspector.
- `scripts/game_room.gd` displays the user-defined sequence: RULES / waiting for selection → REVEAL five numbers one by one (no portraits yet) → AVERAGE only → MULTIPLY by 0.8 without answer → CALCULATED (show answer) → PHOTO (five authored silhouette portraits above their preserved number tiles; target below) → WIN (red border surrounds each winning portrait AND number) → SCORE (all five remaining points over portrait images); only then E advances. `reveal_delay` controls pacing. No 2D panels.
- Each player sees identical monitor content; the separate 101-number small handheld tablet remains entry-only. Headless checks live in `tests/test_inworld_screens.gd`.

## Monitor size / refresh polish (2026-10-14)
- The complete monitor visual is uniformly 0.80-scaled through `ResultDisplay/ResultMonitor` in `scenes/props/player_station.tscn`. This keeps the proportions and alignment of blueprint grid, portraits, five number tiles, frame and labels. The floor stand has been removed and replaced with ceiling suspension. Physical visible face ~2.04 × 1.19 m.
- **No moving blue refresh bar:** `MonitorSweep` mesh/subresource and associated tween were removed intentionally. `set_monitor_page()` only fades the title and headline. Do not reintroduce scan sweeps.
- `tests/test_inworld_screens.gd` guards the smaller transform and absence of scanline, and existing monitor phase results.

## Starting points and zero elimination (user-locked)
- All five players begin with **10 points** (`DengeRoundRules.STARTING_SCORE`). The player(s) closest to the 0.8× average target retain their current points; all other active players lose 1 point per round.
- **At 0 points, a player is eliminated** (`DengeRoundRules.ELIMINATION_SCORE = 0`). Their choice is -1, excluded from future averages, and their score never becomes negative. The starting/reset scores in `scripts/game_room.gd` must be 10 for all five players.
- The score/threshold are announced on the suspended result monitor. New eliminations show ELENDI / PUAN 0. Headless rule checks in `tests/test_round_rules.gd` exercise threshold, ties and exclusions.
- Result monitor is at 80% scale (physical face ~2.04 × 1.19 m). Do not alter the user's manually authored position and screen styling.

## Locked 2026-10-14 monitor choreography
- The supplied three new screenshots clarify the exact display progression: number-only row revealed sequentially; highlighted number row and mean; equation mean × 0.8 then numeric answer; afterwards transition to full five-portrait/number composition with target at bottom; winner highlighted with red full-height portrait+number outline; finally **each portrait overlays the player's remaining points (0–10)**. Do not show portraits during earlier calculation phases and do not announce the next round before point overlays are visible.
- Authored `CalculationPanel` and `Players/Portrait_n/PointsOverlay_n` are editable nodes in `scenes/props/monitor_blueprint.tscn`. `scripts/player_station.gd` controls phase visibility; `scripts/game_room.gd` controls the ordered timed sequence. The visual portraits currently use original abstract silhouettes; replace them with original character assets when available, not TV stills.
- `tests/test_inworld_screens.gd` checks all display phase visibility and point readouts.

## Black boot, round intro and ceiling suspension (2026-10-14, user-locked)
- The monitor begins with a **fully black screen containing only the centered title DENGE**. Do not show “DENGE | TUR 01”, numeric instructions, tablet guidance, E interaction hints or blueprint elements during selection. `StandbyScreen/BlackFace` and `StandbyScreen/CenterTitle` are editable elements in `scenes/props/player_station.tscn`; `STANDBY` hides blueprint/readouts/other labels.
- All active players choose numbers while the monitors remain black with DENGE. Only **after every player has locked in** does `ROUND_TITLE` show `1. TUR` (or N. TUR), then REVEAL→AVERAGE→MULTIPLY→CALCULATED→PHOTO→WIN→SCORE occurs. The title animation is a text fade, not a moving blue scanline.
- The only E cue is `TabletInteractionHint`, a 3D billboard over player 1's **physical desk tablet**, visible when looking toward the tablet and interaction is available. On score results, looking at the tablet and pressing E proceeds/restarts, without prompt on the monitor. `tests/test_tablet_pickup.gd` covers gaze hint behavior.
- Raised result screens are **ceiling-hung**, not floor-standing. Preserve the user's raised `ResultDisplay` transform, remove the old floor base and column, and use paired `ResultDisplay/CeilingMount/LeftCable`, `RightCable`, and roof anchors in `player_station.tscn`. Editable scene geometry only, no runtime geometry generation.

## Score-driven pan liquid and player elimination (2026-10-14, user-locked)
- Each of the five existing rear balances has an editable, physically near-player **right pan**, `scenes/props/balance_scale.tscn` → `BeamPivot/RightSuspension/RightPan/PanContents`. At 10 remaining points its liquid is empty; 9 points=10% full; ... 1 point=90%; 0 points=100%. The increasingly heavy pan dips through `DengeBalanceScale.apply_points()`. Keep the same user-authored balance transform and alignment.
- After the result WIN phase, when points decrease, `scripts/game_room.gd` calls `stations[i].update_life_points(new_scores[i])`, then starts `eliminate_player()` only for players in `result["eliminated_now"]`; do not repeat deaths every turn. At 0 points the pan rotates, pours its glowing (non-graphic) liquid from `RightPan/PourLip` toward `SpillTarget` above the seated player's head via a scene-authored `DeathSpillStream`, and the avatar collapses/disappears. The player's gameplay score=0 and elimination remain authoritative in `DengeRoundRules`.
- `PlayerFigure`, `DeathSpillStream` and `DeathImpact` are editable meshes in `player_station.tscn`, not created at runtime. For first-person player one the body is hidden to avoid blocking the camera; their death state and impact still occur. Resetting the game restores scores, bowl levels, avatar state and rig tilt.
- Test script `tests/test_elimination_vfx.gd` covers 10/7/1/0 points, spillage, death flag and reset. Godot runtime may not be installed in the ChatGPT execution environment; never claim it ran without executing it.

## Player characters (Meshy, rigged)
- Rigged Meshy/Mixamo GLBs live in `assets/models/players/`. Each gets a wrapper scene in `scenes/characters/` (root script `scripts/player_character.gd`) that poses the skeleton seated; pose angles are Inspector exports.
- `scenes/game_room.tscn` **directly instances each of the five Meshy scenes under its station's `PlayerFigure/Character`** with editable station-child paths, so all GLBs appear in the Godot editor without running the game. The `character_scene` export is retained only as a fallback for standalone station instances. `_install_character()` checks for an existing authored `Character`, avoiding duplicates. Primitive `PlayerFigure` placeholders are hidden in the editor and only enabled at runtime when no real model exists. Station 1 is first-person, so its figure hides during play but is present in the editor for placement.
- Station 1 uses `gray_poise.tscn`; stations 2-5 use `player_2..5.tscn` (Meshy text-to-3d → remesh ~25k tris → rigging, textures repacked to JPEG). Posing aims limbs at model-space target directions (exports) and aligns the hip bone to `seat_hip_height`, so any Mixamo- or Meshy-named skeleton works.
- Seated characters have procedural idle motion in `player_character.gd` (breathing on spine/shoulders, noise sway, occasional head look-around); tune or disable via the "Idle Motion" export group.

- Rig safety: `scripts/player_character.gd` must compute bone directions and poses with `Skeleton3D.get_bone_global_pose()` and apply orientations via `set_bone_global_pose()`. Do not multiply `get_bone_pose()` transforms manually: that omits skeleton rest rotations/translations and can distort Meshy rigs. `tests/test_character_pose.gd` checks all five imported wrappers for finite bone transforms (requires Godot).

- Character visibility regression: `tests/test_character_scene_visibility.gd` checks all five rigged GLBs are in `game_room.tscn` **before** `_ready()` and are not duplicated at runtime. Open `scenes/game_room.tscn` (not the shared generic `player_station.tscn`) to inspect the five distinct Meshy assets. Preserve their scene-authored transforms and editable station nesting.
- Character moods (`DengePlayerCharacter.set_mood`, via `DengePlayerStation.set_character_mood`): THINK at round start (right hand taps tablet, left hand to chin at intervals), LOCKED after a bot locks, WATCH (look up at monitor) from ROUND_TITLE, WIN/LOSE at the WIN phase. Arms rest on the desk by default.
- Renderer: Forward+ (switched from GL Compatibility for shadows, SSAO/SSIL, glow and volumetric fog). The old layer-2 twin-light workaround for faceted faces was removed; `character_layers` export remains for selective light cull masks.
- The primitive capsule placeholder figure was removed from `player_station.tscn`; `PlayerFigure` only holds the authored `Character`.
