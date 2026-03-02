extends CanvasLayer

signal shooting_finished(score: int)

@onready var lbl_score = $Panel/LblScore
@onready var lbl_time = $Panel/LblTime
@onready var play_area = $Panel/PlayArea
@onready var btn_close = $Panel/BtnClose

var _score : int = 0
var _time_left : float = 15.0
var _is_running : bool = false

func _ready():
	btn_close.pressed.connect(_on_close)
	hide()

func start_minigame():
	show()
	_score = 0
	_time_left = 15.0
	_is_running = true
	_update_ui()
	
	# Clear old targets
	for c in play_area.get_children():
		c.queue_free()
	
	_spawn_target()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta):
	if not _is_running:
		return
		
	_time_left -= delta
	if _time_left <= 0:
		_time_left = 0
		_is_running = false
		_finish()
	
	_update_ui()

func _spawn_target():
	if not _is_running:
		return
		
	var btn = Button.new()
	btn.text = "🎯"
	btn.add_theme_font_size_override("font_size", 24)
	
	# Random position within play area
	var area_size = play_area.size
	if area_size.x < 50: area_size = Vector2(600, 300) # Fallback if size not yet updated
	
	btn.position = Vector2(
		randf_range(50, area_size.x - 50),
		randf_range(50, area_size.y - 50)
	)
	
	btn.pressed.connect(func(): _on_target_hit(btn))
	play_area.add_child(btn)

func _on_target_hit(btn: Button):
	if not _is_running:
		return
		
	_score += 1
	btn.queue_free()
	_spawn_target()
	_update_ui()

func _update_ui():
	lbl_score.text = "Treffer: %d" % _score
	lbl_time.text = "Zeit: %.1fs" % _time_left

func _on_close():
	_finish()

func _finish():
	_is_running = false
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	shooting_finished.emit(_score)
	# Trigger reward handling usually happens in the caller (MinigameTrigger)
