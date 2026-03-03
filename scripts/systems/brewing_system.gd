extends Node

# brewing_system.gd
# Manages the production of drinks in the basement.

signal brewing_started(slot_id, recipe_id, time_left)
signal brewing_finished(slot_id, item_id)
signal brewing_updated(slot_id, time_left)

var active_brews = {} # slot_id -> { "recipe_id": String, "time_left": float, "reward": String }

func _process(delta: float) -> void:
	var finished_slots = []
	for slot_id in active_brews.keys():
		active_brews[slot_id].time_left -= delta
		emit_signal("brewing_updated", slot_id, active_brews[slot_id].time_left)
		
		if active_brews[slot_id].time_left <= 0:
			finished_slots.append(slot_id)
			
	for slot_id in finished_slots:
		_finish_brewing(slot_id)

func start_brewing(slot_id: String, recipe_id: String) -> bool:
	if active_brews.has(slot_id):
		return false # Slot busy
		
	var recipes = _load_recipes()
	if not recipes.has(recipe_id):
		return false
		
	var recipe = recipes[recipe_id]
	
	# Check ingredients (Assuming InventorySystem exists)
	# In a real scenario, we'd consume them here.
	
	active_brews[slot_id] = {
		"recipe_id": recipe_id,
		"time_left": recipe.get("brewing_time", 30.0),
		"reward": recipe.get("reward_item", "nothing")
	}
	
	emit_signal("brewing_started", slot_id, recipe_id, active_brews[slot_id].time_left)
	print("[BrewingSystem] Starte Brauvorgang Slot %s: %s" % [slot_id, recipe_id])
	return true

func _finish_brewing(slot_id: String) -> void:
	var brew = active_brews[slot_id]
	var reward = brew.reward
	
	# Automatisch nach oben schicken via Dumbwaiter
	if "Dumbwaiter" in get_node("/root"):
		get_node("/root/Dumbwaiter").queue_transport(reward, 0)
	
	print("[BrewingSystem] Brauvorgang beendet! %s in den Aufzug gelegt." % reward)
	
	emit_signal("brewing_finished", slot_id, reward)
	active_brews.erase(slot_id)

func _load_recipes() -> Dictionary:
	var path = "res://data/items/recipes_brewing.json"
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())
	return json.get("recipes", {})
