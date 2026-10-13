extends Node3D
## All 3D geometry is authored in editable .tscn scenes; this script handles input only.

@export_range(0.0005, 0.01, 0.0005) var mouse_sensitivity: float = 0.0025
@export_range(30.0, 160.0, 1.0) var max_yaw_degrees: float = 95.0
@export_range(20.0, 89.0, 1.0) var max_pitch_degrees: float = 55.0
@export_range(0.4, 0.99, 0.01) var terminal_look_threshold: float = 0.78

@onready var player_camera: Camera3D = $PlayerCamera
@onready var terminal_ui: CanvasLayer = $NumberTerminalUI
@onready var prompt_label: Label = $InteractionHints/PromptLabel
@onready var stations: Array[Node3D] = [
	$Arena/PlayerStation_1,
	$Arena/PlayerStation_2,
	$Arena/PlayerStation_3,
	$Arena/PlayerStation_4,
	$Arena/PlayerStation_5
]
@onready var player_console: Node3D = $Arena/PlayerStation_1/Desk/TouchConsole

var view_yaw: float = 0.0
var view_pitch: float = 0.0

func _ready() -> void:
	view_yaw = player_camera.rotation.y
	view_pitch = player_camera.rotation.x
	player_camera.current = true
	terminal_ui.selection_locked.connect(_on_selection_locked)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(_delta: float) -> void:
	if terminal_ui.visible:
		prompt_label.visible = false
		return
	var target_direction: Vector3 = (player_console.global_position - player_camera.global_position).normalized()
	var look_direction: Vector3 = -player_camera.global_transform.basis.z
	prompt_label.visible = look_direction.dot(target_direction) >= terminal_look_threshold

func _unhandled_input(event: InputEvent) -> void:
	if terminal_ui.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			terminal_ui.close()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E and prompt_label.visible:
			terminal_ui.open()
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		view_yaw = clampf(view_yaw - event.relative.x * mouse_sensitivity, deg_to_rad(-max_yaw_degrees), deg_to_rad(max_yaw_degrees))
		view_pitch = clampf(view_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-max_pitch_degrees), deg_to_rad(max_pitch_degrees))
		player_camera.rotation = Vector3(view_pitch, view_yaw, 0.0)

func set_station_result(index: int, title: String, body: String) -> void:
	if index >= 0 and index < stations.size():
		stations[index].set_result_text(title, body)

func _on_selection_locked(value: int) -> void:
	stations[0].set_touch_text("SECIM KILITLENDI", str(value))
	set_station_result(0, "SAYI ALINDI", "DIGERLERI BEKLENIYOR")
	print("DENGE selection locked: ", value)
