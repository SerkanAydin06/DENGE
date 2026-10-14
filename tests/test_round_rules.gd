extends SceneTree
## Run: godot --headless --path . --script res://tests/test_round_rules.gd
## All players start at 10 points; zero points means elimination.

func _initialize() -> void:
	var starting: Array[int] = [
		DengeRoundRules.STARTING_SCORE,
		DengeRoundRules.STARTING_SCORE,
		DengeRoundRules.STARTING_SCORE,
		DengeRoundRules.STARTING_SCORE,
		DengeRoundRules.STARTING_SCORE
	]
	assert(DengeRoundRules.STARTING_SCORE == 10)
	assert(DengeRoundRules.ELIMINATION_SCORE == 0)

	var normal: Dictionary = DengeRoundRules.resolve_round([20, 30, 40, 50, 60], starting)
	assert(is_equal_approx(normal["average"], 40.0))
	assert(is_equal_approx(normal["target"], 32.0))
	assert(normal["winners"] == [1])
	assert(normal["scores"] == [9, 10, 9, 9, 9])
	assert(normal["survivors"].size() == 5)

	var tied: Dictionary = DengeRoundRules.resolve_round([10, 10, 10, 10, 10], starting)
	assert(tied["winners"].size() == 5)
	assert(tied["scores"] == starting)

	# Last point lost: it reaches zero exactly and does not go negative.
	var eliminated: Dictionary = DengeRoundRules.resolve_round([100, 0, 0, 0, 0], [1, 10, 10, 10, 10])
	assert(eliminated["scores"][0] == 0)
	assert(eliminated["eliminated_now"] == [0])
	assert(eliminated["survivors"].size() == 4)

	# Previously eliminated players do not vote or affect the mean/target.
	var without_eliminated: Dictionary = DengeRoundRules.resolve_round([-1, 20, 30, 40, 50], [0, 10, 10, 10, 10])
	assert(is_equal_approx(without_eliminated["average"], 35.0))
	assert(is_equal_approx(without_eliminated["target"], 28.0))
	assert(without_eliminated["winners"] == [2])
	assert(without_eliminated["scores"][0] == 0)
	assert(without_eliminated["survivors"].size() == 4)

	# A table with no active players has no round result.
	var empty_round: Dictionary = DengeRoundRules.resolve_round([-1, -1, -1, -1, -1], [0, 0, 0, 0, 0])
	assert(empty_round.is_empty())
	print("DENGE 10-point scoring and zero-elimination: 5 tests passed.")
	quit(0)
