extends Node3D
## Dekoratif buyuk terazi heykeli. `tilt` (-1..1) ileride sonuc animasyonu icin hazir.

const Kit = preload("res://scripts/mesh_kit.gd")
const Mats = preload("res://scripts/room_materials.gd")

var tilt: float = 0.0: set = set_tilt
var _pivots: Array[Node3D] = []
var _hangers: Array[Node3D] = []

func build(mats: Mats, pedestal_height: float = 2.6) -> void:
	var stone := mats.mat("dark_concrete")
	var metal := mats.mat("dark_metal")
	var top: float = 0.0
	if pedestal_height > 0.0:
		Kit.box(self, "Pedestal", Vector3(0, pedestal_height * 0.5, 0), Vector3(0.9, pedestal_height, 0.9), stone)
		Kit.box(self, "PedestalCap", Vector3(0, pedestal_height + 0.06, 0), Vector3(1.08, 0.12, 1.08), stone)
		top = pedestal_height + 0.12
	Kit.cylinder(self, "Foot", Vector3(0, top + 0.1, 0), 0.12, 0.3, 0.2, metal, 24)
	Kit.cylinder(self, "Stem", Vector3(0, top + 1.3, 0), 0.05, 0.09, 2.2, metal, 16)
	Kit.cylinder(self, "Finial", Vector3(0, top + 2.65, 0), 0.0, 0.09, 0.5, metal, 4)
	_tier(top + 2.2, 1.15, 0.42, 0.0, metal)
	_tier(top + 1.35, 0.78, 0.3, 90.0, metal)

func _tier(y: float, span: float, pan_r: float, yaw_deg: float, metal: Material) -> void:
	var yaw := Node3D.new()
	yaw.name = "Tier_%d" % _pivots.size()
	yaw.position = Vector3(0, y, 0)
	yaw.rotation_degrees.y = yaw_deg
	add_child(yaw)
	var pivot := Node3D.new()
	pivot.name = "BeamPivot"
	yaw.add_child(pivot)
	_pivots.append(pivot)
	Kit.box(pivot, "Beam", Vector3.ZERO, Vector3(span * 1.7, 0.07, 0.07), metal)
	for side: float in [-1.0, 1.0]:
		# Uca dogru yukari kivrilan kol.
		Kit.rod(pivot, "Arm_%d" % int(side), Vector3(side * span * 0.85, 0.0, 0), Vector3(side * span, 0.22, 0), 0.05, metal)
		var hanger := Node3D.new()
		hanger.name = "Hanger_%d" % int(side)
		hanger.position = Vector3(side * span, 0.22, 0)
		pivot.add_child(hanger)
		_hangers.append(hanger)
		var drop: float = 0.95 * span
		for k in range(3):
			var a := TAU * float(k) / 3.0
			Kit.rod(hanger, "Chain_%d" % k, Vector3.ZERO, Vector3(cos(a) * pan_r * 0.8, -drop, sin(a) * pan_r * 0.8), 0.014, metal)
		Kit.cylinder(hanger, "Pan", Vector3(0, -drop - 0.05, 0), pan_r, pan_r * 0.5, 0.12, metal, 32)

func set_tilt(value: float) -> void:
	tilt = clampf(value, -1.0, 1.0)
	for p in _pivots:
		p.rotation.z = tilt * 0.3
	for h in _hangers:
		h.rotation.z = -tilt * 0.3
