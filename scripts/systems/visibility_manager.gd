extends Node3D

## VisibilityManager (Autoload or Scene-local)
## Replaces AutoDither with a simpler, more robust visibility toggle.

@export var player_path: NodePath = "../Player"
@export var fade_group: String = "cutaway_wall"

var _player: Node3D
var _camera: Camera3D
var _last_hits: Array[Node3D] = []

func _ready():
	_player = get_node_or_null(player_path)
	print("[VisibilityManager] Active. Tracking: ", str(_player.name) if _player else "NULL")

func _process(_delta):
	if not _player: return
	
	_camera = get_viewport().get_camera_3d()
	if not _camera: return
	
	var space_state = get_world_3d().direct_space_state
	var origin = _camera.global_position
	var target = _player.global_position + Vector3(0, 1.5, 0)
	
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.collision_mask = 1 # Layer 1 (Walls)
	
	var hits = []
	var exceptions = []
	
	# Detect all obstructions between camera and player
	for i in range(5):
		query.exclude = exceptions
		var result = space_state.intersect_ray(query)
		if result:
			var collider = result.collider
			if collider == _player: 
				break
			
			if collider.is_in_group(fade_group):
				hits.append(collider)
			
			exceptions.append(result.rid)
		else:
			break
			
	# Update visibility
	# Reset old hits that are no longer obstructive
	for old_hit in _last_hits:
		if is_instance_valid(old_hit) and not old_hit in hits:
			_set_visible(old_hit, true)
			
	# Hide new hits
	for hit in hits:
		_set_visible(hit, false)
		
	_last_hits = hits

func _set_visible(node: Node3D, is_visible: bool):
	# Apply to all MeshInstance3D children recursively
	var stack = [node]
	while stack.size() > 0:
		var current = stack.pop_back()
		if current is MeshInstance3D:
			current.visible = is_visible
		for child in current.get_children():
			stack.push_back(child)
