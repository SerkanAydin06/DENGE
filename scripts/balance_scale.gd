extends Node3D
## Rear-seat balance. Right pan is aligned over the player's head by the station scene.
## Visual rig only: pan movement/spilling gameplay is added in a later step.

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

func _ready() -> void:
	_apply_pose()

func _apply_pose() -> void:
	$BeamPivot.rotation.z = tilt * 0.32
	$BeamPivot/RightSuspension/RightPan.rotation.z = -pour_amount * 0.85
