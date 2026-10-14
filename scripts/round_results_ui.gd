extends CanvasLayer
class_name DengeRoundResultsUI

signal continue_requested

@onready var title_label: Label = $Shade/Panel/Content/Title
@onready var target_label: Label = $Shade/Panel/Content/Target
@onready var outcome_label: Label = $Shade/Panel/Content/Outcome
@onready var continue_button: Button = $Shade/Panel/Content/ContinueButton
@onready var rows: Array[Label] = [
	$Shade/Panel/Content/Players/Player1,
	$Shade/Panel/Content/Players/Player2,
	$Shade/Panel/Content/Players/Player3,
	$Shade/Panel/Content/Players/Player4,
	$Shade/Panel/Content/Players/Player5
]

func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue_pressed)

func show_results(round_number: int, selections: Array[int], result: Dictionary) -> void:
	var winners: Array = result["winners"]
	var scores: Array = result["scores"]
	var eliminated_now: Array = result["eliminated_now"]
	var survivors: Array = result["survivors"]
	title_label.text = "DENGE  |  TUR %d SONUCU" % round_number
	target_label.text = "ORTALAMA: %.2f      HEDEF (x 0.8): %.2f" % [result["average"], result["target"]]
	for i in range(rows.size()):
		if selections[i] < 0:
			rows[i].text = "OYUNCU %d     ELENDI     PUAN: %d" % [i + 1, scores[i]]
			continue
		var status: String = "KAZANDI" if winners.has(i) else "-1 PUAN"
		if eliminated_now.has(i):
			status = "ELENDI"
		rows[i].text = "OYUNCU %d      SAYI: %d      %s      PUAN: %d" % [i + 1, selections[i], status, scores[i]]

	if survivors.size() <= 1:
		outcome_label.text = "OYUN BITTI - OYUNCU %d KAZANDI" % (survivors[0] + 1) if survivors.size() == 1 else "OYUN BITTI"
	elif scores[0] <= DengeRoundRules.ELIMINATION_SCORE:
		outcome_label.text = "ELENDIN - DENEMEYI YENIDEN BASLAT"
	else:
		outcome_label.text = "KAZANANLAR: " + _winner_text(winners)
	continue_button.text = "YENIDEN BASLAT" if scores[0] <= DengeRoundRules.ELIMINATION_SCORE or survivors.size() <= 1 else "SONRAKI TUR"
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func dismiss() -> void:
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _winner_text(indices: Array) -> String:
	var names: PackedStringArray = []
	for index in indices:
		names.append(str(index + 1))
	return ", ".join(names)

func _on_continue_pressed() -> void:
	continue_requested.emit()
