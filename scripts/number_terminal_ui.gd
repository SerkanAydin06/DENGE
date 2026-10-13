extends CanvasLayer
signal selection_locked(value: int)

var chosen: int = -1
var locked := false
var panel: PanelContainer
var value_label: Label
var lock_button: Button
var number_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(840, 650)
	panel.position = Vector2(-420, -325)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var title := Label.new()
	title.text = "DENGE  /  DOKUNMATIK SAYI SECIMI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	column.add_child(title)
	value_label = Label.new()
	value_label.text = "Bir sayiya dokun"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 26)
	column.add_child(value_label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 460)
	column.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	for number in range(101):
		var button := Button.new()
		button.text = str(number)
		button.custom_minimum_size = Vector2(70, 48)
		button.pressed.connect(_choose.bind(number))
		grid.add_child(button)
		number_buttons.append(button)
	lock_button = Button.new()
	lock_button.text = "SAYI SEC"
	lock_button.disabled = true
	lock_button.custom_minimum_size.y = 52
	lock_button.pressed.connect(_lock)
	column.add_child(lock_button)
	var exit_button := Button.new()
	exit_button.text = "GERI (ESC)"
	exit_button.pressed.connect(close)
	column.add_child(exit_button)

func _choose(number: int) -> void:
	if locked:
		return
	chosen = number
	value_label.text = "SECILEN SAYI: %d" % chosen
	lock_button.disabled = false
	lock_button.text = "%d SAYISINI KILITLE" % chosen
	for i in range(number_buttons.size()):
		number_buttons[i].button_pressed = false
		number_buttons[i].modulate = Color("#9ad8e3") if i == number else Color.WHITE

func _lock() -> void:
	if locked or chosen < 0:
		return
	locked = true
	lock_button.disabled = true
	lock_button.text = "SECIM KILITLENDI: %d" % chosen
	for button in number_buttons:
		button.disabled = true
	selection_locked.emit(chosen)

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
