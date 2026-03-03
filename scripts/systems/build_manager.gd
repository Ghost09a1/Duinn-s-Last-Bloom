extends Node

signal build_mode_toggled(active: bool)
signal built_item(item_id: String)

var _is_building: bool = false
var _current_item: Dictionary = {}
var _ghost_mesh: MeshInstance3D = null
var _ghost_mat: StandardMaterial3D = null

var furniture_data: Array = []
var _furn_scenes: Dictionary = {}

@onready var _raycast_params := PhysicsRayQueryParameters3D.new()

func _ready() -> void:
	load_furniture_data()
	
	_ghost_mat = StandardMaterial3D.new()
	_ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ghost_mat.albedo_color = Color(0.2, 0.8, 0.2, 0.5)

func load_furniture_data() -> void:
	var path = "res://data/items/furniture.json"
	if not FileAccess.file_exists(path):
		printerr("[BuildManager] furniture.json nicht gefunden")
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var parser = JSON.new()
	if parser.parse(content) == OK:
		furniture_data = parser.get_data()
		for item in furniture_data:
			var scn = load(item["scene_path"])
			if scn:
				_furn_scenes[item["id"]] = scn
			else:
				printerr("[BuildManager] Konnte Szene nicht laden: ", item["scene_path"])

func toggle_build_mode(active: bool) -> void:
	_is_building = active
	build_mode_toggled.emit(_is_building)
	if not active:
		_clear_ghost()

func start_building(item_id: String) -> void:
	for dict in furniture_data:
		if dict["id"] == item_id:
			_current_item = dict
			_create_ghost()
			toggle_build_mode(true)
			return
	printerr("[BuildManager] Item nicht gefunden: ", item_id)

func _create_ghost() -> void:
	_clear_ghost()
	if not _current_item.has("scene_path"): return
	
	var scn = _furn_scenes.get(_current_item["id"])
	if scn:
		var instance = scn.instantiate()
		
		# Suche das erste MeshInstance3D in der Szene als Ghost
		var mesh_instance = null
		if instance is MeshInstance3D:
			mesh_instance = instance.duplicate()
		else:
			for c in instance.get_children():
				if c is MeshInstance3D:
					mesh_instance = c.duplicate()
					break
		
		instance.free()
		
		if mesh_instance:
			_ghost_mesh = mesh_instance
			# Materialien überschreiben
			for i in range(_ghost_mesh.get_surface_override_material_count()):
				_ghost_mesh.set_surface_override_material(i, _ghost_mat)
			
			get_tree().current_scene.add_child(_ghost_mesh)

func _clear_ghost() -> void:
	if is_instance_valid(_ghost_mesh):
		_ghost_mesh.queue_free()
	_ghost_mesh = null
	_current_item = {}

func _unhandled_input(event: InputEvent) -> void:
	if not _is_building: return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if is_instance_valid(_ghost_mesh) and not _current_item.is_empty():
				_place_item()
				# Stoppt das Bauen nach einmaligem Platzieren (oder optional weiterbauen)
				toggle_build_mode(false)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_build_mode(false)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if is_instance_valid(_ghost_mesh):
				_ghost_mesh.rotate_y(deg_to_rad(90))
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if is_instance_valid(_ghost_mesh):
				_ghost_mesh.rotate_y(deg_to_rad(-90))
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if is_instance_valid(_ghost_mesh):
			_ghost_mesh.rotate_y(deg_to_rad(90))

func _process(_delta: float) -> void:
	if not _is_building or not is_instance_valid(_ghost_mesh): return
	
	var cam = get_viewport().get_camera_3d()
	if not cam: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var from = cam.project_ray_origin(mouse_pos)
	var to = from + cam.project_ray_normal(mouse_pos) * 1000.0
	
	_raycast_params.from = from
	_raycast_params.to = to
	_raycast_params.collision_mask = 1 # Layer 1
	
	var space_state = cam.get_world_3d().direct_space_state
	var exceptions = []
	var hit_pos = Vector3.ZERO
	var found_floor = false
	
	for i in range(10):
		_raycast_params.exclude = exceptions
		var result = space_state.intersect_ray(_raycast_params)
		if result:
			var col = result.collider
			if col.name.begins_with("Floor") or "Boden" in col.name or (col.get_parent() and "NavigationRegion" in col.get_parent().name):
				hit_pos = result.position
				found_floor = true
				break
			else:
				exceptions.append(result.rid)
		else:
			break
	
	if found_floor:
		# 1x1 Meter Grid Snapping (Runden auf halbe oder volle Meter)
		var snapped_x = round(hit_pos.x)
		var snapped_z = round(hit_pos.z)
		_ghost_mesh.global_position = Vector3(snapped_x, hit_pos.y, snapped_z)

func _place_item() -> void:
	if GameManager.has_method("get_gold") and GameManager.get_gold() < _current_item["price"]:
		print("[BuildManager] Nicht genug Gold!")
		return
		
	if GameManager.has_method("add_gold"):
		GameManager.add_gold(-_current_item["price"])
	
	var scn = _furn_scenes.get(_current_item["id"])
	var new_prop = scn.instantiate()
	new_prop.global_position = _ghost_mesh.global_position
	new_prop.rotation = _ghost_mesh.rotation
	
	# Kollision generieren
	_inject_collision(new_prop, _current_item)
	
	# Hinzufügen (in der Taverne am besten in den NavigationRegion3D Node)
	var nav = get_tree().current_scene.get_node_or_null("NavigationRegion3D")
	if nav:
		var prop_root = nav.get_node_or_null("FurnRoot")
		if not prop_root: prop_root = nav
		prop_root.add_child(new_prop)
		
		# prop_root.add_child(new_prop)
		prop_root.add_child(new_prop)
		
		# WICHTIG: KEIN nav.bake_navigation_mesh() mehr hier!
		# Die CollisionShape bleibt für physische Klicks/Blockaden,
		# das NavigationObstacle3D regelt die dynamische NPC-Ausweichung.
		print("[BuildManager] Item hinzugefügt (Avoidance aktiv).")
	else:
		get_tree().current_scene.add_child(new_prop)
		
	built_item.emit(_current_item["id"])
	print("[BuildManager] Platziert: ", _current_item["name"])

func _inject_collision(node: Node3D, data: Dictionary) -> void:
	# Wenn Godot schon einen StaticBody generiert hat, ignorieren wir das
	for c in node.get_children():
		if c is StaticBody3D: return
		
	var sb = StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	
	var shape_node = CollisionShape3D.new()
	var box = BoxShape3D.new()
	
	var size_arr = data.get("collision_size", [1,1,1])
	box.size = Vector3(size_arr[0], size_arr[1], size_arr[2])
	shape_node.shape = box
	
	var offset_arr = data.get("collision_offset", [0,0.5,0])
	shape_node.position = Vector3(offset_arr[0], offset_arr[1], offset_arr[2])
	
	sb.add_child(shape_node)
	node.add_child(sb)
	
	# Zusätzlich ein NavigationObstacle3D hinzufügen, um dynamisches Pathfinding sofort abzusperren!
	var obs = NavigationObstacle3D.new()
	var radius = max(size_arr[0], size_arr[2]) * 0.55
	obs.radius = radius
	obs.avoidance_enabled = true
	obs.use_3d_avoidance = true
	obs.position = Vector3(offset_arr[0], offset_arr[1], offset_arr[2])
	node.add_child(obs)
