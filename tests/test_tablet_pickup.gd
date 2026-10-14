extends SceneTree
## Godot headless regression: the same small 3D tablet moves from desk to camera and back.

func _initialize() -> void:
	var room_scene: PackedScene = load("res://scenes/game_room.tscn")
	assert(room_scene != null)
	var room: Node3D = room_scene.instantiate() as Node3D
	root.add_child(room)
	await process_frame
	var tablet: Node3D = room.get_node("Arena/PlayerStation_1/Desk/TouchConsole") as Node3D
	var desk: Node3D = tablet.get_parent() as Node3D
	var camera: Camera3D = room.get_node("PlayerCamera") as Camera3D
	var initial_transform: Transform3D = tablet.transform

	assert(is_equal_approx(tablet.scale.x, 0.20))
	assert(is_equal_approx(tablet.scale.y, 0.20))
	assert(is_equal_approx(tablet.scale.z, 0.20))
	assert(tablet.has_node("NumberGrid/Number_000"))
	assert(tablet.has_node("NumberGrid/Number_100"))

	var hint: Label3D = room.get_node("Arena/PlayerStation_1/TabletInteractionHint") as Label3D
	camera.look_at(tablet.global_position, Vector3.UP)
	room.call("_process", 0.016)
	assert(hint.visible, "Tablet gaze must show the E interaction hint")
	camera.rotation = Vector3.ZERO
	room.call("_process", 0.016)
	assert(not hint.visible, "E hint must disappear when looking away")
	camera.look_at(tablet.global_position, Vector3.UP)

	room.call("_set_tablet_mode", true)
	room.call("_process", 0.016)
	assert(not hint.visible, "E hint must hide while holding the tablet")
	assert(tablet.get_parent() == camera, "Tablet must be camera-held while selecting")
	await create_timer(0.5).timeout
	assert(is_equal_approx(tablet.position.z, -0.19), "Held tablet must fill the seated player's view")

	room.call("_set_tablet_mode", false)
	assert(tablet.get_parent() == desk, "Tablet must return to its real desk")
	await create_timer(0.5).timeout
	assert(tablet.transform.is_equal_approx(initial_transform), "Tablet must return to original editor position")

	assert(room.has_node("Arena/PlayerStation_1/Desk/TouchConsole"))
	assert(not room.has_node("NumberTerminalUI"))
	assert(not room.has_node("RoundResultsUI"))

	print("DENGE physical tablet pickup, zoom and return: passed")
	room.free()
	quit(0)
