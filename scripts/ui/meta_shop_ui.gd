extends CanvasLayer

var lbl_stats : Label
var lbl_bills : Label
var lbl_warning: Label
var lbl_event_preview: Label
var _shop_btns : Dictionary = {}  # id → Button
var _staff_btns: Dictionary = {}

var base_rent = 25
var staff_db = {}

# Alle Shop-Items: id, label, kosten, effekt-beschreibung
const SHOP_ITEMS = [
	{ "id": "comfy_chairs",  "cost": 100, "label": "Bequeme Stühle",    "effect": "+25% Trinkgeld, +30s Geduld" },
	{ "id": "new_sign",      "cost": 150, "label": "Neues Schild",       "effect": "+1 Gast pro Nacht" },
	{ "id": "fancy_bar",     "cost": 300, "label": "Edler Tresen",       "effect": "+50% Trinkgeld" },
	{ "id": "notice_board",  "cost": 120, "label": "Auftragsboard",      "effect": "Aktive Bestellung immer sichtbar" },
	{ "id": "debt_payoff",   "cost": 500, "label": "Schulden abbezahlen","effect": "Entgeht dem Ruin (Game Over Condition)" },
]

func _ready():
	_load_staff_db()
	_build_ui()
	hide()

func _load_staff_db():
	var path = "res://data/staff/staff_roles.json"
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			staff_db = json.data

func _build_ui():
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin = MarginContainer.new()
	for side in ["margin_top","margin_bottom","margin_left","margin_right"]:
		margin.add_theme_constant_override(side, 50)
	panel.add_child(margin)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 60)
	margin.add_child(hbox)

	# ── Linke Seite: Stats & Rechnungen ──
	var left = VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(left)

	var lbl_left_title = Label.new()
	lbl_left_title.text = "═══ ZUHAUSE ═══"
	lbl_left_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_left_title.add_theme_font_size_override("font_size", 20)
	left.add_child(lbl_left_title)

	lbl_stats = Label.new()
	left.add_child(lbl_stats)

	lbl_bills = Label.new()
	left.add_child(lbl_bills)

	var btn_pay = Button.new()
	btn_pay.text = "Miete bezahlen"
	btn_pay.pressed.connect(_on_pay_rent)
	left.add_child(btn_pay)

	# ── Rechte Seite: Shop ──
	var right = VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(right)

	var lbl_shop = Label.new()
	lbl_shop.text = "══ META SHOP ══"
	lbl_shop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_shop.add_theme_font_size_override("font_size", 20)
	right.add_child(lbl_shop)

	for item in SHOP_ITEMS:
		var btn = Button.new()
		btn.text = "[%dG] %s – %s" % [item["cost"], item["label"], item["effect"]]
		btn.pressed.connect(_buy_upgrade.bind(item["id"], item["cost"]))
		right.add_child(btn)
		_shop_btns[item["id"]] = btn

	var sep1 = HSeparator.new()
	right.add_child(sep1)

	var lbl_staff = Label.new()
	lbl_staff.text = "══ PERSONAL MIETEN (pro Nacht) ══"
	lbl_staff.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_staff.add_theme_font_size_override("font_size", 18)
	right.add_child(lbl_staff)

	for staff_id in staff_db.keys():
		var btn = Button.new()
		var s = staff_db[staff_id]
		btn.text = "Anheuern: %s [%dG/Nacht]" % [s["name"], s["daily_wage"]]
		btn.pressed.connect(_toggle_staff.bind(staff_id))
		right.add_child(btn)
		_staff_btns[staff_id] = btn

	var sep2 = HSeparator.new()
	right.add_child(sep2)
	
	var btn_seed = Button.new()
	btn_seed.text = "[10G] Saatgut: Minze"
	btn_seed.pressed.connect(_buy_seed.bind("mint_seed", 10))
	right.add_child(btn_seed)

	var sep3 = HSeparator.new()
	right.add_child(sep3)

	var hbox_nav = HBoxContainer.new()
	right.add_child(hbox_nav)

	var btn_garden = Button.new()
	btn_garden.text = "GARTEN ÖFFNEN"
	btn_garden.pressed.connect(_on_go_to_garden)
	btn_garden.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_nav.add_child(btn_garden)
	
	lbl_event_preview = Label.new()
	lbl_event_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_event_preview.modulate = Color(0.7, 0.9, 1.0)
	right.add_child(lbl_event_preview)

	var btn_next = Button.new()
	btn_next.text = "──► NÄCHSTE SCHICHT"
	btn_next.add_theme_font_size_override("font_size", 22)
	btn_next.pressed.connect(_on_next_shift)
	btn_next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox_nav.add_child(btn_next)

	lbl_warning = Label.new()
	lbl_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_warning.add_theme_font_size_override("font_size", 14)
	lbl_warning.modulate = Color(1.0, 0.2, 0.2) # Rot
	right.add_child(lbl_warning)


func open():
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_update_ui()


func _update_ui():
	# UI öffnen bedeutet auch: Generator baut den Plan für MORGEN!
	var next_plan = DayGenerator.generate_day(GameManager.global_seed, GameManager.night_index)
	var ev_data = next_plan.get("event_data", {})
	if ev_data.has("label"):
		lbl_event_preview.text = "Morgen erwartet uns: %s\n(%s)" % [ev_data["label"], ev_data.get("description", "")]
	else:
		lbl_event_preview.text = ""

	# Stats
	var mult = GameManager.get_tip_multiplier()
	var patience_bonus = GameManager.get_patience_bonus()
	lbl_stats.modulate = Color(1.0, 0.3, 0.3) if GameManager.global_money < 0 else Color(1, 1, 1)
	
	var tier_names = {
		1: "Abandoned Inn",
		2: "Open Inn",
		3: "Staffed Inn",
		4: "Known Hub",
		5: "Magical Inn"
	}
	var t_name = tier_names.get(GameManager.inn_tier, "Inn")
	
	lbl_stats.text = (
		"★ Tier %d: %s ★\n" % [GameManager.inn_tier, t_name] +
		"Reputation: %d XP\n" % GameManager.reputation +
		"Gold: %dG\n" % GameManager.global_money +
		"Trinkgeld-Bonus: ×%.2f\n" % mult +
		"Gedulds-Bonus: +%.0fs\n" % patience_bonus +
		"Fokus-Board: %s\n" % ("✓ Aktiv" if GameManager.is_focused() else "✗") +
		"Extra Gäste: +%d\n" % GameManager.get_extra_guests()
	)
	var current_rent = base_rent + (GameManager.night_index * 5)
	var staff_cost = _get_total_staff_cost()
	var total_bills = current_rent + staff_cost
	lbl_bills.text = "\nMiete (Tag %d): %dG\nPersonal: %dG\nGesamt: %dG\n" % [
		GameManager.night_index + 1, current_rent, staff_cost, total_bills
	]

	# Shop-Buttons: gekaufte Upgrades deaktivieren
	for item in SHOP_ITEMS:
		var btn = _shop_btns.get(item["id"])
		if btn:
			if item["id"] in GameManager.active_upgrades:
				btn.text = "✓ %s (gekauft)" % item["label"]
				btn.disabled = true
			else:
				btn.text = "[%dG] %s – %s" % [item["cost"], item["label"], item["effect"]]
				btn.disabled = false

	# Personal-Buttons aktualisieren
	for staff_id in staff_db.keys():
		var btn = _staff_btns.get(staff_id)
		if btn:
			var s = staff_db[staff_id]
			if staff_id in GameManager.active_staff:
				btn.text = "✖ Feuern: %s (Aktiv)" % s["name"]
				btn.modulate = Color(0.8, 1.0, 0.8)
			else:
				btn.text = "Anheuern: %s [%dG/Nacht]" % [s["name"], s["daily_wage"]]
				btn.modulate = Color(1, 1, 1)

	# Warnung vor Game Over (Schulden nach 10 Tagen)
	if "debt_payoff" in GameManager.active_upgrades:
		lbl_warning.text = "Schulden sind getilgt! Die Taverne ist sicher."
		lbl_warning.modulate = Color(0.3, 1.0, 0.3)
	else:
		var days_left = 10 - GameManager.night_index
		if days_left > 0:
			lbl_warning.text = "Achtung: In %d Tagen pfänden die Schuldeneintreiber das Haus!" % days_left
			lbl_warning.modulate = Color(1.0, 0.5, 0.2)
		else:
			lbl_warning.text = "LETZTE NACHT! Zahle heute oder verliere alles!"
			lbl_warning.modulate = Color(1.0, 0.1, 0.1)


func _get_total_staff_cost() -> int:
	var total = 0
	for s_id in GameManager.active_staff:
		if staff_db.has(s_id):
			total += int(staff_db[s_id].get("daily_wage", 0))
	return total

func _on_pay_rent():
	var current_rent = base_rent + (GameManager.night_index * 5)
	var total_bills = current_rent + _get_total_staff_cost()
	
	if GameManager.global_money >= total_bills:
		GameManager.global_money -= total_bills
		print("[Home] Miete/Personal bezahlt: -%d" % total_bills)
	else:
		print("[Home] Zu wenig Gold für Rechnungen! Malus-Flag gesetzt.")
		GameManager.active_upgrades.append("debt_malus")
	_update_ui()


func _toggle_staff(staff_id: String):
	if staff_id in GameManager.active_staff:
		GameManager.active_staff.erase(staff_id)
		print("[Home] Personal entlassen: %s" % staff_id)
	else:
		GameManager.active_staff.append(staff_id)
		print("[Home] Personal angeheuert: %s" % staff_id)
	_update_ui()


func _buy_upgrade(id: String, cost: int):
	if id in GameManager.active_upgrades:
		return
	if GameManager.global_money >= cost:
		GameManager.global_money -= cost
		GameManager.active_upgrades.append(id)
		print("[Home] Gekauft: %s (-%dG)" % [id, cost])
		_update_ui()
	else:
		print("[Home] Nicht genug Gold!")

func _buy_seed(seed_id: String, cost: int):
	if GameManager.global_money >= cost:
		GameManager.global_money -= cost
		GameManager.global_inventory.append(seed_id)
		print("[Home] Samen gekauft: %s (-%dG)" % [seed_id, cost])
		_update_ui()
	else:
		print("[Home] Nicht genug Gold für Samen!")

func _on_go_to_garden():
	hide()
	var g = get_node_or_null("/root/TavernPrototype/GardenUI")
	if g:
		g.open()
	else:
		push_error("GardenUI nicht via /root/TavernPrototype erreichbar")


func _on_next_shift():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	GameManager.save_game()
	GameManager.restart_night()
