extends Node

# audio_manager.gd
# Centralized system for triggering sound effects.

func play_sfx(sfx_id: String) -> void:
	# Placeholder for actual AudioStreamPlayer logic
	print("[AudioManager] Spiele SFX: %s" % sfx_id)
	
	match sfx_id:
		"coin":
			_simulate_sound("Klingeling! (Gold)")
		"click":
			_simulate_sound("Klick!")
		"brew_done":
			_simulate_sound("Blubb-Fatsch! (Fertig)")
		"alert":
			_simulate_sound("Ding! (Warnung)")
		"applause":
			_simulate_sound("Klatsch-Klatsch!")

func _simulate_sound(_desc: String) -> void:
	# Hier würde man einen AudioStreamPlayer3D instanziieren oder Pool nutzen
	pass
