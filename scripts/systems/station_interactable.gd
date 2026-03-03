extends StaticBody3D
class_name StationInteractable

## Jedes interaktive Objekt in der Welt, das kein Gast ist, 
## sollte dieses Script (oder eine Erweiterung davon) nutzen.

@export var station_id: String = "generic_station"
@export var prompt_text: String = "[Interagieren]"
@export var show_label : bool = true
@export var payload: Dictionary = {}

func _ready() -> void:
	# Falls ein Label3D existiert (z.B. als Child), aktualisieren wir es
	for child in get_children():
		if child is Label3D:
			child.text = prompt_text
			child.visible = show_label

## Wird vom InteractionSystem aufgerufen, wenn der Spieler 'E' drückt.
func interact(_player: CharacterBody3D) -> void:
	print("[StationInteractable] Spieler interagiert mit: ", station_id)
	StationRouter.activate_station(station_id, payload)
