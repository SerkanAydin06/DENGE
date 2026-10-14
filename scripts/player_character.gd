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
@export_range(0.5, 6.0, 0.1) var tap_speed: float = 2.4

const MOODS: Array[String] = ["IDLE", "THINK", "LOCKED", "WATCH", "WIN", "LOSE"]
const FINGER_NAMES: Array[String] = ["Index", "Middle", "Ring", "Pinky"]
const RELAXED_FINGERS: Vector3 = Vector3(18, 26, 14)
const RELAXED_THUMB: Vector3 = Vector3(10, 15, 8)
const FIST_FINGERS: Vector3 = Vector3(85, 95, 65)
const FIST_THUMB: Vector3 = Vector3(35, 45, 25)
const HOLD_CURL: Vector3 = Vector3(35, 45, 30)
const HOLD_THUMB: Vector3 = Vector3(5, 10, 5)

var skeleton: Skeleton3D
var mood: String = "IDLE"
## Birinci sahis: bas gizlenir, kendiliginden hareketler kapanir, kamera goz noktasini izler.
var first_person: bool = false
var _view_yaw_degrees: float = 0.0
var _hold_left: Vector3 = Vector3.ZERO
var _hold_right: Vector3 = Vector3.ZERO
var _holding: bool = false
var _hold_weight: float = 0.0
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
	# Tek katmanli, yavas gurultu: fraktal katmanlar kare kare titreme uretiyordu.
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.fractal_type = FastNoiseLite.FRACTAL_NONE
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

func set_first_person(enabled: bool) -> void:
	first_person = enabled
	_look_current = Vector2.ZERO
	_look_target = Vector2.ZERO

## Birinci sahiste kamera yonu (derece); govde ve omuzlar bir kismini izler.
func set_view_yaw(degrees: float) -> void:
	_view_yaw_degrees = degrees

## Tablet tutulurken iki elin dunya uzayindaki tutma noktalari.
func set_hold_targets(left_world: Vector3, right_world: Vector3, holding: bool) -> void:
	_holding = holding
	if holding:
		_hold_left = left_world
		_hold_right = right_world

## Kafanin icindeki goz noktasi (dunya uzayi). Birinci sahis kamerasi bunu izler.
func eye_global_position() -> Vector3:
	var head: int = _find_bone("Head")
	if skeleton == null or head < 0:
		return global_position + Vector3(0, 1.2, 0)
	var xf: Transform3D = skeleton.global_transform
	var origin: Vector3 = xf * _global_pose(head).origin
	var up: Vector3 = (xf.basis * Vector3.UP).normalized()
	var forward: Vector3 = (xf.basis * Vector3.BACK).normalized()
	return origin + up * 0.085 + forward * 0.09

func apply_seated_pose() -> void:
	_build_pose(_current)

func _process(delta: float) -> void:
	if skeleton == null or not is_visible_in_tree():
		return
	_time += delta
	_mood_time += delta
	_hold_weight = move_toward(_hold_weight, 1.0 if _holding else 0.0, delta * 3.5)
	if first_person:
		_look_current = Vector2.ZERO
	else:
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
		# Avuc yonu (sol el icin; sag aynalanir) ve parmak bukumleri (eklem 1-2-3, derece).
		"l_palm": Vector3(-0.3, -1.0, 0.1),
		"r_palm": Vector3(-0.3, -1.0, 0.1),
		"l_fingers": RELAXED_FINGERS,
		"r_fingers": RELAXED_FINGERS,
		"l_index": RELAXED_FINGERS,
		"r_index": RELAXED_FINGERS,
		"l_thumb": RELAXED_THUMB,
		"r_thumb": RELAXED_THUMB,
	}
	if first_person and state == "THINK":
		state = "IDLE"
	match state:
		"THINK":
			t["head"] = head_pitch + 10.0
			t["look"] = 0.3
			if _think_chin:
				# Sol el cenede: dusunuyor.
				t["l_upper"] = Vector3(0.05, -0.5, 0.86)
				t["l_fore"] = Vector3(-0.5, 0.45, 0.1)
				t["l_palm"] = Vector3(-0.6, 0.2, -1.0)
				t["l_fingers"] = Vector3(65, 85, 55)
				t["l_index"] = Vector3(45, 60, 35)
				t["l_thumb"] = Vector3(20, 25, 10)
				t["head"] = head_pitch + 4.0
			# Sag el tablete ritmik dokunur.
			# Yumusak dalga: keskin kose yok, el titremeden iner kalkar.
			var tap: float = 0.5 - 0.5 * cos(_mood_time * TAU * tap_speed)
			t["r_upper"] = Vector3(0.12, -0.7, 0.7)
			t["r_fore"] = Vector3(-0.05, lerpf(-0.45, -0.1, tap), 1.0)
			# Isaret parmagi acik, digerleri kivrik: tablete dokunur.
			t["r_fingers"] = Vector3(55, 75, 45)
			t["r_index"] = Vector3(8.0 + 18.0 * tap, 10, 5)
			t["r_thumb"] = Vector3(25, 30, 15)
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
			# Sikili yumruklar, avuclar one.
			t["l_palm"] = Vector3(0.0, 0.2, 1.0)
			t["r_palm"] = Vector3(0.0, 0.2, 1.0)
			for side_key in ["l_", "r_"]:
				t[side_key + "fingers"] = FIST_FINGERS
				t[side_key + "index"] = FIST_FINGERS
				t[side_key + "thumb"] = FIST_THUMB
		"LOSE":
			t["spine"] = spine_pitch + 16.0
			t["head"] = head_pitch + 26.0
			t["yaw"] = sin(_mood_time * TAU * 0.45) * 10.0 * exp(-_mood_time * 0.25)
			t["look"] = 0.0
			t["l_upper"] = Vector3(0.12, -0.85, 0.45)
			t["r_upper"] = Vector3(0.12, -0.85, 0.45)
			t["l_fore"] = Vector3(-0.2, -0.35, 1.0)
			t["r_fore"] = Vector3(-0.2, -0.35, 1.0)
			t["l_fingers"] = Vector3(28, 35, 22)
			t["r_fingers"] = Vector3(28, 35, 22)
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
	if first_person:
		breath *= 0.4
	# Birinci sahiste kamera govdeyi izledigi icin sallanma kapali.
	var sway: float = _noise.get_noise_1d(_time) if idle_motion and not first_person else 0.0
	var look: Vector2 = _look_current * float(p["look"]) if idle_motion else Vector2.ZERO

	var body_yaw: float = _view_yaw_degrees * 0.35 if first_person else 0.0
	_rotate_global(_find_bone("Spine"), Basis(Vector3.UP, deg_to_rad(body_yaw)) * Basis(Vector3.RIGHT, deg_to_rad(float(p["spine"]) + breath * breath_degrees)) * Basis(Vector3.BACK, deg_to_rad(sway * sway_degrees)))
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
		var upper: Vector3 = (p[prefix + "upper"] as Vector3) * mirror
		var fore: Vector3 = (p[prefix + "fore"] as Vector3) * mirror
		var palm_dir: Vector3 = (p[prefix + "palm"] as Vector3) * mirror
		var curls: Dictionary = p
		if _hold_weight > 0.0:
			var ik: Array = _solve_arm(side, _hold_left if side == "Left" else _hold_right, mirror)
			if not ik.is_empty():
				upper = upper.normalized().lerp(ik[0], _hold_weight)
				fore = fore.normalized().lerp(ik[1], _hold_weight)
				# Avuclar tabletin yanlarina doner, parmaklar kenari kavrar.
				palm_dir = palm_dir.normalized().lerp(Vector3(-1.0, 0.35, -0.2) * mirror, _hold_weight)
				curls = p.duplicate()
				for key in ["fingers", "index", "thumb"]:
					curls[prefix + key] = (p[prefix + key] as Vector3).lerp(HOLD_CURL if key != "thumb" else HOLD_THUMB, _hold_weight)
		_aim(side + "Arm", side + "ForeArm", upper)
		_aim(side + "ForeArm", side + "Hand", fore)
		_twist_palm(side, palm_dir)
		_curl_fingers(side, curls, prefix)
	if first_person:
		# Kamera kafanin icinde: kafa ve sac kucultulerek gizlenir.
		var head_bone: int = _find_bone("Head")
		if head_bone >= 0:
			skeleton.set_bone_pose_scale(head_bone, Vector3.ONE * 0.001)

## Iki kemikli basit IK: omuzdan hedefe uzanan ust kol ve on kol yonleri (model uzayi).
func _solve_arm(side: String, target_world: Vector3, mirror: Vector3) -> Array:
	var arm: int = _find_bone(side + "Arm")
	var forearm: int = _find_bone(side + "ForeArm")
	var hand: int = _find_bone(side + "Hand")
	if arm < 0 or forearm < 0 or hand < 0:
		return []
	var shoulder: Vector3 = _global_pose(arm).origin
	var upper_len: float = _global_pose(arm).origin.distance_to(_global_pose(forearm).origin)
	var fore_len: float = _global_pose(forearm).origin.distance_to(_global_pose(hand).origin)
	var target: Vector3 = skeleton.global_transform.affine_inverse() * target_world
	var reach: Vector3 = target - shoulder
	var dist: float = clampf(reach.length(), 0.001, (upper_len + fore_len) * 0.995)
	if reach.is_zero_approx() or upper_len <= 0.0:
		return []
	var cos_a: float = clampf((upper_len * upper_len + dist * dist - fore_len * fore_len) / (2.0 * upper_len * dist), -1.0, 1.0)
	var pole: Vector3 = Vector3(0.6, -1.0, -0.3) * mirror
	var bend_axis: Vector3 = reach.cross(pole)
	if bend_axis.is_zero_approx():
		return []
	var upper_dir: Vector3 = reach.normalized().rotated(bend_axis.normalized(), acos(cos_a))
	var elbow: Vector3 = shoulder + upper_dir * upper_len
	return [upper_dir, (shoulder + reach.normalized() * dist - elbow).normalized()]

## On kolu kendi ekseni etrafinda cevirerek avucu hedef yone dondurur.
func _twist_palm(side: String, target_palm: Vector3) -> void:
	var forearm: int = _find_bone(side + "ForeArm")
	var hand: int = _find_bone(side + "Hand")
	var index: int = _find_bone(side + "HandIndex1")
	var pinky: int = _find_bone(side + "HandPinky1")
	var middle: int = _find_bone(side + "HandMiddle1")
	if forearm < 0 or hand < 0 or index < 0 or pinky < 0 or middle < 0:
		return
	var axis: Vector3 = _global_pose(hand).origin - _global_pose(forearm).origin
	var fingers: Vector3 = _global_pose(middle).origin - _global_pose(hand).origin
	var across: Vector3 = _global_pose(index).origin - _global_pose(pinky).origin
	if axis.is_zero_approx() or fingers.is_zero_approx() or across.is_zero_approx():
		return
	axis = axis.normalized()
	# Anatomik avuc normali: sol elde parmaklar x (serce->isaret), sag elde tersi.
	var palm: Vector3 = fingers.cross(across) * (1.0 if side == "Left" else -1.0)
	var current: Vector3 = (palm - axis * palm.dot(axis))
	var wanted: Vector3 = (target_palm - axis * target_palm.dot(axis))
	if current.length_squared() < 0.000001 or wanted.length_squared() < 0.000001:
		return
	var angle: float = current.normalized().signed_angle_to(wanted.normalized(), axis)
	_rotate_global(forearm, Basis(axis, clampf(angle, -2.6, 2.6)))

## Parmak eklemlerini kendi yerel X ekseni etrafinda avuca dogru bukar.
func _curl_fingers(side: String, p: Dictionary, prefix: String) -> void:
	var palm: Vector3 = _palm_normal(side)
	var drum: float = 0.0
	if idle_motion and not first_person and (mood == "LOCKED" or mood == "WATCH" or mood == "IDLE"):
		drum = 1.0
	for finger_index in range(FINGER_NAMES.size()):
		var finger: String = FINGER_NAMES[finger_index]
		var curl: Vector3 = p[prefix + ("index" if finger == "Index" else "fingers")]
		# Beklerken parmaklarla masaya tiklatma dalgasi.
		var finger_wave: float = 0.5 - 0.5 * cos(_time * TAU * 1.3 - float(finger_index) * 0.9)
		var burst: float = clampf(sin(_time * 0.7), 0.0, 1.0)
		var wave: float = drum * finger_wave * burst * burst
		_curl_chain(side + "Hand" + finger, curl + Vector3(18.0, 10.0, 0.0) * wave, palm)
	_curl_chain(side + "HandThumb", p[prefix + "thumb"], palm)

## Avucun su anki normali (model uzayi). Sol elde parmaklar x (serce->isaret), sag elde tersi.
func _palm_normal(side: String) -> Vector3:
	var hand: int = _find_bone(side + "Hand")
	var index: int = _find_bone(side + "HandIndex1")
	var pinky: int = _find_bone(side + "HandPinky1")
	var middle: int = _find_bone(side + "HandMiddle1")
	if hand < 0 or index < 0 or pinky < 0 or middle < 0:
		return Vector3.ZERO
	var fingers: Vector3 = _global_pose(middle).origin - _global_pose(hand).origin
	var across: Vector3 = _global_pose(index).origin - _global_pose(pinky).origin
	var palm: Vector3 = fingers.cross(across) * (1.0 if side == "Left" else -1.0)
	return palm.normalized() if not palm.is_zero_approx() else Vector3.ZERO

## Her eklemi parmak yonu x avuc normali ekseni etrafinda avuca dogru bukar.
## Model uzayinda hesaplandigi icin Meshy ve Mixamo iskeletlerinde ayni sonucu verir.
func _curl_chain(chain: String, degrees: Vector3, palm: Vector3) -> void:
	if palm.is_zero_approx():
		return
	var bones: Array[int] = []
	for joint in range(4):
		var bone: int = _find_bone(chain + str(joint + 1))
		if bone >= 0:
			bones.append(bone)
	for joint in range(mini(3, bones.size())):
		var bone: int = bones[joint]
		var tip: int = bones[joint + 1] if joint + 1 < bones.size() else -1
		var from_bone: int = bone if tip >= 0 else bones[joint - 1] if joint > 0 else -1
		var to_bone: int = tip if tip >= 0 else bone
		if from_bone < 0:
			continue
		var direction: Vector3 = _global_pose(to_bone).origin - _global_pose(from_bone).origin
		var axis: Vector3 = direction.cross(palm)
		if axis.is_zero_approx():
			continue
		_rotate_global(bone, Basis(axis.normalized(), deg_to_rad(degrees[joint])))

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
