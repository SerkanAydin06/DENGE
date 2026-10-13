extends CanvasLayer
signal selection_locked(value: int)
var chosen := 50
var locked := false
var panel: PanelContainer
var value_label: Label
var slider: HSlider
var lock_button: Button

func _ready() -> void:
	visible = false
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(650, 410)
	panel.position = Vector2(635, 335)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = "DENGE  /  SAYI TERMINALI"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 28)
	column.add_child(heading)
	var help := Label.new()
	help.text = "0 ile 100 arasinda bir sayi sec."
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(help)
	value_label = Label.new()
	value_label.text = "50"
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 64)
	column.add_child(value_label)
	slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = chosen
	slider.custom_minimum_size.y = 44
	slider.value_changed.connect(_number_changed)
	column.add_child(slider)
	lock_button = Button.new()
	lock_button.text = "SAYIYI KILITLE"
	lock_button.custom_minimum_size.y = 60
	lock_button.pressed.connect(_lock)
	column.add_child(lock_button)
	var exit_button := Button.new()
	exit_button.text = "EKRANDAN CIK (ESC)"
	exit_button.pressed.connect(close)
	column.add_child(exit_button)

func _number_changed(value: float) -> void:
	chosen = int(value)
	value_label.text = str(chosen)

func _lock() -> void:
	if locked:
		return
	locked = true
	lock_button.disabled = true
	lock_button.text = "SECIM KILITLENDI"
	selection_locked.emit(chosen)

func open() -> void:
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
