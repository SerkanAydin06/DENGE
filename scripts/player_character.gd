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

var skeleton: Skeleton3D

func _ready() -> void:
	var found: Array[Node] = find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		push_warning("DENGE: karakterde Skeleton3D bulunamadi")
		return
	skeleton = found[0] as Skeleton3D
	apply_seated_pose()
	_align_hips_to_seat()

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

func _align_hips_to_seat() -> void:
	var hips: int = _find_bone("Hips")
	var model: Node3D = get_node_or_null("Model") as Node3D
	if hips < 0 or model == null:
		return
	var hip_local: Vector3 = global_transform.affine_inverse() * (skeleton.global_transform * skeleton.get_bone_global_rest(hips).origin)
	model.position += Vector3(0, seat_hip_height, -seat_hip_forward) - Vector3(0, hip_local.y, hip_local.z)

## Kemigi, cocuk kemigine giden yonu model uzayinda `direction` olacak sekilde dondurur.
func _aim(bone_suffix: String, child_suffix: String, direction: Vector3) -> void:
	var bone: int = _find_bone(bone_suffix)
	var child: int = _find_bone(child_suffix)
	if bone < 0 or child < 0 or direction.is_zero_approx():
		return
	var bone_global: Transform3D = _global_pose(bone)
	var child_position: Vector3 = bone_global * skeleton.get_bone_pose(child).origin
	var current: Vector3 = (child_position - bone_global.origin).normalized()
	var delta := Quaternion(current, direction.normalized())
	_set_global_basis(bone, Basis(delta) * bone_global.basis.orthonormalized())

## Kemigi kendi ekleminde model uzayi X ekseni etrafinda one egdirir (derece).
func _pitch(bone_suffix: String, degrees: float) -> void:
	var bone: int = _find_bone(bone_suffix)
	if bone < 0:
		return
	var bone_global: Transform3D = _global_pose(bone)
	_set_global_basis(bone, Basis(Vector3.RIGHT, deg_to_rad(degrees)) * bone_global.basis.orthonormalized())

func _set_global_basis(bone: int, global_basis: Basis) -> void:
	var parent: int = skeleton.get_bone_parent(bone)
	var parent_basis: Basis = _global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis()
	skeleton.set_bone_pose_rotation(bone, (parent_basis.inverse() * global_basis).get_rotation_quaternion())

func _global_pose(bone: int) -> Transform3D:
	var pose: Transform3D = skeleton.get_bone_pose(bone)
	var parent: int = skeleton.get_bone_parent(bone)
	while parent >= 0:
		pose = skeleton.get_bone_pose(parent) * pose
		parent = skeleton.get_bone_parent(parent)
	return pose

## Mixamo ("mixamorig_Hips") ve Meshy ("Hips") adlandirmasini birlikte destekler.
func _find_bone(bone_suffix: String) -> int:
	for bone_name in ["mixamorig_" + bone_suffix, "mixamorig:" + bone_suffix, bone_suffix]:
		var bone: int = skeleton.find_bone(bone_name)
		if bone >= 0:
			return bone
	return -1
