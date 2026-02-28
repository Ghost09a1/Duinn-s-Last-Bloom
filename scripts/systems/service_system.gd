extends Node

## Verarbeitet Service-Auswahl und meldet Ergebnis an Gast und Score.
## Wird vom ServiceMenu aufgerufen.

signal service_completed(result: Dictionary)

var _items : Dictionary = {}
var _recipes_drinks : Dictionary = {}
var _recipes_food : Dictionary = {}

var _current_guest : Node = null
var _prepared_items : Array[String] = [] # Zwischenspeicher für Items auf dem Tresen

var _minigame_drinks : Node = null
var _minigame_food : Node = null


func _ready() -> void:
	_load_items()
	_load_recipes()
	
	# Minigame instanziieren (Drinks)
	var mg_drinks = load("res://scripts/ui/minigame_drinks.gd")
	if mg_drinks:
		_minigame_drinks = mg_drinks.new()
		add_child(_minigame_drinks)
		
	# Minigame instanziieren (Food)
	var mg_food = load("res://scripts/ui/minigame_food.gd")
	if mg_food:
		_minigame_food = mg_food.new()
		add_child(_minigame_food)


func _load_items() -> void:
	var path := "res://data/items/items.json"
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data: Dictionary = json.data
			_items = data.get("items", {})
	else:
		push_warning("[ServiceSystem] Keine items.json gefunden!")


func _load_recipes() -> void:
	var path_drinks := "res://data/items/recipes_drinks.json"
	if FileAccess.file_exists(path_drinks):
		var file := FileAccess.open(path_drinks, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data: Dictionary = json.data
			_recipes_drinks = data.get("recipes", {})
			
	var path_food := "res://data/items/recipes_food.json"
	if FileAccess.file_exists(path_food):
		var file := FileAccess.open(path_food, FileAccess.READ)
		var json := JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_recipes_food = json.data # Hier speichern wir das volle Dictionary (inkl. "ingredients" und "recipes") anstatt nur json.data.get("recipes")


func open(guest: Node) -> void:
	"""Öffnet den Gast für Service. Interaktion geschieht nun primär über Stationen, aber Guest registriert sich hier."""
	_current_guest = guest
	print("[Service] Gast wartet auf Service: %s (möchte: %s)" % [guest.display_name, guest.requested_item])
	
	
func open_station(station_type: String) -> void:
	"""Öffnet das Auswahlmenü (später Minispiel) für die spezifische Station."""
	if not _current_guest:
		print("[Service] Niemand wartet auf Service.")
		return
		
	if station_type == "drinks" and _minigame_drinks:
		_minigame_drinks.open()
		return
		
	if station_type == "food" and _minigame_food:
		_minigame_food.open()
		return
		
	var item_labels : Array = []
	for item_id in _items:
		var tags = _items[item_id].get("tags", [])
		
		# Simples Filtern basierend auf Kategorie
		if station_type == "drinks" and "drink" in tags:
			item_labels.append(_items[item_id].get("label", item_id))
		elif station_type == "food" and "food" in tags:
			item_labels.append(_items[item_id].get("label", item_id))
			
	# Falls nicht gefiltert werden konnte, zeige alle (Fallback)
	if item_labels.is_empty():
		for item_id in _items:
			item_labels.append(_items[item_id].get("label", item_id))
			
	var requested_label = _current_guest.requested_item
	if _items.has(_current_guest.requested_item):
		requested_label = _items[_current_guest.requested_item].get("label", _current_guest.requested_item)
		
	# Zeige das Menü (vorerst das alte UI nutzen, aber nur für Zubereitung)
	ServiceMenuUI.show_menu(item_labels, "Bitte bereiten: " + requested_label)


func serve(item_label: String) -> void:
	"""Spieler hat ein Item im Menü gewählt. Legt es in den Zwischenspeicher (auf den Tresen)."""
	if not _current_guest:
		return
		
	var served_id := ""
	for i_id in _items:
		if _items[i_id].get("label", "") == item_label:
			served_id = i_id
			break
			
	if served_id == "":
		served_id = item_label.to_lower()
		
	_prepared_items.append(served_id)
	print("[Service] Zubereitet und auf Tresen gestellt: %s" % served_id)
	
	# Menü schließen
	ServiceMenuUI._on_service_completed({}) # Simuliert das Schließen des UIs
	
	
func ring_bell() -> void:
	"""Serviert alle zubereiteten Items an den wartenden Gast."""
	if not _current_guest:
		print("[Service] Klingel gedrückt, aber kein Gast wartet.")
		return
		
	if _prepared_items.is_empty():
		print("[Service] Klingel gedrückt, aber nichts zubereitet.")
		return
		
	# Für Variante 0.5: Wir nehmen einfach das erste zubereitete Item.
	# Später können wir Mehrfach-Orders abarbeiten.
	var served_id = _prepared_items[0]
	_evaluate_service(served_id)
	_prepared_items.clear()
	

func serve_from_minigame(item_id: String) -> void:
	"""Wird aus dem Drink-/Food-Minigame aufgerufen, wenn dort ein Item gemixt/gekocht wurde."""
	_prepared_items.append(item_id)
	print("[Service] Minigame zubereitet und auf Tresen gestellt: %s" % item_id)

func _evaluate_service(served_id: String) -> void:
	"""Wertet den servierten Drink aus."""

	# 1. Daten holen – direkt vom Gast-Node
	var item_data   : Dictionary = _items.get(served_id, {"tags": []})
	var served_tags : Array      = item_data.get("tags", [])
	var likes    : Array = _current_guest.likes
	var dislikes : Array = _current_guest.dislikes

	# 2a. Big Drink prüfen (Gesamt-Units > 10)
	var is_big_drink := false
	var recipe_data : Dictionary = _recipes_drinks.get(served_id, {})
	if recipe_data.has("units"):
		var total_units := 0
		for v in recipe_data["units"].values():
			total_units += int(v)
		is_big_drink = total_units > 10

	# 2b. Prefix Scoring
	var points      := 0
	var success     := false
	var earned_money := 0
	var earned_tip   := ""
	var is_perfect   := false
	var big_bonus    := 0

	var intent_matched := false
	var needed_intents : Array = _current_guest.requested_intent
	if not needed_intents.is_empty():
		intent_matched = true
		for req_tag in needed_intents:
			if req_tag not in served_tags:
				intent_matched = false
				break

	var exact_match : bool = (served_id == _current_guest.requested_item)

	if exact_match:
		points       = 3
		success      = true
		is_perfect   = true
		earned_money = _current_guest.wallet + 3   # +3G Perfect-Bonus
		if _current_guest.tip_pool.size() > 0:
			earned_tip = _current_guest.tip_pool[0]
	elif intent_matched:
		points       = 2
		success      = true
		earned_money = _current_guest.wallet
		if _current_guest.tip_pool.size() > 0:
			earned_tip = _current_guest.tip_pool[0]
	else:
		var has_dislike := false
		for d in dislikes:
			if d in served_tags:
				has_dislike = true
				break
		if has_dislike:
			points = -2
		else:
			var has_like := false
			for l in likes:
				if l in served_tags:
					has_like = true
					break
			if has_like:
				points = 1
				success = true
				earned_money = int(_current_guest.wallet / 2.0)
			else:
				points = 0

	# 2c. Big Drink Bonus (+5G, nur bei success)
	if is_big_drink and success:
		big_bonus    = 5
		earned_money += big_bonus
		print("[Service] BIG DRINK! +%dG Bonus" % big_bonus)

	# 2d. size_pref Scoring
	var size_pref : String = _current_guest.size_pref
	if size_pref == "big" and is_big_drink and success:
		points += 1  # Gast wollte groß – bekommt groß: Bonus!
		print("[Service] Size-Match: big ✓ +1 Punkt")
	elif size_pref == "small" and is_big_drink:
		points -= 1  # Gast wollte klein – bekommt zu viel: leichter Abzug
		print("[Service] Size-Mismatch: small + big drink -1 Punkt")

	var result : Dictionary = {
		"guest_id":     _current_guest.guest_id,
		"served_item":  served_id,
		"wanted_item":  _current_guest.requested_item,
		"success":      success,
		"is_perfect":   is_perfect,
		"is_big_drink": is_big_drink,
		"big_bonus":    big_bonus,
		"score_points": points,
		"trust_delta":  points,
		"mood_delta":   points,
		"earned_money": earned_money,
		"earned_tip":   earned_tip,
		"flags":        _current_guest.flags_on_success if success else _current_guest.flags_on_fail
	}

	print("[Service] %s → Wunsch: %s | Punkte: %d | Geld: %d%s%s" % [
		served_id, _current_guest.requested_item, points, int(earned_money),
		" (PERFECT!)" if is_perfect else "",
		" (BIG DRINK!)" if is_big_drink else ""
	])
	_current_guest.on_served(served_id)
	ScoreSystem.record_service(result)
	service_completed.emit(result)
	_current_guest = null
