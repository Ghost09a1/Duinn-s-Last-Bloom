extends CharacterBody3D

## Repräsentiert einen einzelnen Gast.
## Daten kommen per setup() rein, Zustände werden intern verwaltet.

# ── Gastdaten ───────────────────────────────────────────────
@export var guest_id       : String = "guest_01"
@export var display_name   : String = "Gast"
@export var requested_item : String = "Ale"
@export var requested_intent: Array = []
@export var size_pref      : String = "any"  # small | big | any

var wants_drink : bool = true
var wants_food  : bool = false

# ── Zimmer-Wunsch ───────────────────────────────────────────
@export var wants_room_chance    : float = 0.0
@export var wants_room           : bool  = false
@export var room_budget_per_week: int   = 0
@export var stay_duration_days   : Array = []

@export var wallet         : int    = 10
@export var tip_pool       : Array  = []
@export var dialog_root_id : String = "start"
@export var patience       : float  = 90.0
@export var mood           : int    = 0
@export var tags            : Array = []
@export var likes           : Array = []
@export var dislikes        : Array = []
@export var flags_on_success: Array = []
@export var flags_on_fail   : Array = []

# ── Zustand ─────────────────────────────────────────────────
enum State { ENTERING, SEATED, WAITING_FOR_SERVICE, TALKING, SERVED, 	LEAVING,
	SOCIALIZING,
	WATCHING
}
var state : State = State.ENTERING

signal guest_done(guest: Node3D)  ## Wird gefeuert wenn der Gast geht

# ── Nodes ────────────────────────────────────────────────────
@onready var name_label   : Label3D = $NameLabel
@onready var state_label  : Label3D = $StateLabel
@onready var patience_label: Label3D= $PatienceLabel
@onready var timer        : Timer   = $PatienceTimer
@onready var nav_agent    : NavigationAgent3D = $NavigationAgent3D
@onready var social_timer : Timer = Timer.new()

@export var movement_speed : float = 4.0

var _target_pos : Vector3 = Vector3.ZERO
var _moving : bool = false


func _ready() -> void:
	name_label.text  = display_name
	patience_label.visible = false
	_update_state_label()
	_apply_random_skin()
	
	add_child(social_timer)
	social_timer.one_shot = true
	social_timer.timeout.connect(_on_socialize_tick)
	
	_enter()


# ── Skin ─────────────────────────────────────────────────────
const SKINS : Array = [
	"res://assets/characters/skaterMaleA.png",
]

const SHOUTS = ["Prost!", "Lecker!", "Mjam!", "Hehe!", "Prost!", "Nett hier."]
const PERFORMANCE_EMOJIS = ["🎵", "🎶", "👏"]

func _apply_random_skin() -> void:
	var char_model : Node = get_node_or_null("CharacterModel")
	if not char_model:
		return
	var mesh_inst : MeshInstance3D = _find_mesh(char_model)
	if not mesh_inst:
		return
	var tex_path : String = SKINS[_rng.randi() % SKINS.size()]
	var tex : Texture2D = load(tex_path)
	if not tex:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.shading_mode   = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in mesh_inst.get_surface_override_material_count():
		mesh_inst.set_surface_override_material(i, mat)

func _find_mesh(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child in node.get_children():
		var result = _find_mesh(child)
		if result:
			return result
	return null


func _process(_delta: float) -> void:
	if state == State.WAITING_FOR_SERVICE and timer.time_left > 0:
		patience_label.visible = true
		var p_ratio = timer.time_left / timer.wait_time
		patience_label.text = "Geduld: %d%%" % int(p_ratio * 100)
		
		# Farbcodierung
		if p_ratio > 0.5:
			patience_label.modulate = Color("4caf50") # Grün
		elif p_ratio > 0.25:
			patience_label.modulate = Color("ffeb3b") # Gelb
		else:
			# Rot blinkend (sinus welle basierend auf Zeit)
			var blink = (sin(Time.get_ticks_msec() / 150.0) + 1.0) / 2.0
			patience_label.modulate = Color("f44336").lerp(Color.WHITE, blink * 0.5)
	else:
		patience_label.visible = false

func _physics_process(_delta: float) -> void:
	if not _moving or nav_agent.is_navigation_finished():
		if _moving:
			_on_target_reached()
		return
	
	var next_path_pos: Vector3 = nav_agent.get_next_path_position()
	var current_pos: Vector3 = global_position
	var new_velocity: Vector3 = (next_path_pos - current_pos).normalized() * movement_speed
	
	velocity = new_velocity
	move_and_slide()
	
	# Drehen in Laufrichtung
	if velocity.length() > 0.1:
		var look_target = global_position + velocity
		look_target.y = global_position.y
		look_at(look_target, Vector3.UP)
		rotate_object_local(Vector3.UP, PI) # Da CharacterModel nach hinten schaut (180 Grad)

func set_target(pos: Vector3) -> void:
	_target_pos = pos
	_moving = true
	nav_agent.target_position = pos

func _on_target_reached() -> void:
	_moving = false
	velocity = Vector3.ZERO
	print("[Guest] %s hat Ziel erreicht." % display_name)
	
	match state:
		State.ENTERING:
			_set_state(State.WAITING_FOR_SERVICE)
		State.SERVED:
			if state == State.SOCIALIZING:
				_on_socialize_tick()
			elif state == State.WATCHING:
				_on_watching_tick()
		State.LEAVING:
			guest_done.emit(self)
			queue_free()

func _start_socializing() -> void:
	# Verweildauer am Tisch (z.B. 15-30 Sekunden)
	var duration = _rng.randf_range(15.0, 30.0)
	get_tree().create_timer(duration).timeout.connect(_leave)
	_on_socialize_tick()

func _on_socialize_tick() -> void:
	if state != State.SOCIALIZING:
		return
		
	# Wechsel Emoji zufällig oder zeige Shout
	if _rng.randf() > 0.7:
		# Shout!
		if state_label:
			state_label.text = SHOUTS[_rng.randi() % SHOUTS.size()]
	else:
		# Emoji!
		var emotes = ["🥣", "🍺", "💬", "😋", "😴", "🎵"]
		if state_label:
			state_label.text = emotes[_rng.randi() % emotes.size()]
	
	_animate_label()
	social_timer.start(randf_range(3.0, 6.0))

func _on_watching_tick() -> void:
	# Wenn jemand performt, zeigen wir Musiknoten
	if randf() < 0.7:
		state_label.text = PERFORMANCE_EMOJIS.pick_random()
	else:
		state_label.text = ""
	
	_animate_label()
	social_timer.start(randf_range(2.0, 4.0))

func _animate_label() -> void:
	if not state_label: return
	if state_label.text == "": return
	
	var tween = create_tween().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	state_label.scale = Vector3(0.5, 0.5, 0.5)
	tween.tween_property(state_label, "scale", Vector3(1.2, 1.2, 1.2), 0.2)
	tween.tween_property(state_label, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func show_gold_popup(amount: int) -> void:
	# Goldene Zahl die nach oben schwebt
	var label = Label3D.new()
	label.text = "+%dG" % amount
	label.modulate = Color(1.0, 0.84, 0.0) # Gold
	label.billboard = 1 # Viewport
	label.font_size = 48
	add_child(label)
	label.position = Vector3(0, 2, 0)
	
	var tween = create_tween()
	tween.tween_property(label, "position:y", 3.0, 1.0)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(label.queue_free)
	
	if "AudioManager" in get_node("/root"):
		get_node("/root/AudioManager").play_sfx("coin")

var _rng := RandomNumberGenerator.new()

func setup(data: Dictionary) -> void:
	"""Befülle den Gast aus einem Dictionary (z.B. aus JSON geladen)."""
	
	if data.has("instance_seed"):
		_rng.seed = data.get("instance_seed")
	
	guest_id        = data.get("id",              guest_id)
	display_name    = data.get("display_name",    display_name)
	requested_item  = data.get("requested_item",  requested_item)
	requested_intent.assign(data.get("requested_intent", []))
	size_pref       = data.get("size_pref",       "any")
	
	wants_room_chance    = data.get("wants_room_chance", 0.0)
	room_budget_per_week = data.get("room_budget_per_week", 0)
	stay_duration_days.assign(data.get("stay_duration_days", [1, 2]))
	# wants_room wird vom Spawner explizit auf true/false gewürfelt, nicht direkt aus JSON gelesen.
	wants_room           = data.get("wants_room", false)
	
	wallet          = data.get("wallet",          wallet)
	tip_pool.assign(data.get("tip_pool",          []))
	dialog_root_id  = data.get("dialog_root_id",  dialog_root_id)
	patience        = data.get("patience",         patience)
	tags.assign(data.get("tags",              []))
	likes.assign(data.get("likes",           []))
	dislikes.assign(data.get("dislikes",     []))
	flags_on_success.assign(data.get("flags_on_success", []))
	flags_on_fail.assign(data.get("flags_on_fail",    []))


## Wird vom Player-Controller aufgerufen (via interaction_system.gd)
func interact(player: CharacterBody3D) -> void:
	if state == State.WAITING_FOR_SERVICE or state == State.SEATED:
		print("[Guest] %s angesprochen." % display_name)
		_set_state(State.TALKING)
		player.set_locked(true)
		
		# Den DialogSystem bescheid geben, falls ein Zimmer gewollt ist
		var extra_context := {}
		if wants_room:
			extra_context["wants_room"] = true
			
		DialogSystem.start(dialog_root_id, self, extra_context)
		DialogSystem.dialog_ended.connect(_on_dialog_ended.bind(player), CONNECT_ONE_SHOT)


func _on_dialog_ended(player: CharacterBody3D) -> void:
	player.set_locked(false)
	# Wenn noch nicht bedient, zurück auf WAITING und starte JETZT erst den Timer
	if state == State.TALKING:
		_set_state(State.WAITING_FOR_SERVICE)
		
		var effective_patience = patience
		if GameManager.has_method("get_reputation_bonus"):
			effective_patience *= GameManager.get_reputation_bonus()
			
		timer.start(effective_patience)
		print("[Guest] %s: Bestellung aufgenommen. Timer: %.0f (Base: %.0f)" % [display_name, effective_patience, patience])


func on_served(item: String) -> void:
	"""Wird vom ServiceSystem aufgerufen wenn der Spieler etwas serviert."""
	timer.stop()
	
	var item_tags : Array = _get_item_tags(item)
	var reaction  : String
	var mood_delta : int = 0
	
	if item == requested_item:
		reaction = "Perfect! 😄"
		mood_delta = 2
		GameManager.log_event("Served %s: %s -> %s" % [reaction, display_name, item])
	# 2) Hat gewünschte Tags
	elif _has_all_tags(item_tags, requested_intent):
		reaction = "Okay. 🙂"
		mood_delta = 1
		GameManager.log_event("Served Good (Tags OK): %s -> %s" % [display_name, item])
	# 3) Dislike getroffen -> Katastrophe
	elif _tags_overlap(item_tags, dislikes):
		reaction = "Disgusting! 🤢😡"
		mood_delta = -2
		GameManager.log_event("Served DISLIKE: %s -> %s" % [display_name, item])
	# 4) Falsch, aber nicht verhasst
	else:
		reaction = "Wrong order. 😠"
		mood_delta = -1
		GameManager.log_event("Served Wrong: %s -> %s" % [display_name, item])
		
	# Flags anwenden
	var p = get_node_or_null("/root/TavernPrototype/Player") # Hacky, besser über Signal oder Parameter
	if mood_delta >= 1:
		for f in flags_on_success: ScoreSystem.set_flag(f, true)
		if p and p.has_method("play_anim"): p.play_anim("cheer")
	else:
		for f in flags_on_fail: ScoreSystem.set_flag(f, true)
		if p and p.has_method("play_anim"): p.play_anim("sad")

	# Stats aufnehmen
	mood = clampi(mood + mood_delta, -2, 2)

	if state_label:
		state_label.text = "😄" if mood_delta >= 1 else "😡"
		state_label.modulate = Color(0.2, 1.0, 0.2) if mood_delta >= 1 else Color(1.0, 0.2, 0.2)
	
	_set_state(State.SERVED)
	
	# -- NPC FLOW: Release Bar, find Seat --
	var spawner = GameManager.spawner
	if spawner:
		var current_spot = spawner.get_spot_of_guest(self)
		if current_spot:
			spawner.release_spot(current_spot)
		
		var seat = spawner.request_spot("guest_seats", self)
		if seat:
			set_target(seat.global_position)
		else:
			# Kein Sitzplatz? Dann direkt gehen
			await get_tree().create_timer(1.0).timeout
			_leave()


func _get_item_tags(item_id: String) -> Array:
	var items_db : Dictionary = {}
	var f := FileAccess.open("res://data/items/items.json", FileAccess.READ)
	if f:
		items_db = JSON.parse_string(f.get_as_text()).get("items", {})
		f.close()
	return items_db.get(item_id, {}).get("tags", [])


func _tags_overlap(a: Array, b: Array) -> bool:
	for tag in a:
		if tag in b:
			return true
	return false

func _has_all_tags(item_tags: Array, req_tags: Array) -> bool:
	for tag in req_tags:
		if not tag in item_tags:
			return false
	return true


func _pick(options: Array) -> String:
	return options[_rng.randi() % options.size()]


# ── Private ──────────────────────────────────────────────────
func _enter() -> void:
	print("[Guest] %s betritt die Taverne." % display_name)
	GameManager.log_event("Gast betreten: %s" % display_name)
	_set_state(State.ENTERING)
	
	# Finde einen freien Queue Spot (wird später vom Spawner präzisiert)
	# Hier für den Anfang: Zufälliger bar_queue Spot
	var spots = get_tree().get_nodes_in_group("bar_queue")
	if spots.size() > 0:
		set_target(spots[0].global_position) # Hack: Erster Spot (Spawner wird das regeln)

func apply_rush_penalty() -> void:
	"""Wird aufgerufen wenn die Bar zu voll ist."""
	patience *= 0.7 # 30% weniger Geduld
	if timer.time_left > 0:
		var new_time = timer.time_left * 0.7
		timer.start(new_time)
	print("[Guest] %s ist genervt von der Schlange. Neue Geduld: %.0fs" % [display_name, patience])

func _leave() -> void:
	print("[Guest] %s verlässt die Taverne. Mood: %d" % [display_name, mood])
	GameManager.log_event("Gast gegangen: %s (Mood: %d)" % [display_name, mood])
	_set_state(State.LEAVING)
	
	# Spot freigeben
	var spawner = GameManager.spawner
	if spawner:
		var spot = spawner.get_spot_of_guest(self)
		if spot:
			spawner.release_spot(spot)
	
	var exit = get_node_or_null("/root/TavernPrototype/NPCNavigation/ExitMarker")
	if exit:
		set_target(exit.global_position)
	else:
		# Fallback falls kein Marker
		await get_tree().create_timer(1.0).timeout
		guest_done.emit(self)
		queue_free()


func _set_state(new_state: State) -> void:
	state = new_state
	_update_state_label()
	print("[Guest] %s -> %s" % [display_name, State.keys()[new_state]])


func _update_state_label() -> void:
	if not state_label: return
	
	match state:
		State.ENTERING:
			state_label.text = "🚶"
			state_label.modulate = Color.WHITE
		State.SEATED:
			state_label.text = "🪑"
			state_label.modulate = Color(0.8, 0.8, 0.8)
		State.WAITING_FOR_SERVICE:
			if wants_drink and wants_food:
				state_label.text = "🍺🍔"
			elif wants_drink:
				state_label.text = "🍺"
			elif wants_food:
				state_label.text = "🍔"
			else:
				state_label.text = "💬"
			state_label.modulate = Color.WHITE
		State.TALKING:
			state_label.text = "💬?"
			state_label.modulate = Color(0.6, 0.8, 1.0)
		State.SERVED:
			pass # Wird in on_served mit Reactions (😡/😄) gesetzt
		State.SOCIALIZING:
			pass # Wird in _on_socialize_tick gesetzt
		State.LEAVING:
			state_label.text = "🚪"
			state_label.modulate = Color(0.5, 0.5, 0.5)


func _on_patience_timer_timeout() -> void:
	if state == State.WAITING_FOR_SERVICE:
		if has_node("CharacterModel/AnimationPlayer"):
			var anim = get_node("CharacterModel/AnimationPlayer")
			if anim.has_animation("sad"): anim.play("sad")
			
		if patience_label:
			patience_label.text = "Gegangen!"
			patience_label.modulate = Color("f44336")
			
		# Angry Emoji setzen, bevor er geht
		if state_label:
			state_label.text = "😡"
			state_label.modulate = Color(1.0, 0.2, 0.2)
			
		print("[Guest] %s verlässt (zu lange gewartet)." % display_name)
		GameManager.log_event("Patience out: %s" % display_name)
		mood = clampi(mood - 1, -2, 2)
		ScoreSystem.record_guest_skipped(guest_id)
		
		# Kurz warten, damit man das rote Emoji sieht, dann echtes Leave() verarbeiten
		_set_state(State.SERVED) # Hack: Set on SERVED so update_label doesn't overwrite it immediately
		await get_tree().create_timer(1.0).timeout
		_leave()
