extends Node

## StationRouter (Autoload)
## Leitet Interaktions-Events von StationInteractables an die richtigen Systeme weiter.

func activate_station(station_id: String, payload: Dictionary = {}) -> void:
	print("[StationRouter] Aktiviere Station: '%s' mit Payload: %s" % [station_id, payload])
	
	match station_id:
		"drinks_station":
			ServiceSystem.open_station("drinks")
		"food_station":
			ServiceSystem.open_station("food")
		"bell":
			ServiceSystem.ring_bell()
		"ledger":
			if GameManager.has_node("/root/EndNightUI"): # Beispiel, wie du UIs aufrufen kannst
				pass # EndNightUI.open()
			else:
				push_warning("[StationRouter] Ledger UI noch nicht implementiert.")
		"shop_board":
			if BuildMenuUI:
				BuildMenuUI.open()
		"room_board":
			var room_ui = load("res://scenes/ui/RoomAssignmentUI.tscn").instantiate()
			get_tree().root.add_child(room_ui)
			room_ui.assignment_finished.connect(func(): room_ui.queue_free())
			room_ui.start()
		"garden_door":
			var garden_gui = load("res://scenes/ui/GardenUI.tscn")
			if garden_gui:
				var inst = garden_gui.instantiate()
				get_tree().root.add_child(inst)
				inst.open()
		"front_door":
			var door_gui = load("res://scenes/ui/DoorUI.tscn")
			if door_gui:
				var inst = door_gui.instantiate()
				get_tree().root.add_child(inst)
				inst.open()
		"test_dialog":
			DialogSystem.start("test_station", null)
		"minigame_cleaning":
			var cleaning_scene = load("res://scenes/ui/CleaningMinigame.tscn")
			if cleaning_scene:
				var inst = cleaning_scene.instantiate()
				get_tree().root.add_child(inst)
				# Schwierigkeit basiert auf Verschmutzung
				var diff = int((100 - GameManager.cleanliness_level) / 10.0) + 3
				inst.start_minigame(diff)
		"tower_range":
			push_warning("[StationRouter] Tower Range Minigame Aufruf via Router ausstehend.")
		_:
			push_warning("[StationRouter] Unbekannte Station ID: %s" % station_id)
