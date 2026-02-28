extends CanvasLayer

## Zusammenfassungs-Screen nach Ende einer Nacht.
## Zeigt Score-Daten und bietet "Nächste Nacht"-Button an.

@onready var panel        : PanelContainer = $Panel
@onready var title_lbl    : Label          = $Panel/VBox/Title
@onready var stats_lbl    : Label          = $Panel/VBox/Stats
@onready var flags_lbl    : Label          = $Panel/VBox/Flags
@onready var restart_btn  : Button         = $Panel/VBox/RestartBtn


var night_summary : Dictionary = {}
var _meta_shop : Node = null

func _ready() -> void:
	panel.visible = false
	ScoreSystem.night_complete.connect(_on_night_complete)
	restart_btn.pressed.connect(_on_continue_to_shop)


func _on_night_complete(summary: Dictionary) -> void:
	GameManager.process_rooms(summary)
	
	if not GameManager.room_applicants.is_empty() and GameManager.get_free_room_count() > 0:
		var room_ui = load("res://scenes/ui/RoomAssignmentUI.tscn").instantiate()
		get_tree().root.add_child(room_ui)
		room_ui.assignment_finished.connect(show_summary.bind(summary))
		room_ui.start()
	else:
		# Falls keine Bewerber da sind, leeren wir die Queue trotzdem (sonst stauen sie sich in der DB)
		GameManager.room_applicants.clear()
		show_summary(summary)


func show_summary(summary: Dictionary) -> void:
	panel.visible = true
	night_summary = summary
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	restart_btn.text = "Zurücklehnen (Meta Shop)"
	restart_btn.grab_focus()

	var total   : int   = summary.get("guest_count", 0)
	var correct : int   = summary.get("correct", 0)
	var wrong   : int   = summary.get("wrong", 0)
	var angry   : int   = summary.get("angry", 0)
	var points  : int   = summary.get("total_points", 0)
	var money   : int   = int(summary.get("money_earned", 0))
	var tips    : Array = summary.get("tips_collected", [])

	# Perfect + Big Drink counts aus den Einzel-Ergebnissen ermitteln
	var perfect_count : int = 0
	var big_count     : int = 0
	var perfect_bonus : int = 0
	var big_bonus_total : int = 0
	for r in summary.get("guest_results", []):
		if r.get("is_perfect", false):
			perfect_count += 1
			perfect_bonus += 3
		if r.get("is_big_drink", false) and r.get("success", false):
			big_count += 1
			big_bonus_total += r.get("big_bonus", 0)

	var mult := GameManager.get_tip_multiplier()
	var debt_active := "debt_malus" in GameManager.active_upgrades
	var room_renewals : int = int(summary.get("room_renewals", 0))

	var is_flawless : bool = (correct == total and total > 0)
	if is_flawless:
		title_lbl.text = "★ PERFEKTE NACHT! ★"
		title_lbl.modulate = Color(1.0, 0.85, 0.1)
	else:
		title_lbl.text = "— Abend beendet —"
		title_lbl.modulate = Color(1, 1, 1)

	var tips_str := "Keine"
	if tips.size() > 0:
		tips_str = ", ".join(tips)

	var debt_str := ""
	if debt_active:
		debt_str = "\n⚠️ SCHULDEN-MALUS AKTIV: Trinkgeld ×0.5!"

	var t = "Gäste: %d  |  Punkte: %d\n" % [total, points]
	t += "✓ Richtig: %d    ✗ Falsch: %d    😡 Verärgert: %d\n\n" % [correct, wrong, angry]
	t += "=== EINNAHMEN ===\n"
	t += "💰 Basisverdienst:        %dG\n" % (money - perfect_bonus - big_bonus_total - room_renewals)
	if perfect_count > 0:
		t += "★ Perfect-Bonus ×%d:    +%dG\n" % [perfect_count, perfect_bonus]
	if big_count > 0:
		t += "🍺 Big Drink ×%d:         +%dG\n" % [big_count, big_bonus_total]
	if room_renewals > 0:
		t += "🛏️ Zimmermieten:          +%dG\n" % room_renewals
	t += "Trinkgeld-Bonus:       ×%.2f\n" % mult
	t += "────────────────────────\n"
	t += "💳 GESAMT: %dG\n" % money
	t += "🎁 Trinkgelder: %s" % tips_str
	t += debt_str
	
	stats_lbl.text = t

	var all_flags : Array = []
	for key in summary.get("flags_set", {}).keys():
		all_flags.append(key)
	for result in summary.get("guest_results", []):
		for flag in result.get("flags", []):
			if flag not in all_flags:
				all_flags.append(flag)

	if all_flags.is_empty():
		flags_lbl.text = "Entscheidungen: keine"
	else:
		var lines := "Entscheidungen:\n"
		for flag in all_flags:
			lines += "  • %s\n" % flag
		flags_lbl.text = lines

	print("[EndNight] Summary angezeigt.")


func _on_continue_to_shop() -> void:
	# 1. Ergebnisse an GameManager übergeben
	var money = night_summary.get("money_earned", 0)
	var tips = night_summary.get("tips_collected", [])
	GameManager.apply_night_results(money, tips)
	
	# 2. UI verstecken
	panel.visible = false
	
	# 3. Bewerber & Zimmer prüfen
	if not GameManager.room_applicants.is_empty() and GameManager.get_free_room_count() > 0:
		var room_ui = load("res://scenes/ui/AssignRoomUI.tscn").instantiate()
		get_tree().root.add_child(room_ui)
		room_ui.open()
		return
		
	# 4. Shop laden und anzeigen
	if not _meta_shop:
		var shop_script = load("res://scripts/ui/meta_shop_ui.gd")
		if shop_script:
			_meta_shop = shop_script.new()
			get_tree().root.add_child(_meta_shop)
	
	if _meta_shop:
		_meta_shop.open()
	else:
		push_warning("[EndNightUI] Konnte Meta Shop nicht laden! Notfall-Restart.")
		GameManager.restart_night()
