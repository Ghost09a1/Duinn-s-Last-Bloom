extends CanvasLayer

signal cleaning_finished(success: bool)

@onready var stains_container = $Panel/StainsArea
@onready var lbl_info = $Panel/LblInfo
@onready var progress_bar = $Panel/ProgressBar
@onready var btn_close = $Panel/BtnClose

var _total_stains : int = 0
var _cleaned_stains : int = 0

func _ready() -> void:
	btn_close.pressed.connect(_on_close)
	hide()

func start_minigame(difficulty: int = 5) -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_total_stains = difficulty
	_cleaned_stains = 0
	progress_bar.max_value = _total_stains
	progress_bar.value = 0
	lbl_info.text = "Entferne alle %d Schmutzflecken!" % _total_stains
	
	# Alte Flecken löschen
	for c in stains_container.get_children():
		c.queue_free()
		
	# Neue generieren
	for i in range(_total_stains):
		var btn = Button.new()
		btn.text = "Schmutz"
		btn.add_theme_font_size_override("font_size", 20)
		btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		# Zufällige Position (simuliert durch einfache Margins)
		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_left", randi_range(0, 400))
		m.add_theme_constant_override("margin_top", randi_range(0, 300))
		m.add_child(btn)
		stains_container.add_child(m)
		
		btn.pressed.connect(_on_stain_clicked.bind(m))

func _on_stain_clicked(node_to_free: Node) -> void:
	node_to_free.queue_free()
	_cleaned_stains += 1
	progress_bar.value = _cleaned_stains
	
	if _cleaned_stains >= _total_stains:
		lbl_info.text = "Raum ist blitzblank!"
		
		# Belohnung (Reputation oder Sauberkeitswert)
		GameManager.add_reputation(5)
		
		# Kurze Verzögerung vorm Schließen
		await get_tree().create_timer(1.0).timeout
		_finish(true)

func _on_close() -> void:
	_finish(false)

func _finish(success: bool) -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	cleaning_finished.emit(success)
