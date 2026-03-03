extends Node3D

@export var move_speed : float = 15.0
@export var zoom_speed : float = 2.0
@export var min_zoom : float = 5.0
@export var max_zoom : float = 30.0
@export var rotation_speed : float = 5.0

@export var fade_speed : float = 5.0
@export var min_alpha : float = 0.0

enum WallMode { UP, CUTAWAY, DOWN }
var current_wall_mode: WallMode = WallMode.CUTAWAY

var _target_rotation_y: float = 45.0
var _target_y_offset: float = 0.0
var _faded_meshes : Dictionary = {} # mesh_rid -> { "node": Node3D, "target_alpha": 1.0, "current_alpha": 1.0, "original_materials": Array }

@onready var cam : Camera3D = $Camera3D

var player : CharacterBody3D

# Assuming player_path and cam_path are defined elsewhere, e.g., as @export vars
@export var player_path: NodePath
@export var cam_path: NodePath


func _ready() -> void:
	# Start-Rotation setzen
	rotation_degrees.y = 45.0
	_target_rotation_y = 45.0
	
	if player_path and player == null:
		player = get_node_or_null(player_path)
		
	if player == null:
		# Fallback if NodePath fails
		player = get_node_or_null("/root/TavernPrototype/Player")
		print("[IsoCamera] Fallback player search used: ", "FOUND" if player else "NOT FOUND")
	
	if cam_path and not cam:
		cam = get_node_or_null(cam_path)
	
	if cam == null:
		push_error("[IsoCamera] Camera3D wurde nicht als Child gefunden!")
		return
	cam.current = true
	
	if player:
		global_position = player.global_position
	else:
		push_error("[IsoCamera] Player-Node wurde NICHT gefunden!")


func _process(delta: float) -> void:
	if not player: return
	
	# Rotation glätten
	rotation_degrees.y = rad_to_deg(lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(_target_rotation_y), rotation_speed * delta))
	
	# Player folgen (nur X/Z für harten Iso-Look, oder vollflächig)
	var target_pos = player.global_position
	target_pos.y += _target_y_offset
	global_position = global_position.lerp(target_pos, 10.0 * delta)
	
	var move_dir = Vector3.ZERO
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
	_process_fading(delta)

func _update_cutaway(_delta: float) -> void:
	if player == null or cam == null: return
	
	var hits = []
	
	if current_wall_mode == WallMode.UP:
		# Nichts ausblenden
		pass
		
	elif current_wall_mode == WallMode.DOWN:
		# Alles in Gruppe 'cutaway_wall' ausblenden
		hits = get_tree().get_nodes_in_group("cutaway_wall")
		
	else: # CUTAWAY (Default)
		var space_state = get_world_3d().direct_space_state
		# Start ray far outside to ensure we hit even outer walls
		var cam_forward = -cam.global_transform.basis.z.normalized()
		var from = player.global_position - cam_forward * 50.0 
		var to = player.global_position + Vector3(0, 1.5, 0)
		
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = 1
		
		var exceptions = []
		
		# 1. RAYCAST HITS
		for i in range(10):
			query.exclude = exceptions
			var result = space_state.intersect_ray(query)
			if result:
				var collider = result.collider
				if collider == player:
					break
					
				if collider.is_in_group("cutaway_wall"):
					hits.append(collider)
				
				exceptions.append(result.rid)
			else:
				break
				
		# 2. POSITION-BASED HIDING
		var walls = get_tree().get_nodes_in_group("cutaway_wall")
		var cam_to_player = (player.global_position - cam.global_position).normalized()
		var cam_dir_2d = Vector2(cam_to_player.x, cam_to_player.z).normalized()
		
		for wall in walls:
			if not wall is Node3D: continue
			if wall in hits: continue
			
			var to_wall = (wall.global_position - player.global_position)
			var to_wall_2d = Vector2(to_wall.x, to_wall.z)
			
			if to_wall_2d.dot(cam_dir_2d) < -0.1:
				hits.append(wall)

	# Update target alphas and visibility
	for mesh_rid in _faded_meshes.keys():
		_faded_meshes[mesh_rid]["target_alpha"] = 1.0
		
	for collider in hits:
		var rid = collider.get_instance_id()
		if not _faded_meshes.has(rid):
			_setup_mesh_for_fading(collider, rid)
		_faded_meshes[rid]["target_alpha"] = min_alpha
		
func _process_fading(delta: float) -> void:
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
	# Absolute cutaway: If alpha is low, we hide the meshes entirely.
	# This is a foolproof fallback for cases where transparency materials fail.
	var should_hide = (alpha < 0.9)
	for slot in secondary_mats:
		if is_instance_valid(slot["mesh"]):
			if should_hide:
				slot["mesh"].visible = false
			else:
				slot["mesh"].visible = true
				if slot["mat"] != null:
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

func set_floor_level(level: int) -> void:
	# 0 = Ground, -1 = Basement
	if level == -1:
		_target_y_offset = -4.0
	else:
		_target_y_offset = 0.0
	print("[IsoCamera] Floor Level auf %d gesetzt (Offset: %.1f)" % [level, _target_y_offset])

func _unhandled_input(event: InputEvent) -> void:
	# 90° Rotation (Q und R, da E für Interaktion reserviert ist)
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_Q:
			_target_rotation_y += 90.0
		elif event.keycode == KEY_R:
			_target_rotation_y -= 90.0
			
		# Wall Modes (1, 2, 3)
		elif event.keycode == KEY_1:
			current_wall_mode = WallMode.UP
			print("[IsoCamera] Mode: Walls Up")
		elif event.keycode == KEY_2:
			current_wall_mode = WallMode.CUTAWAY
			print("[IsoCamera] Mode: Cutaway")
		elif event.keycode == KEY_3:
			current_wall_mode = WallMode.DOWN
			print("[IsoCamera] Mode: Walls Down")
	
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
