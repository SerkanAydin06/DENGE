extends CanvasLayer
class_name DengeNumberTerminal
signal selection_locked(value: int)

@onready var chosen_label: Label = $Dim/CenterPanel/Layout/ChosenLabel
@onready var lock_button: Button = $Dim/CenterPanel/Layout/LockButton
@onready var exit_button: Button = $Dim/CenterPanel/Layout/ExitButton
@onready var number_grid: GridContainer = $Dim/CenterPanel/Layout/Scroll/NumberGrid

var chosen: int = -1
var locked: bool = false
var number_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	for number in range(101):
		var button: Button = number_grid.get_node("Number_%d" % number) as Button
		number_buttons.append(button)
		button.pressed.connect(_choose.bind(number))
	lock_button.pressed.connect(_lock)
	exit_button.pressed.connect(close)

func _choose(number: int) -> void:
	if locked:
		return
	chosen = number
	chosen_label.text = "SECILEN SAYI: %d" % chosen
	lock_button.text = "%d SAYISINI KILITLE" % chosen
	lock_button.disabled = false
	for i in range(number_buttons.size()):
		number_buttons[i].modulate = Color("#8fe1ea") if i == chosen else Color.WHITE

func _lock() -> void:
	if chosen < 0 or locked:
		return
	locked = true
	lock_button.disabled = true
	lock_button.text = "SECIM KILITLENDI: %d" % chosen
	for button in number_buttons:
		button.disabled = true
	selection_locked.emit(chosen)

func reset_for_next_round() -> void:
	chosen = -1
	locked = false
	chosen_label.text = "0-100 ARASINDA SAYI SEC"
	lock_button.text = "SAYIYI KILITLE"
	lock_button.disabled = true
	for button in number_buttons:
		button.disabled = false
		button.modulate = Color.WHITE

func open() -> void:
	if locked:
		return
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
