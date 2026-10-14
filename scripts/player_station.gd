extends Node3D
class_name DengePlayerStation
## In-world-only player console and results display. Geometry remains scene-editable.

signal number_locked(value: int)

@export_range(1, 5, 1) var player_number: int = 1

const DIGIT_KEYS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "SIL", "0", "OK"]
const KEY_Y: Array[float] = [0.045, -0.025, -0.095, -0.165]
const KEY_X: Array[float] = [-0.255, 0.0, 0.255]

@onready var touch_target: Node3D = $Desk/TouchConsole
@onready var touch_title: Label3D = $Desk/TouchConsole/TouchTitle
@onready var touch_body: Label3D = $Desk/TouchConsole/TouchBody
@onready var result_title: Label3D = $ResultDisplay/ResultMonitor/ResultTitle
@onready var result_body: Label3D = $ResultDisplay/ResultMonitor/ResultBody
@onready var result_details: Label3D = $ResultDisplay/ResultMonitor/ResultDetails
@onready var result_footer: Label3D = $ResultDisplay/ResultMonitor/ResultFooter
@onready var sweep: MeshInstance3D = $ResultDisplay/ResultMonitor/MonitorSweep
@onready var seat_eye: Marker3D = $SeatEye

var entered_digits: String = ""
var tablet_locked: bool = false
var tablet_enabled: bool = true
var key_labels: Array[Label3D] = []
var monitor_tween: Tween

func _ready() -> void:
	for index in range(DIGIT_KEYS.size()):
		key_labels.append(touch_target.get_node("Keys/Key_%02d" % index) as Label3D)
	reset_tablet(1)
	set_monitor_page("DENGE", "OTURUM HAZIR", "HEDEF = ORTALAMA x 0.8", "E: SAYI GIR")

func eye_position() -> Vector3:
	return seat_eye.global_position

func reset_tablet(round_id: int) -> void:
	entered_digits = ""
	tablet_locked = false
	tablet_enabled = true
	touch_title.text = "TUR %02d  /  SAYI GIR" % round_id
	_show_digits()
	_set_key_color(Color(0.74, 0.94, 1.0, 1.0))

func disable_tablet() -> void:
	entered_digits = ""
	tablet_locked = true
	tablet_enabled = false
	touch_title.text = "OYUNDAN ELENDI"
	touch_body.text = "--"
	_set_key_color(Color(0.35, 0.38, 0.4, 1.0))

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
	sweep.position.y = 0.25
	result_body.modulate.a = 0.36
	monitor_tween = create_tween()
	monitor_tween.set_parallel(true)
	monitor_tween.tween_property(result_body, "modulate:a", 1.0, 0.38)
	monitor_tween.tween_property(sweep, "position:y", -0.245, 0.48)

func append_digit(digit: int) -> void:
	if not tablet_enabled or tablet_locked or digit < 0 or digit > 9:
		return
	if entered_digits.length() >= 3:
		return
	var candidate: String = entered_digits + str(digit)
	if int(candidate) > DengeRoundRules.MAX_NUMBER:
		return
	entered_digits = candidate
	_show_digits()

func erase_digit() -> void:
	if tablet_enabled and not tablet_locked:
		entered_digits = entered_digits.substr(0, maxi(0, entered_digits.length() - 1))
		_show_digits()

func confirm_number() -> void:
	if not tablet_enabled or tablet_locked or entered_digits.is_empty():
		return
	var chosen: int = int(entered_digits)
	if chosen < DengeRoundRules.MIN_NUMBER or chosen > DengeRoundRules.MAX_NUMBER:
		return
	tablet_locked = true
	touch_title.text = "SAYI KILITLENDI"
	touch_body.text = "%03d" % chosen
	_set_key_color(Color(0.4, 0.53, 0.55, 1.0))
	number_locked.emit(chosen)

func touch_world_ray(ray_origin: Vector3, ray_direction: Vector3) -> bool:
	## Ray-plane hit testing in the touch console's own editable transform.
	if not tablet_enabled or tablet_locked:
		return false
	var inverse: Transform3D = touch_target.global_transform.affine_inverse()
	var local_origin: Vector3 = inverse * ray_origin
	var local_direction: Vector3 = inverse.basis * ray_direction
	if absf(local_direction.z) < 0.00001:
		return false
	var t: float = (0.07 - local_origin.z) / local_direction.z
	if t <= 0.0:
		return false
	var hit: Vector3 = local_origin + local_direction * t
	if absf(hit.x) > 0.42 or absf(hit.y) > 0.22:
		return false
	for i in range(DIGIT_KEYS.size()):
		var column: int = i % 3
		var row: int = i / 3
		if absf(hit.x - KEY_X[column]) < 0.115 and absf(hit.y - KEY_Y[row]) < 0.032:
			_press_key(i)
			return true
	return true

func _press_key(index: int) -> void:
	var key: String = DIGIT_KEYS[index]
	if key == "SIL":
		erase_digit()
	elif key == "OK":
		confirm_number()
	else:
		append_digit(int(key))

func _show_digits() -> void:
	touch_body.text = entered_digits if not entered_digits.is_empty() else "---"

func _set_key_color(color: Color) -> void:
	for label in key_labels:
		label.modulate = color
