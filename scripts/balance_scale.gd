extends Node3D
## Scene-editable balance statue; the beam pivot may be animated.
@export_range(-1.0, 1.0, 0.01) var tilt: float = 0.0:
	set(value):
		tilt = clampf(value, -1.0, 1.0)
		if is_node_ready():
			$BeamPivot.rotation.z = tilt * 0.28

func _ready() -> void:
	$BeamPivot.rotation.z = tilt * 0.28
