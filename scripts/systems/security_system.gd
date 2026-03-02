extends Node

## SecuritySystem (Autoload)
## Verwaltet den Status der Eingangstür und prüft, ob Gäste abgewiesen werden.

var is_door_open: bool = true

func _ready() -> void:
	# Reset state just in case
	is_door_open = true

func set_door_state(open: bool) -> void:
	is_door_open = open
	print("[Security] Tür ist nun %s" % ("OFFEN" if open else "GESCHLOSSEN"))

func reset_for_night() -> void:
	is_door_open = true
	print("[Security] Nacht beginnt, Tür ist OFFEN.")

## Prüft, ob ein Gast eintreten darf. Falls false, wird der Spawner ihn überspringen.
func evaluate_guest_entry(guest_id: String, guest_data: Dictionary) -> bool:
	if not is_door_open:
		print("[Security] Gast %s abgewiesen (Tür ist geschlossen)." % guest_id)
		return false
		
	var tags = guest_data.get("tags", [])
	var has_bouncer = GameManager.active_staff.has("bouncer")
	
	if "troublemaker" in tags:
		if has_bouncer:
			print("[Security] Bouncer hat Troublemaker '%s' den Zutritt verweigert!" % guest_id)
			GameManager.log_event("Bouncer blockiert: %s" % guest_id)
			return false
		else:
			print("[Security] Troublemaker '%s' betritt die Taverne (Kein Bouncer da)." % guest_id)
			
	return true
