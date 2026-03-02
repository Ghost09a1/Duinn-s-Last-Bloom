extends CanvasLayer

@onready var points_label = $Panel/PointsLabel
@onready var grid = $Panel/VBoxContainer/GridContainer
@onready var btn_close = $Panel/BtnClose

var _talent_data : Dictionary = {}

func _ready():
	btn_close.pressed.connect(close)
	_load_talent_data()
	hide()

func _load_talent_data():
	var path = "res://data/talents/talents.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			_talent_data = json.data.get("talents", {})

func open():
	show()
	_refresh_ui()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close():
	hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _refresh_ui():
	points_label.text = "Talentpunkte: %d" % GameManager.talent_points
	
	# Clear grid
	for c in grid.get_children():
		c.queue_free()
		
	for t_id in _talent_data.keys():
		var t = _talent_data[t_id]
		var btn = Button.new()
		btn.text = "%s (%d Pkt)" % [t.label, t.cost]
		btn.tooltip_text = t.description
		
		if GameManager.has_talent(t_id):
			btn.disabled = true
			btn.text = "[Aktiv] " + t.label
		elif GameManager.talent_points < t.cost:
			btn.disabled = true
		
		btn.pressed.connect(func(): _buy_talent(t_id, t.cost))
		grid.add_child(btn)

func _buy_talent(t_id: String, cost: int):
	if GameManager.unlock_talent(t_id, cost):
		_refresh_ui()
