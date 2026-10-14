extends SceneTree
## Run: godot --headless --path . --script res://tests/test_elimination_vfx.gd
## Keeps the score-to-bowl-to-death interaction deterministic.

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/props/player_station.tscn")
	assert(packed != null)
	var station: DengePlayerStation = packed.instantiate() as DengePlayerStation
	root.add_child(station)
	await process_frame

	assert(station.rear_scale != null)
	assert(station.rear_scale.has_node("BeamPivot/RightSuspension/RightPan/PanContents"))
	assert(station.rear_scale.has_node("BeamPivot/RightSuspension/RightPan/PourLip"))
	assert(station.has_node("PlayerFigure/Head"))
	assert(station.has_node("DeathSpillStream"))
	assert(station.has_node("DeathImpact"))

	station.reset_life(false)
	assert(station.current_points == 10)
	assert(is_zero_approx(station.rear_scale.fill_amount))
	assert(not station.rear_scale.contents.visible)
	assert(not station.is_eliminated)

	station.update_life_points(7, 0.12)
	await create_timer(0.20).timeout
	assert(is_equal_approx(station.rear_scale.fill_amount, 0.3), "At 7 points the pan is 30 percent full")
	assert(station.rear_scale.contents.visible)

	station.update_life_points(1, 0.12)
	await create_timer(0.20).timeout
	assert(is_equal_approx(station.rear_scale.fill_amount, 0.9), "At 1 point the pan is 90 percent full")

	station.update_life_points(0, 0.12)
	await create_timer(0.20).timeout
	assert(is_equal_approx(station.rear_scale.fill_amount, 1.0))
	assert(not station.is_eliminated, "The death must be triggered after the 0-score reveal")
	station.eliminate_player()
	await create_timer(2.55).timeout
	assert(station.is_eliminated)
	assert(station.rear_scale.spilled)
	assert(not station.player_figure.visible, "Player must collapse and disappear after the spill")
	assert(not station.death_stream.visible)

	station.reset_life(false)
	assert(not station.is_eliminated)
	assert(not station.rear_scale.spilled)
	assert(is_zero_approx(station.rear_scale.fill_amount))
	assert(station.player_figure.visible)
	assert(not station.death_stream.visible)
	print("DENGE 10-to-zero bowl fill, spillage, death and reset checks passed.")
	station.free()
	quit(0)
