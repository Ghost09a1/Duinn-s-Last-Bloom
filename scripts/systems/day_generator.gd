extends Node

## DayGenerator (Autoload)
## Berechnet deterministisch aus (global_seed + night_index) den gesamten Tagesablauf:
## Welches Event findet statt? Wie viele Gäste kommen? Wer kommt?

var current_plan : Dictionary = {}

func generate_day(global_seed: int, day_index: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = global_seed + day_index
	
	# 1. Event auswürfeln
	var event_id = _roll_event(rng)
	var event_data = GameManager.events_db.get(event_id, {})
	
	# 2. Base Guest Count bestimmen (Start mit 2-3, plus Upgrades)
	var base_count = rng.randi_range(2, 4)
	if day_index > 2: base_count += 1
	base_count += GameManager.get_extra_guests()
	
	# Event Modifier anwenden
	var ev_modifier = event_data.get("guest_modifier", 0)
	var final_guest_count = maxi(1, base_count + ev_modifier)
	
	# 3. Gäste-Liste zusammenstellen
	# Wir nehmen vorerst einfach nacheinander zufällige Archetypen aus dem GuestSpawner.
	# (Da der GuestSpawner die Archetypen lädt, greifen wir der Einfachheit halber auf seine DB zu, 
	# oder wir laden sie hier neu. Für diesen Prototyp füllen wir die Queue mit IDs).
	
	var guest_sequence : Array[String] = []
	var available_archetypes = _get_weighted_archetypes()
	
	if available_archetypes.size() > 0:
		for i in range(final_guest_count):
			var selected_id = _roll_guest(rng, available_archetypes)
			guest_sequence.append(selected_id)
	
	current_plan = {
		"seed": rng.seed,
		"day_index": day_index,
		"event_id": event_id,
		"event_data": event_data, # Kopie für direkten Zugriff
		"guest_count": final_guest_count,
		"guest_sequence": guest_sequence
	}
	
	print("[DayGenerator] Plante Tag %d (Seed %d). Event: %s, Gäste: %d" % [day_index, rng.seed, event_id, final_guest_count])
	return current_plan


func _roll_event(rng: RandomNumberGenerator) -> String:
	if GameManager.events_db.is_empty():
		return "none"
		
	var pool = []
	var total_weight = 0
	for e_id in GameManager.events_db.keys():
		var w = int(GameManager.events_db[e_id].get("weight", 0))
		total_weight += w
		pool.append({"id": e_id, "w": w})
		
	if total_weight <= 0: return "none"
	
	var result = "none"
	var roll = rng.randi() % total_weight
	var current = 0
	for entry in pool:
		current += entry["w"]
		if roll < current:
			result = entry["id"]
			break
			
	return result

func _get_weighted_archetypes() -> Array[Dictionary]:
	var path = "res://data/guests/guests.json"
	var pool : Array[Dictionary] = []
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			var db = json.data
			for g_id in db.keys():
				var base_weight = float(db[g_id].get("spawn_weight", 100.0))
				
				# Memory Modifier anwenden
				if GameManager.npc_memory.has(g_id):
					var outcome = GameManager.npc_memory[g_id].get("last_outcome", "none")
					if outcome == "perfect":
						base_weight *= 1.5
					elif outcome == "bad":
						base_weight *= 0.7
					elif outcome == "walkout":
						base_weight *= 0.5
						
				pool.append({"id": g_id, "w": int(base_weight)})
	return pool

func _roll_guest(rng: RandomNumberGenerator, pool: Array[Dictionary]) -> String:
	var total_weight = 0
	for entry in pool:
		total_weight += entry["w"]
		
	if total_weight <= 0: return "generic_guest"
	
	var roll = rng.randi() % total_weight
	var current = 0
	for entry in pool:
		current += entry["w"]
		if roll < current:
			return entry["id"]
			
	return pool[0]["id"]
