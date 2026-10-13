extends Node3D
## Oyuncu istasyonu: koltuk, merkeze bakan acili masa, dokunmatik sayi ekrani
## ve yalnizca o oyuncunun gorecegi sonuc monitoru. Orijin koltuk, yerel -Z merkez.

const Kit = preload("res://scripts/mesh_kit.gd")
const Mats = preload("res://scripts/room_materials.gd")

const DESK_HEIGHT := 0.76
const EYE_HEIGHT := 1.25
const DESK_GAP := 0.07
const SCREEN_BG := Color("#08171c")
const SCREEN_ACCENT := Color("#8fd3df")

var player_index: int = 0
var touch_target: Node3D
var _touch_title: Label
var _touch_body: Label
var _result_title: Label
var _result_body: Label

## axis_distance: koltugun merkeze uzakligi. desk_outer/inner: masa kenarlarinin merkeze uzakligi.
func build(mats: Mats, index: int, axis_distance: float, desk_outer: float, desk_inner: float, half_angle: float) -> void:
	player_index = index
	Kit.slot(self, "Chair", "player_chair", Vector3.ZERO, _build_chair.bind(mats))
	var near_z: float = -(axis_distance - desk_outer)
	var far_z: float = -(axis_distance - desk_inner)
	var w_near: float = desk_outer * tan(half_angle) - DESK_GAP
	var w_far: float = desk_inner * tan(half_angle) - DESK_GAP
	var outline := PackedVector2Array([Vector2(-w_near, near_z), Vector2(w_near, near_z), Vector2(w_far, far_z), Vector2(-w_far, far_z)])
	Kit.slot(self, "Desk", "player_desk", Vector3.ZERO, _build_desk.bind(mats, outline))

	# Oyuncuya dogru egimli dokunmatik sayi ekrani.
	var touch := Kit.slot(self, "TouchConsole", "touch_console", Vector3(0, DESK_HEIGHT + 0.1, near_z - 0.3), _build_housing.bind(mats, Vector2(0.62, 0.42)))
	touch.rotation_degrees.x = -72.0
	var touch_labels := _screen(touch, "TouchScreen", Vector2(0.54, 0.35), Vector2i(540, 350))
	_touch_title = touch_labels[0]
	_touch_body = touch_labels[1]
	touch_target = touch

	# Masanin merkez tarafinda dik sonuc monitoru.
	var monitor_z: float = far_z + 0.28
	Kit.box(self, "MonitorStand", Vector3(0, DESK_HEIGHT + 0.03, monitor_z + 0.03), Vector3(0.08, 0.06, 0.05), mats.mat("dark_metal"))
	var monitor := Kit.slot(self, "ResultMonitor", "result_monitor", Vector3(0, DESK_HEIGHT + 0.22, monitor_z), _build_housing.bind(mats, Vector2(0.6, 0.36)))
	monitor.rotation_degrees.x = -14.0
	var result_labels := _screen(monitor, "ResultScreen", Vector2(0.55, 0.31), Vector2i(640, 360))
	_result_title = result_labels[0]
	_result_body = result_labels[1]

	set_touch_text("SAYI GİRİŞİ", "0 - 100")
	set_result_text("DENGE", "BEKLENİYOR")

func eye_position() -> Vector3:
	return to_global(Vector3(0, EYE_HEIGHT, 0.06))

func set_touch_text(title: String, body: String) -> void:
	_touch_title.text = title
	_touch_body.text = body

func set_result_text(title: String, body: String) -> void:
	_result_title.text = title
	_result_body.text = body

func _build_chair(root: Node3D, mats: Mats) -> void:
	var leather := mats.mat("leather")
	var metal := mats.mat("metal")
	for k in range(5):
		var a := TAU * float(k) / 5.0
		var leg := Kit.box(root, "BaseLeg_%d" % k, Vector3(sin(a), 0, cos(a)) * 0.17 + Vector3(0, 0.04, 0.05), Vector3(0.05, 0.04, 0.34), metal)
		leg.rotation.y = a
	Kit.cylinder(root, "Column", Vector3(0, 0.25, 0.05), 0.035, 0.035, 0.38, metal, 12)
	Kit.box(root, "Seat", Vector3(0, 0.48, 0.05), Vector3(0.56, 0.1, 0.52), leather)
	var back := Kit.box(root, "Back", Vector3(0, 0.88, 0.33), Vector3(0.54, 0.66, 0.08), leather)
	back.rotation_degrees.x = 8.0
	for side: float in [-1.0, 1.0]:
		Kit.box(root, "Armrest_%d" % int(side), Vector3(side * 0.31, 0.68, 0.08), Vector3(0.06, 0.04, 0.36), leather)
		Kit.box(root, "ArmSupport_%d" % int(side), Vector3(side * 0.31, 0.59, 0.12), Vector3(0.03, 0.16, 0.03), metal)

func _build_desk(root: Node3D, mats: Mats, outline: PackedVector2Array) -> void:
	Kit.prism(root, "DeskTop", outline, DESK_HEIGHT - 0.06, 0.06, mats.mat("desk"))
	var center := Vector2.ZERO
	for p in outline:
		center += p
	center /= float(outline.size())
	var inner := PackedVector2Array()
	for p in outline:
		inner.append(center + (p - center) * 0.72)
	Kit.prism(root, "DeskBody", inner, 0.0, DESK_HEIGHT - 0.06, mats.mat("dark_metal"))

func _build_housing(root: Node3D, mats: Mats, size_: Vector2) -> void:
	Kit.box(root, "Housing", Vector3(0, 0, -0.03), Vector3(size_.x, size_.y, 0.05), mats.mat("bezel"))

## Viewport tabanli ekran: ileride tam bir Control sahnesiyle degistirilebilir.
func _screen(parent: Node3D, name_: String, size_: Vector2, pixels: Vector2i) -> Array[Label]:
	var vp := SubViewport.new()
	vp.name = name_ + "Viewport"
	vp.size = pixels
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var bg := ColorRect.new()
	bg.color = SCREEN_BG
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vp.add_child(bg)
	var frame := ReferenceRect.new()
	frame.border_color = SCREEN_ACCENT.darkened(0.4)
	frame.border_width = 3.0
	frame.editor_only = false
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 12
	frame.offset_top = 12
	frame.offset_right = -12
	frame.offset_bottom = -12
	vp.add_child(frame)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	vp.add_child(column)
	var labels: Array[Label] = []
	for font_size: int in [int(pixels.y * 0.1), int(pixels.y * 0.2)]:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", SCREEN_ACCENT)
		column.add_child(label)
		labels.append(label)
	var footer := Label.new()
	footer.text = "OYUNCU %d" % (player_index + 1)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", int(pixels.y * 0.07))
	footer.add_theme_color_override("font_color", SCREEN_ACCENT.darkened(0.35))
	column.add_child(footer)

	var quad := QuadMesh.new()
	quad.size = size_
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = vp.get_texture()
	Kit.mesh_node(parent, name_, quad, Vector3(0, 0, 0.0), m)
	return labels
