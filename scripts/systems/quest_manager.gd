extends Node

## QuestManager (Autoload)
## Verwaltet aktive Quests und prüft deren Fortschritt.

signal quest_accepted(quest_id: String)
signal quest_completed(quest_id: String)

var _all_quests : Dictionary = {}
var active_quests : Dictionary = {} # quest_id -> progress_data

func _ready() -> void:
	_load_quests()

func _load_quests() -> void:
	var path := "res://data/quests/quests.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_all_quests = json.data.get("quests", {})
	else:
		push_warning("[QuestManager] Keine quests.json gefunden!")

func accept_quest(quest_id: String) -> void:
	if not _all_quests.has(quest_id):
		push_error("[QuestManager] Quest ID '%s' nicht gefunden!" % quest_id)
		return
		
	if active_quests.has(quest_id):
		print("[QuestManager] Quest '%s' ist bereits aktiv." % quest_id)
		return
		
	if ScoreSystem._flags_set.get(_all_quests[quest_id].get("completion_flag", ""), false):
		print("[QuestManager] Quest '%s' wurde bereits erledigt." % quest_id)
		return

	active_quests[quest_id] = {"started": true}
	var label = _all_quests[quest_id].get("label", quest_id)
	print("[QuestManager] Quest angenommen: %s" % label)
	show_notification("Neue Quest: " + label, Color.CORNFLOWER_BLUE)
	
	quest_accepted.emit(quest_id)
	GameManager.log_event("Quest angenommen: %s" % quest_id)

func show_notification(text: String, color: Color = Color.WHITE) -> void:
	var qn_scene = load("res://scenes/ui/QuestNotification.tscn")
	if qn_scene:
		var inst = qn_scene.instantiate()
		get_tree().root.add_child(inst)
		inst.display(text, color)

func check_progress(type: String, payload: Dictionary) -> void:
	"""Wird von anderen Systemen (z.B. ScoreSystem) aufgerufen, um Fortschritt zu melden."""
	for quest_id in active_quests.keys():
		var quest = _all_quests[quest_id]
		if quest.get("type") != type:
			continue
			
		var match_found = false
		match type:
			"serve_item_perfect":
				if payload.get("served_item") == quest.get("target_item") and \
				   payload.get("guest_id") == quest.get("target_guest") and \
				   payload.get("is_perfect") == true:
					match_found = true
			"serve_item":
				if payload.get("served_item") == quest.get("target_item") and \
				   payload.get("guest_id") == quest.get("target_guest"):
					match_found = true
					
		if match_found:
			complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
		
	var quest = _all_quests[quest_id]
	var label = quest.get("label", quest_id)
	print("[QuestManager] Quest ERLEDIGT: %s" % label)
	show_notification("Quest erledigt: " + label, Color.GOLD)
	
	# Belohnungen
	var rep = quest.get("reward_reputation", 0)
	var money = quest.get("reward_money", 0)
	var flag = quest.get("completion_flag", "")
	
	if rep > 0: GameManager.add_reputation(rep)
	if money > 0: GameManager.global_money += money
	if flag != "": ScoreSystem.set_flag(flag, true)
	
	active_quests.erase(quest_id)
	quest_completed.emit(quest_id)
	GameManager.log_event("Quest abgeschlossen: %s" % quest_id)
