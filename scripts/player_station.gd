extends Node3D
class_name DengePlayerStation
## Each number 0..100 is a separate, editable Label3D on the physical tablet.
## Results and reveal animations stay exclusively on the large freestanding monitor.

signal number_locked(value: int)

@export_range(1, 5, 1) var player_number: int = 1

const GRID_COLUMNS: int = 10
const GRID_STEP_X: float = 0.14
const GRID_STEP_Y: float = 0.056
const GRID_LEFT: float = -0.63
const GRID_TOP: float = 0.22

@onready var touch_target: Node3D = $Desk/TouchConsole
@onready var touch_title: Label3D = $Desk/TouchConsole/TouchTitle
@onready var touch_body: Label3D = $Desk/TouchConsole/TouchBody
@onready var choice_highlight: MeshInstance3D = $Desk/TouchConsole/ChoiceHighlight
@onready var result_title: Label3D = $ResultDisplay/ResultMonitor/ResultTitle
@onready var result_body: Label3D = $ResultDisplay/ResultMonitor/ResultBody
@onready var result_details: Label3D = $ResultDisplay/ResultMonitor/ResultDetails
@onready var result_footer: Label3D = $ResultDisplay/ResultMonitor/ResultFooter
@onready var blueprint: Node3D = $ResultDisplay/ResultMonitor/MonitorBlueprint
@onready var average_frame: Node3D = $ResultDisplay/ResultMonitor/MonitorBlueprint/AverageFrame
@onready var target_panel: Node3D = $ResultDisplay/ResultMonitor/MonitorBlueprint/TargetPanel
@onready var target_value: Label3D = $ResultDisplay/ResultMonitor/MonitorBlueprint/TargetPanel/TargetValue
@onready var calculation_panel: Node3D = $ResultDisplay/ResultMonitor/MonitorBlueprint/CalculationPanel
@onready var calculation_average: Label3D = $ResultDisplay/ResultMonitor/MonitorBlueprint/CalculationPanel/AverageValue
@onready var calculation_answer: Label3D = $ResultDisplay/ResultMonitor/MonitorBlueprint/CalculationPanel/AnswerValue
@onready var player_readouts: Array[Label3D] = [
	$ResultDisplay/ResultMonitor/PlayerReadouts/Player_1,
	$ResultDisplay/ResultMonitor/PlayerReadouts/Player_2,
	$ResultDisplay/ResultMonitor/PlayerReadouts/Player_3,
	$ResultDisplay/ResultMonitor/PlayerReadouts/Player_4,
	$ResultDisplay/ResultMonitor/PlayerReadouts/Player_5
]
@onready var seat_eye: Marker3D = $SeatEye

var entered_digits: String = ""
var chosen_number: int = -1
var tablet_locked: bool = false
var tablet_enabled: bool = true
var number_labels: Array[Label3D] = []
var monitor_tween: Tween

func _ready() -> void:
	for number in range(DengeRoundRules.MAX_NUMBER + 1):
		number_labels.append(touch_target.get_node("NumberGrid/Number_%03d" % number) as Label3D)
	reset_tablet(1)
	set_monitor_page("DENGE", "OTURUM HAZIR", "HEDEF = ORTALAMA x 0.8", "E: SAYI SEC")

func eye_position() -> Vector3:
	return seat_eye.global_position

func reset_tablet(round_id: int) -> void:
	entered_digits = ""
	chosen_number = -1
	tablet_locked = false
	tablet_enabled = true
	touch_title.text = "TUR %02d  |  SAYI SEC" % round_id
	_show_number()
	_refresh_number_colors()

func disable_tablet() -> void:
	entered_digits = ""
	chosen_number = -1
	tablet_locked = true
	tablet_enabled = false
	touch_title.text = "OYUNDAN ELENDI"
	touch_body.text = "--"
	_refresh_number_colors()

func set_touch_text(title: String, body: String) -> void:
	touch_title.text = title
	touch_body.text = body

func set_result_text(title: String, body: String) -> void:
	set_monitor_page(title, body, "", "")

func set_monitor_page(title: String, headline: String, details: String, footer: String) -> void:
	result_title.text = title
	result_body.text = headline
	result_details.text = details
	result_footer.text = footer
	if monitor_tween and monitor_tween.is_running():
		monitor_tween.kill()
	# Soft text fade only; no moving cyan line across the screen.
	result_title.modulate.a = 0.75
	result_body.modulate.a = 0.28
	monitor_tween = create_tween()
	monitor_tween.set_parallel(true)
	monitor_tween.tween_property(result_title, "modulate:a", 1.0, 0.28)
	monitor_tween.tween_property(result_body, "modulate:a", 1.0, 0.38)

func choose_number(number: int) -> void:
	if not tablet_enabled or tablet_locked:
		return
	if number < DengeRoundRules.MIN_NUMBER or number > DengeRoundRules.MAX_NUMBER:
		return
	chosen_number = number
	entered_digits = str(number)
	_show_number()
	_refresh_number_colors()

func set_monitor_numbers(shown: Array[String]) -> void:
	if shown.size() != player_readouts.size():
		return
	for i in range(player_readouts.size()):
		var readout: Label3D = player_readouts[i]
		if readout.text != shown[i]:
			readout.text = shown[i]
			readout.modulate.a = 0.30
			var reveal_tween: Tween = create_tween()
			reveal_tween.tween_property(readout, "modulate:a", 1.0, 0.33)
		if shown[i] == "X":
			readout.modulate = Color(0.72, 0.16, 0.19, readout.modulate.a)
		else:
			readout.modulate = Color(0.055, 0.115, 0.21, readout.modulate.a)


func set_monitor_phase(phase: String, target: float = -1.0, winners: Array = [], point_totals: Array = [], average: float = -1.0) -> void:
	## All elements are authored in monitor_blueprint.tscn, never in a 2D popup.
	## REVEAL -> AVERAGE -> MULTIPLY -> CALCULATED -> PHOTO -> WIN -> SCORE.
	var calculation_visible: bool = phase == "AVERAGE" or phase == "MULTIPLY" or phase == "CALCULATED"
	var portraits_visible: bool = phase == "PHOTO" or phase == "WIN" or phase == "SCORE"
	var factor_visible: bool = phase == "MULTIPLY" or phase == "CALCULATED"
	var answer_visible: bool = phase == "CALCULATED"

	average_frame.visible = calculation_visible
	calculation_panel.visible = calculation_visible
	target_panel.visible = portraits_visible
	result_details.visible = phase == "RULES" or phase == "LOCKED" or phase == "REVEAL"
	result_footer.visible = not calculation_visible

	if calculation_visible:
		calculation_average.text = "%.2f" % average
		calculation_answer.text = "%.2f" % target if answer_visible else "--"
		calculation_panel.get_node("MultiplySign").visible = factor_visible
		calculation_panel.get_node("FactorValue").visible = factor_visible
		calculation_panel.get_node("FactorCaption").visible = factor_visible
		calculation_panel.get_node("EqualsSign").visible = answer_visible
		calculation_panel.get_node("AnswerBox").visible = answer_visible
		calculation_panel.get_node("AnswerValue").visible = answer_visible
		calculation_panel.get_node("AnswerCaption").visible = answer_visible
		if phase == "AVERAGE":
			average_frame.scale = Vector3(0.98, 0.75, 1.0)
			var outline_tween: Tween = create_tween()
			outline_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			outline_tween.tween_property(average_frame, "scale", Vector3.ONE, 0.36)
	else:
		average_frame.scale = Vector3.ONE

	if portraits_visible:
		target_value.text = "%.2f" % target
		if phase == "PHOTO":
			target_panel.scale = Vector3(0.85, 0.85, 1.0)
			var target_tween: Tween = create_tween()
			target_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			target_tween.tween_property(target_panel, "scale", Vector3.ONE, 0.40)

	for i in range(player_readouts.size()):
		var portrait: Node3D = blueprint.get_node("Players/Portrait_%d" % (i + 1)) as Node3D
		for child_name in ["PortraitPanel", "Head", "Torso"]:
			var art: Node3D = portrait.get_node(child_name) as Node3D
			art.visible = portraits_visible
		var winner_border: Node3D = portrait.get_node("WinnerBorder_%d" % (i + 1)) as Node3D
		var win_label: Label3D = portrait.get_node("WinLabel_%d" % (i + 1)) as Label3D
		var legacy_score: Label3D = portrait.get_node("Score_%d" % (i + 1)) as Label3D
		var points_overlay: Node3D = portrait.get_node("PointsOverlay_%d" % (i + 1)) as Node3D
		var points_label: Label3D = points_overlay.get_node("PointsValue") as Label3D

		var is_winner: bool = (phase == "WIN" or phase == "SCORE") and winners.has(i)
		winner_border.visible = is_winner
		win_label.visible = phase == "WIN" and is_winner
		legacy_score.visible = false
		points_overlay.visible = phase == "SCORE" and i < point_totals.size()
		if i < point_totals.size():
			points_label.text = "%d PUAN" % int(point_totals[i])

		if phase == "PHOTO":
			portrait.scale = Vector3(0.94, 0.94, 1.0)
			var photo_tween: Tween = create_tween()
			photo_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			photo_tween.tween_property(portrait, "scale", Vector3.ONE, 0.40)
		elif phase == "WIN" and is_winner:
			winner_border.scale = Vector3(0.9, 0.9, 1.0)
			win_label.scale = Vector3(0.65, 0.65, 1.0)
			var win_tween: Tween = create_tween().set_parallel(true)
			win_tween.tween_property(winner_border, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK)
			win_tween.tween_property(win_label, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_BACK)
		elif phase == "SCORE" and points_overlay.visible:
			points_overlay.scale = Vector3(0.75, 0.75, 1.0)
			var score_tween: Tween = create_tween()
			score_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			score_tween.tween_property(points_overlay, "scale", Vector3.ONE, 0.40)


func append_digit(digit: int) -> void:
	## Optional keyboard input; on the screen all 101 entries remain individually selectable.
	if not tablet_enabled or tablet_locked or digit < 0 or digit > 9:
		return
	if entered_digits.length() >= 3:
		return
	var candidate: String = entered_digits + str(digit)
	if int(candidate) > DengeRoundRules.MAX_NUMBER:
		return
	choose_number(int(candidate))
	entered_digits = candidate

func erase_digit() -> void:
	if not tablet_enabled or tablet_locked:
		return
	if entered_digits.is_empty():
		clear_selection()
		return
	entered_digits = entered_digits.substr(0, maxi(0, entered_digits.length() - 1))
	chosen_number = int(entered_digits) if not entered_digits.is_empty() else -1
	_show_number()
	_refresh_number_colors()

func clear_selection() -> void:
	if not tablet_enabled or tablet_locked:
		return
	entered_digits = ""
	chosen_number = -1
	_show_number()
	_refresh_number_colors()

func confirm_number() -> void:
	if not tablet_enabled or tablet_locked or chosen_number < 0:
		return
	tablet_locked = true
	touch_title.text = "SECIM KILITLENDI"
	touch_body.text = "%03d" % chosen_number
	_refresh_number_colors()
	number_locked.emit(chosen_number)

func touch_world_ray(ray_origin: Vector3, ray_direction: Vector3) -> bool:
	## The mesh and the 101 labels are physically on the desk; no 2D overlay.
	if not tablet_enabled or tablet_locked:
		return false
	var inverse: Transform3D = touch_target.global_transform.affine_inverse()
	var local_origin: Vector3 = inverse * ray_origin
	var local_direction: Vector3 = inverse.basis * ray_direction
	if absf(local_direction.z) < 0.00001:
		return false
	var t: float = (0.094 - local_origin.z) / local_direction.z
	if t <= 0.0:
		return false
	var hit: Vector3 = local_origin + local_direction * t
	if absf(hit.x) > 0.84 or absf(hit.y) > 0.51:
		return false
	if absf(hit.y + 0.435) < 0.045:
		if hit.x < -0.34:
			clear_selection()
			return true
		if hit.x > 0.34:
			confirm_number()
			return true
	for number in range(number_labels.size()):
		var position_2d: Vector2 = _grid_position(number)
		if absf(hit.x - position_2d.x) <= 0.065 and absf(hit.y - position_2d.y) <= 0.026:
			choose_number(number)
			return true
	return true

func _grid_position(number: int) -> Vector2:
	if number == DengeRoundRules.MAX_NUMBER:
		return Vector2(0.0, GRID_TOP - 10.0 * GRID_STEP_Y)
	var column: int = number % GRID_COLUMNS
	var row: int = int(float(number) / float(GRID_COLUMNS))
	return Vector2(GRID_LEFT + float(column) * GRID_STEP_X, GRID_TOP - float(row) * GRID_STEP_Y)

func _show_number() -> void:
	touch_body.text = "%03d" % chosen_number if chosen_number >= 0 else "---"

func _refresh_number_colors() -> void:
	choice_highlight.visible = chosen_number >= 0
	if chosen_number >= 0:
		var position_2d: Vector2 = _grid_position(chosen_number)
		choice_highlight.position = Vector3(position_2d.x, position_2d.y, 0.076)
	for number in range(number_labels.size()):
		if not tablet_enabled or tablet_locked:
			number_labels[number].modulate = Color(0.36, 0.42, 0.5, 1.0)
		elif number == chosen_number:
			number_labels[number].modulate = Color(1.0, 1.0, 1.0, 1.0)
		else:
			number_labels[number].modulate = Color(0.72, 0.91, 0.99, 1.0)
