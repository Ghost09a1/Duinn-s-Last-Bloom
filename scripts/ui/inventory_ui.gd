extends CanvasLayer

@onready var item_container: VBoxContainer = %ItemContainer
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close)

func open() -> void:
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_ui()

func close() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _refresh_ui() -> void:
	# Clear old children
	for child in item_container.get_children():
		child.queue_free()
		
	# Tally the inventory array into a dictionary: {"item_id": count}
	var tallies = {}
	for item_id in GameManager.global_inventory:
		tallies[item_id] = tallies.get(item_id, 0) + 1
		
	# Spawn Labels for each item
	if tallies.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Inventar ist leer."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color(0.6, 0.6, 0.6)
		item_container.add_child(empty_lbl)
	else:
		# Lade Item-Namen aus items.json 
		var items_db = {}
		var path = "res://data/items/items.json"
		if FileAccess.file_exists(path):
			var f = FileAccess.open(path, FileAccess.READ)
			var json = JSON.new()
			if json.parse(f.get_as_text()) == OK and json.data.has("items"):
				items_db = json.data["items"]
		
		# Erzeuge Liste
		for item_id in tallies.keys():
			var count = tallies[item_id]
			# Versuche Label aus DB zu holen, sonst nutze ID als Fallback
			var display_name = item_id
			if items_db.has(item_id):
				display_name = items_db[item_id].get("label", item_id)
			elif item_id == "mint_seed": # Hardcoded fallback, falls nicht in items.json
				display_name = "Minz-Samen"
				
			var lbl = Label.new()
			lbl.text = "%dx %s" % [count, display_name]
			lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			item_container.add_child(lbl)
