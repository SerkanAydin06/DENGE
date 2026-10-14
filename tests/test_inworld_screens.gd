extends SceneTree
## Run: godot --headless --path . --script res://tests/test_inworld_screens.gd

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/props/player_station.tscn")
	assert(packed != null, "Player station scene not found")
	var station: DengePlayerStation = packed.instantiate() as DengePlayerStation
	root.add_child(station)
	await process_frame

	var tablet: Node3D = station.get_node("Desk/TouchConsole") as Node3D
	assert(is_equal_approx(tablet.scale.x, 0.20), "Tablet should be standard compact physical size")
	assert(tablet.position.y < 1.0, "Tablet must lie on the desk, not float above it")
	var number_grid: Node3D = station.get_node("Desk/TouchConsole/NumberGrid") as Node3D
	assert(number_grid.get_child_count() == 101, "Tablet must show exactly 101 individual numbers")
	assert(number_grid.has_node("Number_000"))
	assert(number_grid.has_node("Number_050"))
	assert(number_grid.has_node("Number_100"))
	assert(station.has_node("Desk/TouchConsole/ConfirmChoice"))
	assert(station.has_node("Desk/TouchConsole/ClearChoice"))
	assert(station.has_node("TabletInteractionHint"))
	assert(not station.get_node("TabletInteractionHint").visible, "Only show E when looking at desk tablet")
	assert(station.has_node("ResultDisplay/CeilingMount/LeftCable"))
	assert(station.has_node("ResultDisplay/CeilingMount/RightCable"))
	assert(station.has_node("ResultDisplay/CeilingMount/LeftRoofAnchor"))
	assert(station.has_node("ResultDisplay/CeilingMount/RightRoofAnchor"))
	assert(not station.has_node("ResultDisplay/FloorBase"), "Monitor no longer stands on the floor")
	assert(not station.has_node("ResultDisplay/ResultMonitor/MonitorSweep"), "Refresh stripe must not return")
	assert(station.has_node("ResultDisplay/ResultMonitor/PlayerReadouts/Player_5"))
	var monitor: Node3D = station.get_node("ResultDisplay/ResultMonitor") as Node3D
	var bezel: MeshInstance3D = monitor.get_node("MonitorBezel") as MeshInstance3D
	var bezel_mesh: BoxMesh = bezel.mesh as BoxMesh
	assert(is_equal_approx(monitor.scale.x, 0.80), "Monitor width must be scaled to 80 percent")
	assert(is_equal_approx(monitor.scale.y, 0.80), "Monitor height must be scaled to 80 percent")
	assert(bezel_mesh.size.x * monitor.scale.x <= 2.05, "Physical monitor should be about 2.04 meters wide")

	station.reset_tablet(1)
	station.choose_number(100)
	assert(station.chosen_number == 100)
	assert(station.choice_highlight.visible)
	station.confirm_number()
	assert(station.tablet_locked, "100 must lock")
	station.reset_tablet(2)
	assert(not station.tablet_locked, "Next round must unlock the tablet")
	assert(station.chosen_number == -1)

	station.append_digit(5)
	station.append_digit(0)
	assert(station.chosen_number == 50)
	station.clear_selection()
	assert(station.chosen_number == -1)

	station.set_monitor_numbers(["10", "20", "30", "--", "100"])
	assert(station.player_readouts[4].text == "100")
	var blueprint: Node3D = station.get_node("ResultDisplay/ResultMonitor/MonitorBlueprint") as Node3D
	assert(blueprint.has_node("Grid/GridV_20"))
	assert(blueprint.has_node("Grid/GridH_12"))
	assert(blueprint.has_node("BalanceMotif/Beam"))
	assert(blueprint.has_node("Players/Portrait_5/Head"))
	assert(blueprint.has_node("Players/Portrait_5/PortraitImage"))
	assert(blueprint.has_node("Players/Portrait_5/WinnerBorder_5/FrameImage"))
	assert(station.has_node("ResultDisplay/ResultMonitor/StandbyScreen/GeneratedLogo"))
	assert(station.has_node("DeathImpact/GeneratedSplash"))
	# ZIP textures are optional in GitHub-only checkout; authored sprites are always present.
	var pack_installed: bool = ResourceLoader.exists("res://assets/generated/portrait_1.png", "Texture2D")
	if pack_installed:
		for i in range(1, 6):
			var picture: Sprite3D = blueprint.get_node("Players/Portrait_%d/PortraitImage" % i) as Sprite3D
			assert(picture.texture != null, "Every portrait needs its installed image")
	assert(blueprint.has_node("Players/Portrait_5/NumberTile"))
	assert(blueprint.has_node("CalculationPanel/AverageValue"))
	assert(blueprint.has_node("CalculationPanel/FactorValue"))
	assert(blueprint.has_node("CalculationPanel/AnswerValue"))
	assert(blueprint.has_node("Players/Portrait_5/PointsOverlay_5/PointsValue"))
	assert(station.has_node("ResultDisplay/ResultMonitor/StandbyScreen/BlackFace"))
	assert(station.standby_screen.visible, "Black DENGE standby must be visible at launch")
	assert(station.generated_logo.visible == (station.generated_logo.texture != null))
	assert(station.standby_title.text == "DENGE")
	assert(not station.blueprint.visible, "Grid should not appear until all numbers locked")

	station.set_monitor_phase("ROUND_TITLE")
	station.set_monitor_intro_title(1)
	assert(station.standby_screen.visible)
	assert(not station.blueprint.visible)
	assert(station.standby_title.text == "1. TUR")

	# 1) Numbers reveal without images.
	station.set_monitor_phase("REVEAL")
	assert(not station.standby_screen.visible)
	assert(station.blueprint.visible)
	assert(not blueprint.get_node("Players/Portrait_1/PortraitPanel").visible)
	assert(not blueprint.get_node("Players/Portrait_1/PortraitImage").visible)
	assert(not station.calculation_panel.visible)
	assert(not station.target_panel.visible)

	# 2) Mean appears before the multiplier and before the final answer.
	station.set_monitor_phase("AVERAGE", -1.0, [], [], 16.6)
	assert(station.average_frame.visible)
	assert(station.calculation_panel.visible)
	assert(station.calculation_average.text == "16.60")
	assert(not station.calculation_panel.get_node("FactorValue").visible)
	assert(not station.calculation_panel.get_node("AnswerBox").visible)

	# 3) Show 0.8 multiplication first, with answer still hidden.
	station.set_monitor_phase("MULTIPLY", -1.0, [], [], 16.6)
	assert(station.calculation_panel.get_node("FactorValue").visible)
	assert(not station.calculation_panel.get_node("AnswerBox").visible)

	# 4) Reveal the calculated target on the equation screen.
	station.set_monitor_phase("CALCULATED", 13.28, [], [], 16.6)
	assert(station.calculation_panel.get_node("AnswerBox").visible)
	assert(station.calculation_answer.text == "13.28")
	assert(not station.target_panel.visible)

	# 5) Next, show portraits over chosen numbers with target below.
	station.set_monitor_phase("PHOTO", 13.28)
	assert(blueprint.get_node("Players/Portrait_1/PortraitPanel").visible)
	assert(blueprint.get_node("Players/Portrait_1/PortraitImage").visible == pack_installed)
	assert(blueprint.get_node("Players/Portrait_1/Head").visible != pack_installed)
	assert(not station.calculation_panel.visible)
	assert(station.target_panel.visible)
	assert(station.target_value.text == "13.28")
	assert(not blueprint.get_node("Players/Portrait_3/WinnerBorder_3").visible)

	# 6) Reveal winner after photos and the target are already visible.
	station.set_monitor_phase("WIN", 13.28, [2])
	assert(blueprint.get_node("Players/Portrait_3/WinnerBorder_3").visible)
	assert(blueprint.get_node("Players/Portrait_3/WinLabel_3").visible)
	assert(not blueprint.get_node("Players/Portrait_2/WinnerBorder_2").visible)
	assert(not blueprint.get_node("Players/Portrait_3/PointsOverlay_3").visible)

	# 7) All five remaining scores are displayed on top of their portraits.
	station.set_monitor_phase("SCORE", 13.28, [2], [9, 9, 10, 9, 9])
	assert(blueprint.get_node("Players/Portrait_3/WinnerBorder_3").visible)
	assert(not blueprint.get_node("Players/Portrait_3/WinLabel_3").visible)
	for player_index in range(1, 6):
		var overlay: Node3D = blueprint.get_node("Players/Portrait_%d/PointsOverlay_%d" % [player_index, player_index]) as Node3D
		assert(overlay.visible)
	assert(blueprint.get_node("Players/Portrait_3/PointsOverlay_3/PointsValue").text == "10 PUAN")
	assert(blueprint.get_node("Players/Portrait_1/PointsOverlay_1/PointsValue").text == "9 PUAN")

	# New round hides the scores and portraits again.
	station.set_monitor_phase("STANDBY")
	assert(station.standby_screen.visible)
	assert(station.standby_title.text == "DENGE")
	assert(not station.target_panel.visible)
	assert(not station.average_frame.visible)
	assert(not station.calculation_panel.visible)
	assert(not blueprint.get_node("Players/Portrait_3/PointsOverlay_3").visible)
	assert(not blueprint.get_node("Players/Portrait_1/PortraitPanel").visible)
	station.set_monitor_page("TUR 2", "HEDEF 28.00", "ORTALAMA 35.00", "E: DEVAM")
	assert(station.result_body.text == "HEDEF 28.00")
	assert(station.result_footer.text == "E: DEVAM")

	var game_scene: PackedScene = load("res://scenes/game_room.tscn")
	assert(game_scene != null, "Main scene is missing")
	var game: Node = game_scene.instantiate()
	assert(not game.has_node("NumberTerminalUI"))
	assert(not game.has_node("RoundResultsUI"))
	assert(not game.has_node("InteractionHints"))
	assert(game.has_node("Arena/PlayerStation_5"))
	print("DENGE 101-number tablet / enlarged monitor scene checks passed.")
	station.free()
	game.free()
	quit(0)
