extends Node

## Globaler Spielzustand. Koordiniert die Hauptphasen.
## Als Autoload registriert (Projekteinstellungen > Autoload).

enum Phase { BOOT, IN_NIGHT, IN_DIALOG, IN_SERVICE, IN_ROOM_ASSIGNMENT, END_NIGHT }
var phase : Phase = Phase.BOOT
var night_index : int = 1

var global_money : int = 0
var global_inventory : Array[String] = []
var active_upgrades : Array[String] = []
var active_staff : Array[String] = []

var is_game_over : bool = false
var game_over_reason : String = ""

# ── Progression (Tiers) ──────────────────────────────────────
var reputation : int = 0
var inn_tier : int = 1

func add_reputation(amount: int) -> void:
	if amount == 0: return
	reputation += amount
	print("[Progression] Reputation %+d (Gesamt: %d)" % [amount, reputation])
	_check_tier_upgrade()

func _check_tier_upgrade() -> void:
	var next_tier = inn_tier + 1
	var threshold = _get_reputation_threshold(next_tier)
	
	if threshold > 0 and reputation >= threshold:
		var old_tier = inn_tier
		inn_tier = next_tier
		log_event("Das Inn hat Tier %d erreicht!" % inn_tier)
		print("+++ TIER UPGRADE: %d -> %d +++" % [old_tier, inn_tier])
		_check_tier_upgrade() # Rekursiv für Multi-Level-Ups

func _get_reputation_threshold(tier: int) -> int:
	match tier:
		2: return 100
		3: return 500
		4: return 1500
		5: return 5000
		_: return -1

# ── Seed & Events ────────────────────────────────────────────
var global_seed : int = 0
var current_event : String = "none"
var events_db : Dictionary = {}

# ── Farming State ────────────────────────────────────────────
var garden_plots : Array[Dictionary] = [
	{"seed": "", "days_growing": 0},
	{"seed": "", "days_growing": 0},
	{"seed": "", "days_growing": 0}
]

# ── Zimmer-Verwaltung ────────────────────────────────────────
var rooms : Dictionary = {
	"room_1": {"occupant_id": "", "days_remaining": 0, "days_until_next_payment": 0, "cleanliness": 100},
	"room_2": {"occupant_id": "", "days_remaining": 0, "days_until_next_payment": 0, "cleanliness": 100}
}
var room_applicants : Array[Dictionary] = []

func get_free_room_count() -> int:
	var count = 0
	for r in rooms.values():
		if r["occupant_id"] == "":
			count += 1
	return count

func assign_room(room_id: String, applicant: Dictionary) -> void:
	if rooms.has(room_id):
		rooms[room_id]["occupant_id"] = applicant["guest_id"]
		var stay_days = applicant.get("stay_duration_days", [7, 7])
		var actual_stay = randi_range(stay_days[0], stay_days[1])
		rooms[room_id]["days_remaining"] = actual_stay
		rooms[room_id]["days_until_next_payment"] = 7
		
		# Vorauszahlung (1 Woche Miete)
		var budget = applicant.get("room_budget_per_week", 0)
		global_money += budget
		print("[Rooms] Zimmer '%s' vergeben an %s (%d Tage). Vorauszahlung: %dG." % [room_id, applicant["display_name"], actual_stay, budget])
		
		# Entferne aus Bewerberliste, falls vorhanden
		var idx = room_applicants.find(applicant)
		if idx != -1:
			room_applicants.remove_at(idx)

# ── Persistentes Memory ──────────────────────────────────────
var npc_memory : Dictionary = {}  # z.B. {"beatrice_01": {"met": true, "last_outcome": "perfect"}}

# ── Upgrade-Effekte ──────────────────────────────────────────
## Trinkgeld-Multiplikator aus aktiven Upgrades
func get_tip_multiplier() -> float:
	# Schulden-Malus überschreibt alles – spürbare Konsequenz!
	if "debt_malus" in active_upgrades:
		return 0.5
	var m := 1.0
	if "comfy_chairs" in active_upgrades: m += 0.25
	if "fancy_bar"    in active_upgrades: m += 0.5
	return m

## Zusätzliche Geduld (Sekunden) aus Upgrades & Personal
func get_patience_bonus() -> float:
	var b := 0.0
	if "comfy_chairs" in active_upgrades: b += 30.0
	if "bouncer" in active_staff: b += 20.0
	return b

## Ob Fokus-Modus aktiv ist (Bestellung immer im HUD)
func is_focused() -> bool:
	return "notice_board" in active_upgrades

## Ob extra Gäste pro Nacht gespawnt werden
func get_extra_guests() -> int:
	var e := 0
	if "new_sign" in active_upgrades: e += 1
	return e

var _events : Array[String] = []
const MAX_EVENTS = 10


func _ready() -> void:
	if global_seed == 0:
		randomize()
		global_seed = randi()
		
	# Flags vom DialogSystem direkt ans ScoreSystem weiterleiten
	DialogSystem.flag_set.connect(ScoreSystem.record_flag)
	_run_boot_validator()
	load_game()

# ── Save / Load System ───────────────────────────────────────
const SAVE_PATH = "user://savegame.json"

func save_game() -> void:
	var data := {
		"global_seed": global_seed,
		"night_index": night_index,
		"current_event": current_event,
		"global_money": global_money,
		"global_inventory": global_inventory,
		"active_upgrades": active_upgrades,
		"active_staff": active_staff,
		"garden_plots": garden_plots,
		"rooms": rooms,
		"flags_set": ScoreSystem._flags_set,
		"npc_memory": npc_memory,
		"reputation": reputation,
		"inn_tier": inn_tier
	}
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()
		print("[Save] Spielstand gespeichert.")
	else:
		push_error("[Save] Fehler beim Speichern!")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[Save] Kein Savegame gefunden. Neues Spiel.")
		return
		
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f:
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			var data: Dictionary = json.data
			global_seed      = data.get("global_seed", global_seed)
			night_index      = data.get("night_index", 1)
			current_event    = data.get("current_event", "none")
			global_money     = data.get("global_money", 0)
			
			global_inventory.clear()
			global_inventory.assign(data.get("global_inventory", []))
			
			active_upgrades.clear()
			active_upgrades.assign(data.get("active_upgrades", []))
			
			active_staff.clear()
			active_staff.assign(data.get("active_staff", []))
			
			if data.has("garden_plots"):
				garden_plots.assign(data.get("garden_plots", []))
			
			if data.has("rooms"):
				rooms = data.get("rooms")
			
			ScoreSystem._flags_set = data.get("flags_set", {})
			npc_memory             = data.get("npc_memory", {})
			reputation             = data.get("reputation", 0)
			inn_tier               = data.get("inn_tier", 1)
			
			print("[Save] Spielstand geladen. (Tag %d, %dG)" % [night_index, global_money])
		f.close()


func _run_boot_validator() -> void:
	print("[Validator] Starte Boot-Validierung...")
	var errors := 0

	# 0. Lade Events
	var events_path = "res://data/events/events.json"
	if FileAccess.file_exists(events_path):
		var f = FileAccess.open(events_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			var data: Dictionary = json.data
			if data.has("events"):
				events_db = data.events
		else:
			push_error("[Validator] Fehler beim Laden von events.json")
			errors += 1

	# 1. Sammle alle gültigen Items
	var valid_items := {}
	
	var scan_paths = [
		"res://data/items/items.json",
		"res://data/items/recipes_drinks.json",
		"res://data/items/recipes_food.json"
	]
	
	for path in scan_paths:
		if FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.READ)
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK:
				var data: Dictionary = json.data
				if data.has("items"):
					for k in data.items.keys(): valid_items[k] = true
				if data.has("recipes"):
					for k in data.recipes.keys(): valid_items[k] = true

	# 2. Prüfe Gäste
	var guests_path = "res://data/guests/guests.json"
	if FileAccess.file_exists(guests_path):
		var f = FileAccess.open(guests_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			var guests: Dictionary = json.data
			for g_id in guests.keys():
				var g = guests[g_id]
				# Item check
				var req_item = g.get("requested_item", "")
				if req_item != "" and not valid_items.has(req_item):
					push_error("[Validator] Gast '%s' verlangt '%s', aber dieses Item/Rezept existiert nicht!" % [g_id, req_item])
					errors += 1
				
				# Dialog check
				var root_id = g.get("dialog_root_id", "")
				if root_id != "":
					var d_path = "res://data/dialogs/%s.json" % root_id
					if not FileAccess.file_exists(d_path):
						push_error("[Validator] Gast '%s' referenziert Dialog '%s', aber Datei %s fehlt!" % [g_id, root_id, d_path])
						errors += 1
	
	if errors == 0:
		print("[Validator] OK. Alle Daten referenzieren sich korrekt.")
	else:
		push_error("[Validator] FAILED mit %d Fehlern!" % errors)


func register_spawner(spawner: Node) -> void:
	"""Wird vom GuestSpawner aus _ready() aufgerufen – auch nach Szenen-Reload."""
	_spawner = spawner
	phase = Phase.IN_NIGHT
	ScoreSystem.reset()
	print("[GameManager] Nacht %d startet. (Geld: %dG)" % [night_index, global_money])
	spawner.start_night()

func apply_night_results(money: int, tips: Array) -> void:
	"""Speichert die Einnahmen der Nacht im globalen Status."""
	global_money += money
	for tip in tips:
		global_inventory.append(tip)
	print("[GameManager] Nacht-Resultate gebucht. Neues Guthaben: %dG" % global_money)


func restart_night() -> void:
	"""Startet eine neue Prototyp-Nacht (Reset + Szene neu laden)."""
	if _check_game_over():
		print("[GameManager] GAME OVER ausgelöst! Spielstand wird gelöscht.")
		_delete_save()
		_reset_all_data()
		get_tree().reload_current_scene()
		return
		
	# Farming
	var farming_logs = FarmingSystem.process_growth()
	for msg in farming_logs:
		log_event(msg)
		
	# Resets für die neue Nacht
	room_applicants.clear()
	
	night_index += 1
	log_event("Nacht %d gestartet" % night_index)
	print("[GameManager] Szene neu laden.")
	get_tree().reload_current_scene()


func _check_game_over() -> bool:
	if night_index >= 10 and not ("debt_payoff" in active_upgrades):
		is_game_over = true
		game_over_reason = "Die Gnadenfrist ist abgelaufen. Du konntest deine Schulden nicht rechtzeitig begleichen. Das Inn wurde gepfändet."
		return true
	return false

func _delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var dir = DirAccess.open("user://")
		if dir:
			dir.remove("savegame.json")

func _reset_all_data() -> void:
	# Generiere neuen Seed für neues Spiel
	randomize()
	global_seed = randi()
	current_event = "none"
	
	night_index = 1
	global_money = 0
	reputation = 0
	inn_tier = 1
	global_inventory.clear()
	active_upgrades.clear()
	active_staff.clear()
	garden_plots = [
		{"seed": "", "days_growing": 0},
		{"seed": "", "days_growing": 0},
		{"seed": "", "days_growing": 0}
	]
	ScoreSystem._flags_set.clear()
	npc_memory.clear()
	room_applicants.clear()
	for r in rooms.values():
		r["occupant_id"] = ""
		r["days_remaining"] = 0
		r["days_until_next_payment"] = 0
		r["cleanliness"] = 100


func log_event(text: String) -> void:
	print("[Event] %s" % text)
	_events.append(text)
	if _events.size() > MAX_EVENTS:
		_events.pop_front()


func get_event_log() -> Array[String]:
	return _events


var _spawner : Node = null

# ── Zimmer-Logik (Tageswechsel) ──────────────────────────────
func process_rooms(night_summary: Dictionary) -> void:
	"""Wird vor dem RoomAssignmentUI aufgerufen. Verarbeitet laufende Zimmer."""
	var new_income = 0
	
	for room_id in rooms.keys():
		var r = rooms[room_id]
		if r["occupant_id"] != "":
			r["days_remaining"] -= 1
			r["days_until_next_payment"] -= 1
			
			if r["days_remaining"] <= 0:
				print("[Rooms] Gast %s verlässt %s." % [r["occupant_id"], room_id])
				r["occupant_id"] = ""
				if not ("cleaner" in active_staff):
					r["cleanliness"] -= 50 # Zimmer ist sehr dreckig bei Auszug
				else:
					print("[Rooms] Cleaner staff hat das Zimmer instant gereinigt.")
			elif r["days_until_next_payment"] <= 0:
				r["days_until_next_payment"] = 7
				
				# Da wir das Budget nicht parat haben, holen wir es aus der DB
				var guest_id = r["occupant_id"]
				var b = 0
				# Quick & dirty: Lade es direkt aus der Datei oder nutze gecachten Wert
				var g_path = "res://data/guests/guests.json"
				if FileAccess.file_exists(g_path):
					var f = FileAccess.open(g_path, FileAccess.READ)
					var j = JSON.new()
					if j.parse(f.get_as_text()) == OK:
						if j.data.has(guest_id):
							b = j.data[guest_id].get("room_budget_per_week", 0)
				
				if b > 0:
					print("[Rooms] Gast %s zahlt neue Wochenmiete: %dG." % [guest_id, b])
					new_income += b
	
	if new_income > 0:
		night_summary["room_renewals"] = new_income
		global_money += new_income
