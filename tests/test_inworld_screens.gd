extends SceneTree
## Run: godot --headless --path . --script res://tests/test_inworld_screens.gd

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/props/player_station.tscn")
	assert(packed != null, "Player station scene not found")
	var station: DengePlayerStation = packed.instantiate() as DengePlayerStation
	root.add_child(station)

	assert(station.has_node("Desk/TouchConsole/Keys/Key_11"), "Physical confirm key missing")
	assert(station.has_node("ResultDisplay/ResultMonitor/MonitorSweep"), "Animated result monitor missing")
	station.reset_tablet(1)
	station.append_digit(1)
	station.append_digit(0)
	station.append_digit(0)
	assert(station.entered_digits == "100")
	station.confirm_number()
	assert(station.tablet_locked, "100 must lock")
	station.reset_tablet(2)
	assert(not station.tablet_locked, "Next round must unlock the tablet")

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
	print("DENGE physical touch / monitor scene checks passed.")
	station.free()
	game.free()
	quit(0)
