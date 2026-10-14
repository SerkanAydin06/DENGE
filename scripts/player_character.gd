extends Node3D
class_name DengePlayerCharacter
## Meshy/Mixamo iskeletli karakteri koltukta oturur poza getirir.
## Uzuvlar, dinlenme pozundan bagimsiz olarak model uzayindaki hedef yonlere
## cevrilir (+Z ileri, +X karakterin solu; sag taraf aynalanir). Inspector'dan ayarlanabilir.

@export var thigh_direction: Vector3 = Vector3(0.08, -0.12, 1.0)
@export var shin_direction: Vector3 = Vector3(0.02, -1.0, 0.12)
@export var foot_direction: Vector3 = Vector3(0.0, -0.35, 1.0)
@export var upper_arm_direction: Vector3 = Vector3(0.18, -0.92, 0.3)
@export var forearm_direction: Vector3 = Vector3(0.06, -0.4, 1.0)
@export var spine_pitch: float = 6.0
@export var head_pitch: float = 4.0
## Kalca kemiginin koltuktaki hedef konumu (karakter kokune gore, metre).
## Farkli boydaki modeller bu noktaya hizalanir.
@export var seat_hip_height: float = 0.615
@export var seat_hip_forward: float = 0.0

@export_group("Idle Motion")
## Oturan karakterin nefes alma, hafif sallanma ve etrafa bakinma hareketleri.
@export var idle_motion: bool = true
@export_range(0.0, 5.0, 0.1) var breath_degrees: float = 1.4
@export_range(0.05, 1.0, 0.01) var breath_speed: float = 0.26
@export_range(0.0, 5.0, 0.1) var sway_degrees: float = 1.0
@export_range(0.0, 40.0, 0.5) var look_yaw_degrees: float = 16.0
@export_range(0.0, 15.0, 0.5) var look_pitch_degrees: float = 5.0
@export_range(1.0, 15.0, 0.5) var look_interval: float = 4.0

var skeleton: Skeleton3D
var _idle_bones: Dictionary = {}
var _seated_pose: Dictionary = {}
var _idle_time: float = 0.0
var _look_target: Vector2 = Vector2.ZERO
var _look_current: Vector2 = Vector2.ZERO
var _next_look: float = 0.0
var _noise: FastNoiseLite = FastNoiseLite.new()

func _ready() -> void:
	var found: Array[Node] = find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		push_warning("DENGE: karakterde Skeleton3D bulunamadi")
		return
	skeleton = found[0] as Skeleton3D
	apply_seated_pose()
	_align_hips_to_seat()
	_prepare_idle()

func _prepare_idle() -> void:
	# Her karakter farkli zamanlamayla hareket etsin.
	_idle_time = randf() * 100.0
	_next_look = randf_range(0.5, look_interval)
	_noise.seed = randi()
	_noise.frequency = 0.35
	for bone_suffix in ["Spine", "Neck", "Head", "LeftShoulder", "RightShoulder"]:
		var bone: int = _find_bone(bone_suffix)
		if bone >= 0:
			_idle_bones[bone_suffix] = bone

func _process(delta: float) -> void:
	if not idle_motion or skeleton == null or _idle_bones.is_empty() or not is_visible_in_tree():
		return
	_idle_time += delta
	_next_look -= delta
	if _next_look <= 0.0:
		# Cogu zaman merkeze, ara sira yandaki oyunculara veya monitore bakar.
		if randf() < 0.4:
			_look_target = Vector2.ZERO
		else:
			_look_target = Vector2(randf_range(-1.0, 1.0) * look_yaw_degrees, randf_range(-0.4, 1.0) * look_pitch_degrees)
		_next_look = randf_range(look_interval * 0.6, look_interval * 1.5)
	_look_current = _look_current.lerp(_look_target, 1.0 - exp(-delta * 2.2))

	var breath: float = sin(_idle_time * TAU * breath_speed)
	var sway: float = _noise.get_noise_1d(_idle_time * 10.0)
	for bone_suffix in _idle_bones:
		skeleton.set_bone_pose_rotation(_idle_bones[bone_suffix], _seated_pose[_idle_bones[bone_suffix]])
	if _idle_bones.has("Spine"):
		_rotate_global(_idle_bones["Spine"], Basis(Vector3.RIGHT, deg_to_rad(breath * breath_degrees)) * Basis(Vector3.BACK, deg_to_rad(sway * sway_degrees)))
	for side_suffix in ["LeftShoulder", "RightShoulder"]:
		if _idle_bones.has(side_suffix):
			var side_sign: float = 1.0 if side_suffix == "LeftShoulder" else -1.0
			_rotate_global(_idle_bones[side_suffix], Basis(Vector3.BACK, deg_to_rad(breath * 0.8 * side_sign)))
	var look: Basis = Basis(Vector3.UP, deg_to_rad(_look_current.x)) * Basis(Vector3.RIGHT, deg_to_rad(_look_current.y))
	if _idle_bones.has("Neck") and _idle_bones.has("Head"):
		var half: Basis = Basis(Vector3.UP, deg_to_rad(_look_current.x * 0.5)) * Basis(Vector3.RIGHT, deg_to_rad(_look_current.y * 0.5))
		_rotate_global(_idle_bones["Neck"], half)
		_rotate_global(_idle_bones["Head"], half)
	elif _idle_bones.has("Head"):
		_rotate_global(_idle_bones["Head"], look)

## Kemigi kendi ekleminde model uzayindaki bir donusle dondurur.
func _rotate_global(bone: int, rotation_delta: Basis) -> void:
	_set_global_basis(bone, rotation_delta * _global_pose(bone).basis.orthonormalized())

func apply_seated_pose() -> void:
	skeleton.reset_bone_poses()
	_pitch("Spine", spine_pitch)
	_pitch("Head", head_pitch)
	for side: String in ["Left", "Right"]:
		var mirror := Vector3(1, 1, 1) if side == "Left" else Vector3(-1, 1, 1)
		_aim(side + "UpLeg", side + "Leg", thigh_direction * mirror)
		_aim(side + "Leg", side + "Foot", shin_direction * mirror)
		_aim(side + "Foot", side + "ToeBase", foot_direction * mirror)
		_aim(side + "Arm", side + "ForeArm", upper_arm_direction * mirror)
		_aim(side + "ForeArm", side + "Hand", forearm_direction * mirror)
	_seated_pose.clear()
	for bone in range(skeleton.get_bone_count()):
		_seated_pose[bone] = skeleton.get_bone_pose_rotation(bone)

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

## Kemigi kendi ekleminde model uzayi X ekseni etrafinda one egdirir (derece).
func _pitch(bone_suffix: String, degrees: float) -> void:
	var bone: int = _find_bone(bone_suffix)
	if bone < 0:
		return
	var bone_global: Transform3D = _global_pose(bone)
	_set_global_basis(bone, Basis(Vector3.RIGHT, deg_to_rad(degrees)) * bone_global.basis.orthonormalized())

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
