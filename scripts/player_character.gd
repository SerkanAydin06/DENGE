extends Node3D
class_name DengePlayerCharacter
## Meshy/Mixamo iskeletli karakteri koltukta oturtur ve oyun anlarina gore canlandirir.
## Uzuvlar, dinlenme pozundan bagimsiz olarak model uzayindaki hedef yonlere
## cevrilir (+Z ileri, +X karakterin solu; sag taraf aynalanir). Inspector'dan ayarlanabilir.
##
## Ruh halleri (set_mood): IDLE, THINK (tablete dokunur / dusunur), LOCKED (secti, bekler),
## WATCH (monitore bakar), WIN (sevinir), LOSE (uzulur).

@export var thigh_direction: Vector3 = Vector3(0.08, -0.12, 1.0)
@export var shin_direction: Vector3 = Vector3(0.02, -1.0, 0.12)
@export var foot_direction: Vector3 = Vector3(0.0, -0.35, 1.0)
## Kollar masada: ust kol ve on kol yonleri.
@export var upper_arm_direction: Vector3 = Vector3(0.2, -0.75, 0.6)
@export var forearm_direction: Vector3 = Vector3(0.14, -0.12, 1.0)
@export var spine_pitch: float = 6.0
@export var head_pitch: float = 4.0
## Kalca kemiginin koltuktaki hedef konumu (karakter kokune gore, metre).
## Farkli boydaki modeller bu noktaya hizalanir.
@export var seat_hip_height: float = 0.615
@export var seat_hip_forward: float = 0.0
## Karakter modellerinin cizim katmani (isiklarin cull mask'i ile secici aydinlatma icin).
@export_flags_3d_render var character_layers: int = 1

@export_group("Idle Motion")
## Oturan karakterin nefes alma, hafif sallanma ve etrafa bakinma hareketleri.
@export var idle_motion: bool = true
@export_range(0.0, 5.0, 0.1) var breath_degrees: float = 1.6
@export_range(0.05, 1.0, 0.01) var breath_speed: float = 0.26
@export_range(0.0, 5.0, 0.1) var sway_degrees: float = 1.4
@export_range(0.0, 40.0, 0.5) var look_yaw_degrees: float = 22.0
@export_range(0.0, 15.0, 0.5) var look_pitch_degrees: float = 6.0
@export_range(1.0, 15.0, 0.5) var look_interval: float = 3.5

@export_group("Moods")
## Ruh hali gecislerinin hizi (buyudukce daha hizli).
@export_range(0.5, 12.0, 0.1) var mood_blend_speed: float = 4.0
## WATCH: monitore bakis icin bas ve govde egimi (negatif = yukari).
@export var watch_head_pitch: float = -22.0
@export var watch_spine_pitch: float = -4.0
@export_range(0.5, 6.0, 0.1) var tap_speed: float = 3.2

const MOODS: Array[String] = ["IDLE", "THINK", "LOCKED", "WATCH", "WIN", "LOSE"]

var skeleton: Skeleton3D
var mood: String = "IDLE"
var _time: float = 0.0
var _mood_time: float = 0.0
var _look_target: Vector2 = Vector2.ZERO
var _look_current: Vector2 = Vector2.ZERO
var _next_look: float = 0.0
var _think_chin: bool = false
var _next_think_switch: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()
## Su anki (karisik) poz parametreleri; her karede hedefe dogru yumusakca ilerler.
var _current: Dictionary = {}

func _ready() -> void:
	var found: Array[Node] = find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		push_warning("DENGE: karakterde Skeleton3D bulunamadi")
		return
	skeleton = found[0] as Skeleton3D
	for mesh in find_children("*", "MeshInstance3D", true, false):
		(mesh as MeshInstance3D).layers = character_layers
	_time = randf() * 100.0
	_next_look = randf_range(0.5, look_interval)
	_noise.seed = randi()
	_noise.frequency = 0.35
	_current = _mood_targets("IDLE")
	apply_seated_pose()
	_align_hips_to_seat()

## Oyun akisi tarafindan cagrilir. Bilinmeyen deger IDLE kabul edilir.
func set_mood(new_mood: String) -> void:
	if not MOODS.has(new_mood):
		new_mood = "IDLE"
	if new_mood == mood:
		return
	mood = new_mood
	_mood_time = 0.0
	_next_think_switch = randf_range(1.5, 3.0)
	_think_chin = randf() < 0.4

func apply_seated_pose() -> void:
	_build_pose(_current)

func _process(delta: float) -> void:
	if skeleton == null or not is_visible_in_tree():
		return
	_time += delta
	_mood_time += delta
	_update_look(delta)
	if mood == "THINK":
		_next_think_switch -= delta
		if _next_think_switch <= 0.0:
			_think_chin = not _think_chin
			_next_think_switch = randf_range(2.0, 4.0) if _think_chin else randf_range(1.5, 3.5)
	var target: Dictionary = _mood_targets(mood)
	var blend: float = 1.0 - exp(-delta * mood_blend_speed)
	for key in target:
		_current[key] = lerp(_current[key], target[key], blend)
	_build_pose(_current)

## Her ruh hali icin hedef poz parametreleri. Kol yonleri sol taraf icindir.
func _mood_targets(state: String) -> Dictionary:
	var t: Dictionary = {
		"spine": spine_pitch,
		"head": head_pitch,
		"yaw": 0.0,
		"l_upper": upper_arm_direction,
		"l_fore": forearm_direction,
		"r_upper": upper_arm_direction,
		"r_fore": forearm_direction,
		"look": 1.0,
	}
	match state:
		"THINK":
			t["head"] = head_pitch + 10.0
			t["look"] = 0.3
			if _think_chin:
				# Sol el cenede: dusunuyor.
				t["l_upper"] = Vector3(0.05, -0.5, 0.86)
				t["l_fore"] = Vector3(-0.5, 0.45, 0.1)
				t["head"] = head_pitch + 4.0
			# Sag el tablete ritmik dokunur.
			var tap: float = maxf(0.0, sin(_mood_time * TAU * tap_speed))
			t["r_upper"] = Vector3(0.12, -0.7, 0.7)
			t["r_fore"] = Vector3(-0.05, lerpf(-0.45, -0.1, tap), 1.0)
		"LOCKED":
			t["spine"] = spine_pitch - 5.0
			t["l_fore"] = Vector3(0.3, -0.1, 1.0)
			t["r_fore"] = Vector3(0.3, -0.1, 1.0)
		"WATCH":
			t["spine"] = watch_spine_pitch
			t["head"] = watch_head_pitch
			t["look"] = 0.15
		"WIN":
			var pump: float = sin(_mood_time * TAU * 1.6)
			t["spine"] = -8.0
			t["head"] = -14.0
			t["look"] = 0.0
			t["l_upper"] = Vector3(0.35, 0.9, 0.12)
			t["r_upper"] = Vector3(0.35, 0.9, 0.12)
			t["l_fore"] = Vector3(0.1, 1.0, 0.1 + 0.35 * pump)
			t["r_fore"] = Vector3(0.1, 1.0, 0.1 - 0.35 * pump)
		"LOSE":
			t["spine"] = spine_pitch + 16.0
			t["head"] = head_pitch + 26.0
			t["yaw"] = sin(_mood_time * TAU * 0.45) * 10.0 * exp(-_mood_time * 0.25)
			t["look"] = 0.0
			t["l_upper"] = Vector3(0.12, -0.85, 0.45)
			t["r_upper"] = Vector3(0.12, -0.85, 0.45)
			t["l_fore"] = Vector3(-0.2, -0.35, 1.0)
			t["r_fore"] = Vector3(-0.2, -0.35, 1.0)
	return t

func _update_look(delta: float) -> void:
	_next_look -= delta
	if _next_look <= 0.0:
		# Cogu zaman merkeze, ara sira yandaki oyunculara bakar.
		if randf() < 0.35:
			_look_target = Vector2.ZERO
		else:
			_look_target = Vector2(randf_range(-1.0, 1.0) * look_yaw_degrees, randf_range(-0.5, 1.0) * look_pitch_degrees)
		_next_look = randf_range(look_interval * 0.6, look_interval * 1.5)
	_look_current = _look_current.lerp(_look_target, 1.0 - exp(-delta * 2.5))

func _build_pose(p: Dictionary) -> void:
	skeleton.reset_bone_poses()
	var breath: float = sin(_time * TAU * breath_speed) if idle_motion else 0.0
	var sway: float = _noise.get_noise_1d(_time * 10.0) if idle_motion else 0.0
	var look: Vector2 = _look_current * float(p["look"]) if idle_motion else Vector2.ZERO

	_rotate_global(_find_bone("Spine"), Basis(Vector3.RIGHT, deg_to_rad(float(p["spine"]) + breath * breath_degrees)) * Basis(Vector3.BACK, deg_to_rad(sway * sway_degrees)))
	for side: String in ["Left", "Right"]:
		var side_sign: float = 1.0 if side == "Left" else -1.0
		_rotate_global(_find_bone(side + "Shoulder"), Basis(Vector3.BACK, deg_to_rad(breath * 0.8 * side_sign)))
	var yaw: float = float(p["yaw"]) + look.x
	var pitch: float = float(p["head"]) + look.y
	var neck: int = _find_bone("Neck")
	var head_share: float = 0.5 if neck >= 0 else 1.0
	var turn: Basis = Basis(Vector3.UP, deg_to_rad(yaw * head_share)) * Basis(Vector3.RIGHT, deg_to_rad(pitch * head_share))
	_rotate_global(neck, turn)
	_rotate_global(_find_bone("Head"), turn)

	for side: String in ["Left", "Right"]:
		var mirror := Vector3(1, 1, 1) if side == "Left" else Vector3(-1, 1, 1)
		var prefix: String = "l_" if side == "Left" else "r_"
		_aim(side + "UpLeg", side + "Leg", thigh_direction * mirror)
		_aim(side + "Leg", side + "Foot", shin_direction * mirror)
		_aim(side + "Foot", side + "ToeBase", foot_direction * mirror)
		_aim(side + "Arm", side + "ForeArm", (p[prefix + "upper"] as Vector3) * mirror)
		_aim(side + "ForeArm", side + "Hand", (p[prefix + "fore"] as Vector3) * mirror)

func _align_hips_to_seat() -> void:
	var hips: int = _find_bone("Hips")
	var model: Node3D = get_node_or_null("Model") as Node3D
	if hips < 0 or model == null:
		return
	var hip_local: Vector3 = to_local(skeleton.to_global(skeleton.get_bone_global_pose(hips).origin))
	model.position += Vector3(0, seat_hip_height, -seat_hip_forward) - Vector3(0, hip_local.y, hip_local.z)

## Kemigi, cocuk kemigine giden yonu model uzayinda `direction` olacak sekilde dondurur.
func _aim(bone_suffix: String, child_suffix: String, direction: Vector3) -> void:
	var bone: int = _find_bone(bone_suffix)
	var child: int = _find_bone(child_suffix)
	if bone < 0 or child < 0 or direction.is_zero_approx():
		return
	var bone_global: Transform3D = _global_pose(bone)
	var child_position: Vector3 = _global_pose(child).origin
	var bone_direction: Vector3 = child_position - bone_global.origin
	if bone_direction.length_squared() <= 0.00000001:
		return
	var current: Vector3 = bone_direction.normalized()
	var delta := Quaternion(current, direction.normalized())
	_set_global_basis(bone, Basis(delta) * bone_global.basis.orthonormalized())

## Kemigi kendi ekleminde model uzayindaki bir donusle dondurur.
func _rotate_global(bone: int, rotation_delta: Basis) -> void:
	if bone < 0:
		return
	_set_global_basis(bone, rotation_delta * _global_pose(bone).basis.orthonormalized())

func _set_global_basis(bone: int, target_basis: Basis) -> void:
	# Godot handles the bone rest and parent offsets when converting a global pose.
	var pose: Transform3D = _global_pose(bone)
	pose.basis = target_basis.orthonormalized()
	skeleton.set_bone_global_pose(bone, pose)

func _global_pose(bone: int) -> Transform3D:
	# get_bone_pose() alone omits the bone's rest hierarchy.
	return skeleton.get_bone_global_pose(bone)

## Mixamo ("mixamorig_Hips") ve Meshy ("Hips") adlandirmasini birlikte destekler.
func _find_bone(bone_suffix: String) -> int:
	for bone_name in ["mixamorig_" + bone_suffix, "mixamorig:" + bone_suffix, bone_suffix, bone_suffix.to_lower()]:
		var bone: int = skeleton.find_bone(bone_name)
		if bone >= 0:
			return bone
	return -1
