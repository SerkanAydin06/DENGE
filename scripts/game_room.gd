extends Node3D
## DENGE prototype room. All geometry is generated using built-in Godot meshes.
## No external 3D models required.

const SEAT_COUNT := 5
const ROOM_RADIUS := 10.5

func _ready() -> void:
	_build_room()
	_build_seats()
	_build_centerpiece()
	_build_lighting()
	_build_camera()


func _material(color: Color, metallic: float = 0.0, roughness: float = 0.75) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material


func _box(name_: String, position_: Vector3, size_: Vector3, material: Material, parent: Node3D = self) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_
	var mesh := BoxMesh.new()
	mesh.size = size_
	node.mesh = mesh
	node.material_override = material
	node.position = position_
	parent.add_child(node)
	return node


func _cylinder(name_: String, position_: Vector3, radius: float, height: float, material: Material, parent: Node3D = self) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.material_override = material
	node.position = position_
	parent.add_child(node)
	return node


func _build_room() -> void:
	var floor_mat := _material(Color("#24262d"), 0.15, 0.42)
	var wall_mat := _material(Color("#171921"))
	var gold := _material(Color("#a3834d"), 0.65, 0.28)
	_cylinder("CircularFloor", Vector3(0, -0.2, 0), ROOM_RADIUS, 0.4, floor_mat)
	_cylinder("RaisedPlatform", Vector3(0, 0.04, 0), 6.9, 0.12, _material(Color("#33343a")))
	for i in range(16):
		var angle := TAU * float(i) / 16.0
		var point := Vector3(sin(angle) * ROOM_RADIUS, 3.1, cos(angle) * ROOM_RADIUS)
		var wall := _box("Wall_%02d" % i, point, Vector3(4.15, 6.3, 0.35), wall_mat)
		wall.rotation.y = angle
	for i in range(12):
		var angle := TAU * float(i) / 12.0
		var point := Vector3(sin(angle) * 9.7, 2.9, cos(angle) * 9.7)
		_cylinder("Pillar_%02d" % i, point, 0.22, 5.8, gold)
	_cylinder("CenterInlay", Vector3(0, 0.115, 0), 2.7, 0.018, gold)


func _build_seats() -> void:
	var seat_mat := _material(Color("#442b2b"), 0.1, 0.65)
	var frame_mat := _material(Color("#aa8952"), 0.7, 0.3)
	var desk_mat := _material(Color("#262932"), 0.15, 0.55)
	for i in range(SEAT_COUNT):
		var angle := TAU * float(i) / float(SEAT_COUNT)
		var seat_root := Node3D.new()
		seat_root.name = "PlayerSeat_%d" % (i + 1)
		seat_root.position = Vector3(sin(angle) * 4.7, 0, cos(angle) * 4.7)
		seat_root.rotation.y = angle + PI
		add_child(seat_root)
		_box("ChairSeat", Vector3(0, 0.75, 0), Vector3(1.45, 0.22, 1.15), seat_mat, seat_root)
		_box("ChairBack", Vector3(0, 1.35, 0.5), Vector3(1.48, 1.35, 0.22), seat_mat, seat_root)
		_box("BackTrim", Vector3(0, 1.98, 0.5), Vector3(1.6, 0.09, 0.3), frame_mat, seat_root)
		for side in [-1.0, 1.0]:
			_box("ChairLeg", Vector3(side * 0.55, 0.35, 0), Vector3(0.16, 0.7, 0.15), frame_mat, seat_root)
		_box("TerminalStand", Vector3(0, 0.85, -1.15), Vector3(0.18, 1.65, 0.2), frame_mat, seat_root)
		_box("Terminal", Vector3(0, 1.7, -1.15), Vector3(1.55, 0.16, 0.85), desk_mat, seat_root)
		_box("TerminalAccent", Vector3(0, 1.8, -1.2), Vector3(1.18, 0.02, 0.52), frame_mat, seat_root)


func _build_centerpiece() -> void:
	var gold := _material(Color("#bf9b5d"), 0.8, 0.22)
	var dark := _material(Color("#202128"), 0.25, 0.5)
	_cylinder("ScaleBase", Vector3(0, 0.36, 0), 1.18, 0.65, dark)
	_cylinder("ScaleStem", Vector3(0, 1.34, 0), 0.09, 1.55, gold)
	_box("ScaleBeam", Vector3(0, 2.12, 0), Vector3(3.2, 0.12, 0.15), gold)
	for side in [-1.0, 1.0]:
		_cylinder("ScaleDish", Vector3(side * 1.42, 1.28, 0), 0.55, 0.08, gold)
		_box("ScaleChain", Vector3(side * 1.42, 1.71, 0), Vector3(0.035, 0.85, 0.035), gold)


func _build_lighting() -> void:
	var world := WorldEnvironment.new()
	world.name = "Environment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0b0c11")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#d4c6a8")
	env.ambient_light_energy = 0.3
	world.environment = env
	add_child(world)
	var key := OmniLight3D.new()
	key.name = "CentralWarmLight"
	key.position = Vector3(0, 5.2, 0)
	key.light_color = Color("#ffdcac")
	key.light_energy = 2.6
	key.omni_range = 16
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.name = "SoftFill"
	fill.rotation_degrees = Vector3(-55, -35, 0)
	fill.light_energy = 0.35
	add_child(fill)


func _build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "OverviewCamera"
	camera.position = Vector3(0, 10.8, 14.8)
	add_child(camera)
	camera.look_at(Vector3(0, 0.9, 0), Vector3.UP)
	camera.fov = 58
	camera.current = true
