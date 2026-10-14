extends Node3D
class_name DengeBalanceScale
## The RightPan is closest to the player. Liquid rises as their points run out.
## At zero the pan tips and its contents spill toward the seated player.

const MAX_POINTS: int = 10

@export_range(-1.0, 1.0, 0.01) var tilt: float = 0.0:
	set(value):
		tilt = clampf(value, -1.0, 1.0)
		if is_node_ready():
			_apply_pose()

@export_range(0.0, 1.0, 0.01) var pour_amount: float = 0.0:
	set(value):
		pour_amount = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_pose()

@export_range(0.0, 1.0, 0.01) var fill_amount: float = 0.0:
	set(value):
		fill_amount = clampf(value, 0.0, 1.0)
		if is_node_ready():
			_apply_fill()

@onready var contents: MeshInstance3D = $BeamPivot/RightSuspension/RightPan/PanContents
@onready var pouring_point: Marker3D = $BeamPivot/RightSuspension/RightPan/PourLip

var liquid_tween: Tween
var spilled: bool = false

func _ready() -> void:
	_apply_pose()
	_apply_fill()

func apply_points(points: int, seconds: float = 0.85) -> void:
	if spilled:
		return
	var new_fill: float = float(MAX_POINTS - clampi(points, 0, MAX_POINTS)) / float(MAX_POINTS)
	if liquid_tween and liquid_tween.is_running():
		liquid_tween.kill()
	liquid_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	liquid_tween.tween_property(self, "fill_amount", new_fill, seconds)
	# The increasingly heavy near pan gradually lowers toward the player's head.
	liquid_tween.tween_property(self, "tilt", -0.45 * new_fill, seconds)

func spill() -> void:
	if spilled:
		return
	spilled = true
	if liquid_tween and liquid_tween.is_running():
		liquid_tween.kill()
	fill_amount = 1.0
	liquid_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	liquid_tween.tween_property(self, "pour_amount", 1.0, 0.62)
	liquid_tween.tween_property(self, "tilt", -0.70, 0.62)
	await liquid_tween.finished
	liquid_tween = create_tween()
	liquid_tween.tween_property(self, "fill_amount", 0.0, 1.25)

func reset_scale() -> void:
	if liquid_tween and liquid_tween.is_running():
		liquid_tween.kill()
	spilled = false
	pour_amount = 0.0
	tilt = 0.0
	fill_amount = 0.0

func _apply_pose() -> void:
	$BeamPivot.rotation.z = tilt * 0.32
	$BeamPivot/RightSuspension/RightPan.rotation.z = -pour_amount * 0.85

func _apply_fill() -> void:
	contents.visible = fill_amount > 0.002
	var full_height: float = 0.38
	var h: float = maxf(0.002, full_height * fill_amount)
	contents.scale.y = h / full_height
	contents.position.y = 0.05 + h * 0.5
