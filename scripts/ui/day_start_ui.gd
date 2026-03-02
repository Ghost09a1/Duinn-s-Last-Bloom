extends CanvasLayer

signal day_started

@onready var title_lbl: Label = %TitleLbl
@onready var desc_lbl: Label = %DescLbl
@onready var start_btn: Button = %StartBtn

func _ready() -> void:
	visible = false
	start_btn.pressed.connect(_on_start_pressed)

func open() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var day = GameManager.night_index
	var ev_id = GameManager.current_event
	var ev_data = GameManager.events_db.get(ev_id, {})
	
	var ev_title = ev_data.get("label", "Ruhiger Standard-Tag")
	var ev_desc = ev_data.get("description", "Nichts Außergewöhnliches. Ein regulärer Abend.")
	
	title_lbl.text = "Tag %d: %s" % [day, ev_title]
	desc_lbl.text = ev_desc
	
	start_btn.grab_focus()

func _on_start_pressed() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	day_started.emit()
	queue_free()
