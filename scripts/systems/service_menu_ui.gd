extends CanvasLayer

## Service-Menü: zeigt verfügbare Items als Buttons an.
## Wird von ServiceSystem.open() aufgerufen.

@onready var panel      : PanelContainer = $Panel
@onready var items_box  : VBoxContainer  = $Panel/VBox/Items
@onready var wanted_lbl : Label          = $Panel/VBox/Wanted
@onready var trust_lbl  : Label          = $Panel/VBox/TrustLbl


func _ready() -> void:
	panel.visible = false
	ServiceSystem.service_completed.connect(_on_service_completed)


func show_menu(items: Array, wanted: String) -> void:
	panel.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)  # Maus freigeben für UI-Klicks
	wanted_lbl.text = "Gast möchte: %s" % wanted

	# ── Trust / Beziehungs-Feedback ──────────────────────────────
	var g_name = "Unbekannt"
	if ServiceSystem._current_guest != null:
		var n = ServiceSystem._current_guest.get("display_name")
		g_name = n if n != null else "Unbekannt"
		
	if g_name.begins_with("guest_") or g_name == "Unbekannt":
		trust_lbl.text = "" # Generischer Gast
	else:
		var mem = GameManager.npc_memory.get(g_name, {})
		var t = mem.get("trust", 0)
		var v = mem.get("visits", 0)
		
		var t_cat = "Neutral"
		var t_col = Color.WHITE
		if t > 30: 
			t_cat = "Stammgast (Sehr vertraut)"
			t_col = Color(0.2, 0.9, 0.3)
		elif t > 10: 
			t_cat = "Vertraut"
			t_col = Color(0.5, 0.9, 0.3)
		elif t < -10: 
			t_cat = "Misstrauisch"
			t_col = Color(0.9, 0.4, 0.2)
		elif t <= -30: 
			t_cat = "Feindselig"
			t_col = Color(0.9, 0.1, 0.1)
			
		trust_lbl.text = "Beziehung: %s (%d) | Besuche: %d" % [t_cat, t, v]
		trust_lbl.add_theme_color_override("font_color", t_col)

	for child in items_box.get_children():
		child.queue_free()

	var first_btn : Button = null
	for item in items:
		var btn := Button.new()
		btn.text = item
		btn.pressed.connect(_on_item_pressed.bind(item))
		items_box.add_child(btn)
		if first_btn == null:
			first_btn = btn

	# Ersten Button fokussieren (Tastaturnavigation)
	if first_btn:
		await get_tree().process_frame
		first_btn.grab_focus()


func _on_item_pressed(item: String) -> void:
	# Buttons entsperrt lassen, da das UI ohnehin gleich "simuliert" geschlossen wird
	ServiceSystem.serve(item)
	
	# Neues Verhalten: Menü nach Zubereitung sofort schließen, 
	# da der Drink auf dem Tresen landet, nicht beim Gast.
	_on_service_completed({})


func _on_service_completed(_result: Dictionary) -> void:
	if GameManager.is_focused():
		# Fokus-Modus: Nur die Item-Buttons ausräumen, wanted_lbl bleibt sichtbar
		for child in items_box.get_children():
			child.queue_free()
		# Panel sichtbar lassen als Hinweisleiste
		wanted_lbl.modulate = Color(0.7, 0.9, 1.0)
	else:
		panel.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
