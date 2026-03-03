extends Node

# dumbwaiter.gd
# Manages the transfer of items between the Kitchen and the Basement.

signal item_arrived(target_floor, item_id)
signal pickup_occurred(floor_level, item_id)

var items_at_top = [] # Items waiting in the Kitchen
var items_at_bottom = [] # Items waiting in the Basement

func queue_transport(item_id: String, to_floor: int) -> void:
	"""
	to_floor: 0 for Kitchen, -1 for Basement
	"""
	print("[Dumbwaiter] Transportiere %s nach Ebene %d" % [item_id, to_floor])
	
	# Simulate transport time (optional, for now instant)
	if to_floor == 0:
		items_at_top.append(item_id)
	else:
		items_at_bottom.append(item_id)
		
	emit_signal("item_arrived", to_floor, item_id)

func has_items(floor_level: int) -> bool:
	if floor_level == 0:
		return items_at_top.size() > 0
	return items_at_bottom.size() > 0

func pickup_item(floor_level: int) -> String:
	var item = ""
	if floor_level == 0 and items_at_top.size() > 0:
		item = items_at_top.pop_front()
	elif floor_level == -1 and items_at_bottom.size() > 0:
		item = items_at_bottom.pop_front()
		
	if item != "":
		emit_signal("pickup_occurred", floor_level, item)
		print("[Dumbwaiter] Item abgeholt auf Ebene %d: %s" % [floor_level, item])
		
	return item
