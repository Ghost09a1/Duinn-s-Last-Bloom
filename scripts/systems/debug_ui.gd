extends CanvasLayer

@onready var panel := $PanelContainer
@onready var content_lbl := $PanelContainer/MarginContainer/VBoxContainer/ContentLabel
@onready var log_lbl := $PanelContainer/MarginContainer/VBoxContainer/LogLabel

var _visible := false

func _ready() -> void:
	panel.visible = false
	layer = 100 # Ganz oben
	
	# Simulator Button
	var btn_sim = Button.new()
	btn_sim.text = "[H4] RUN 100 NIGHTS SIM"
	btn_sim.pressed.connect(_on_sim_pressed)
	content_lbl.get_parent().add_child(btn_sim)
	
func _on_sim_pressed() -> void:
	print("[DebugUI] Starte Simulator...")
	AutoSimulator.run_simulation(GameManager.global_seed, 100)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		_visible = !_visible
		panel.visible = _visible

func _process(_delta: float) -> void:
	if not _visible:
		return
		
	var text = "== DEBUG OVERLAY ==\n"
	text += "Nacht: %d\n" % GameManager.night_index
	text += "Phase: %s\n" % GameManager.Phase.keys()[GameManager.phase]
	
	if GameManager._spawner:
		text += "Seed: %d\n" % GameManager._spawner._active_seed
		if GameManager._spawner._active_event != "":
			text += "Event: %s\n" % GameManager._spawner._active_event
			
	if not ServiceSystem._prepared_items.is_empty():
		text += "\n-- TRESEN --\n"
		for item in ServiceSystem._prepared_items:
			text += "- %s\n" % item
	
	# Aktive Gäste auslesen
	text += "\n-- GÄSTE --\n"
	var has_guests = false
	if GameManager._spawner:
		for slot in GameManager._spawner._active_guests:
			var g = GameManager._spawner._active_guests[slot]
			if g != null:
				has_guests = true
				text += "[%s] %s (%s)\n" % [slot.name, g.display_name, g.guest_id]
				text += " Wunsch: %s | Mood: %d | Patience: %.1f\n" % [g.requested_item, g.mood, g.timer.time_left]
				text += " State: %s\n" % g.State.keys()[g.state]
				
	if not has_guests:
		text += "Niemand da.\n"
		
	# Flags
	text += "\n-- FLAGS --\n"
	var flags = ScoreSystem._flags_set.keys()
	if flags.is_empty():
		text += "Keine\n"
	else:
		text += ", ".join(flags) + "\n"
		
	content_lbl.text = text
	
	# Event Log (letzte 5-10 Events)
	var log_text = "\n-- EVENT LOG --\n"
	for ev in GameManager.get_event_log():
		log_text += "- %s\n" % ev
	log_lbl.text = log_text
