extends CanvasLayer

# ── Zutaten ──────────────────────────────────────────────────
var units : Dictionary = {
	"adelhyde": 0, "bronson": 0, "delta": 0,
	"flanergide": 0, "karmotrine": 0
}

var labels  : Dictionary = {}
var chk_ice  : CheckBox
var chk_aged : CheckBox

# ── Shaker / Blended ─────────────────────────────────────────
const BLEND_THRESHOLD : float = 3.0  # Sekunden → blended
var _shaker_time  : float = 0.0
var _shaking      : bool  = false
var _blended      : bool  = false
var _lbl_shaker   : Label
var _bar_shaker   : ProgressBar
var _btn_mix      : Button

# ── UI-Aufbau ────────────────────────────────────────────────
func _ready():
	_build_ui()
	hide()

func _build_ui():
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(420, 360)
	add_child(panel)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	var title = Label.new()
	title.text = "─── DRINK MIXER ───"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var grid = GridContainer.new()
	grid.columns = 4
	vbox.add_child(grid)

	for ing in units.keys():
		var lbl_name = Label.new()
		lbl_name.text = ing.capitalize()
		grid.add_child(lbl_name)

		var btn_sub = Button.new()
		btn_sub.text = "-"
		btn_sub.pressed.connect(func(): add_unit(ing, -1))
		grid.add_child(btn_sub)

		var lbl_val = Label.new()
		lbl_val.text = "0"
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_val.custom_minimum_size = Vector2(30, 0)
		labels[ing] = lbl_val
		grid.add_child(lbl_val)

		var btn_add = Button.new()
		btn_add.text = "+"
		btn_add.pressed.connect(func(): add_unit(ing, 1))
		grid.add_child(btn_add)

	# Flags
	var hbox_flags = HBoxContainer.new()
	hbox_flags.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_flags)

	chk_ice = CheckBox.new()
	chk_ice.text = "Ice"
	hbox_flags.add_child(chk_ice)

	chk_aged = CheckBox.new()
	chk_aged.text = "Aged"
	hbox_flags.add_child(chk_aged)

	# Shaker-Progress
	_bar_shaker = ProgressBar.new()
	_bar_shaker.min_value = 0.0
	_bar_shaker.max_value = BLEND_THRESHOLD
	_bar_shaker.value = 0.0
	_bar_shaker.show_percentage = false
	_bar_shaker.custom_minimum_size = Vector2(380, 18)
	vbox.add_child(_bar_shaker)

	_lbl_shaker = Label.new()
	_lbl_shaker.text = "Halte MIX gedrückt … (< %.0fs = mixed, ≥ %.0fs = blended)" % [BLEND_THRESHOLD, BLEND_THRESHOLD]
	_lbl_shaker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_shaker.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_lbl_shaker)

	# Buttons
	var hbox_actions = HBoxContainer.new()
	hbox_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox_actions)

	_btn_mix = Button.new()
	_btn_mix.text = "MIX"
	_btn_mix.button_down.connect(_on_mix_pressed)
	_btn_mix.button_up.connect(_on_mix_released)
	hbox_actions.add_child(_btn_mix)

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


# ── Shaker-Logik ─────────────────────────────────────────────
func _process(delta: float):
	if not _shaking:
		return
	_shaker_time += delta
	_bar_shaker.value = minf(_shaker_time, BLEND_THRESHOLD)

	if _shaker_time >= BLEND_THRESHOLD:
		_lbl_shaker.text = "🍹 BLENDED!"
		_lbl_shaker.modulate = Color(0.3, 0.8, 1.0)
	else:
		var pct = int(_shaker_time / BLEND_THRESHOLD * 100)
		_lbl_shaker.text = "Schütteln … %d%%" % pct
		_lbl_shaker.modulate = Color(1.0, 0.9, 0.3)

func _on_mix_pressed():
	_shaking = true
	_shaker_time = 0.0

func _on_mix_released():
	_shaking = false
	_blended = _shaker_time >= BLEND_THRESHOLD
	_bar_shaker.value = 0.0
	_lbl_shaker.modulate = Color(1, 1, 1)
	_lbl_shaker.text = "⇒ %s" % ("BLENDED" if _blended else "Mixed")
	_serve()


# ── Mix-Auswertung ───────────────────────────────────────────
func _serve():
	var ice   = chk_ice.button_pressed
	var aged  = chk_aged.button_pressed

	var found_drink_id = "sludge"
	var best_match = false

	var recipes = ServiceSystem._recipes_drinks
	for recipe_id in recipes:
		var recipe: Dictionary = recipes[recipe_id]
		var r_units = recipe.get("units", {})

		var match_units = true
		for k in units.keys():
			if r_units.get(k, 0) != units[k]:
				match_units = false
				break

		var blend_ok = recipe.get("blended", false) == _blended
		if match_units and recipe.get("ice", false) == ice and recipe.get("aged", false) == aged and blend_ok:
			found_drink_id = recipe_id
			best_match = true
			break

	if not best_match:
		print("[MinigameDrinks] Ungültige Mischung → sludge")
	else:
		print("[MinigameDrinks] Rezept gemixt: ", found_drink_id)

	ServiceSystem.serve_from_minigame(found_drink_id)
	_on_cancel()


func add_unit(ingredient: String, amount: int):
	units[ingredient] = clampi(units[ingredient] + amount, 0, 20)
	_update_ui()

func _update_ui():
	for ing in units.keys():
		labels[ing].text = str(units[ing])

func _on_reset():
	for k in units.keys():
		units[k] = 0
	chk_ice.button_pressed   = false
	chk_aged.button_pressed  = false
	_blended    = false
	_shaker_time = 0.0
	_bar_shaker.value = 0.0
	_lbl_shaker.modulate = Color(1, 1, 1)
	_lbl_shaker.text = "Halte MIX gedrückt … (< %.0fs = mixed, ≥ %.0fs = blended)" % [BLEND_THRESHOLD, BLEND_THRESHOLD]
	_update_ui()

func _on_cancel():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
