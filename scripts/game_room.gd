extends Node3D
## Sinematik, sade bir mahkeme salonu prototipi.
## Tum mimari ve mobilyalar Godot primitive meshlerinden olusur.

const WALL := Color("#343940")
const FLOOR := Color("#26292d")
const METAL := Color("#565c64")
const BLACK := Color("#10151a")
const SCREEN := Color("#9db9b3")

func mat(color: Color, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = 0.68
	return m

func block(part: String, pos: Vector3, size: Vector3, material: Material, parent: Node3D = null) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = part
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	mesh.material_override = material
	mesh.position = pos
	(parent if parent != null else self).add_child(mesh)
	return mesh

func label3d(value: String, pos: Vector3, pixel_size: float = 0.008, parent: Node3D = null) -> Label3D:
	var label := Label3D.new()
	label.text = value
	label.pixel_size = pixel_size
	label.font_size = 38
	label.modulate = Color("#dce7e3")
	label.outline_size = 4
	label.position = pos
	(parent if parent != null else self).add_child(label)
	return label

func _ready() -> void:
	build_shell()
	build_stations()
	build_display()
	build_lights()
	build_camera()

func build_shell() -> void:
	var concrete := mat(WALL)
	var tiles := mat(FLOOR)
	var dark := mat(BLACK)
	block("StoneFloor", Vector3(0, -0.16, 0), Vector3(19, 0.3, 17), tiles)
	block("RearWall", Vector3(0, 4.5, -8.3), Vector3(19, 9, 0.45), concrete)
	block("LeftWall", Vector3(-9.3, 4.5, 0), Vector3(0.45, 9, 17), concrete)
	block("RightWall", Vector3(9.3, 4.5, 0), Vector3(0.45, 9, 17), concrete)
	block("Ceiling", Vector3(0, 9.0, 0), Vector3(19, 0.35, 17), concrete)
	block("RearFeature", Vector3(0, 4.8, -8.0), Vector3(8.0, 6.8, 0.12), dark)
	for i in range(7):
		var x := -8.0 + i * 2.67
		block("WallSeam_%d" % i, Vector3(x, 4.4, -8.04), Vector3(0.035, 8.2, 0.08), mat(Color("#20242a")))
	for i in range(6):
		block("FloorJoint_%d" % i, Vector3(-7.5 + i * 3.0, 0.005, 0), Vector3(0.024, 0.006, 16.2), mat(Color("#171b20")))

func build_stations() -> void:
	var chair := mat(Color("#272e35"))
	var steel := mat(METAL, 0.6)
	var terminal := mat(BLACK)
	var panel := mat(SCREEN)
	# Bes istasyon: on sirada uc, arka sirada iki.
	var spots := [
		Vector3(-5.6, 0, 1.7), Vector3(0, 0, 1.7), Vector3(5.6, 0, 1.7),
		Vector3(-2.8, 0, -3.2), Vector3(2.8, 0, -3.2)
	]
	for i in range(spots.size()):
		var seat := Node3D.new()
		seat.name = "PlayerStation_%d" % (i + 1)
		seat.position = spots[i]
		add_child(seat)
		block("DeskTop", Vector3(0, 1.30, -0.55), Vector3(2.6, 0.13, 1.1), terminal, seat)
		for side in [-1.0, 1.0]:
			block("DeskLeg", Vector3(side * 1.12, 0.65, -0.55), Vector3(0.12, 1.3, 0.12), steel, seat)
		block("ChairCushion", Vector3(0, 0.66, 0.93), Vector3(1.12, 0.18, 1.05), chair, seat)
		block("ChairBack", Vector3(0, 1.21, 1.40), Vector3(1.15, 1.12, 0.17), chair, seat)
		block("Tablet", Vector3(0, 1.71, -0.66), Vector3(0.98, 0.78, 0.09), terminal, seat)
		block("TabletDisplay", Vector3(0, 1.72, -0.60), Vector3(0.84, 0.63, 0.02), panel, seat)
		label3d("00", Vector3(0, 1.75, -0.574), 0.009, seat)
		block("SideMonitor", Vector3(1.0, 1.79, -0.77), Vector3(0.52, 0.66, 0.11), terminal, seat)
		block("StatusScreen", Vector3(1.0, 1.80, -0.705), Vector3(0.43, 0.53, 0.02), mat(Color("#6f171f")), seat)
		label3d("P%d" % (i + 1), Vector3(1.0, 1.79, -0.68), 0.004, seat)
		block("OverheadFixture", Vector3(0, 6.85, -0.5), Vector3(2.4, 0.15, 1.0), steel, seat)
		block("OverheadDiffuser", Vector3(0, 6.75, -0.5), Vector3(2.1, 0.025, 0.74), mat(Color("#d0d6cf")), seat)

func build_display() -> void:
	var panel := mat(BLACK)
	var pale := mat(Color("#819b9a"))
	block("ScoreboardFrame", Vector3(0, 5.40, -7.68), Vector3(6.6, 2.5, 0.2), panel)
	block("ScoreboardGlass", Vector3(0, 5.4, -7.54), Vector3(6.35, 2.25, 0.035), pale)
	label3d("D E N G E", Vector3(0, 5.78, -7.50), 0.015)
	label3d("0.8", Vector3(0, 4.92, -7.50), 0.016)

func build_lights() -> void:
	var world := WorldEnvironment.new()
	world.name = "Atmosphere"
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#0c1014")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#c3d0d1")
	environment.ambient_light_energy = 0.48
	world.environment = environment
	add_child(world)
	for idx in range(5):
		var coords := [Vector3(-5.6, 6.5, 1.7), Vector3(0, 6.5, 1.7), Vector3(5.6, 6.5, 1.7), Vector3(-2.8, 6.5, -3.2), Vector3(2.8, 6.5, -3.2)]
		var light := OmniLight3D.new()
		light.name = "ColdLight_%d" % idx
		light.position = coords[idx]
		light.light_color = Color("#d3e3e7")
		light.light_energy = 2.5
		light.omni_range = 8.0
		light.shadow_enabled = true
		add_child(light)

func build_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "OverviewCamera"
	camera.position = Vector3(0, 7.7, 12.9)
	add_child(camera)
	camera.look_at(Vector3(0, 2.1, -2.3))
	camera.fov = 67
	camera.current = true
