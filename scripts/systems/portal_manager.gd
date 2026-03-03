extends Node

# portal_manager.gd
# Handles Tier 4 Portal logic, magical guests, and inter-dimensional events.

signal portal_activated()
signal portal_event_triggered(event_type: String)

var is_active : bool = false
var reputation_threshold : int = 1000

func _ready() -> void:
	# Check periodically or on reputation change
	if "GameManager" in get_node("/root"):
		_check_activation()

func _check_activation() -> void:
	var current_rep = GameManager.reputation
	if not is_active and current_rep >= reputation_threshold:
		var has_key = GameManager.global_inventory.count("portal_key") > 0
		if has_key:
			activate_portal()

func activate_portal() -> void:
	is_active = true
	emit_signal("portal_activated")
	print("[PortalManager] Das Portal zwischen den Welten ist nun aktiv! 🌀")
	
	# Update Visuelles in der Szene falls vorhanden
	var portal_node = get_tree().root.find_child("PortalAnchor", true, false)
	if portal_node:
		var light = portal_node.find_child("PortalLight", true, false)
		if light: light.light_energy = 2.0
		
		var label = portal_node.find_child("Label3D", true, false)
		if label: label.text = "ACTIVE PORTAL"
		
	if "GameManager" in get_node("/root"):
		GameManager.log_event("Das antike Portal leuchtet nun in unheimlichem Blau.")

func trigger_random_event() -> String:
	if not is_active: return "none"
	
	var current_night = 0
	if "GameManager" in get_node("/root"): current_night = GameManager.night_index
	var rng = GameRNG.rng_for("portal_loot_%d" % current_night)
	var roll = rng.randf()
	
	if roll < 0.4: # 40% Chance for Loot
		var loots = ["void_shard", "void_essence", "portal_key"]
		var selected_loot = loots.pick_random()
		GameManager.global_inventory.append(selected_loot)
		print("[PortalManager] Random Loot received: %s" % selected_loot)
		emit_signal("portal_event_triggered", "loot_" + selected_loot)
		if "GameManager" in get_node("/root"):
			GameManager.log_event("Das Portal spuckte etwas aus: 1x %s!" % selected_loot)
		return "loot_" + selected_loot
	else:
		var events = ["magical_visitor", "mana_surge", "void_whisper"]
		var selected = events.pick_random()
		emit_signal("portal_event_triggered", selected)
		print("[PortalManager] Portal Event: %s" % selected)
		return selected

func get_portal_status() -> String:
	if is_active: return "Active"
	var current_rep = GameManager.reputation
	var has_key = GameManager.global_inventory.count("portal_key") > 0
	if current_rep < reputation_threshold:
		return "Dormant (Reputation %d/%d)" % [current_rep, reputation_threshold]
	if not has_key:
		return "Dormant (Portal Key missing)"
	return "Dormant"
