extends Node3D

@export var move_speed : float = 15.0
@export var zoom_speed : float = 2.0
@export var min_zoom : float = 5.0
@export var max_zoom : float = 30.0
@export var rotation_speed : float = 5.0

@export var fade_speed : float = 5.0
@export var min_alpha : float = 0.2

var _faded_meshes : Dictionary = {} # mesh_rid -> { "node": Node3D, "target_alpha": 1.0, "current_alpha": 1.0, "original_materials": Array }

@onready var cam : Camera3D = $Camera3D

var player : CharacterBody3D
var _target_y_rot : float = 0.0


func _ready() -> void:
	_target_y_rot = rotation.y
	if cam == null:
		push_error("[IsoCamera] Camera3D wurde nicht als Child gefunden!")
		return
	cam.current = true
	
	# Hole den Player
	player = get_node_or_null("../Player")
	if player == null:
		player = get_node_or_null("/root/TavernPrototype/Player")

func _process(delta: float) -> void:
	var move_dir = Vector3.ZERO
	# Rotation Input
	if Input.is_action_just_pressed("ui_page_down") or Input.is_physical_key_pressed(KEY_E):
		_target_y_rot -= PI / 2.0
	elif Input.is_action_just_pressed("ui_page_up") or Input.is_physical_key_pressed(KEY_Q):
		_target_y_rot += PI / 2.0
		
	# Interpolate Rotation
	rotation.y = lerp_angle(rotation.y, _target_y_rot, rotation_speed * delta)
	
	# Hole Basis für relative Bewegung
	var cam_basis = global_transform.basis
	
	# WASD Movement -> Map to Local Camera Coordinates
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("ui_up") or Input.is_physical_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_physical_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_physical_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_physical_key_pressed(KEY_D):
		input_dir.x += 1

	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		# Translatiere Input entsprechend der Kamera-Rotation (X = Right, Z = Backwards)
		# Wir wollen dass W "nach oben" (auf dem Bildschirm) geht, also in Richtung -Z lokal
		move_dir = (cam_basis.x * input_dir.x) + (cam_basis.z * input_dir.y)
		global_position += move_dir * move_speed * delta

	_update_cutaway(delta)

func _update_cutaway(delta: float) -> void:
	if player == null or cam == null: return
	
	var space_state = get_world_3d().direct_space_state
	var from = cam.global_position
	# Ray to player slightly above ground
	var to = player.global_position + Vector3(0, 1.0, 0) 
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	var exceptions = []
	var hits = []
	
	for i in range(10):
		query.exclude = exceptions
		var result = space_state.intersect_ray(query)
		if result:
			if result.collider == player:
				break
				
			if result.collider.is_in_group("cutaway_wall"):
				hits.append(result.collider)
				
			exceptions.append(result.rid)
		else:
			break
			
	# Update target alphas
	for mesh_rid in _faded_meshes.keys():
		_faded_meshes[mesh_rid]["target_alpha"] = 1.0 # default back to visible
		
	for collider in hits:
		var rid = collider.get_instance_id()
		if not _faded_meshes.has(rid):
			_setup_mesh_for_fading(collider, rid)
		_faded_meshes[rid]["target_alpha"] = min_alpha
		
	# Process fading
	var to_erase = []
	for rid in _faded_meshes.keys():
		var data = _faded_meshes[rid]
		if not is_instance_valid(data["node"]):
			to_erase.append(rid)
			continue
			
		data["current_alpha"] = move_toward(data["current_alpha"], data["target_alpha"], fade_speed * delta)
		
		# Apply alpha to all materials
		_apply_alpha_to_mesh(data["node"], data["current_alpha"], data["secondary_mats"])
		
		if data["current_alpha"] >= 0.99 and data["target_alpha"] >= 0.99:
			_restore_mesh_materials(data["node"], data["original_mats"])
			to_erase.append(rid)
			
	for rid in to_erase:
		_faded_meshes.erase(rid)

func _setup_mesh_for_fading(collider: Node3D, rid: int) -> void:
	var meshes = _get_all_meshes(collider)
	var originals = []
	var secondary = []
	
	for mesh_inst in meshes:
		for i in range(mesh_inst.get_surface_override_material_count()):
			var orig = mesh_inst.get_surface_override_material(i)
			originals.append({"mesh": mesh_inst, "index": i, "mat": orig})
			
			if orig == null and mesh_inst.mesh != null:
				orig = mesh_inst.mesh.surface_get_material(i)
				
			var fade_mat = null
			if orig is StandardMaterial3D:
				fade_mat = orig.duplicate()
				fade_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			
			secondary.append({"mesh": mesh_inst, "index": i, "mat": fade_mat})
			
			if fade_mat != null:
				mesh_inst.set_surface_override_material(i, fade_mat)
				
	_faded_meshes[rid] = {
		"node": collider,
		"target_alpha": 1.0,
		"current_alpha": 1.0,
		"original_mats": originals,
		"secondary_mats": secondary
	}

func _apply_alpha_to_mesh(_node: Node3D, alpha: float, secondary_mats: Array) -> void:
	for slot in secondary_mats:
		if slot["mat"] != null and is_instance_valid(slot["mesh"]):
			slot["mat"].albedo_color.a = alpha

func _restore_mesh_materials(_node: Node3D, original_mats: Array) -> void:
	for slot in original_mats:
		if is_instance_valid(slot["mesh"]):
			slot["mesh"].set_surface_override_material(slot["index"], slot["mat"])

func _get_all_meshes(node: Node) -> Array[MeshInstance3D]:
	var result : Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_get_all_meshes(child))
	return result

func _unhandled_input(event: InputEvent) -> void:
	if cam == null: return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
				cam.size = clamp(cam.size - zoom_speed, min_zoom, max_zoom)
			else:
				cam.fov = clamp(cam.fov - zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if cam.projection == Camera3D.PROJECTION_ORTHOGONAL:
				cam.size = clamp(cam.size + zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_click(event.position)

func _handle_click(mouse_pos: Vector2) -> void:
	if player == null or player._locked: return
	
	var from = cam.project_ray_origin(mouse_pos)
	var to = from + cam.project_ray_normal(mouse_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1 # Nur Layer 1 abfragen (Wände auf Layer 2 werden ignoriert)
	
	var exceptions = []
	var move_target_found = false
	
	for i in range(10): # Raycast durch max 10 Wände/Decken etc. iterativ ignorieren
		query.exclude = exceptions
		var result = space_state.intersect_ray(query)
		
		if result:
			var collider = result.collider
			
			if collider.has_method("interact"):
				print("[IsoCamera] Clicked Interactable: ", collider.name)
				player.move_to(result.position, collider)
				move_target_found = true
				break
			elif collider.name.begins_with("Floor") or "Boden" in collider.name or (collider.get_parent() and collider.get_parent().name.begins_with("Floor")):
				print("[IsoCamera] Clicked Floor: ", collider.name)
				player.move_to(result.position)
				move_target_found = true
				break
			elif collider.get_parent() and "NavigationRegion" in collider.get_parent().name:
				print("[IsoCamera] Fallback: Clicked NavRegion Obj: ", collider.name)
				player.move_to(result.position)
				move_target_found = true
				break
			else:
				# Kein Floor und kein Interactable (vermutlich Wand/Dach). Ignorieren!
				exceptions.append(result.rid)
		else:
			break
			
	if not move_target_found:
		print("[IsoCamera] Click hit nothing walkable.")
