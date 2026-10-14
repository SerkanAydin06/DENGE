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
	assert(blueprint.has_node("Players/Portrait_5/NumberTile"))
	station.set_monitor_phase("AVERAGE")
	assert(station.average_frame.visible)
	assert(not station.target_panel.visible)
	station.set_monitor_phase("TARGET", 24.0)
	assert(not station.average_frame.visible)
	assert(station.target_panel.visible)
	assert(station.target_value.text == "24.00")
	station.set_monitor_phase("RESULT", 24.0, [2], ["FARK 6.00\nPUAN 9 (-1)", "B", "C", "D", "E"])
	assert(blueprint.get_node("Players/Portrait_3/WinnerBorder_3").visible)
	assert(blueprint.get_node("Players/Portrait_3/WinLabel_3").visible, "Winner needs a KAZANDI label")
	assert(not blueprint.get_node("Players/Portrait_2/WinnerBorder_2").visible)
	assert(not blueprint.get_node("Players/Portrait_2/WinLabel_2").visible)
	assert(blueprint.get_node("Players/Portrait_1/Score_1").text == "FARK 6.00\nPUAN 9 (-1)")
	station.set_monitor_phase("RULES")
	assert(not station.target_panel.visible)
	assert(not station.average_frame.visible)
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
