extends Node

@export var obstacle_radius: float = 0.8
var _obs: NavigationObstacle3D

func _ready() -> void:
	# Verhindere, dass doppelte Obstacles spawnen
	for c in get_children():
		if c is NavigationObstacle3D:
			return
			
	# Erstelle dynamisches Hindernis für den NavAgent
	_obs = NavigationObstacle3D.new()
	_obs.radius = obstacle_radius
	_obs.avoidance_enabled = true
	# WICHTIG: Erlaubt Agents, dieses Obstacle als statisches Polygon beim Pathfinding zu behandeln 
	# (Verhindert das Durchlaufen bei direkten Vector-Fallbacks)
	_obs.use_3d_avoidance = true 
	
	add_child.call_deferred(_obs)

func _process(_delta: float) -> void:
	if is_instance_valid(_obs):
		_obs.global_position = get_parent().global_position
