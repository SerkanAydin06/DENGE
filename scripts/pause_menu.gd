extends CanvasLayer
class_name DengePauseMenu
## Duraklatma menusu: Esc ile acilir, oyunu durdurur. F11 her yerde tam ekrani acar/kapatir.

signal resumed

@onready var resume_button: Button = $Shade/Panel/Content/ResumeButton
@onready var fullscreen_button: Button = $Shade/Panel/Content/FullscreenButton
@onready var quit_button: Button = $Shade/Panel/Content/QuitButton

var _mouse_mode_before: Input.MouseMode = Input.MOUSE_MODE_CAPTURED

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(close)
	fullscreen_button.pressed.connect(toggle_fullscreen)
	quit_button.pressed.connect(_quit)

func is_open() -> bool:
	return visible

func open() -> void:
	if visible:
		return
	_mouse_mode_before = Input.mouse_mode
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()

func close() -> void:
	if not visible:
		return
	visible = false
	get_tree().paused = false
	Input.mouse_mode = _mouse_mode_before
	resumed.emit()

func toggle_fullscreen() -> void:
	var window: Window = get_window()
	if window.mode == Window.MODE_FULLSCREEN or window.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		window.mode = Window.MODE_WINDOWED
	else:
		window.mode = Window.MODE_FULLSCREEN

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key: InputEventKey = event as InputEventKey
	if key.keycode == KEY_F11:
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
	elif visible and key.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func _quit() -> void:
	get_tree().paused = false
	get_tree().quit()
