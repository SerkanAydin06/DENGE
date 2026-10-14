extends SceneTree
## Run: godot --headless --path . --script res://tests/test_inworld_screens.gd

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/props/player_station.tscn")
	assert(packed != null, "Player station scene not found")
	var station: DengePlayerStation = packed.instantiate() as DengePlayerStation
	root.add_child(station)

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
	assert(station.has_node("ResultDisplay/ResultMonitor/MonitorSweep"))
	assert(station.has_node("ResultDisplay/ResultMonitor/PlayerReadouts/Player_5"))
	var bezel: MeshInstance3D = station.get_node("ResultDisplay/ResultMonitor/MonitorBezel") as MeshInstance3D
	var bezel_mesh: BoxMesh = bezel.mesh as BoxMesh
	assert(bezel_mesh.size.x >= 2.5, "Large result display must be at least 2.5 units wide")

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
	assert(station.player_readouts[4].text == "05 / 100")
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
