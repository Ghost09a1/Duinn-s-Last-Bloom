extends CanvasLayer

@onready var rooms_container = $PanelContainer/MarginContainer/HBox/LeftBox/RoomsC
@onready var applicants_container = $PanelContainer/MarginContainer/HBox/RightBox/ApplicantsC
@onready var lbl_header = $PanelContainer/MarginContainer/HBox/LeftBox/LblHeader
@onready var btn_close = $PanelContainer/MarginContainer/HBox/RightBox/BtnClose

func _ready() -> void:
	btn_close.pressed.connect(_on_close)
	hide()

func open() -> void:
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh()

func _refresh() -> void:
	# 1. Zimmer auflisten
	for c in rooms_container.get_children():
		c.queue_free()
		
	var free_count = 0
	for room_id in GameManager.rooms:
		var r = GameManager.rooms[room_id]
		var l = Label.new()
		if r.occupant_id == "":
			l.text = "%s: [ LEER ]" % room_id
			l.modulate = Color(0.5, 1.0, 0.5)
			free_count += 1
		else:
			l.text = "%s: Belegt (noch %d Tage)" % [room_id, r.days_remaining]
			l.modulate = Color(1.0, 0.5, 0.5)
		rooms_container.add_child(l)
		
	lbl_header.text = "ZIMMERVERGABE (%d frei)" % free_count
	
	# 2. Bewerber auflisten
	for c in applicants_container.get_children():
		c.queue_free()
		
	if GameManager.room_applicants.is_empty():
		var l = Label.new()
		l.text = "Keine Bewerber heute."
		applicants_container.add_child(l)
	else:
		for raw_app in GameManager.room_applicants:
			var app: Dictionary = raw_app
			var hbox = HBoxContainer.new()
			
			var l = Label.new()
			l.text = "%s (Budget: %dG)" % [app.get("display_name", "???"), app.get("room_budget_per_week", 0)]
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(l)
			
			var btn = Button.new()
			btn.text = "Aufnehmen"
			btn.disabled = (free_count == 0)
			# btn.pressed.connect(_on_assign.bind(app)) # GEHT IN GODOT 4 SO NICHT MEHR (Binden an Dictionaries oft fehlerhaft, besser Lambda)
			btn.pressed.connect(func(): _on_assign(app))
			hbox.add_child(btn)
			
			applicants_container.add_child(hbox)

func _on_assign(app: Dictionary) -> void:
	# Finde erstes freies Zimmer
	var found_room = ""
	for r_id in GameManager.rooms:
		if GameManager.rooms[r_id].occupant_id == "":
			found_room = r_id
			break
			
	if found_room != "":
		GameManager.assign_room(found_room, app)
		_refresh()

func _on_close() -> void:
	hide()
	var shop = get_node_or_null("/root/TavernPrototype/MetaShopUI")
	if shop:
		shop.open()
	else:
		push_error("[AssignRoomUI] MetaShopUI nicht gefunden!")
