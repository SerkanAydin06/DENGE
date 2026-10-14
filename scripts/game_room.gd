extends Node3D
## DENGE local prototype: physical tablet controls numbers, 3D monitor shows ALL round information.
## No fullscreen number picker, scorecard or modal HUD.

@export_range(0.0005, 0.01, 0.0005) var mouse_sensitivity: float = 0.0025
@export_range(30.0, 160.0, 1.0) var max_yaw_degrees: float = 95.0
@export_range(20.0, 89.0, 1.0) var max_pitch_degrees: float = 55.0
@export_range(0.1, 3.0, 0.1) var reveal_delay: float = 1.2
@export_range(0.2, 4.0, 0.1) var bot_think_seconds: float = 1.0
@export_range(0.2, 0.8, 0.01) var tablet_pickup_seconds: float = 0.38
@export_range(0.16, 0.35, 0.01) var tablet_hold_distance: float = 0.19
## Tabletin yerel uzayinda sol/sag elin tuttugu kenar noktalari (olcek oncesi).
@export var tablet_grip_left: Vector3 = Vector3(-0.86, -0.12, -0.05)
@export var tablet_grip_right: Vector3 = Vector3(0.86, -0.12, -0.05)
@export_range(0.88, 0.995, 0.005) var tablet_look_threshold: float = 0.955

@onready var player_camera: Camera3D = $PlayerCamera
@onready var stations: Array[DengePlayerStation] = [
	$Arena/PlayerStation_1,
	$Arena/PlayerStation_2,
	$Arena/PlayerStation_3,
	$Arena/PlayerStation_4,
	$Arena/PlayerStation_5
]
@onready var player_console: Node3D = $Arena/PlayerStation_1/Desk/TouchConsole
@onready var tablet_interaction_hint: Label3D = $Arena/PlayerStation_1/TabletInteractionHint

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var round_number: int = 1
var scores: Array[int] = [DengeRoundRules.STARTING_SCORE, DengeRoundRules.STARTING_SCORE, DengeRoundRules.STARTING_SCORE, DengeRoundRules.STARTING_SCORE, DengeRoundRules.STARTING_SCORE]
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
	# Govde gorundugu icin yakin kirpma mesafesi kucuk tutulur.
	player_camera.near = 0.03
	for i in range(stations.size()):
		stations[i].reset_life(i == 0)
	stations[0].number_locked.connect(_on_selection_locked)
	# The same real 3D tablet is moved into the camera's hands and returned to its desk.
	tablet_desk_parent = player_console.get_parent() as Node3D
	tablet_rest_position = player_console.position
	tablet_rest_rotation = player_console.rotation
	tablet_rest_scale = player_console.scale
	rng.randomize()
	_prepare_round()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(_delta: float) -> void:
	_update_first_person_body()
	# This E hint belongs to the small physical tablet, never to the monitor.
	tablet_interaction_hint.visible = (not tablet_mode and not tablet_transition
		and not revealing and (round_result_ready or not stations[0].tablet_locked)
		and _looking_at_tablet())


## Birinci sahis: kamera karakterin goz noktasini izler, govde bakis yonunu
## kismen takip eder, tablet tutulurken eller tabletin kenarlarini kavrar.
func _update_first_person_body() -> void:
	var character: DengePlayerCharacter = stations[0].get_character()
	if character == null or not character.first_person:
		return
	player_camera.global_position = character.eye_global_position()
	character.set_view_yaw(rad_to_deg(view_yaw))
	var holding: bool = tablet_mode and player_console.get_parent() == player_camera
	if holding:
		var xf: Transform3D = player_console.global_transform
		character.set_hold_targets(xf * tablet_grip_left, xf * tablet_grip_right, true)
	else:
		character.set_hold_targets(Vector3.ZERO, Vector3.ZERO, false)


func _looking_at_tablet() -> bool:
	var to_tablet: Vector3 = player_console.global_position - player_camera.global_position
	if to_tablet.length_squared() < 0.001:
		return false
	var forward: Vector3 = -player_camera.global_transform.basis.z
	return forward.dot(to_tablet.normalized()) >= tablet_look_threshold


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
			if _looking_at_tablet():
				_next_round()
			get_viewport().set_input_as_handled()
			return

		if tablet_mode:
			if not tablet_transition and _handle_tablet_keyboard(event):
				get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_E and not revealing and not round_result_ready:
			if not stations[0].tablet_locked and not tablet_mode and _looking_at_tablet():
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
		station.set_monitor_phase("STANDBY")
	tablet_mode = false
	revealing = false
	round_result_ready = false
	for i in range(stations.size()):
		if scores[i] <= DengeRoundRules.ELIMINATION_SCORE:
			stations[i].disable_tablet()
		else:
			stations[i].reset_tablet(round_number)
	# Rakipler tur basinda dusunur ve tabletlerine dokunur.
	_set_all_moods("THINK")
	# Until everyone locks a number, every monitor shows only DENGE.

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
			continue
		if i == 0:
			selections.append(value)
		else:
			# Opponents lock their choices silently while the monitor remains black.
			await get_tree().create_timer(bot_think_seconds * rng.randf_range(0.6, 1.4)).timeout
			var bot_value: int = _bot_choice()
			stations[i].choose_number(bot_value)
			stations[i].confirm_number()
			stations[i].set_character_mood("LOCKED")
			selections.append(bot_value)

	var result: Dictionary = DengeRoundRules.resolve_round(selections, scores)
	if result.is_empty():
		revealing = false
		return
	# Only now, after every active player locks in, announce the round.
	_set_all_monitor_phases("ROUND_TITLE")
	_set_all_moods("WATCH")
	for station in stations:
		station.set_monitor_intro_title(round_number)
	await get_tree().create_timer(reveal_delay * 1.6).timeout
	_play_monitor_sequence(selections, result)

func _bot_choice() -> int:
	# Basit dusunme seviyesi: 50 * 0.8^k etrafinda, gurultulu.
	var depth: int = rng.randi_range(0, 4)
	var guess: float = 50.0 * pow(DengeRoundRules.TARGET_MULTIPLIER, float(depth)) + rng.randf_range(-9.0, 9.0)
	return clampi(roundi(guess), DengeRoundRules.MIN_NUMBER, DengeRoundRules.MAX_NUMBER)

func _player_name(index: int) -> String:
	return "SEN (OYUNCU 1)" if index == 0 else "OYUNCU %d" % (index + 1)

func _play_monitor_sequence(selections: Array[int], result: Dictionary) -> void:
	# Exactly the staged order requested for the in-world blueprint monitor.
	# Only the freestanding 3D monitor displays calculations and results.
	_set_all_monitor_phases("REVEAL")
	_broadcast("DENGE  |  TUR %02d" % round_number, "SAYILAR ACIKLANIYOR", "", "SECIMLER TEK TEK GOSTERILIYOR")
	await get_tree().create_timer(reveal_delay).timeout

	var shown: Array[String] = ["--", "--", "--", "--", "--"]
	for i in range(selections.size()):
		shown[i] = str(selections[i]) if selections[i] >= 0 else "X"
		for station in stations:
			station.set_monitor_numbers(shown)
		_broadcast(
			"DENGE  |  SAYILAR",
			"%s: %s" % [_player_name(i), shown[i]],
			"",
			"OYUNCU %d / %d" % [i + 1, selections.size()]
		)
		await get_tree().create_timer(reveal_delay).timeout

	# 1: Average appears by itself in the white bottom card.
	_set_all_monitor_phases("AVERAGE", -1.0, [], [], float(result["average"]))
	_broadcast(
		"DENGE  |  ORTALAMA",
		"SECILEN SAYILARIN ORTALAMASI",
		"",
		""
	)
	await get_tree().create_timer(reveal_delay * 1.4).timeout

	# 2: Show the multiplication operation, keeping the answer hidden.
	_set_all_monitor_phases("MULTIPLY", -1.0, [], [], float(result["average"]))
	_broadcast(
		"DENGE  |  HESAPLAMA",
		"ORTALAMA x 0.8",
		"",
		""
	)
	await get_tree().create_timer(reveal_delay * 1.3).timeout

	# 3: Reveal the numerical result at the end of the equation.
	_set_all_monitor_phases("CALCULATED", float(result["target"]), [], [], float(result["average"]))
	_broadcast(
		"DENGE  |  HEDEF SAYI",
		"SONUC HESAPLANDI",
		"",
		""
	)
	await get_tree().create_timer(reveal_delay * 1.5).timeout

	# 4: Switch from the equation to portraits over the same five number cards.
	_set_all_monitor_phases("PHOTO", float(result["target"]))
	_broadcast(
		"DENGE  |  OYUNCULAR",
		"OYUNCULAR VE SECIMLERI",
		"",
		"HEDEF SAYI ALTTA"
	)
	await get_tree().create_timer(reveal_delay * 1.5).timeout

	var winners: Array = result["winners"]
	var winner_numbers: PackedStringArray = []
	for index in winners:
		winner_numbers.append(str(int(index) + 1))
	var winner_title: String = "KAZANAN: OYUNCU %s" % ", ".join(winner_numbers)
	if winners.size() > 1:
		winner_title = "BERABERE: %s" % ", ".join(winner_numbers)

	# 5: Winner frame spans the portrait and chosen-number card.
	_set_all_monitor_phases("WIN", float(result["target"]), winners)
	for i in range(stations.size()):
		stations[i].set_character_mood("WIN" if winners.has(i) else "LOSE")
	_broadcast(
		"DENGE  |  KAZANAN",
		winner_title,
		"",
		"PUANLAR ACIKLANACAK"
	)
	await get_tree().create_timer(reveal_delay * 1.7).timeout

	# The losing players' nearby bowls gain liquid according to their new scores.
	# Any newly eliminated player reaches 0, receives a final spill and dies.
	var new_scores: Array[int] = result["scores"]
	for i in range(stations.size()):
		stations[i].update_life_points(new_scores[i], 0.9)
	await get_tree().create_timer(1.0).timeout

	var newly_eliminated: Array = result["eliminated_now"]
	for index in newly_eliminated:
		stations[int(index)].eliminate_player()
	if not newly_eliminated.is_empty():
		_broadcast("DENGE  |  ELEME", "0 PUAN - ELENDI", "KEFE BOSALIYOR...", "")
		await get_tree().create_timer(2.8).timeout

	# 6: After any elimination, overlay remaining points on all portraits.
	scores = new_scores
	var survivor_ids: Array = result["survivors"]
	game_finished = scores[0] <= DengeRoundRules.ELIMINATION_SCORE or survivor_ids.size() <= 1
	# The E interaction prompt belongs to the real desk tablet only.
	_set_all_monitor_phases("SCORE", float(result["target"]), winners, scores)
	_broadcast(
		"DENGE  |  TUR %02d PUANLARI" % round_number,
		"KALAN PUANLAR",
		"",
		""
	)
	revealing = false
	round_result_ready = true


func _set_all_moods(mood: String) -> void:
	for station in stations:
		station.set_character_mood(mood)


func _set_all_monitor_phases(phase: String, target: float = -1.0, winners: Array = [], point_totals: Array = [], average: float = -1.0) -> void:
	for station in stations:
		station.set_monitor_phase(phase, target, winners, point_totals, average)


func _next_round() -> void:
	if not round_result_ready:
		return
	if game_finished:
		round_number = 1
		scores = [DengeRoundRules.STARTING_SCORE, DengeRoundRules.STARTING_SCORE, DengeRoundRules.STARTING_SCORE, DengeRoundRules.STARTING_SCORE, DengeRoundRules.STARTING_SCORE]
		for i in range(stations.size()):
			stations[i].reset_life(i == 0)
		game_finished = false
	else:
		round_number += 1
	_prepare_round()
