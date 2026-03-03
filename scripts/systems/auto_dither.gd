extends Node3D

## AutoDither system.
## Detects objects between the camera and the player and makes them transparent.

@export var player_path: NodePath = "../Player"
@export var transparency_value: float = 0.3

var _player: Node3D
var _camera: Camera3D
var _last_hit: Node3D

func _ready():
	_player = get_node_or_null(player_path)
	_camera = get_viewport().get_camera_3d()
	print("[AutoDither] System active. Tracking player: ", _player != null)

func _process(_delta):
	if not _player or not _camera:
		_camera = get_viewport().get_camera_3d()
		return
		
	var space_state = get_world_3d().direct_space_state
	var origin = _camera.global_position
	var end = _player.global_position + Vector3(0, 1, 0) # Ray to player's torso
	
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collision_mask = 1 # Collide with walls (Layer 1)
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_node = result.get("collider")
		if hit_node and hit_node != _player:
			if _last_hit and _last_hit != hit_node:
				_set_node_transparency(_last_hit, 1.0)
			
			_set_node_transparency(hit_node, transparency_value)
			_last_hit = hit_node
		else:
			_clear_last_hit()
	else:
		_clear_last_hit()

func _clear_last_hit():
	if _last_hit:
		_set_node_transparency(_last_hit, 1.0)
		_last_hit = null

func _set_node_transparency(node: Node3D, alpha: float):
	# Simplified: toggle visibility for now as we don't have a dither shader yet
	# In a full implementation, we would swap materials or set a shader parameter
	if node.has_node("Mesh"):
		var mesh_instance = node.get_node("Mesh") as MeshInstance3D
		if mesh_instance:
			if alpha < 1.0:
				mesh_instance.visible = false
			else:
				mesh_instance.visible = true
