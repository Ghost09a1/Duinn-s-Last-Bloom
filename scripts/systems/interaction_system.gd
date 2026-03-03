extends Node

## InteractionManager (Veraltet, nur als Dokumentation oder Fallback-Proxy)
## World-Interaktionen sollten direkt über das InteractionSystem des Players 
## und das StationInteractable Script laufen.

func interact(target: Node3D, player: CharacterBody3D):
	if target.has_method("interact"):
		target.interact(player)
	else:
		push_warning("[InteractionManager] Objekt %s hat keine interact() Methode." % target.name)
