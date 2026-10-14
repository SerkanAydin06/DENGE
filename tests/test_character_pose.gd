extends SceneTree
## Run in Godot: godot --headless --path . --script res://tests/test_character_pose.gd
## Validate new rigged GLB wrappers, seated pose transforms and bone hierarchy.

func _initialize() -> void:
	var wrappers: Array[String] = [
		"res://scenes/characters/gray_poise.tscn",
		"res://scenes/characters/player_2.tscn",
		"res://scenes/characters/player_3.tscn",
		"res://scenes/characters/player_4.tscn",
		"res://scenes/characters/player_5.tscn"
	]
	for path in wrappers:
		var packed: PackedScene = load(path) as PackedScene
		assert(packed != null, "Character wrapper cannot be loaded: " + path)
		var actor: DengePlayerCharacter = packed.instantiate() as DengePlayerCharacter
		assert(actor != null, "Character script missing: " + path)
		root.add_child(actor)
		await process_frame
		assert(actor.skeleton != null, "Meshy GLB is not rigged: " + path)
		assert(actor.skeleton.get_bone_count() > 0, "Empty Skeleton3D: " + path)
		actor.apply_seated_pose()
		for bone in range(actor.skeleton.get_bone_count()):
			var pose: Transform3D = actor.skeleton.get_bone_global_pose(bone)
			assert(pose.origin.is_finite(), "Invalid seated bone position: " + path)
			assert(pose.basis.x.is_finite() and pose.basis.y.is_finite() and pose.basis.z.is_finite(), "Invalid seated bone orientation: " + path)
		actor.free()
	print("DENGE: five rigged models and seated skeleton transforms validated.")
	quit(0)
