extends CanvasLayer

@onready var applicants_container = %ApplicantsContainer
@onready var rooms_container      = %RoomsContainer
@onready var assign_btn           = %AssignBtn
@onready var reject_btn           = %RejectBtn
@onready var continue_btn         = %ContinueBtn
@onready var info_lbl             = %InfoLbl

var selected_applicant_index : int = -1
var selected_room_id        : String = ""

# Referenzen auf erstellte UI-Elemente
var _applicant_nodes = []
var _room_nodes = []

signal assignment_finished

func _ready() -> void:
	assign_btn.pressed.connect(_on_assign_pressed)
	reject_btn.pressed.connect(_on_reject_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	_update_ui()


func start() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	GameManager.phase = GameManager.Phase.IN_ROOM_ASSIGNMENT
	_update_ui()
	print("[RoomUI] Gestartet. %d Bewerber." % GameManager.room_applicants.size())


func _update_ui() -> void:
	_applicant_nodes.clear()
	for child in applicants_container.get_children():
		child.queue_free()
		
	_room_nodes.clear()
	for child in rooms_container.get_children():
		child.queue_free()
	
	selected_applicant_index = -1
	selected_room_id = ""
	_update_buttons()
	
	var all_handled = GameManager.room_applicants.is_empty()
	if all_handled:
		info_lbl.text = "Alle Bewerbungen bearbeitet."
		continue_btn.disabled = false
		return
		
	continue_btn.disabled = true
	info_lbl.text = "Wähle einen Gast und ein freies Zimmer."
	
	# 1) Bewerber Liste
	for i in range(GameManager.room_applicants.size()):
		var app: Dictionary = GameManager.room_applicants[i]
		var btn = Button.new()
		var d = "%s\nBudget: %dG\nDauer: %d-%d Tage" % [
			app.get("display_name", "?"),
			app.get("room_budget_per_week", 0),
			app.get("stay_duration_days", [1])[0],
			app.get("stay_duration_days", [1])[-1]
		]
		btn.text = d
		btn.custom_minimum_size = Vector2(250, 60)
		btn.pressed.connect(_on_applicant_selected.bind(i, btn))
		applicants_container.add_child(btn)
		_applicant_nodes.append(btn)
		
	# 2) Zimmer Liste
	for r_id in GameManager.rooms.keys():
		var r = GameManager.rooms[r_id]
		var is_free = (r["occupant_id"] == "")
		var is_clean = (r["cleanliness"] > 20) # nur in sauberes zimmer? mal schauen.
		
		var btn = Button.new()
		var txt = "Zimmer: %s\nSauberkeit: %d%%" % [r_id, r["cleanliness"]]
		if not is_free:
			txt += "\n[Belegt von %s]" % r["occupant_id"]
			btn.disabled = true
		btn.text = txt
		btn.custom_minimum_size = Vector2(200, 60)
		btn.pressed.connect(_on_room_selected.bind(r_id, btn))
		rooms_container.add_child(btn)
		_room_nodes.append(btn)


func _on_applicant_selected(index: int, node: Button) -> void:
	selected_applicant_index = index
	for b in _applicant_nodes: b.add_theme_color_override("font_color", Color.WHITE)
	node.add_theme_color_override("font_color", Color.GREEN)
	_update_buttons()

func _on_room_selected(r_id: String, node: Button) -> void:
	selected_room_id = r_id
	for b in _room_nodes: b.add_theme_color_override("font_color", Color.WHITE)
	node.add_theme_color_override("font_color", Color.GREEN)
	_update_buttons()


func _update_buttons() -> void:
	assign_btn.disabled = (selected_applicant_index == -1 or selected_room_id == "")
	reject_btn.disabled = (selected_applicant_index == -1)


func _on_assign_pressed() -> void:
	if selected_applicant_index < 0 or selected_room_id == "": return
	
	var app: Dictionary = GameManager.room_applicants[selected_applicant_index]
	var budget = app.get("room_budget_per_week", 0)
	var durations = app.get("stay_duration_days", [3])
	var dur = durations[randi() % durations.size()]
	
	# Zimmer belegen
	var room = GameManager.rooms[selected_room_id]
	room["occupant_id"] = app.get("guest_id", "???")
	room["days_remaining"] = dur
	room["days_until_next_payment"] = 7
	
	# Geld abbuchen
	GameManager.global_money += budget
	
	print("[RoomUI] Zugewiesen: %s in %s für %d Tage. (+%dG)" % [app.get("guest_id"), selected_room_id, dur, budget])
	
	# NPC Memory Updaten
	var g_id = app.get("guest_id", "")
	if g_id != "" and not g_id.begins_with("guest_"):
		if not GameManager.npc_memory.has(g_id): GameManager.npc_memory[g_id] = {"met":true}
		GameManager.npc_memory[g_id]["given_room"] = true
	
	GameManager.room_applicants.remove_at(selected_applicant_index)
	_update_ui()


func _on_reject_pressed() -> void:
	if selected_applicant_index < 0: return
	var app: Dictionary = GameManager.room_applicants[selected_applicant_index]
	print("[RoomUI] Bewerber abgelehnt: %s" % app.get("guest_id"))
	GameManager.room_applicants.remove_at(selected_applicant_index)
	_update_ui()


func _on_continue_pressed() -> void:
	hide()
	assignment_finished.emit()
