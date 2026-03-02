extends StaticBody3D

## Jedes Objekt, das ansprechbar sein soll, bekommt dieses Script.
## (Veraltet: Nutze stattdessen StationInteractable für World-Stations).
## Der Player-Raycast prüft, ob .has_method("interact") true ist.

@export var label : String = "Objekt"  ## Name der im Debug-Log erscheint

# Fallback für alte Stations, bis sie im Editor auf StationInteractable umgestellt sind
func interact(player: CharacterBody3D) -> void:
	print("[Interact System - Legacy] Spieler interagiert mit: ", name)
	
	if name == "StationDrinks":
		StationRouter.activate_station("drinks_station")
	elif name == "StationFood":
		StationRouter.activate_station("food_station")
	elif name == "ServiceBell":
		StationRouter.activate_station("bell")
	else:
		# Standard-Verhalten für andere Objekte
		pass
