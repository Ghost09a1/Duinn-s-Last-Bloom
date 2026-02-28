extends Node

## Generiert Nächte prozedural aus einem Seed.
## Wählt Gäste (anhand von Reputations-Vorbedingungen und Spawn-Weights) aus.

var _seed : int = 0
var _rng  : RandomNumberGenerator = RandomNumberGenerator.new()

# Geladene Daten (werden vom GuestSpawner oder GameManager hierhin gereicht oder hier geladen)
var _guest_db : Dictionary = {}
var _event_db : Dictionary = {}


func init(guest_db: Dictionary, event_db: Dictionary) -> void:
	_guest_db = guest_db
	_event_db = event_db


func generate_night(night_index: int) -> Dictionary:
	"""Generiert eine Nacht basierend auf dem Index (als Seed-Basis)."""
	_seed = hash("tavern_game_" + str(night_index))
	_rng.seed = _seed
	
	print("[Generator] Generiere Nacht %d (Seed: %d)" % [night_index, _seed])
	
	var event_id = _pick_event(night_index)
	var num_guests = 2 + int(night_index / 2) # Tag 1=2, Tag 2=3, Tag 4=4...
	
	var seq = _pick_guests(num_guests)
	
	# Wende Global Patience Modifier an (Gäste werden ungeduldiger im Mid-Game)
	var global_pat_mod = max(0.5, 1.0 - (night_index * 0.05))
	
	var advanced_seq = []
	for g_id in seq:
		advanced_seq.append({
			"id": g_id,
			"overrides": {
				"patience": _guest_db[g_id].get("patience", 30.0) * global_pat_mod
			}
		})
	
	var night_data := {
		"id": "night_gen_%02d" % night_index,
		"seed": _seed,
		"event_id": event_id,
		"sequence": advanced_seq
	}
	
	return night_data


func _pick_event(night_index: int) -> String:
	# Event-Chance steigt leicht: Startet bei 10%, steigt pro Tag um 2%, maximal 40%
	var chance = min(0.4, 0.1 + (night_index * 0.02))
	if _rng.randf() > chance:
		return ""
		
	var keys = _event_db.keys()
	if keys.is_empty():
		return ""
		
	# Wähle zufällig
	var pick_idx = _rng.randi_range(0, keys.size() - 1)
	return keys[pick_idx]


func _pick_guests(count: int) -> Array:
	var seq := []
	var pool := _guest_db.keys()
	if pool.is_empty(): return seq
	
	var last_picked := ""
	
	for i in range(count):
		# 1) Gewichte berechnen für aktuellen Slot
		var weighted_pool := []
		var total_weight := 0.0
		
		for guest_id in pool:
			var data = _guest_db[guest_id]
			var mem = GameManager.npc_memory.get(guest_id, {})
			var t = mem.get("trust", 0)
			
			# Min_trust check
			var min_t = data.get("min_trust", -100)
			if t < min_t:
				continue # Kann diesen Gast nicht spawnen
				
			var weight = float(data.get("base_weight", 10.0))
			
			# Trust-Modifikatoren
			if t > 10:
				weight *= 2.0  # Stammgast
			elif t > 30:
				weight *= 3.0  # Sehr treuer Gast
				
			if t <= -10:
				weight *= 0.1  # Ungern gesehene Gäste
				
			if t <= -30:
				weight = 0.0   # Kommt gar nicht mehr
				
			# Verhindere gleichen Gast 2x direkt hintereinander
			if guest_id == last_picked:
				weight *= 0.1
				
			if weight > 0:
				weighted_pool.append({"id": guest_id, "weight": weight})
				total_weight += weight
				
		if total_weight <= 0.0:
			break # Niemand will kommen!
			
		# 2) Würfel werfen
		var roll = _rng.randf() * total_weight
		var picked = ""
		var current := 0.0
		
		for entry in weighted_pool:
			current += entry.weight
			if roll <= current:
				picked = entry.id
				break
				
		if picked == "":
			picked = weighted_pool[-1].id
			
		seq.append(picked)
		last_picked = picked
		
	return seq
