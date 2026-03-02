extends StaticBody3D

@export var minigame_scene: PackedScene
@export var prompt_text: String = "[Minispiel spielen]"

func interact(player: Node) -> void:
	if not minigame_scene:
		push_error("[%s] Keine Minigame-Szene zugewiesen!" % name)
		return
		
	# 1. Spieler "einfrieren" (Kamera und Bewegung blockieren)
	if player.has_method("set_locked"):
		player.set_locked(true)
		
	# 2. Minispiel instanziieren und zum Tree hinzufügen
	var mg_instance = minigame_scene.instantiate()
	get_tree().root.add_child(mg_instance)
	
	# 3. Verbinden des Finish-Signals, um Spieler wieder zu entriegeln
	if mg_instance.has_signal("cleaning_finished"):
		mg_instance.cleaning_finished.connect(_on_minigame_finished.bind(player))
		mg_instance.start_minigame()
	elif mg_instance.has_signal("shooting_finished"):
		mg_instance.shooting_finished.connect(_on_minigame_finished.bind(player))
		mg_instance.start_minigame()
	else:
		push_warning("[%s] Unbekanntes Minispiel-Signal. Entriegelt sofort." % name)
		_on_minigame_finished(true, player)

func _on_minigame_finished(result: Variant, player: Node) -> void:
	# Minispiel hat sich selbst per queue_free() oder hide() aufgeräumt
	if player.has_method("set_locked"):
		player.set_locked(false)
		
	# Falls es ein Schießspiel war, wenden wir die Belohnung an
	if result is int:
		GameManager.apply_security_reward(result)
		
	# Falls es eine Camera-Modifikation gab (Iso vs. ThirdPerson), wird dies im Player gehandhabt
	print("[%s] Minigame beendet mit Resultat: %s" % [name, result])
