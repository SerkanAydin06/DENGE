extends SceneTree
## Run: godot --headless --path . --script res://tests/test_character_scene_visibility.gd
## Character nodes must be authored in the room, not spawned only at runtime.

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/game_room.tscn") as PackedScene
	assert(scene != null)
	var room: Node3D = scene.instantiate() as Node3D
	assert(room != null)
	# This is before _ready(): all five imported GLBs must already exist.
	for i in range(1, 6):
		var station_path: String = "Arena/PlayerStation_%d" % i
		var figure_path: String = station_path + "/PlayerFigure"
		var character_path: String = figure_path + "/Character"
		assert(room.has_node(character_path), "Player %d is missing from the editor scene" % i)
		var character: Node3D = room.get_node(character_path) as Node3D
		assert(character is DengePlayerCharacter, "Player %d has no character rig script" % i)
		assert(character.has_node("Model"), "Player %d has no imported GLB" % i)

	root.add_child(room)
	await process_frame
	for i in range(1, 6):
		var figure: Node3D = room.get_node("Arena/PlayerStation_%d/PlayerFigure" % i) as Node3D
		var character_count: int = 0
		for child in figure.get_children():
			if child is DengePlayerCharacter:
				character_count += 1
		assert(character_count == 1, "Duplicate model spawned at station %d" % i)
		assert(figure.visible == (i != 1), "Only the local first-person figure should hide")
	print("DENGE five editor-authored Meshy models, no runtime duplicates: passed.")
	room.free()
	quit(0)
