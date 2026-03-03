extends Node
class_name InnTierManager

## InnTierManager (Phase E)
## Schaltet Bereiche der Taverne frei, basierend auf GameManager.inn_tier.

@export var tier_1_nodes: Node3D
@export var tier_2_nodes: Node3D
@export var tier_3_nodes: Node3D

func _ready() -> void:
	# Initiales Update
	update_tier_visibility()
	
	# Optional: Auf Tier-Upgrades hören (falls GameManager ein Signal hätte, 
	# sonst prüfen wir es einfach in jeder Nacht beim restart).
	# Für diesen Prototyp prüfen wir es bei jedem Szenen-Start in _ready.

func update_tier_visibility() -> void:
	var current_tier = GameManager.inn_tier
	print("[InnTierManager] Aktualisiere Sichtbarkeit für Tier: ", current_tier)
	
	if tier_1_nodes:
		tier_1_nodes.visible = current_tier >= 1
	
	if tier_2_nodes:
		tier_2_nodes.visible = current_tier >= 2
		_toggle_collision(tier_2_nodes, current_tier >= 2)
		
	if tier_3_nodes:
		tier_3_nodes.visible = current_tier >= 3
		_toggle_collision(tier_3_nodes, current_tier >= 3)

func _toggle_collision(parent: Node, enabled: bool) -> void:
	for child in parent.get_children():
		if child is CollisionObject3D:
			child.input_ray_pickable = enabled
			# Deaktivieren von CollisionShapes ist sauberer
			for shape in child.get_children():
				if shape is CollisionShape3D:
					shape.disabled = !enabled
		_toggle_collision(child, enabled)
