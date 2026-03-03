extends Node

func activate_station(station_id: String, payload: Dictionary = {}) -> void:
	print("[StationRouter] Aktiviere Station: '%s'" % station_id)
	
	match station_id:
		"drinks_station":
			ServiceSystem.open_station("drinks")
		"food_station":
			ServiceSystem.open_station("food")
		"bell":
			ServiceSystem.ring_bell()
		"ledger":
			_open_autoload_ui(EndNightUI)
		"shop_board":
			_open_autoload_ui(BuildMenuUI)
		"room_board":
			_instantiate_ui("res://scenes/ui/RoomAssignmentUI.tscn")
		"garden_door":
			_instantiate_ui("res://scenes/ui/GardenUI.tscn")
		"front_door":
			_instantiate_ui("res://scenes/ui/DoorUI.tscn")
		"minigame_cleaning":
			_start_cleaning_minigame()
		"tower_range":
			_instantiate_ui("res://scenes/ui/BirdsTowerMinigame.tscn", "start_minigame")
		"trapdoor":
			var p = payload.get("player")
			if p:
				_handle_basement_transition(p)
		"brewing_station":
			print("[StationRouter] Brewing Station aktiviert.")
			_handle_brewing_interaction(payload.get("player"))
		"dumbwaiter":
			print("[StationRouter] Dumbwaiter aktiviert.")
			_handle_dumbwaiter_interaction(payload.get("player"))
		"stage":
			print("[StationRouter] Bühne aktiviert.")
			_handle_stage_interaction(payload.get("player"))
		_:
			push_warning("[StationRouter] Unbekannte Station ID: %s" % station_id)

func _open_autoload_ui(ui_node: Node):
	if ui_node and ui_node.has_method("open"):
		ui_node.open()
	elif ui_node:
		ui_node.show()

func _instantiate_ui(path: String, start_method: String = "open"):
	if not FileAccess.file_exists(path):
		push_error("[StationRouter] Scene nicht gefunden: " + path)
		return
	var scene = load(path)
	if scene:
		var inst = scene.instantiate()
		get_tree().root.add_child(inst)
		if inst.has_method(start_method):
			inst.call(start_method)
		elif inst.has_method("start"):
			inst.start()

func _start_cleaning_minigame():
	var scene_path = "res://scenes/ui/CleaningMinigame.tscn"
	if not FileAccess.file_exists(scene_path): return
	var inst = load(scene_path).instantiate()
	get_tree().root.add_child(inst)
	# Schwierigkeit basiert auf Verschmutzung
	var cleanliness = 100
	if "cleanliness_level" in GameManager:
		cleanliness = GameManager.cleanliness_level
	var diff = int((100 - cleanliness) / 10.0) + 3
	if inst.has_method("start_minigame"):
		inst.start_minigame(diff)

func _handle_basement_transition(player: CharacterBody3D):
	# Toggle Ground <-> Basement
	var cam = get_node_or_null("/root/TavernPrototype/IsoCameraContainer")
	
	if player.global_position.y < -1.0:
		# Zurück nach oben
		var target = get_node_or_null("/root/TavernPrototype/NavigationRegion3D/Pantry/Trapdoor")
		if target:
			player.global_position = target.global_position + Vector3(0, 1, 1) # Neben die Falltür
		if cam: cam.set_floor_level(0)
	else:
		# Ab in den Keller
		var target = get_node_or_null("/root/TavernPrototype/Tier2_Addons/Basement_Base/BasementSpawn")
		if target:
			player.global_position = target.global_position
		if cam: cam.set_floor_level(-1)
	
	# NavAgent Reset (Wichtig damit er nicht zum alten Ziel will)
	if player.has_method("stop_movement"):
		player.stop_movement()

func _handle_brewing_interaction(_player: CharacterBody3D):
	# Placeholder: Startet einfach Met-Brauen wenn Slot frei
	var sys = get_node_or_null("/root/BrewingSystem")
	if sys:
		if sys.start_brewing("slot_1", "mead"):
			DialogSystem.start("brewing_started", _player)
		else:
			DialogSystem.start("brewing_busy", _player)
	else:
		print("[StationRouter] BrewingSystem Autoload nicht gefunden!")

func _handle_dumbwaiter_interaction(_player: CharacterBody3D):
	var sys = get_node_or_null("/root/Dumbwaiter")
	if not sys: return
	
	var floor_level = 0
	if _player.global_position.y < -1.0:
		floor_level = -1
		
	if sys.has_items(floor_level):
		var item_id = sys.pickup_item(floor_level)
		# Add to inventory (ScoreSystem as proxy for inventory)
		if "ScoreSystem" in GameManager:
			GameManager.ScoreSystem.add_to_inventory(item_id)
		DialogSystem.start("dumbwaiter_pickup", _player, {"item": item_id})
	else:
		DialogSystem.start("dumbwaiter_empty", _player)

func _handle_stage_interaction(_player: CharacterBody3D):
	if "AudioManager" in get_node("/root"):
		get_node("/root/AudioManager").play_sfx("coin")
	var sys = get_node_or_null("/root/PerformanceSystem")
	if not sys: return
	
	if sys.is_active:
		DialogSystem.start("stage_busy", _player)
	else:
		# Einfacher Start-Dialog (Platzhalter)
		sys.start_performance("Barde Barnaby", 45.0)
		DialogSystem.start("stage_started", _player)
	
func _on_portal_interact(player: CharacterBody3D, _payload: Dictionary) -> void:
	if "PortalManager" in get_node("/root"):
		var pm = get_node("/root/PortalManager")
		var status = pm.get_portal_status()
		
		var dialog_data = {
			"id": "portal_info",
			"nodes": {
				"start": {
					"text": "Das antike Portal vibriert leise in der Luft. Status: %s" % status,
					"choices": [
						{"text": "Zurück", "next": "end"}
					]
				}
			}
		}
		
		if "DialogSystem" in get_node("/root"):
			DialogSystem.start_custom(dialog_data)
			player.set_locked(true)
			DialogSystem.dialog_ended.connect(func(): player.set_locked(false), CONNECT_ONE_SHOT)
	
	if "AudioManager" in get_node("/root"):
		get_node("/root/AudioManager").play_sfx("click")
