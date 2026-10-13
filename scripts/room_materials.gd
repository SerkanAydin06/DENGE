extends RefCounted
## Salonun tum malzemeleri tek yerde tanimlanir.
## res://assets/materials/<ad>.tres varsa prosedurel renk yerine o kullanilir.

const OVERRIDE_DIR := "res://assets/materials/%s.tres"

var _materials: Dictionary = {}

func _init() -> void:
	_define("polished_floor", Color("#1c2025"), 0.25, 0.22)
	_define("concrete", Color("#3b4046"), 0.0, 0.85)
	_define("dark_concrete", Color("#202328"), 0.0, 0.9)
	_define("dome", Color("#2a3036"), 0.0, 0.8, 0.0, true)
	_define("metal", Color("#5f676e"), 0.75, 0.38)
	_define("dark_metal", Color("#23272c"), 0.6, 0.42)
	_define("desk", Color("#30353b"), 0.45, 0.3)
	_define("leather", Color("#141619"), 0.0, 0.5)
	_define("wood", Color("#5b3322"), 0.0, 0.5)
	_define("bezel", Color("#0b0d10"), 0.3, 0.35)
	_define("dome_light", Color("#bfe0e4"), 0.0, 0.5, 1.3)
	_define("oculus", Color("#7fa6ad"), 0.0, 0.5, 0.8)
	_define("sconce", Color("#f3d6a4"), 0.0, 0.5, 2.0)

func _define(key: String, color: Color, metallic: float, roughness: float, glow: float = 0.0, double_sided: bool = false) -> void:
	var path := OVERRIDE_DIR % key
	if ResourceLoader.exists(path):
		_materials[key] = load(path)
		return
	var m := StandardMaterial3D.new()
	m.resource_name = key
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = glow
	if double_sided:
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = m

func mat(key: String) -> Material:
	return _materials[key]
