extends Node3D
## Fully editable player station; geometry and screen labels live in player_station.tscn.
@export_range(1, 5, 1) var player_number: int = 1

@onready var touch_target: Node3D = $Desk/TouchConsole
@onready var touch_title: Label3D = $Desk/TouchConsole/TouchTitle
@onready var touch_body: Label3D = $Desk/TouchConsole/TouchBody
@onready var result_title: Label3D = $Desk/ResultMonitor/ResultTitle
@onready var result_body: Label3D = $Desk/ResultMonitor/ResultBody
@onready var seat_eye: Marker3D = $SeatEye

func eye_position() -> Vector3:
	return seat_eye.global_position

func set_touch_text(title: String, body: String) -> void:
	touch_title.text = title
	touch_body.text = body

func set_result_text(title: String, body: String) -> void:
	result_title.text = title
	result_body.text = body
