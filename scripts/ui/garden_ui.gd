extends CanvasLayer

var slots : Array[Button] = []
var lbl_inventory : Label

func _ready():
	_build_ui()
	hide()

func _build_ui():
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin = MarginContainer.new()
	for side in ["margin_top","margin_bottom","margin_left","margin_right"]:
		margin.add_theme_constant_override(side, 40)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "═══ DER GARTEN ═══"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	var desc = Label.new()
	desc.text = "Hier kannst du Samen anpflanzen. Sie wachsen über Nacht."
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	lbl_inventory = Label.new()
	lbl_inventory.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_inventory.modulate = Color(0.8, 0.8, 1.0)
	vbox.add_child(lbl_inventory)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	for i in range(3):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(150, 150)
		btn.pressed.connect(_on_slot_clicked.bind(i))
		hbox.add_child(btn)
		slots.append(btn)

	var btn_back = Button.new()
	btn_back.text = "Zurück ins Haus"
	btn_back.custom_minimum_size = Vector2(200, 40)
	btn_back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_back.pressed.connect(close)
	vbox.add_child(btn_back)


func open():
	show()
	_update_ui()
	
func close():
	hide()
	var shop = get_node_or_null("/root/TavernPrototype/MetaShopUI")
	if shop: shop.open()


func _update_ui():
	# Update Inventar Anzeige für Samen
	var seed_count = 0
	for item in GameManager.global_inventory:
		if item == "mint_seed": seed_count += 1
	lbl_inventory.text = "Saatgut im Inventar: %dx Minz-Samen" % seed_count

	for i in range(3):
		var state = FarmingSystem.get_plot_state(i)
		var btn = slots[i]
		
		if state.is_empty() or state["seed"] == "":
			btn.text = "Beet %d\n[ Leer ]\n\n(Klicken zum Pflanzen)"
			btn.modulate = Color(0.5, 0.3, 0.2) # Braun (Erde)
		else:
			if FarmingSystem.can_harvest(i):
				btn.text = "Beet %d\n[ FERTIG! ]\n\n(Klicken zum Ernten)"
				btn.modulate = Color(0.2, 1.0, 0.2) # Grün
			else:
				var days = state["days_growing"]
				btn.text = "Beet %d\n[ Wächst... ]\nTag %d" % [i+1, days]
				btn.modulate = Color(0.5, 0.8, 0.5) # Hellgrün


func _on_slot_clicked(index: int):
	var state = FarmingSystem.get_plot_state(index)
	
	if state["seed"] == "":
		# Versuche zu pflanzen
		if FarmingSystem.plant_seed(index, "mint_seed"):
			print("[Garden] Samen gepflanzt in Beet %d" % index)
		else:
			print("[Garden] Pflanzen fehlgeschlagen (Keine Samen?)")
	else:
		# Versuche zu ernten
		if FarmingSystem.harvest(index):
			print("[Garden] Geerntet von Beet %d" % index)
		else:
			print("[Garden] Noch nicht reif!")
			
	_update_ui()
