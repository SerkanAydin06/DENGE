extends Node3D
## DENGE local prototype: physical tablet controls numbers, 3D monitor shows ALL round information.
## No fullscreen number picker, scorecard or modal HUD.

@export_range(0.0005, 0.01, 0.0005) var mouse_sensitivity: float = 0.0025
@export_range(30.0, 160.0, 1.0) var max_yaw_degrees: float = 95.0
@export_range(20.0, 89.0, 1.0) var max_pitch_degrees: float = 55.0
@export_range(0.4, 0.99, 0.01) var terminal_look_threshold: float = 0.72
@export_range(0.1, 3.0, 0.1) var reveal_delay: float = 0.75
@export_range(0.2, 0.8, 0.01) var tablet_pickup_seconds: float = 0.38
@export_range(0.16, 0.35, 0.01) var tablet_hold_distance: float = 0.19

@onready var player_camera: Camera3D = $PlayerCamera
@onready var stations: Array[DengePlayerStation] = [
	$Arena/PlayerStation_1,
	$Arena/PlayerStation_2,
	$Arena/PlayerStation_3,
	$Arena/PlayerStation_4,
	$Arena/PlayerStation_5
]
@onready var player_console: Node3D = $Arena/PlayerStation_1/Desk/TouchConsole

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var round_number: int = 1
var scores: Array[int] = [0, 0, 0, 0, 0]
var game_finished: bool = false
var tablet_mode: bool = false
var tablet_transition: bool = false
var tablet_motion: Tween
var tablet_desk_parent: Node3D
var tablet_rest_position: Vector3
var tablet_rest_rotation: Vector3
var tablet_rest_scale: Vector3
var revealing: bool = false
var round_result_ready: bool = false

var view_yaw: float = 0.0
var view_pitch: float = 0.0

func _ready() -> void:
	view_yaw = player_camera.rotation.y
	view_pitch = player_camera.rotation.x
	player_camera.current = true
	stations[0].number_locked.connect(_on_selection_locked)
	# The same real 3D tablet is moved into the camera's hands and returned to its desk.
	tablet_desk_parent = player_console.get_parent() as Node3D
	tablet_rest_position = player_console.position
	tablet_rest_rotation = player_console.rotation
	tablet_rest_scale = player_console.scale
	rng.randomize()
	_prepare_round()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if tablet_mode:
				_set_tablet_mode(false)
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_viewport().set_input_as_handled()
			return

		if round_result_ready and event.keycode == KEY_E:
			_next_round()
			get_viewport().set_input_as_handled()
			return

		if tablet_mode:
			if not tablet_transition and _handle_tablet_keyboard(event):
				get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_E and not revealing and not round_result_ready:
			if not stations[0].tablet_locked and _looking_at_tablet():
				_set_tablet_mode(true)
				get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if tablet_mode:
			if tablet_transition:
				get_viewport().set_input_as_handled()
				return
			var ray_origin: Vector3 = player_camera.project_ray_origin(event.position)
			var ray_direction: Vector3 = player_camera.project_ray_normal(event.position)
			stations[0].touch_world_ray(ray_origin, ray_direction)
			get_viewport().set_input_as_handled()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not tablet_mode:
		view_yaw = clampf(view_yaw - event.relative.x * mouse_sensitivity, deg_to_rad(-max_yaw_degrees), deg_to_rad(max_yaw_degrees))
		view_pitch = clampf(view_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-max_pitch_degrees), deg_to_rad(max_pitch_degrees))
		player_camera.rotation = Vector3(view_pitch, view_yaw, 0.0)

func _handle_tablet_keyboard(event: InputEventKey) -> bool:
	if event.keycode >= KEY_0 and event.keycode <= KEY_9:
		stations[0].append_digit(event.keycode - KEY_0)
		return true
	if event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9:
		stations[0].append_digit(event.keycode - KEY_KP_0)
		return true
	if event.keycode == KEY_BACKSPACE:
		stations[0].erase_digit()
		return true
	if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
		stations[0].confirm_number()
		return true
	return false

func _looking_at_tablet() -> bool:
	var towards: Vector3 = (player_console.global_position - player_camera.global_position).normalized()
	var look: Vector3 = -player_camera.global_transform.basis.z
	return look.dot(towards) >= terminal_look_threshold

func _set_tablet_mode(enabled: bool) -> void:
	if enabled == tablet_mode:
		return
	tablet_mode = enabled
	tablet_transition = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if enabled else Input.MOUSE_MODE_CAPTURED

	if tablet_motion and tablet_motion.is_running():
		tablet_motion.kill()

	if enabled:
		# Pickup: keep the world's small tablet size; bring it close to the eyes
		# so it appears large without using a separate screen-space popup.
		player_console.reparent(player_camera, true)
		tablet_motion = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tablet_motion.tween_property(player_console, "position", Vector3(0, -0.015, -tablet_hold_distance), tablet_pickup_seconds)
		tablet_motion.tween_property(player_console, "rotation", Vector3.ZERO, tablet_pickup_seconds)
		tablet_motion.tween_property(player_console, "scale", tablet_rest_scale, tablet_pickup_seconds)
		_broadcast("DENGE  |  TUR %02d" % round_number, "SAYINI SEC", "TABLETTE 0 - 100 SAYILARINI DOKUN\nTEMIZLE / ONAY VEYA KLAVYE 0-9", "ESC: TABLETI BIRAK")
	else:
		# Put the physical tablet back exactly where the Godot scene places it.
		player_console.reparent(tablet_desk_parent, true)
		tablet_motion = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tablet_motion.tween_property(player_console, "position", tablet_rest_position, tablet_pickup_seconds)
		tablet_motion.tween_property(player_console, "rotation", tablet_rest_rotation, tablet_pickup_seconds)
		tablet_motion.tween_property(player_console, "scale", tablet_rest_scale, tablet_pickup_seconds)

	tablet_motion.finished.connect(_on_tablet_motion_finished)


func _on_tablet_motion_finished() -> void:
	tablet_transition = false
	if not tablet_mode:
		player_console.position = tablet_rest_position
		player_console.rotation = tablet_rest_rotation
		player_console.scale = tablet_rest_scale

func _broadcast(title: String, headline: String, details: String, footer: String) -> void:
	for station in stations:
		station.set_monitor_page(title, headline, details, footer)

func _prepare_round() -> void:
	for station in stations:
		station.set_monitor_numbers(["--", "--", "--", "--", "--"])
	tablet_mode = false
	revealing = false
	round_result_ready = false
	for i in range(stations.size()):
		if scores[i] <= DengeRoundRules.ELIMINATION_SCORE:
			stations[i].disable_tablet()
		else:
			stations[i].reset_tablet(round_number)
	_broadcast(
		"DENGE  |  TUR %02d" % round_number,
		"SAYI SECIMI",
		"TABLETTE 0 - 100 TEK TEK SEC\nHEDEF = ORTALAMA x 0.8\nEN YAKIN SAYI KAZANIR",
		"TABLETE BAK + E"
	)

func _on_selection_locked(value: int) -> void:
	if game_finished or revealing or round_result_ready:
		return
	if tablet_mode:
		_set_tablet_mode(false)
	revealing = true

	var selections: Array[int] = []
	for i in range(stations.size()):
		if scores[i] <= DengeRoundRules.ELIMINATION_SCORE:
			selections.append(-1)
		elif i == 0:
			selections.append(value)
		else:
			selections.append(rng.randi_range(DengeRoundRules.MIN_NUMBER, DengeRoundRules.MAX_NUMBER))

	var result: Dictionary = DengeRoundRules.resolve_round(selections, scores)
	if result.is_empty():
		revealing = false
		return
	_play_monitor_sequence(selections, result)

func _play_monitor_sequence(selections: Array[int], result: Dictionary) -> void:
	_broadcast("DENGE  |  TUR %02d" % round_number, "SECIMLER KILITLENDI", "OYUNCULARIN SAYILARI\nACIKLANACAK...", "HESAPLAMA BASLIYOR")
	await get_tree().create_timer(reveal_delay).timeout

	var shown: Array[String] = ["--", "--", "--", "--", "--"]
	for i in range(selections.size()):
		shown[i] = str(selections[i]) if selections[i] >= 0 else "X"
		for station in stations:
			station.set_monitor_numbers(shown)
		_broadcast(
			"DENGE  |  SAYILAR",
			"OYUNCU %d: %s" % [i + 1, shown[i]],
			_format_numbers(shown),
			"ACIKLAMA SURUYOR..."
		)
		await get_tree().create_timer(reveal_delay).timeout

	_broadcast(
		"DENGE  |  HESAPLAMA",
		"HEDEF: %.2f" % result["target"],
		"ORTALAMA: %.2f\nCARPAN: 0.80\nEN YAKIN SAYI KAZANIR" % result["average"],
		"SONUC HESAPLANIYOR..."
	)
	await get_tree().create_timer(reveal_delay * 1.8).timeout

	scores = result["scores"]
	var winners: Array = result["winners"]
	var survivor_ids: Array = result["survivors"]
	var winner_names: PackedStringArray = []
	for index in winners:
		winner_names.append(str(index + 1))
	var who: String = ", ".join(winner_names)
	game_finished = scores[0] <= DengeRoundRules.ELIMINATION_SCORE or survivor_ids.size() <= 1
	var footer: String = "E: YENIDEN BASLAT" if game_finished else "E: SONRAKI TUR"
	var details: String = _format_scores()
	_broadcast(
		"DENGE  |  TUR %02d SONUCU" % round_number,
		"KAZANAN: %s" % who,
		"HEDEF: %.2f\n%s" % [result["target"], details],
		footer
	)
	revealing = false
	round_result_ready = true

func _format_numbers(shown: Array[String]) -> String:
	return "1:%s    2:%s    3:%s\n4:%s    5:%s" % [shown[0], shown[1], shown[2], shown[3], shown[4]]

func _format_scores() -> String:
	return "1:%d    2:%d    3:%d\n4:%d    5:%d" % [scores[0], scores[1], scores[2], scores[3], scores[4]]

func _next_round() -> void:
	if not round_result_ready:
		return
	if game_finished:
		round_number = 1
		scores = [0, 0, 0, 0, 0]
		game_finished = false
	else:
		round_number += 1
	_prepare_round()
