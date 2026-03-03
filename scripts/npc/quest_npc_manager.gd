extends Node3D

## QuestNPCManager
## Verwaltet das Spawnen von wichtigen Story-NPCs an festen Positionen in der Welt.

@export var guest_scene : PackedScene = preload("res://scenes/npc/Guest.tscn")

func _ready() -> void:
	# Wir warten kurz, damit GameManager & QuestManager initialisiert sind
	call_deferred("_check_quest_spawns")

func _check_quest_spawns() -> void:
	# Beispiel: Beatrice's Quest prüfen
	# Wir schauen in die Quests, ob Beatrice erscheinen soll.
	# HINWEIS: In einem echten System würde man hier durch eine Liste von Quest-NPCs loopen.
	
	_spawn_beatrice_if_needed()

func _spawn_beatrice_if_needed() -> void:
	# ID "beatrice_01" oder ähnlich aus quests.json prüfen
	# Für diesen Prototyp prüfen wir einfach, ob die Quest "beatrice_request" aktiv ist.
	# Da der QuestManager noch simpel ist, simulieren wir die Logik:
	
	var quest_active = false
	if GameManager.night_index >= 1: # Beatrice kommt ab Nacht 1
		quest_active = true
	
	if quest_active:
		var marker = get_parent().get_node_or_null("NavigationRegion3D/QuestNPCs/QuestNPC_Beatrice")
		if marker and marker.is_inside_tree():
			print("[QuestNPCManager] Spawne Beatrice am Marker.")
			var beatrice = guest_scene.instantiate()
			# Wir fügen sie zuerst dem Baum hinzu, damit sie eine Position annehmen kann
			get_parent().add_child(beatrice)
			beatrice.global_position = marker.global_position
			
			# Daten für Beatrice laden
			var data = _load_guest_data("beatrice")
			if not data.is_empty():
				beatrice.setup(data)

func _load_guest_data(guest_id: String) -> Dictionary:
	var path = "res://data/guests/guests.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			if json.data.has(guest_id):
				return json.data[guest_id]
	return {}
