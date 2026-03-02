extends CanvasLayer

@onready var lbl_status: Label = %LblStatus
@onready var btn_toggle: Button = %BtnToggle
@onready var btn_close_ui: Button = %BtnClose

func _ready() -> void:
	visible = false
	btn_toggle.pressed.connect(_on_toggle_door)
	btn_close_ui.pressed.connect(close)

func open() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_ui()

func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _refresh_ui() -> void:
	if SecuritySystem.is_door_open:
		lbl_status.text = "Die Tür ist OFFEN."
		lbl_status.modulate = Color(0.2, 1.0, 0.2)
		btn_toggle.text = "Tür SCHLIESSEN"
	else:
		lbl_status.text = "Die Tür ist GESCHLOSSEN."
		lbl_status.modulate = Color(1.0, 0.2, 0.2)
		btn_toggle.text = "Tür ÖFFNEN"

func _on_toggle_door() -> void:
	SecuritySystem.set_door_state(!SecuritySystem.is_door_open)
	_refresh_ui()
