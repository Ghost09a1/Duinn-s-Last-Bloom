extends Node

# room_manager.gd
# Manages guest room occupancy and nightly income.

signal room_assigned(room_id, guest_id)
signal room_freed(room_id)

var rooms = {
	"room_1": {"occupied": false, "guest_id": "", "price": 50},
	"room_2": {"occupied": false, "guest_id": "", "price": 50},
}

func get_available_room_id() -> String:
	for id in rooms.keys():
		if not rooms[id].occupied:
			return id
	return ""

func assign_room(room_id: String, guest_id: String) -> bool:
	if not rooms.has(room_id) or rooms[room_id].occupied:
		return false
		
	rooms[room_id].occupied = true
	rooms[room_id].guest_id = guest_id
	
	emit_signal("room_assigned", room_id, guest_id)
	print("[RoomManager] Zimmer %s an %s vermietet." % [room_id, guest_id])
	return true

func collect_rent() -> int:
	var total_rent = 0
	for id in rooms.keys():
		if rooms[id].occupied:
			total_rent += rooms[id].price
			# Zimmer wieder freigeben für den nächsten Tag
			var g_id = rooms[id].guest_id
			if g_id != "" and "GameManager" in get_node("/root") and GameManager.npc_memory.has(g_id):
				GameManager.npc_memory[g_id]["last_seen_day"] = GameManager.night_index
				
			rooms[id].occupied = false
			rooms[id].guest_id = ""
			emit_signal("room_freed", id)
			
	if total_rent > 0:
		if "ScoreSystem" in GameManager:
			GameManager.ScoreSystem.add_gold(total_rent)
			print("[RoomManager] %d Gold Miete eingenommen." % total_rent)
			
	return total_rent

func is_room_available() -> bool:
	return get_available_room_id() != ""
