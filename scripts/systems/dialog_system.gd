extends Node

## Lädt und verarbeitet Dialogdaten aus JSON.
## Kommuniziert mit DialogUI über Signale.

signal dialog_started
signal dialog_ended
signal node_changed(speaker: String, text: String, choices: Array)
signal flag_set(flag_name: String, value: bool)

var _data     : Dictionary = {}  # gesamte Dialog-Daten
var _nodes    : Dictionary = {}  # nodes-Dictionary aus JSON
var _current  : String     = ""  # aktuelle Node-ID
var _guest    : Node       = null
var _extra    : Dictionary = {}

func start(dialog_path: String, guest: Node, extra_context: Dictionary = {}) -> void:
	"""Lädt eine Dialog-JSON und startet den Dialog."""
	_guest = guest
	_extra = extra_context
	var full_path := "res://data/dialogs/%s.json" % dialog_path
	var file := FileAccess.open(full_path, FileAccess.READ)
	if not file:
		push_error("[Dialog] Datei nicht gefunden: %s" % full_path)
		return

	var json     := JSON.new()
	var err      := json.parse(file.get_as_text())
	file.close()

	if err != OK:
		push_error("[Dialog] JSON-Fehler in %s" % full_path)
		return

	_data   = json.data
	_nodes  = _data.get("nodes", {})
	_current = "start"
	print("[Dialog] Starte Dialog: %s" % _data.get("id", "?"))
	dialog_started.emit()
	_show_current()


func choose(index: int) -> void:
	"""Verarbeitet eine Auswahl des Spielers."""
	var node : Dictionary = _nodes.get(_current, {})
	var choices : Array   = node.get("choices", [])

	if index < 0 or index >= choices.size():
		push_warning("[Dialog] Ungültiger Choice-Index: %d" % index)
		return

	var choice : Dictionary = choices[index]

	# Flag-Effekte der aktuellen Node anwenden
	for effect in node.get("effects", []):
		flag_set.emit(effect.get("flag", ""), effect.get("value", true))
		print("[Dialog] Flag gesetzt: %s = %s" % [effect.get("flag"), effect.get("value")])

	# Aktion oder Weiterleitung
	var action : String = choice.get("action", "")
	var next   : String = choice.get("next", "")

	if action == "open_service":
		print("[Dialog] -> Service-Menü öffnen")
		dialog_ended.emit()
		if _guest:
			ServiceSystem.open(_guest)
		return
	
	if action == "start_quest":
		var q_id = choice.get("quest_id", "")
		if q_id != "":
			QuestManager.accept_quest(q_id)
		# Dialog geht meistens weiter oder endet danach

	if next == "end" or next.is_empty() or not _nodes.has(next):
		print("[Dialog] Dialog beendet.")
		dialog_ended.emit()
		return

	_current = next
	_show_current()


func _show_current() -> void:
	var node : Dictionary = _nodes.get(_current, {})
	var speaker : String  = node.get("speaker", "???")
	var text    : String  = node.get("text",    "...")
	
	# Dynamische Text-Injektion (z.B. für Zimmerwünsche)
	if _current == "start" and _extra.get("wants_room", false):
		text += "\n\n(Übrigens: Ich brauche heute Nacht ein Zimmer. Habt ihr noch was frei?)"
		
	var raw_choices: Array = node.get("choices", [])
	
	# Choices filtern basierend auf required_flags
	var choices : Array = []
	for c in raw_choices:
		if _check_conditions(c):
			choices.append(c)
			
	print("[Dialog] %s: %s" % [speaker, text])
	node_changed.emit(speaker, text, choices)


func _check_conditions(choice: Dictionary) -> bool:
	# 1. Flag-Check
	if choice.has("required_flags"):
		var reqs = choice.get("required_flags", [])
		for flag in reqs:
			if not ScoreSystem._flags_set.get(flag, false):
				return false # Ein benötigtes Flag fehlt
				
	# 2. Trust-Check
	if choice.has("required_trust") and _guest != null:
		var req_trust = choice.get("required_trust", 0)
		var guest_id = _guest.name # Der Node-Name sollte die ID sein
		if guest_id != "" and not guest_id.begins_with("guest_"):
			var current_trust = 0
			if GameManager.npc_memory.has(guest_id):
				current_trust = GameManager.npc_memory[guest_id].get("trust", 0)
				
			if current_trust < req_trust:
				return false # Trust zu niedrig
				
	return true
