extends Node3D
## DENGE - mahkeme salonu tarzinda genis dairesel oyun salonu.
## Ortada basamakli platform uzerinde bes oyunculu acili masa duzeni,
## arkada hakim kursusu, cevrede galeri, yanlarda dev terazi heykelleri ve kubbe.

const Kit = preload("res://scripts/mesh_kit.gd")
const Mats = preload("res://scripts/room_materials.gd")
const StationScript = preload("res://scripts/player_station.gd")
const ScaleScript = preload("res://scripts/balance_scale.gd")
const TERMINAL_SCRIPT = preload("res://scripts/number_terminal_ui.gd")

# Yerlesim olculeri (metre).
const PLAYERS := 5
const ROOM_RADIUS := 14.0
const WALL_HEIGHT := 7.5
const DOME_HEIGHT := 5.5
const PLATFORM_TOP := 0.36
const CHAIR_RADIUS := 2.15
const DESK_OUTER := 1.62
const DESK_INNER := 0.72
const HOST_DISTANCE := 6.8
const GALLERY_RADIUS := 9.6
const STATUE_RADIUS := 5.6
const STATUE_ANGLES: Array[float] = [90.0, 148.0, 212.0, 270.0]

# Kamera.
const MOUSE_SENSITIVITY := 0.0025
const MAX_YAW := 95.0
const MAX_PITCH := 55.0
const PROMPT_DOT := 0.965

var mats: Mats
var stations: Array = []
var terminal_ui: CanvasLayer
var prompt_label: Label
var player_camera: Camera3D
var player_console: Node3D
var view_yaw := 0.0
var view_pitch := 0.0

func _ready() -> void:
	mats = Mats.new()
	_build_architecture(_group("Architecture"))
	_build_stations(_group("Arena"))
	_build_host_bench(_group("HostBench"))
	_build_gallery(_group("Gallery"))
	_build_statues(_group("Statues"))
	_build_lighting(_group("Lighting"))
	_build_camera()
	_build_terminal_ui()

func _group(name_: String) -> Node3D:
	var n := Node3D.new()
	n.name = name_
	add_child(n)
	return n

func _build_architecture(root: Node3D) -> void:
	Kit.cylinder(root, "Floor", Vector3(0, -0.1, 0), ROOM_RADIUS, ROOM_RADIUS, 0.2, mats.mat("polished_floor"), 64)
	for r: float in [5.0, 7.6, 11.5]:
		Kit.ring(root, "FloorJoint_%d" % int(r), Vector3.ZERO, r, 0.05, mats.mat("dark_metal"))
	# Basamakli sekizgen platform.
	Kit.cylinder(root, "PlatformStepLower", Vector3(0, PLATFORM_TOP * 0.25, 0), 4.5, 4.5, PLATFORM_TOP * 0.5, mats.mat("dark_concrete"), 8)
	Kit.cylinder(root, "PlatformStepUpper", Vector3(0, PLATFORM_TOP * 0.75, 0), 3.8, 3.8, PLATFORM_TOP * 0.5, mats.mat("concrete"), 8)
	Kit.cylinder(root, "CenterInlay", Vector3(0, PLATFORM_TOP + 0.003, 0), 0.62, 0.62, 0.006, mats.mat("dark_metal"), 8)
	# Beton blok duvar, dikey derzler ve yatay bloklama cizgileri.
	var panels := 44
	var panel_width: float = TAU * (ROOM_RADIUS - 0.2) / float(panels)
	for i in range(panels):
		var a := TAU * float(i) / float(panels)
		var out := Vector3(sin(a), 0, cos(a))
		var wall := Kit.box(root, "Wall_%02d" % i, out * (ROOM_RADIUS - 0.2) + Vector3.UP * WALL_HEIGHT * 0.5, Vector3(panel_width - 0.04, WALL_HEIGHT, 0.4), mats.mat("concrete"))
		wall.rotation.y = a
	for k in range(1, 8):
		Kit.ring(root, "WallCourse_%d" % k, Vector3(0, k * 0.9, 0), ROOM_RADIUS - 0.4, 0.035, mats.mat("dark_concrete"))
	Kit.cylinder(root, "WallCornice", Vector3(0, WALL_HEIGHT + 0.15, 0), ROOM_RADIUS - 0.35, ROOM_RADIUS - 0.35, 0.3, mats.mat("dark_concrete"), 64, false)
	# Basamakli kubbe ve aralarindaki isik halkalari.
	var tiers := 9
	for k in range(tiers):
		var t0: float = float(k) / float(tiers)
		var t1: float = float(k + 1) / float(tiers)
		var r0: float = _dome_radius(t0)
		var r1: float = _dome_radius(t1)
		var y0: float = WALL_HEIGHT + 0.3 + DOME_HEIGHT * sin(t0 * PI * 0.5)
		var y1: float = WALL_HEIGHT + 0.3 + DOME_HEIGHT * sin(t1 * PI * 0.5)
		Kit.cylinder(root, "DomeTier_%d" % k, Vector3(0, (y0 + y1) * 0.5, 0), r1, r0, y1 - y0, mats.mat("dome"), 64, false)
		Kit.ring(root, "DomeLight_%d" % k, Vector3(0, y1 - 0.05, 0), r1 + 0.03, 0.05, mats.mat("dome_light"))
	Kit.cylinder(root, "Oculus", Vector3(0, WALL_HEIGHT + 0.3 + DOME_HEIGHT, 0), _dome_radius(1.0), _dome_radius(1.0), 0.05, mats.mat("oculus"), 64)

func _dome_radius(t: float) -> float:
	return lerpf(ROOM_RADIUS - 0.35, 3.6, 1.0 - cos(t * PI * 0.5))

func _build_stations(root: Node3D) -> void:
	root.position.y = PLATFORM_TOP
	var half_angle: float = PI / float(PLAYERS)
	for i in range(PLAYERS):
		var a := TAU * float(i) / float(PLAYERS)
		var station := StationScript.new()
		station.name = "PlayerStation_%d" % (i + 1)
		station.position = Vector3(sin(a), 0, cos(a)) * CHAIR_RADIUS
		# rotation.y = a, yerel -Z eksenini merkeze cevirir.
		station.rotation.y = a
		root.add_child(station)
		station.build(mats, i, CHAIR_RADIUS, DESK_OUTER, DESK_INNER, half_angle)
		stations.append(station)
	player_console = stations[0].touch_target

func _build_host_bench(root: Node3D) -> void:
	# Oyuncu 1'in tam karsisinda, merkeze bakan sunucu/hakim kursusu.
	root.position = Vector3(0, 0, -HOST_DISTANCE)
	root.rotation.y = PI
	Kit.slot(root, "Bench", "host_bench", Vector3.ZERO, _build_bench_placeholder)
	var spot := SpotLight3D.new()
	spot.name = "HostSpot"
	spot.position = Vector3(0, 5.5, -0.6)
	spot.rotation_degrees.x = -80.0
	spot.light_color = Color("#f0d9b5")
	spot.light_energy = 2.2
	spot.spot_range = 8.0
	spot.spot_angle = 22.0
	root.add_child(spot)

func _build_bench_placeholder(root: Node3D) -> void:
	var stone := mats.mat("dark_concrete")
	var metal := mats.mat("dark_metal")
	Kit.box(root, "DaisLower", Vector3(0, 0.2, 0.3), Vector3(4.6, 0.4, 3.4), stone)
	Kit.box(root, "DaisUpper", Vector3(0, 0.55, 0.5), Vector3(3.6, 0.3, 2.6), mats.mat("concrete"))
	var top: float = 0.7
	Kit.box(root, "JudgeDesk", Vector3(0, top + 0.5, -0.5), Vector3(2.6, 1.0, 0.45), metal)
	Kit.box(root, "JudgeDeskTop", Vector3(0, top + 1.03, -0.45), Vector3(2.8, 0.06, 0.65), mats.mat("desk"))
	Kit.box(root, "ThroneSeat", Vector3(0, top + 0.5, 0.45), Vector3(0.75, 0.12, 0.62), mats.mat("leather"))
	Kit.box(root, "ThroneBack", Vector3(0, top + 1.75, 0.82), Vector3(0.95, 2.5, 0.18), mats.mat("leather"))
	var cap := Kit.cylinder(root, "ThroneCap", Vector3(0, top + 3.3, 0.82), 0.0, 0.66, 0.6, metal, 4)
	cap.rotation_degrees.y = 45.0
	Kit.box(root, "Monolith", Vector3(0, top + 3.4, 1.7), Vector3(1.7, 6.8, 0.8), mats.mat("concrete"))
	var emblem := ScaleScript.new()
	emblem.name = "HostEmblemScale"
	emblem.position = Vector3(0, top + 6.8, 1.7)
	emblem.scale = Vector3.ONE * 0.45
	root.add_child(emblem)
	emblem.build(mats, 0.0)

func _build_gallery(root: Node3D) -> void:
	var count := 46
	for i in range(count):
		var a := TAU * (float(i) + 0.5) / float(count)
		# Hakim kursusunun arkasi bos birakilir.
		if absf(angle_difference(a, PI)) < deg_to_rad(20.0):
			continue
		var seg := Kit.slot(root, "GallerySection_%02d" % i, "gallery_section", Vector3(sin(a), 0, cos(a)) * GALLERY_RADIUS, _build_gallery_section.bind(TAU * GALLERY_RADIUS / float(count)))
		seg.rotation.y = a

func _build_gallery_section(root: Node3D, width: float) -> void:
	var wood := mats.mat("wood")
	Kit.box(root, "Balustrade", Vector3(0, 0.55, 0), Vector3(width - 0.02, 1.1, 0.1), wood)
	Kit.box(root, "Rail", Vector3(0, 1.13, 0), Vector3(width, 0.06, 0.2), mats.mat("dark_metal"))
	Kit.box(root, "Tier", Vector3(0, 0.25, 1.0), Vector3(width + 0.05, 0.5, 1.8), mats.mat("dark_concrete"))
	for side: float in [-0.25, 0.25]:
		var x: float = side * width
		Kit.box(root, "SeatCushion_%d" % int(side * 4.0), Vector3(x, 0.95, 0.95), Vector3(0.46, 0.1, 0.42), mats.mat("leather"))
		Kit.box(root, "SeatBack_%d" % int(side * 4.0), Vector3(x, 1.3, 1.18), Vector3(0.46, 0.62, 0.08), mats.mat("leather"))
		var arch := Kit.cylinder(root, "SeatArch_%d" % int(side * 4.0), Vector3(x, 1.61, 1.18), 0.23, 0.23, 0.08, mats.mat("leather"), 16)
		arch.rotation_degrees.x = 90.0

func _build_statues(root: Node3D) -> void:
	for deg: float in STATUE_ANGLES:
		var a := deg_to_rad(deg)
		var statue := ScaleScript.new()
		statue.name = "BalanceStatue_%d" % int(deg)
		statue.position = Vector3(sin(a), 0, cos(a)) * STATUE_RADIUS
		# Kollar merkeze dik dursun.
		statue.rotation.y = a + PI * 0.5
		root.add_child(statue)
		statue.build(mats)

func _build_lighting(root: Node3D) -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#05070a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8ea4b4")
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.7
	world.environment = env
	root.add_child(world)
	# Kubbeden inen soguk ana isik.
	var dome := SpotLight3D.new()
	dome.name = "DomeKeyLight"
	dome.position = Vector3(0, WALL_HEIGHT + DOME_HEIGHT - 0.5, 0)
	dome.rotation_degrees.x = -90.0
	dome.light_color = Color("#cfe4ea")
	dome.light_energy = 3.0
	dome.spot_range = 16.0
	dome.spot_angle = 32.0
	dome.shadow_enabled = true
	root.add_child(dome)
	var table := OmniLight3D.new()
	table.name = "TableFill"
	table.position = Vector3(0, 2.8, 0)
	table.light_color = Color("#bcd2dc")
	table.light_energy = 0.7
	table.omni_range = 5.0
	root.add_child(table)
	# Duvarda sicak aplikler.
	for i in range(6):
		var a := TAU * (float(i) + 0.5) / 6.0
		var out := Vector3(sin(a), 0, cos(a))
		var fixture := Kit.box(root, "Sconce_%d" % i, out * (ROOM_RADIUS - 0.5) + Vector3.UP * 3.4, Vector3(0.9, 0.22, 0.2), mats.mat("sconce"))
		fixture.rotation.y = a
		var light := OmniLight3D.new()
		light.name = "SconceLight_%d" % i
		light.position = out * (ROOM_RADIUS - 0.9) + Vector3.UP * 3.4
		light.light_color = Color("#f0c995")
		light.light_energy = 1.2
		light.omni_range = 4.5
		root.add_child(light)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "PlayerCamera"
	cam.fov = 70.0
	add_child(cam)
	cam.global_position = stations[0].eye_position()
	cam.look_at(Vector3(0.0, 1.7, -HOST_DISTANCE), Vector3.UP)
	view_pitch = cam.rotation.x
	view_yaw = cam.rotation.y
	cam.current = true
	player_camera = cam
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_terminal_ui() -> void:
	terminal_ui = TERMINAL_SCRIPT.new()
	terminal_ui.name = "NumberTerminalUI"
	add_child(terminal_ui)
	var hints := CanvasLayer.new()
	hints.name = "InteractionHints"
	add_child(hints)
	prompt_label = Label.new()
	prompt_label.text = "[E] SAYI TERMINALINI AC"
	prompt_label.add_theme_font_size_override("font_size", 30)
	prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	prompt_label.position = Vector2(-200, -90)
	prompt_label.visible = false
	hints.add_child(prompt_label)
	terminal_ui.connect("selection_locked", _on_selection_locked)

## Ileride oyun mantigi her oyuncunun kendi monitorune buradan yazacak.
func set_station_result(index: int, title: String, body: String) -> void:
	stations[index].set_result_text(title, body)

func _on_selection_locked(value: int) -> void:
	stations[0].set_touch_text("SEÇİM KİLİTLENDİ", str(value))
	set_station_result(0, "SEÇİMİN ALINDI", "DİĞERLERİ BEKLENİYOR")
	print("DENGE: Selected number locked: ", value)

func _process(_delta: float) -> void:
	if is_instance_valid(prompt_label) and is_instance_valid(player_camera) and is_instance_valid(player_console) and not terminal_ui.visible:
		var aim := (player_console.global_position - player_camera.global_position).normalized()
		var facing := -player_camera.global_transform.basis.z
		prompt_label.visible = facing.dot(aim) > PROMPT_DOT

func _unhandled_input(event: InputEvent) -> void:
	if terminal_ui.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			terminal_ui.call("close")
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
		if prompt_label.visible:
			terminal_ui.call("open")
			prompt_label.visible = false
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		view_yaw = clampf(view_yaw - event.relative.x * MOUSE_SENSITIVITY, deg_to_rad(-MAX_YAW), deg_to_rad(MAX_YAW))
		view_pitch = clampf(view_pitch - event.relative.y * MOUSE_SENSITIVITY, deg_to_rad(-MAX_PITCH), deg_to_rad(MAX_PITCH))
		if is_instance_valid(player_camera):
			player_camera.rotation = Vector3(view_pitch, view_yaw, 0.0)
