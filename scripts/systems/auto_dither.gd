extends Node

var fadeable_meshes : Array[MeshInstance3D] = []
var _target_alphas : Dictionary = {} # MeshInstance3D : float

func _ready() -> void:
	# Das Skript liegt auf TavernPrototype, also ist NavigationRegion3D ein direktes Child
	var nav = get_node_or_null("NavigationRegion3D")
	if nav:
		_setup_materials(nav)
		# ACHTUNG: Runtime-Bake entfernt wegen Godot GPU/CPU-Transfer Stalls.
		# Der User muss das NavMesh im Editor baken (PARSED_GEOMETRY_BOTH).
func _setup_materials(node: Node) -> void:
	# Ignoriere den Boden komplett für X-Ray
	if node.name.begins_with("Floor") or "Boden" in node.name:
		pass
	elif node is MeshInstance3D:
		var mesh = node.mesh
		if mesh:
			for i in range(mesh.get_surface_count()):
				var mat = node.get_surface_override_material(i)
				if mat == null:
					mat = mesh.surface_get_material(i)
					
				if mat is StandardMaterial3D:
					var new_mat = mat.duplicate() as StandardMaterial3D
					new_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
					new_mat.distance_fade_mode = BaseMaterial3D.DISTANCE_FADE_DISABLED
					node.set_surface_override_material(i, new_mat)
					if node not in fadeable_meshes:
						fadeable_meshes.append(node)
					_target_alphas[node] = 1.0
	
	for child in node.get_children():
		_setup_materials(child)

func set_target_alphas(hit_meshes: Array) -> void:
	var blocking_meshes = []
	for m in hit_meshes:
		_find_meshes_recursive(m, blocking_meshes)
		
	for m in fadeable_meshes:
		if m in blocking_meshes:
			_target_alphas[m] = 0.15 # X-Ray Alpha
		else:
			_target_alphas[m] = 1.0
			
	# Harter Cutaway für die Hauptwände, wenn sie im Vordergrund stehen!
	var cam = get_viewport().get_camera_3d()
	var nav = get_node_or_null("NavigationRegion3D")
	if cam and nav:
		var cam_pos = cam.global_position
		# Wände stehen bei +/- 6.
		# Wenn die Kamera z.B. bei Z=10 steht, ist die WallSouth (Z=6) im Vordergrund und blockiert die Ansicht des Raums.
		_check_cutaway(nav.get_node_or_null("WallNorth"), cam_pos.z < -4.0)
		_check_cutaway(nav.get_node_or_null("WallSouth"), cam_pos.z > 4.0)
		_check_cutaway(nav.get_node_or_null("WallEast"),  cam_pos.x > 4.0)
		_check_cutaway(nav.get_node_or_null("WallWest"),  cam_pos.x < -4.0)

func _check_cutaway(wall_node: Node, hide: bool) -> void:
	if wall_node == null or not hide: return
	for m in fadeable_meshes:
		if wall_node.is_ancestor_of(m) or m == wall_node:
			_target_alphas[m] = 0.15

func _find_meshes_recursive(node: Node, arr: Array) -> void:
	if node is MeshInstance3D:
		arr.append(node)
	for c in node.get_children():
		_find_meshes_recursive(c, arr)

func _process(delta: float) -> void:
	for m in fadeable_meshes:
		var target = _target_alphas.get(m, 1.0)
		for i in range(m.mesh.get_surface_count()):
			var mat = m.get_surface_override_material(i)
			if mat and mat is StandardMaterial3D:
				mat.albedo_color.a = lerp(mat.albedo_color.a, target, 8.0 * delta)
				
		# Schalte verdeckende Wände für die Godot-Raycasts unsichtbar (Layer 2)
		if target < 0.5:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			if m.get_parent() is CollisionObject3D:
				m.get_parent().set_collision_layer_value(1, false)
				m.get_parent().set_collision_layer_value(2, true)
		else:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			if m.get_parent() is CollisionObject3D:
				m.get_parent().set_collision_layer_value(1, true)
				m.get_parent().set_collision_layer_value(2, false)
