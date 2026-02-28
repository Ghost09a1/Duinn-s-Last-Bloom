extends CanvasLayer

## Zeigt Dialog-Text und Auswahloptionen an.
## Verbindet sich mit DialogSystem über Signale.

@onready var panel       : PanelContainer = $Panel
@onready var speaker_lbl : Label          = $Panel/VBox/Speaker
@onready var text_lbl    : Label          = $Panel/VBox/Text
@onready var choices_box : VBoxContainer  = $Panel/VBox/Choices


func _ready() -> void:
	panel.visible = false
	DialogSystem.node_changed.connect(show_node)
	DialogSystem.dialog_ended.connect(hide_dialog)


func show_node(speaker: String, text: String, choices: Array) -> void:
	"""Wird von DialogSystem via Signal aufgerufen."""
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	speaker_lbl.text = speaker
	text_lbl.text    = text

	# Alte Buttons löschen
	for child in choices_box.get_children():
		child.queue_free()

	# Keine Choices = automatisch schließen nach kurzer Pause
	if choices.is_empty():
		await get_tree().create_timer(1.5).timeout
		hide_dialog()
		return

	# Buttons für jede Antwort erstellen
	var first_btn : Button = null
	for i in choices.size():
		var btn := Button.new()
		btn.text = choices[i].get("text", "...")
		btn.pressed.connect(_on_choice_pressed.bind(i))
		choices_box.add_child(btn)
		if first_btn == null:
			first_btn = btn

	if first_btn:
		await get_tree().process_frame
		first_btn.grab_focus()


func hide_dialog() -> void:
	panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for child in choices_box.get_children():
		child.queue_free()


func _on_choice_pressed(index: int) -> void:
	# Buttons sofort deaktivieren (kein Doppelklick)
	for child in choices_box.get_children():
		(child as Button).disabled = true
	DialogSystem.choose(index)
