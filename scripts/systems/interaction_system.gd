extends StaticBody3D

## Jedes Objekt, das ansprechbar sein soll, bekommt dieses Script.
## Der Player-Raycast prüft, ob .has_method("interact") true ist.

@export var label : String = "Objekt"  ## Name der im Debug-Log erscheint

# Definiere ein globales Event oder rufe GameManager auf
func interact(_player: CharacterBody3D) -> void:
	print("[Interact] Spieler interagiert mit: ", name) # Nutze den Node-Namen zur Unterscheidung
	
	if name == "StationDrinks":
		ServiceSystem.open_station("drinks")
	elif name == "StationFood":
		ServiceSystem.open_station("food")
	elif name == "ServiceBell":
		ServiceSystem.ring_bell()
	else:
		# Standard-Verhalten für andere Objekte
		pass
