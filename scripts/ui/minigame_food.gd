extends CanvasLayer

var pot_slots : Array[String] = []
const MAX_SLOTS = 3

var lbl_slots : Label

func _ready():
	_build_ui()
	hide()

func _build_ui():
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(400, 300)
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "--- KOCHTOPF ---"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	lbl_slots = Label.new()
	lbl_slots.text = "Topf: [ Leer ]"
	lbl_slots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_slots)

	var grid = GridContainer.new()
	grid.columns = 3
	vbox.add_child(grid)

	# Zutaten-Buttons basierend auf der JSON aufbauen (verzögert, da ServiceSystem laden muss)
	call_deferred("_populate_ingredients", grid)

	var hbox_actions = HBoxContainer.new()
	hbox_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_actions)

	var btn_cook = Button.new()
	btn_cook.text = "COOK"
	btn_cook.pressed.connect(_on_cook)
	hbox_actions.add_child(btn_cook)

	var btn_reset = Button.new()
	btn_reset.text = "Reset"
	btn_reset.pressed.connect(_on_reset)
	hbox_actions.add_child(btn_reset)

	var btn_cancel = Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.pressed.connect(_on_cancel)
	hbox_actions.add_child(btn_cancel)


func _populate_ingredients(grid: GridContainer):
	var _ingredients = ServiceSystem._recipes_food.get("ingredients", {})
	# Da in unserer JSON "ingredients" auf gleicher Ebene wie "recipes" lag, haben wir in ServiceSystem nur "recipes" geladen.
	# Wir müssen _recipes_food anders laden, um ingredients zu bekommen.
	# HACK: Da ServiceSystem nur "recipes" liest, bauen wir die Buttons hartcodiert für den Prototyp
	# oder wir passen ServiceSystem an. Nehmen wir hartcodiert:
	var ing_keys = ["meat", "veg", "water", "dough", "herbs"]
	var ing_labels = ["Fleisch", "Gemüse", "Wasser", "Teig", "Kräuter"]
	
	for i in range(ing_keys.size()):
		var btn = Button.new()
		btn.text = "+ " + ing_labels[i]
		var k = ing_keys[i]
		btn.pressed.connect(func(): add_to_pot(k))
		grid.add_child(btn)


func open():
	_on_reset()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func add_to_pot(ingredient: String):
	if pot_slots.size() < MAX_SLOTS:
		pot_slots.append(ingredient)
		_update_ui()


func _update_ui():
	if pot_slots.is_empty():
		lbl_slots.text = "Topf: [ Leer ]"
	else:
		lbl_slots.text = "Topf: " + str(pot_slots)


func _on_reset():
	pot_slots.clear()
	_update_ui()


func _on_cancel():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_cook():
	var found_food_id = "sludge" # Fallback
	var best_match = false
	
	var recipes = ServiceSystem._recipes_food
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		var reqs = recipe.get("requires", [])
		
		# Prüfen ob alle requires im Topf sind (und Länge stimmt)
		if reqs.size() == pot_slots.size():
			var temp_slots = pot_slots.duplicate()
			var is_match = true
			for r in reqs:
				var idx = temp_slots.find(r)
				if idx != -1:
					temp_slots.remove_at(idx)
				else:
					is_match = false
					break
			if is_match:
				found_food_id = recipe_id
				best_match = true
				break
			
	if not best_match:
		print("[MinigameFood] Ungültige Mischung. Gebe Sludge aus.")
	else:
		print("[MinigameFood] Rezept gekocht: ", found_food_id)
		
	ServiceSystem.serve_from_minigame(found_food_id)
	_on_cancel()
