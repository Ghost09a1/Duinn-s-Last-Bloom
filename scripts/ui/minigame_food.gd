extends CanvasLayer

# ── Zutaten (Tally-basiert für Food) ────────────────────────
var ingredients_added : Array[String] = []
var ingredient_counts : Dictionary = {
	"meat": 0, "veg": 0, "water": 0, "dough": 0, "herbs": 0
}

var labels  : Dictionary = {}
var _current_method : String = "boil" # boil, fry, bake
var _btn_boil : Button
var _btn_fry : Button
var _btn_bake : Button

# ── UI-Aufbau ────────────────────────────────────────────────
func _ready():
	_build_ui()
	hide()

func _build_ui():
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 420)
	add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "─── KÜCHEN-STATION ───"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 4
	vbox.add_child(grid)

	for ing in ingredient_counts.keys():
		var lbl_name = Label.new()
		lbl_name.text = ing.capitalize()
		grid.add_child(lbl_name)

		var btn_sub = Button.new()
		btn_sub.text = "-"
		btn_sub.pressed.connect(func(): add_ingredient(ing, -1))
		grid.add_child(btn_sub)

		var lbl_val = Label.new()
		lbl_val.text = "0"
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_val.custom_minimum_size = Vector2(30, 0)
		labels[ing] = lbl_val
		grid.add_child(lbl_val)

		var btn_add = Button.new()
		btn_add.text = "+"
		btn_add.pressed.connect(func(): add_ingredient(ing, 1))
		grid.add_child(btn_add)

	# Methoden-Auswahl
	var lbl_meth = Label.new()
	lbl_meth.text = "Zubereitungsmethode:"
	lbl_meth.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_meth)

	var hbox_methods = HBoxContainer.new()
	hbox_methods.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_methods)

	_btn_boil = Button.new()
	_btn_boil.text = "KOCHEN"
	_btn_boil.toggle_mode = true
	_btn_boil.pressed.connect(func(): select_method("boil"))
	hbox_methods.add_child(_btn_boil)

	_btn_fry = Button.new()
	_btn_fry.text = "BRATEN"
	_btn_fry.toggle_mode = true
	_btn_fry.pressed.connect(func(): select_method("fry"))
	hbox_methods.add_child(_btn_fry)

	_btn_bake = Button.new()
	_btn_bake.text = "BACKEN"
	_btn_bake.toggle_mode = true
	_btn_bake.pressed.connect(func(): select_method("bake"))
	hbox_methods.add_child(_btn_bake)
	
	select_method("boil") # Default

	# Buttons
	var hbox_actions = HBoxContainer.new()
	hbox_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_actions)

	var btn_serve = Button.new()
	btn_serve.text = "SERVIEREN"
	btn_serve.custom_minimum_size = Vector2(120, 40)
	btn_serve.pressed.connect(_on_serve_pressed)
	hbox_actions.add_child(btn_serve)

	var btn_reset = Button.new()
	btn_reset.text = "Reset"
	btn_reset.pressed.connect(_on_reset)
	hbox_actions.add_child(btn_reset)

	var btn_cancel = Button.new()
	btn_cancel.text = "Cancel"
	btn_cancel.pressed.connect(_on_cancel)
	hbox_actions.add_child(btn_cancel)


func open():
	_on_reset()
	show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func select_method(m: String):
	_current_method = m
	_btn_boil.button_pressed = (m == "boil")
	_btn_fry.button_pressed = (m == "fry")
	_btn_bake.button_pressed = (m == "bake")

func add_ingredient(ing: String, amount: int):
	ingredient_counts[ing] = clampi(ingredient_counts[ing] + amount, 0, 5)
	_update_ui()

func _update_ui():
	for ing in ingredient_counts.keys():
		labels[ing].text = str(ingredient_counts[ing])

func _on_reset():
	for k in ingredient_counts.keys():
		ingredient_counts[k] = 0
	select_method("boil")
	_update_ui()

func _on_cancel():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_serve_pressed():
	var found_food_id = "burnt_food"
	var best_match = false

	# Baue das Array der hinzugefügten Zutaten für den Vergleich
	var current_ings = []
	for ing in ingredient_counts.keys():
		for i in range(ingredient_counts[ing]):
			current_ings.append(ing)
	current_ings.sort()

	var recipes = ServiceSystem._recipes_food.get("recipes", {})
	for recipe_id in recipes:
		var recipe = recipes[recipe_id]
		var req_ings = Array(recipe.get("requires", [])).duplicate()
		req_ings.sort()
		
		var method_ok = recipe.get("method", "boil") == _current_method
		
		if current_ings == req_ings and method_ok:
			# Prüfe ob Curry freigeschaltet ist (nur wenn Event aktiv)
			if recipe_id == "curry" and GameManager.current_event != "caravan":
				continue
				
			found_food_id = recipe_id
			best_match = true
			break

	if not best_match:
		print("[MinigameFood] Ungültige Kombination -> burnt_food")
	else:
		print("[MinigameFood] Rezept gekocht: ", found_food_id)

	ServiceSystem.serve_from_minigame(found_food_id)
	_on_cancel()
