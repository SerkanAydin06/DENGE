extends Node3D
## DENGE - genis dairesel oyun salonu, bes merkeze donuk istasyon.

const ROOM_RADIUS := 18.0
const SEAT_RADIUS := 8.5
const PLAYERS := 5
const MOUSE_SENSITIVITY := 0.0025
const MAX_YAW := 95.0
const MAX_PITCH := 55.0

const TERMINAL_SCRIPT = preload("res://scripts/number_terminal_ui.gd")
var terminal_ui: CanvasLayer
var prompt_label: Label
var player_camera: Camera3D
var view_yaw := 0.0
var view_pitch := 0.0

var concrete: StandardMaterial3D
var dark_concrete: StandardMaterial3D
var metal: StandardMaterial3D
var leather: StandardMaterial3D
var black: StandardMaterial3D
var screen: StandardMaterial3D

func material(color: Color, metalness: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metalness
	m.roughness = 0.68
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	return m

func box_part(name_: String, at: Vector3, size_: Vector3, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = name_
	var shape := BoxMesh.new()
	shape.size = size_
	n.mesh = shape
	n.material_override = mat
	n.position = at
	(parent if parent != null else self).add_child(n)
	return n

func cylinder(name_: String, at: Vector3, radius: float, height_: float, mat: Material, parent: Node3D = null) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = name_
	var shape := CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height_
	shape.radial_segments = 64
	n.mesh = shape
	n.material_override = mat
	n.position = at
	(parent if parent != null else self).add_child(n)
	return n

func _process(_delta: float) -> void:
	if is_instance_valid(prompt_label) and is_instance_valid(player_camera) and not terminal_ui.visible:
		var target := Vector3(0.0, 1.86, SEAT_RADIUS - 1.58)
		var aim := (target - player_camera.global_position).normalized()
		var facing := -player_camera.global_transform.basis.z
		prompt_label.visible = facing.dot(aim) > 0.82

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

func _ready() -> void:
	concrete = material(Color("#464b51"))
	dark_concrete = material(Color("#292d32"))
	metal = material(Color("#778087"), 0.7)
	leather = material(Color("#191c21"))
	black = material(Color("#101317"))
	screen = material(Color("#a1bdc6"), 0.0, 0.65)
	_build_room()
	_build_center()
	_build_seats()
	_build_lighting()
	_build_camera()
	_build_terminal_ui()

func _build_room() -> void:
	cylinder("ConcreteFloor", Vector3(0, -0.17, 0), ROOM_RADIUS, 0.34, concrete)
	cylinder("Ceiling", Vector3(0, 11.8, 0), ROOM_RADIUS, 0.3, dark_concrete)
	# 48 beton duvar paneli, aralarinda koyu metal derz.
	for i in range(48):
		var a := TAU * float(i) / 48.0
		var tangent := Vector3(cos(a), 0, -sin(a))
		var point := Vector3(sin(a), 0, cos(a)) * (ROOM_RADIUS - 0.2)
		var wall := box_part("ConcreteWall_%02d" % i, point + Vector3.UP * 5.9, Vector3(2.29, 11.8, 0.35), concrete)
		wall.rotation.y = a
		var seam := box_part("MetalSeam_%02d" % i, point + tangent * 1.17 + Vector3.UP * 5.9, Vector3(0.09, 11.5, 0.4), black)
		seam.rotation.y = a
	# Gercek parcali beton plakalar: merkez disindaki karolar.
	for ix in range(-8, 9):
		for iz in range(-8, 9):
			var p := Vector3(ix * 2.05, 0.018, iz * 2.05)
			if p.length() < ROOM_RADIUS - 2.0 and p.length() > 3.25:
				box_part("FloorTile_%d_%d" % [ix, iz], p, Vector3(2.0, 0.035, 2.0), concrete if (ix + iz) % 3 else dark_concrete)

func _build_center() -> void:
	cylinder("RaisedPlatformFoundation", Vector3(0, 0.37, 0), 3.0, 0.74, dark_concrete)
	cylinder("PlatformStoneTop", Vector3(0, 0.75, 0), 2.88, 0.08, concrete)
	cylinder("PlatformMetalTrim", Vector3(0, 0.69, 0), 3.02, 0.06, metal)
	# Terazi tabani, direk, yatay kol ve iki kefesi.
	cylinder("BalanceFoot", Vector3(0, 1.08, 0), 0.78, 0.58, metal)
	cylinder("BalanceStem", Vector3(0, 2.46, 0), 0.12, 2.25, metal)
	box_part("BalanceBeam", Vector3(0, 3.55, 0), Vector3(3.55, 0.14, 0.18), metal)
	for side: float in [-1.0, 1.0]:
		var x: float = side * 1.55
		for offset: float in [-0.38, 0.38]:
			box_part("Chain_%s_%s" % [str(side), str(offset)], Vector3(x + offset, 2.96, 0), Vector3(0.032, 1.10, 0.032), metal)
		cylinder("Pan_%s" % str(side), Vector3(x, 2.42, 0), 0.65, 0.08, metal)

func _build_seats() -> void:
	for i in range(PLAYERS):
		var a := TAU * float(i) / float(PLAYERS)
		var root := Node3D.new()
		root.name = "PlayerStation_%d" % (i + 1)
		root.position = Vector3(sin(a) * SEAT_RADIUS, 0, cos(a) * SEAT_RADIUS)
		# Godot'un -Z ekseni koltugun bakis yonudur.
		add_child(root)
		root.look_at(Vector3(0, 0, 0), Vector3.UP)
		box_part("LeatherSeat", Vector3(0, 0.73, 0.65), Vector3(1.45, 0.26, 1.25), leather, root)
		box_part("LeatherBack", Vector3(0, 1.46, 1.25), Vector3(1.42, 1.52, 0.24), leather, root)
		box_part("Headrest", Vector3(0, 2.23, 1.25), Vector3(1.1, 0.2, 0.26), leather, root)
		for side in [-1.0, 1.0]:
			box_part("Armrest_%s" % str(side), Vector3(side * 0.75, 1.02, 0.7), Vector3(0.17, 0.15, 1.05), leather, root)
			box_part("ChairLeg_%s" % str(side), Vector3(side * 0.52, 0.34, 0.72), Vector3(0.14, 0.68, 0.14), metal, root)
		# Ayri, kosesi belirgin sehpa.
		box_part("PedestalBase", Vector3(0, 0.10, -1.4), Vector3(0.85, 0.13, 0.76), metal, root)
		box_part("PedestalStem", Vector3(0, 0.65, -1.4), Vector3(0.20, 1.12, 0.19), metal, root)
		box_part("RectangularTable", Vector3(0, 1.24, -1.4), Vector3(1.7, 0.15, 1.05), black, root)
		# Oyuncuya bakan dik PC monitoru.
		box_part("MonitorStand", Vector3(0, 1.40, -1.58), Vector3(0.12, 0.24, 0.12), metal, root)
		box_part("MonitorBody", Vector3(0, 1.86, -1.58), Vector3(1.30, 0.77, 0.10), black, root)
		box_part("MonitorScreen", Vector3(0, 1.86, -1.516), Vector3(1.15, 0.62, 0.018), screen, root)

func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#080b10")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#ccd8e1")
	env.ambient_light_energy = 0.48
	world.environment = env
	add_child(world)
	var center := OmniLight3D.new()
	center.name = "WarmBalanceFocus"
	center.position = Vector3(0, 7.2, 0)
	center.light_color = Color("#e9dec8")
	center.light_energy = 2.5
	center.omni_range = 13.0
	center.shadow_enabled = true
	add_child(center)
	for i in range(PLAYERS):
		var a := TAU * float(i) / float(PLAYERS)
		var p := Vector3(sin(a) * SEAT_RADIUS, 8.6, cos(a) * SEAT_RADIUS)
		box_part("CeilingFixture_%d" % i, p + Vector3.UP * 1.0, Vector3(2.4, 0.15, 1.15), metal)
		var light := OmniLight3D.new()
		light.name = "ColdSeatLight_%d" % i
		light.position = p
		light.light_color = Color("#d4e5f3")
		light.light_energy = 2.0
		light.omni_range = 10.0
		add_child(light)

func _build_camera() -> void:
	var cam := Camera3D.new()
	cam.name = "PlayerCamera"
	# Seat 1 is positioned on +Z; the camera sits at seated eye height.
	var eye := Vector3(0.0, 1.75, SEAT_RADIUS + 0.65)
	cam.position = eye
	add_child(cam)
	cam.look_at(Vector3(0.0, 2.1, 0.0), Vector3.UP)
	cam.fov = 75.0
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
	prompt_label.position = Vector2(765, 910)
	prompt_label.visible = false
	hints.add_child(prompt_label)
	terminal_ui.connect("selection_locked", _on_selection_locked)

func _on_selection_locked(value: int) -> void:
	print("DENGE: Selected number locked: ", value)
