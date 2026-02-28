extends CanvasLayer

@onready var shop_panel = $Panel
@onready var btn_close = $Panel/BtnClose
@onready var item_container = $Panel/ScrollContainer/ItemContainer
@onready var lbl_gold = $Panel/LblGold

func _ready() -> void:
	btn_close.pressed.connect(_on_close)
	hide()
	
	# Initialisiere die Shop-Liste
	_build_ui()

func _process(_delta: float) -> void:
	if visible:
		if GameManager.has_method("get_gold"):
			lbl_gold.text = "Geld: " + str(GameManager.get_gold()) + " G"

func open_build_menu() -> void:
	show()

func _on_close() -> void:
	hide()
	BuildManager.toggle_build_mode(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		if visible:
			_on_close()
		else:
			open_build_menu()

func _build_ui() -> void:
	for c in item_container.get_children():
		c.queue_free()
		
	# Warte kurz, falls der Autoload noch lädt
	await get_tree().process_frame
	
	for item_data in BuildManager.furniture_data:
		var btn = Button.new()
		btn.text = "%s (%d G)" % [item_data["name"], int(item_data["price"])]
		btn.add_theme_font_size_override("font_size", 20)
		btn.custom_minimum_size = Vector2(250, 40)
		btn.pressed.connect(_on_item_pressed.bind(item_data["id"]))
		item_container.add_child(btn)

func _on_item_pressed(item_id: String) -> void:
	# Verstecke das Menü erstmal nicht, damit der Spieler mehrere bauen kann,
	# oder verstecke es für bessere Übersicht. Hier verstecken wirs für Übersicht.
	hide()
	print("[BuildMenu] Gewählt: ", item_id)
	BuildManager.start_building(item_id)
