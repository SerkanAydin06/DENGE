extends RefCounted
## Prosedurel geometri yardimcilari.
## Her buyuk parca bir "slot" ile kurulur: res://assets/models/<slot>.tscn varsa
## prosedurel yer tutucu yerine o sahne kullanilir (ileride gercek modeller icin).

const MODEL_DIR := "res://assets/models/%s.tscn"

static func slot(parent: Node3D, name_: String, slot_id: String, at: Vector3, builder: Callable) -> Node3D:
	var anchor := Node3D.new()
	anchor.name = name_
	anchor.position = at
	anchor.set_meta("asset_slot", slot_id)
	parent.add_child(anchor)
	var path := MODEL_DIR % slot_id
	if ResourceLoader.exists(path):
		var packed := load(path) as PackedScene
		if packed != null:
			anchor.add_child(packed.instantiate())
			return anchor
	builder.call(anchor)
	return anchor

static func mesh_node(parent: Node3D, name_: String, mesh: Mesh, at: Vector3, mat: Material) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = name_
	n.mesh = mesh
	n.material_override = mat
	n.position = at
	parent.add_child(n)
	return n

static func box(parent: Node3D, name_: String, at: Vector3, size_: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size_
	return mesh_node(parent, name_, mesh, at, mat)

static func cylinder(parent: Node3D, name_: String, at: Vector3, top_r: float, bottom_r: float, height_: float, mat: Material, segments: int = 48, caps: bool = true) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height_
	mesh.radial_segments = segments
	mesh.rings = 1
	mesh.cap_top = caps
	mesh.cap_bottom = caps
	return mesh_node(parent, name_, mesh, at, mat)

static func ring(parent: Node3D, name_: String, at: Vector3, radius: float, thickness: float, mat: Material) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius - thickness * 0.5
	mesh.outer_radius = radius + thickness * 0.5
	mesh.rings = 96
	mesh.ring_segments = 6
	return mesh_node(parent, name_, mesh, at, mat)

## Iki nokta arasinda ince cubuk (zincir, destek vb.).
static func rod(parent: Node3D, name_: String, from: Vector3, to: Vector3, thickness: float, mat: Material) -> MeshInstance3D:
	var dir := to - from
	var n := box(parent, name_, (from + to) * 0.5, Vector3(thickness, dir.length(), thickness), mat)
	var axis := Vector3.UP.cross(dir.normalized())
	if axis.length() > 0.0001:
		n.basis = Basis(axis.normalized(), Vector3.UP.angle_to(dir))
	return n

## XZ duzleminde dis bukey cokgeni y'den yukari dogru ekstrude eder.
static func prism(parent: Node3D, name_: String, polygon: PackedVector2Array, y: float, height_: float, mat: Material) -> MeshInstance3D:
	var pts := polygon.duplicate()
	var area: float = 0.0
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		area += a.x * b.y - b.x * a.y
	if area < 0.0:
		pts.reverse()
	var top: float = y + height_
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, pts.size() - 1):
		for p: Vector2 in [pts[0], pts[i], pts[i + 1]]:
			st.set_normal(Vector3.UP)
			st.set_uv(p)
			st.add_vertex(Vector3(p.x, top, p.y))
		for p: Vector2 in [pts[0], pts[i + 1], pts[i]]:
			st.set_normal(Vector3.DOWN)
			st.set_uv(p)
			st.add_vertex(Vector3(p.x, y, p.y))
	var run: float = 0.0
	for i in range(pts.size()):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var edge := b - a
		var normal := Vector3(edge.y, 0.0, -edge.x).normalized()
		var next_run: float = run + edge.length()
		var quad := [
			[Vector3(a.x, y, a.y), Vector2(run, y)], [Vector3(b.x, y, b.y), Vector2(next_run, y)], [Vector3(b.x, top, b.y), Vector2(next_run, top)],
			[Vector3(a.x, y, a.y), Vector2(run, y)], [Vector3(b.x, top, b.y), Vector2(next_run, top)], [Vector3(a.x, top, a.y), Vector2(run, top)],
		]
		for v in quad:
			st.set_normal(normal)
			st.set_uv(v[1])
			st.add_vertex(v[0])
		run = next_run
	return mesh_node(parent, name_, st.commit(), Vector3.ZERO, mat)
