extends CanvasLayer

signal shooting_finished(score: int)

@onready var play_area = $Panel/PlayArea
@onready var lbl_score = $Panel/LblScore
@onready var lbl_time = $Panel/LblTime
@onready var btn_close = $Panel/BtnClose

var _score : int = 0
var _time_left : float = 15.0
var _is_playing : bool = false
var _spawn_timer : float = 0.0

func _ready() -> void:
	btn_close.pressed.connect(_on_close)
	hide()

func start_minigame() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_score = 0
	_time_left = 15.0
	_is_playing = true
	_spawn_timer = 0.5
	_update_labels()
	
	for c in play_area.get_children():
		c.queue_free()

func _process(delta: float) -> void:
	if not _is_playing: return
	
	_time_left -= delta
	_update_labels()
	
	if _time_left <= 0:
		_end_game()
		return
		
	_spawn_timer -= delta
	if _spawn_timer <= 0:
		_spawn_target()
		_spawn_timer = randf_range(0.4, 0.9)

func _spawn_target() -> void:
	var btn = Button.new()
	btn.text = "(O)"
	btn.add_theme_font_size_override("font_size", 24)
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", randi_range(50, 450))
	m.add_theme_constant_override("margin_top", randi_range(50, 250))
	m.add_child(btn)
	play_area.add_child(m)
	
	btn.pressed.connect(_on_target_hit.bind(m))
	
	# Ziel verschwindet nach 1-2 Sekunden automatisch
	_despawn_after(m, randf_range(1.0, 2.0))

func _despawn_after(node_to_free: Node, time: float) -> void:
	await get_tree().create_timer(time).timeout
	if is_instance_valid(node_to_free):
		node_to_free.queue_free()

func _on_target_hit(node_to_free: Node) -> void:
	if is_instance_valid(node_to_free):
		node_to_free.queue_free()
		_score += 1
		_update_labels()

func _update_labels() -> void:
	lbl_score.text = "Treffer: %d" % _score
	lbl_time.text = "Zeit: %.1fs" % _time_left

func _end_game() -> void:
	_is_playing = false
	lbl_time.text = "Zeit Abgelaufen!"
	
	var rep_gain = int(_score / 3.0)
	if rep_gain > 0:
		GameManager.add_reputation(rep_gain)
		
	await get_tree().create_timer(1.5).timeout
	_finish(_score)

func _on_close() -> void:
	_is_playing = false
	_finish(_score)

func _finish(final_score: int) -> void:
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	shooting_finished.emit(final_score)
