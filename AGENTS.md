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
- Engine: Godot 4, GDScript; initial target: Windows, 1920×1080, GL Compatibility.
- Game: original psychological number-selection strategy game inspired by a dramatic balance-game setting. Avoid copying trademarked art or branding.
- Design locked (reference: wide courtroom-style round hall): dark concrete block walls, stepped dome with ring light strips, warm wall sconces, wooden gallery balustrade with arched seats around the hall; **stepped octagonal central platform** with **five angled desks forming a pentagon ring**, office chairs facing center; each desk has a **sloped touch screen for number entry** and an **upright result monitor visible only to that player**; host/judge bench with tall monolith opposite player 1; **exactly five balance scales, one directly behind each chair**, with one pan over the seated player's head (ready for tilt/pour animation). **No balance at the center or freestanding extra scales.**
- Camera: player 1's seated eye-level view toward center/host.
- Core files: scenes/game_room.tscn, scenes/room_shell.tscn, scenes/center_platform.tscn, scenes/props/*.tscn, scenes/ui/number_terminal_ui.tscn, scripts/game_room.gd.
- All architecture, furniture, individual screens, materials, camera and lighting must be **serialized and editable in Godot scenes**, not created procedurally from _ready(). Use packed scene instances and Inspector-friendly @export controls.
- Current priority: refine/test the 3D room. Do not add gameplay, networking, menus or new dependencies without request.

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
