extends Node

## Backend-Logik für das Garten-Minispiel.

# Wir nutzen das im GameManager vorhandene Array "garden_plots" als State.
# Struktur eines Plots: {"seed": "mint_seed", "days_growing": 0}

const SEED_GROWTH_TIMES = {
	"mint_seed": 2  # Minze braucht 2 Nächte zum Wachsen
}

const SEED_TO_HARVEST = {
	"mint_seed": "mint_leaf"
}


func process_growth() -> Array[String]:
	"""
	Wird am Ende der Schicht/Nacht vom GameManager aufgerufen.
	Pflanzen in den Beeten wachsen um 1 Tag.
	Gibt Meldungen (Logs) zurück, z.B. wenn etwas ausgewachsen ist.
	"""
	var logs : Array[String] = []
	for i in range(GameManager.garden_plots.size()):
		var plot = GameManager.garden_plots[i]
		if plot["seed"] != "":
			plot["days_growing"] += 1
			var req_days = SEED_GROWTH_TIMES.get(plot["seed"], 1)
			if plot["days_growing"] == req_days:
				logs.append("Beet %d: %s ist nun erntebereit!" % [i + 1, _get_seed_name(plot["seed"])])
	return logs


func get_plot_state(index: int) -> Dictionary:
	if index < 0 or index >= GameManager.garden_plots.size():
		return {}
	return GameManager.garden_plots[index]


func plant_seed(index: int, seed_id: String) -> bool:
	if index < 0 or index >= GameManager.garden_plots.size(): return false
	
	var plot = GameManager.garden_plots[index]
	if plot["seed"] != "":
		return false # Slot schon belegt
		
	# Prüfen, ob wir den Seed im Inventar haben
	var inv_index = GameManager.global_inventory.find(seed_id)
	if inv_index != -1:
		GameManager.global_inventory.remove_at(inv_index)
		plot["seed"] = seed_id
		plot["days_growing"] = 0
		print("[Farming] %s in Beet %d gepflanzt." % [seed_id, index])
		return true
	
	return false # Kein Seed da


func can_harvest(index: int) -> bool:
	if index < 0 or index >= GameManager.garden_plots.size(): return false
	var plot = GameManager.garden_plots[index]
	var seed_id = plot["seed"]
	if seed_id == "": return false
	
	var req_days = SEED_GROWTH_TIMES.get(seed_id, 1)
	return plot["days_growing"] >= req_days


func harvest(index: int) -> bool:
	if not can_harvest(index): return false
	var plot = GameManager.garden_plots[index]
	var harvest_item = SEED_TO_HARVEST.get(plot["seed"], "nothing")
	
	GameManager.global_inventory.append(harvest_item)
	print("[Farming] Beet %d geerntet: %s" % [index, harvest_item])
	
	# Slot resetten
	plot["seed"] = ""
	plot["days_growing"] = 0
	return true


func _get_seed_name(seed_id: String) -> String:
	match seed_id:
		"mint_seed": return "Minze"
		_: return "Unbekannte Pflanze"
