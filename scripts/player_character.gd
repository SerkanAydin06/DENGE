extends Node3D
class_name DengePlayerCharacter
## Meshy/Mixamo iskeletli karakteri koltukta oturur poza getirir.
## Acilar derece cinsinden, modelin dinlenme pozundaki eksenlere gore uygulanir
## (X: one/arkaya egilme, Z: yana acilma). Inspector'dan ince ayar yapilabilir.

@export var thigh_pitch: float = -88.0
@export var knee_pitch: float = 92.0
@export var foot_pitch: float = -8.0
@export var spine_pitch: float = 6.0
@export var head_pitch: float = 4.0
@export var upper_arm_down: float = 12.0
@export var upper_arm_forward: float = -28.0
@export var forearm_pitch: float = -62.0
@export var hand_pitch: float = 10.0

var skeleton: Skeleton3D

func _ready() -> void:
	var found: Array[Node] = find_children("*", "Skeleton3D", true, false)
	if found.is_empty():
		push_warning("DENGE: karakterde Skeleton3D bulunamadi")
		return
	skeleton = found[0] as Skeleton3D
	apply_seated_pose()

func apply_seated_pose() -> void:
	skeleton.reset_bone_poses()
	_rotate("Spine", Vector3(spine_pitch, 0, 0))
	_rotate("Head", Vector3(head_pitch, 0, 0))
	for side: String in ["Left", "Right"]:
		# Karakterin solu +X yonunde; sag taraf aynalanir.
		var mirror: float = 1.0 if side == "Left" else -1.0
		_rotate(side + "UpLeg", Vector3(thigh_pitch, 0, 0))
		_rotate(side + "Leg", Vector3(knee_pitch, 0, 0))
		_rotate(side + "Foot", Vector3(foot_pitch, 0, 0))
		_rotate(side + "Arm", Vector3(upper_arm_forward, 0, -upper_arm_down * mirror))
		_rotate(side + "ForeArm", Vector3(forearm_pitch, 0, 0))
		_rotate(side + "Hand", Vector3(hand_pitch, 0, 0))

## Kemigi, ebeveynine gore model uzayindaki eksenlerle (derece) dondurur.
func _rotate(bone_suffix: String, euler_degrees: Vector3) -> void:
	var bone: int = skeleton.find_bone("mixamorig_" + bone_suffix)
	if bone < 0:
		bone = skeleton.find_bone("mixamorig:" + bone_suffix)
	if bone < 0:
		return
	var global_rest: Basis = skeleton.get_bone_global_rest(bone).basis.orthonormalized()
	var delta := Basis.from_euler(Vector3(deg_to_rad(euler_degrees.x), deg_to_rad(euler_degrees.y), deg_to_rad(euler_degrees.z)))
	var local_delta: Basis = global_rest.inverse() * delta * global_rest
	var rest: Basis = skeleton.get_bone_rest(bone).basis.orthonormalized()
	skeleton.set_bone_pose_rotation(bone, (rest * local_delta).get_rotation_quaternion())
