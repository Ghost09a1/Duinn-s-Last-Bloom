extends Node

## Sammelt Prototyp-Metriken pro Nacht.
## Wird von ServiceSystem und DialogSystem gefüttert.

signal night_complete(summary: Dictionary)

var _results     : Array[Dictionary] = []
var _flags_set   : Dictionary = {}   # global gesammelte Flags
var _guest_count : int = 0
var money_earned : int = 0
var tips_collected : Array[String] = []


func reset() -> void:
	_results.clear()
	_flags_set.clear()
	_guest_count = 0
	money_earned = 0
	tips_collected.clear()
	print("[Score] Reset.")


func record_service(result: Dictionary) -> void:
	"""Wird von ServiceSystem nach jedem Service aufgerufen."""
	_results.append(result)
	_guest_count += 1
	
	if result.get("success", false):
		var final_money : int = result.get("earned_money", 0)
		var base_money : int = result.get("base_price", 0)
		var mult : float = result.get("tip_mult", 1.0)
		money_earned += final_money
		if mult > 1.0:
			print("[Score] Trinkgeld-Bonus ×%.2f: %d → %d" % [mult, base_money, final_money])
		var tip = result.get("earned_tip", "")
		if tip != "":
			tips_collected.append(tip)
			
	# ── Reputation ──────────────────────────────────────────────
	if result.get("is_perfect", false):
		GameManager.add_reputation(10)
	elif result.get("success", false):
		GameManager.add_reputation(5)
		
	var msg = "Service: %s an %s (Erfolg: %s)" % [result.get("served_item", "?"), result.get("guest_id", "?"), result.get("success", false)]
	GameManager.log_event(msg)
	print("[Score] Ergebnis gespeichert: %s" % result)
	
	# Session 16: Quest-Fortschritt prüfen
	if result.get("success", false):
		QuestManager.check_progress("serve_item", result)
		if result.get("is_perfect", false):
			QuestManager.check_progress("serve_item_perfect", result)

	
	# ── Zimmer-Bewerbung ────────────────────────────────────────
	if result.get("success", false) and result.get("wants_room", false):
		var applicant = {
			"display_name": result.get("display_name", "???"),
			"guest_id": result.get("guest_id", ""),
			"room_budget_per_week": result.get("room_budget_per_week", 0),
			"stay_duration_days": result.get("stay_duration_days", [1, 2])
		}
		GameManager.room_applicants.append(applicant)
		print("[Score] Gast %s zur Zimmerbewerber-Liste hinzugefügt!" % applicant.display_name)

	# ── Memory-Update für NPCs ──────────────────────────────────
	var guest_id : String = result.get("guest_id", "")
	if guest_id != "" and not guest_id.begins_with("guest_"): # einfaches Filter für Named vs Generic (falls wir generische einbauen)
		if not GameManager.npc_memory.has(guest_id):
			GameManager.npc_memory[guest_id] = {"met": true, "trust": 0, "visits": 0}
		
		var mem = GameManager.npc_memory[guest_id]
		mem["visits"] = mem.get("visits", 0) + 1
		var current_trust = mem.get("trust", 0)
		
		var outcome = "bad"
		if result.get("is_perfect", false):
			outcome = "perfect"
			current_trust += 5
		elif result.get("success", false):
			outcome = "ok"
			current_trust += 2
		else:
			# Fail / Wrong drink
			current_trust -= 3
		
		# Extra penalty for dislike mood
		if result.get("mood_delta", 0) < 0:
			current_trust -= 2
			
		mem["last_outcome"] = outcome
		mem["last_seen_day"] = GameManager.night_index
		current_trust = clamp(current_trust, -100, 100)
		mem["trust"] = current_trust
		
		print("[Score] NPC %s -> %s (Trust neu: %d, Visits: %d)" % [guest_id, outcome, current_trust, mem["visits"]])


func record_flag(flag: String, value: bool) -> void:
	"""Wird von DialogSystem via flag_set-Signal aufgerufen."""
	_flags_set[flag] = value
	GameManager.log_event("Flag: %s=%s" % [flag, value])


func record_guest_skipped(guest_id: String) -> void:
	"""Wird aufgerufen wenn ein Gast geht ohne bedient zu werden."""
	_results.append({
		"guest_id":    guest_id,
		"served_item": "Nothing",
		"success":     false,
		"score_points": -2, # Weggehen ohne Service = dicker Minuspunkt
		"trust_delta": -1,
		"mood_delta":  -1,
		"flags":       []
	})
	_guest_count += 1
	GameManager.add_reputation(-5)
	
	if guest_id != "" and not guest_id.begins_with("guest_"):
		if not GameManager.npc_memory.has(guest_id):
			GameManager.npc_memory[guest_id] = {"met": true, "trust": 0, "visits": 0}
			
		var mem = GameManager.npc_memory[guest_id]
		mem["visits"] = mem.get("visits", 0) + 1
		mem["last_outcome"] = "walkout"
		mem["last_seen_day"] = GameManager.night_index
		
		var current_trust = mem.get("trust", 0)
		current_trust -= 10 # Heftiger Malus für langes Warten
		current_trust = clamp(current_trust, -100, 100)
		mem["trust"] = current_trust
		
		print("[Score] NPC %s -> Walkout (Trust neu: %d, Visits: %d)" % [guest_id, current_trust, mem["visits"]])

func get_summary() -> Dictionary:
	var correct := _results.filter(func(r): return r.get("success", false)).size()
	var wrong   := _results.size() - correct
	
	var angry := 0
	var total_points := 0
	for r in _results:
		if r.get("mood_delta", 0) < 0:
			angry += 1
		total_points += r.get("score_points", 0)
			
	return {
		"guest_count":    _guest_count,
		"served_count":   _results.size(),
		"correct":        correct,
		"wrong":          wrong,
		"angry":          angry,
		"total_points":   total_points,
		"money_earned":   money_earned,
		"tips_collected": tips_collected.duplicate(),
		"flags_set":      _flags_set.duplicate(),
		"guest_results":  _results.duplicate()
	}


func finish_night() -> void:
	var summary := get_summary()
	print("[Score] Nacht beendet: %s" % summary)
	night_complete.emit(summary)
