extends SceneTree
## Run with: godot --headless --path . --script res://tests/test_round_rules.gd

func _initialize() -> void:
	var neutral: Array[int] = [0, 0, 0, 0, 0]
	var normal: Dictionary = DengeRoundRules.resolve_round([20, 30, 40, 50, 60], neutral)
	assert(is_equal_approx(normal["average"], 40.0))
	assert(is_equal_approx(normal["target"], 32.0))
	assert(normal["winners"] == [1])
	assert(normal["scores"] == [-1, 0, -1, -1, -1])

	var tied: Dictionary = DengeRoundRules.resolve_round([10, 10, 10, 10, 10], neutral)
	assert(tied["winners"].size() == 5)
	assert(tied["scores"] == neutral)

	var eliminated: Dictionary = DengeRoundRules.resolve_round([100, 0, 0, 0, 0], [-9, 0, 0, 0, 0])
	assert(eliminated["scores"][0] == -10)
	assert(eliminated["eliminated_now"].has(0))
	assert(eliminated["survivors"].size() == 4)

	var without_eliminated: Dictionary = DengeRoundRules.resolve_round([-1, 20, 30, 40, 50], [-10, 0, 0, 0, 0])
	assert(is_equal_approx(without_eliminated["average"], 35.0))
	assert(is_equal_approx(without_eliminated["target"], 28.0))
	assert(without_eliminated["winners"] == [2])
	assert(without_eliminated["scores"][0] == -10)

	print("DENGE round rules: 4 tests passed.")
	quit(0)
