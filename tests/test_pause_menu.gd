extends SceneTree
## Run: godot --headless --path . --script res://tests/test_pause_menu.gd
## Esc opens the pause menu and pauses the game; resume restores play.

func _initialize() -> void:
	var room: Node3D = (load("res://scenes/game_room.tscn") as PackedScene).instantiate() as Node3D
	root.add_child(room)
	await process_frame
	var menu: DengePauseMenu = room.get_node("PauseMenu") as DengePauseMenu
	assert(menu != null, "Pause menu must be part of the game room")
	assert(not menu.visible, "Pause menu starts hidden")
	assert(menu.process_mode == Node.PROCESS_MODE_ALWAYS)

	var esc := InputEventKey.new()
	esc.keycode = KEY_ESCAPE
	esc.pressed = true
	room._unhandled_input(esc)
	assert(menu.visible, "Esc must open the pause menu")
	assert(paused, "Game must pause while the menu is open")

	menu.close()
	assert(not menu.visible)
	assert(not paused, "Resume must unpause the game")

	# While the tablet is held, Esc only puts the tablet down.
	room.call("_set_tablet_mode", true)
	room._unhandled_input(esc)
	assert(not menu.visible, "Esc with the tablet in hand must not open the menu")
	print("DENGE pause menu: passed")
	room.free()
	quit(0)
