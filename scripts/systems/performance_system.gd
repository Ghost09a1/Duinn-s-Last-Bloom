extends Node

# performance_system.gd
# Manages shows on the stage and their impact on popularity.

signal performance_started(artist_name, duration)
signal performance_ended

var is_active: bool = false
var current_artist: String = ""
var time_left: float = 0.0

func _process(delta: float) -> void:
	if is_active:
		time_left -= delta
		
		# Ruf-Bonus pro Sekunde
		if "ScoreSystem" in GameManager:
			GameManager.reputation += 0.5 * delta
			
		if time_left <= 0:
			end_performance()

func start_performance(artist: String, duration: float = 60.0) -> void:
	is_active = true
	current_artist = artist
	time_left = duration
	
	# Benachrichtige Gäste in der Nähe
	var guests = get_tree().get_nodes_in_group("guests")
	for guest in guests:
		if guest.has_method("set_watching"):
			# Nur Gäste die bereits sitzen schauen zu
			if guest.state == guest.State.SOCIALIZING:
				guest.state = guest.State.WATCHING
	
	emit_signal("performance_started", artist, duration)
	print("[PerformanceSystem] '%s' betritt die Bühne!" % artist)

func end_performance() -> void:
	is_active = false
	current_artist = ""
	
	# Gäste gehen zurück zum Socializing
	var guests = get_tree().get_nodes_in_group("guests")
	for guest in guests:
		if guest.state == guest.State.WATCHING:
			guest.state = guest.State.SOCIALIZING
			
	emit_signal("performance_ended")
	print("[PerformanceSystem] Performance beendet.")
