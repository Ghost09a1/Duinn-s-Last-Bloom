extends StaticBody3D
class_name StationInteractable

## Jedes interaktive Objekt in der Welt, das kein Gast ist, 
## sollte dieses Script (oder eine Erweiterung davon) nutzen.

@export var station_id: String = "generic_station"
@export var display_name: String = "Station"
@export var payload: Dictionary = {}

## Wird vom InteractionSystem aufgerufen, wenn der Spieler 'E' drückt.
func interact(_player: CharacterBody3D) -> void:
	print("[StationInteractable] Spieler interagiert mit: ", display_name)
	StationRouter.activate_station(station_id, payload)
