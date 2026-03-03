extends Node3D

## Spawnt Gäste basierend auf einer Nacht-Sequenz (JSON) oder dem NightGenerator.
## Wird später vom NightManager gesteuert.

@export var guest_scene : PackedScene  # res://scenes/npc/Guest.tscn

var _queue   : Array[Dictionary] = []
var _slots   : Array[Marker3D] = []
var _active_guests : Dictionary = {} # Mapping von Slot (Marker3D) -> Guest (Node3D) oder null

var _active_seed: int = 0
var _active_event: String = ""

# -- Marker Management --
var _bar_queue_spots : Array[Marker3D] = []
var _guest_seats     : Array[Marker3D] = []
var _occupied_spots  : Dictionary = {} # Marker3D -> Guest Node



func _ready() -> void:
	# Sammle alle SpawnPoints
	for child in get_parent().get_children():
		if child is Marker3D and child.name.begins_with("SpawnPoint"):
			_slots.append(child)
			_active_guests[child] = null
			
	# Sammle Queue- und Sitz-Marker aus der NPCNavigation (Tags in Gruppen)
	for spot in get_tree().get_nodes_in_group("bar_queue"):
		if spot is Marker3D:
			_bar_queue_spots.append(spot)
			_occupied_spots[spot] = null
			
	for seat in get_tree().get_nodes_in_group("guest_seats"):
		if seat is Marker3D:
			_guest_seats.append(seat)
			_occupied_spots[seat] = null

	# Daten laden
	_load_night_data()
	
	# Erst NACH Queue-Aufbau beim GameManager registrieren
	GameManager.call_deferred("register_spawner", self)


func _load_night_data() -> void:
	# 1. Gäste-Datenbank laden
	var guest_db := {}
	var db_path := "res://data/guests/guests.json"
	if FileAccess.file_exists(db_path):
		var file := FileAccess.open(db_path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			guest_db = json.data
			
	# Hole Plan vom neuen deterministischen Generator
	if DayGenerator.current_plan.is_empty():
		DayGenerator.generate_day(GameManager.global_seed, GameManager.night_index)
		
	var plan = DayGenerator.current_plan
	_active_seed = plan.get("seed", 0)
	
	var ev_data = plan.get("event_data", {})
	_active_event = ev_data.get("label", "none")
	if _active_event != "none":
		print("[Spawner] Event aktiv: %s" % _active_event)
		GameManager.current_event = plan.get("event_id", "none")
	
	var sequence = plan.get("guest_sequence", [])
	
	for guest_entry in sequence:
		var guest_id = guest_entry["id"]
		# Gast aus DB laden und an Queue anhängen
		if guest_id in guest_db:
			var g_data = guest_db[guest_id].duplicate()
			g_data["id"] = guest_id # ID anhängen
			g_data["instance_seed"] = guest_entry["instance_seed"]
			g_data["room_roll"] = guest_entry["room_roll"]
			
			# Wende Event-Modifikatoren an (Patience/Mood)
			if ev_data:
				if ev_data.has("patience_bonus"):
					g_data["patience"] = g_data.get("patience", 30.0) + ev_data["patience_bonus"]
				if ev_data.has("mood_modifier"):
					g_data["mood"] = g_data.get("mood", 0) + ev_data["mood_modifier"]
					
			_queue.append(g_data)
		else:
			push_warning("[Spawner] Gast %s aus Sequenz nicht in DB!" % guest_id)


func start_night() -> void:
	"""Startet die Nacht und spawnt bis alle freien Slots belegt sind."""
	print("[Spawner] Nacht beginnt – %d Gäste." % _queue.size())
	_spawn_next_batch()


func _spawn_next_batch() -> void:
	for slot in _slots:
		if _active_guests[slot] == null and not _queue.is_empty():
			_spawn_guest_at(slot)
	_check_night_end()


func _spawn_guest_at(slot: Marker3D) -> void:
	if guest_scene == null:
		push_error("[Spawner] guest_scene nicht gesetzt!")
		return

	var data   : Dictionary = _queue.pop_front()
	var pos    : Vector3 = slot.global_position

	var guest_id = data.get("id", "generic_guest")
	if not SecuritySystem.evaluate_guest_entry(guest_id, data):
		# Gast abgewiesen! Nächster Versuch in 1.5s
		print("[Spawner] Gast %s wurde abgewiesen, Spawner überspringt ihn." % data.get("display_name", "?"))
		_active_guests[slot] = null
		await get_tree().create_timer(1.5).timeout
		if not _queue.is_empty():
			_spawn_guest_at(slot)
		else:
			_check_night_end()
		return

	var guest : Node3D = guest_scene.instantiate()
	# Position VOR add_child setzen – Physics Bodies brauchen das
	guest.position = pos
	get_parent().add_child(guest)
	
	# Upgrade: Patience-Bonus anwenden
	var pat_bonus : float = GameManager.get_patience_bonus()
	if pat_bonus > 0.0:
		data["patience"] = data.get("patience", 90.0) + pat_bonus

	# Memory: Konsequenzen vorheriger Events anwenden
	var g_id = data.get("id", "generic_guest")
	if g_id != "generic_guest" and GameManager.npc_memory.has(g_id):
		var outcome = GameManager.npc_memory[g_id].get("last_outcome", "none")
		if outcome == "perfect":
			data["patience"] = data.get("patience", 90.0) + 5.0
			data["mood"] = data.get("mood", 0) + 5
		elif outcome == "bad":
			data["patience"] = data.get("patience", 90.0) - 5.0
			data["mood"] = data.get("mood", 0) - 2
		elif outcome == "walkout":
			data["patience"] = data.get("patience", 90.0) - 15.0
			data["mood"] = data.get("mood", 0) - 5
		
	# Zimmer-Würfeln
	data["wants_room"] = false # Reset auf false
	var free_rooms = GameManager.get_free_room_count()
	if free_rooms > 0:
		var chance : float = data.get("wants_room_chance", 0.0)
		var pre_roll : float = data.get("room_roll", 1.0)
		if pre_roll <= chance:
			data["wants_room"] = true
			print("[Spawner] Gast %s will ein Zimmer (Chance: %.2f). pre-roll: %.2f" % [data.get("display_name", "?"), chance, pre_roll])
	
	guest.setup(data)
	
	# guest.guest_done feuert self – wir binden noch den Slot ran, damit _on_guest_done weiß welcher Slot frei wird
	guest.guest_done.connect(_on_guest_done.bind(slot))
	_active_guests[slot] = guest
	
	# -- NPC FLOW START --
	# Finde freien Bar-Spot
	var bar_spot = request_spot("bar_queue", guest)
	if bar_spot:
		guest.set_target(bar_spot.global_position)
	
	print("[Spawner] Gast gespawnt: %s (patience: %.0fs)" % [data.get("display_name", "?"), data.get("patience", 90.0)])

# -- Neue Management Funktionen --

func request_spot(group: String, guest_node: Node) -> Marker3D:
	var list : Array[Marker3D] = []
	if group == "bar_queue": 
		list = _bar_queue_spots
		# -- SERVICE RUSH CHECK --
		var occupied_count = 0
		for spot in list:
			if _occupied_spots[spot] != null: occupied_count += 1
		
		if occupied_count >= list.size():
			print("[Spawner] SERVICE RUSH! Queue is full. Guest patience penalty applied.")
			if guest_node.has_method("apply_rush_penalty"):
				guest_node.apply_rush_penalty()
	
	elif group == "guest_seats": 
		list = _guest_seats
	
	for spot in list:
		if _occupied_spots[spot] == null:
			_occupied_spots[spot] = guest_node
			return spot
	return null

func release_spot(spot: Marker3D) -> void:
	if _occupied_spots.has(spot):
		_occupied_spots[spot] = null

func get_spot_of_guest(guest_node: Node) -> Marker3D:
	for spot in _occupied_spots:
		if _occupied_spots[spot] == guest_node:
			return spot
	return null


func _on_guest_done(_guest: Node3D, slot: Marker3D) -> void:
	_active_guests[slot] = null
	await get_tree().create_timer(1.5).timeout
	if not _queue.is_empty():
		_spawn_guest_at(slot)
	else:
		_check_night_end()


func _check_night_end() -> void:
	if _queue.is_empty():
		var all_empty = true
		for slot in _slots:
			if _active_guests[slot] != null:
				all_empty = false
		if all_empty:
			print("[Spawner] Alle Gäste fertig.")
			ScoreSystem.finish_night()
