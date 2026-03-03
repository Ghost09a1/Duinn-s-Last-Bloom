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

func trigger_random_event() -> void:
	if not is_active: return
	
	var events = ["magical_visitor", "mana_surge", "void_whisper"]
	var selected = events.pick_random()
	emit_signal("portal_event_triggered", selected)
	print("[PortalManager] Portal Event: %s" % selected)

func get_portal_status() -> String:
	return "Active" if is_active else "Dormant (Reputation %d/%d)" % [GameManager.reputation, reputation_threshold]
