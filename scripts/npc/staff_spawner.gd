extends Node3D

@export var staff_scene: PackedScene

func _ready() -> void:
	if not staff_scene:
		push_error("[StaffSpawner] Keine staff_scene zugewiesen!")
		return
		
	# Spawne aktives Personal aus GameManager
	for staff_id in GameManager.active_staff:
		_spawn_staff(staff_id)

func _spawn_staff(staff_id: String) -> void:
	var staff_member = staff_scene.instantiate()
	add_child(staff_member)
	
	# Bestimme Rolle basierend auf ID
	var role = "cleaner" if "cleaner" in staff_id else "waiter"
	if staff_id == "bouncer": role = "bouncer"
	
	if staff_member.has_method("set"):
		staff_member.set("role", role)
		
	# Finde einen freien SpawnPoint (oder platziere sie zentral)
	staff_member.global_position = global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	
	print("[StaffSpawner] Personal '%s' (Rolle: %s) gespawnt." % [staff_id, role])
