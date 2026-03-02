@tool
extends EditorScript

## Führt man dieses Script im Editor aus (File -> Run), 
## generiert es die Tier1_Base.tscn vollautomatisch.

func _run() -> void:
	print("=> Generiere Tier1_Base.tscn ...")
	
	# Stelle sicher, dass das Verzeichnis existiert
	if not DirAccess.dir_exists_absolute("res://scenes/world/tiers"):
		DirAccess.make_dir_recursive_absolute("res://scenes/world/tiers")
	
	var root = Node3D.new()
	root.name = "Tier1_Base"
	
	# Navigation Region
	var nav = NavigationRegion3D.new()
	nav.name = "NavigationRegion3D"
	# Standard NavMesh einhängen
	var nav_mesh = NavigationMesh.new()
	nav_mesh.agent_radius = 0.4
	nav.navigation_mesh = nav_mesh
	root.add_child(nav)
	nav.owner = root
	
	# -- Struktur / Räume --
	var struct = Node3D.new()
	struct.name = "Structure"
	nav.add_child(struct)
	struct.owner = root
	
	# Floor (Common Room + Flur oben)
	var floor_csg = CSGBox3D.new()
	floor_csg.name = "Floor_Main"
	floor_csg.size = Vector3(14, 0.4, 12)
	floor_csg.position = Vector3(0, -0.2, 0)
	floor_csg.use_collision = true
	struct.add_child(floor_csg)
	floor_csg.owner = root
	
	# Flur Oben (Upper Floor)
	var floor_upper = CSGBox3D.new()
	floor_upper.name = "Floor_Upper"
	floor_upper.size = Vector3(14, 0.4, 4)
	floor_upper.position = Vector3(0, 3.8, -4)
	floor_upper.use_collision = true
	struct.add_child(floor_upper)
	floor_upper.owner = root
	
	# Treppe
	var stairs = CSGPolygon3D.new()
	stairs.name = "Stairs"
	stairs.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(0, 4), Vector2(4, 4), Vector2(4, 0)
	])
	stairs.depth = 2.0
	stairs.position = Vector3(4, 0, -2)
	stairs.rotation_degrees = Vector3(0, -90, 0) # Rotiert
	stairs.use_collision = true
	struct.add_child(stairs)
	stairs.owner = root
	
	# Wände
	var create_wall = func(n: String, s: Vector3, p: Vector3, is_cutaway: bool = false):
		var w = CSGBox3D.new()
		w.name = n
		w.size = s
		w.position = p
		w.use_collision = true
		if is_cutaway:
			w.add_to_group("cutaway_wall")
		struct.add_child(w)
		w.owner = root
	
	# Außenwände (Süd-Wände sind Cutaway in isometrisch Front)
	create_wall.call("Wall_North", Vector3(14, 8, 0.4), Vector3(0, 3.8, -6), false)
	create_wall.call("Wall_South", Vector3(14, 4, 0.4), Vector3(0, 1.8, 6), true)
	create_wall.call("Wall_West", Vector3(0.4, 8, 12), Vector3(-7, 3.8, 0), false) # Cutaway oft nur South + East
	create_wall.call("Wall_East", Vector3(0.4, 4, 12), Vector3(7, 1.8, 0), true)
	
	# -- Stations --
	var stations = Node3D.new()
	stations.name = "Stations"
	nav.add_child(stations)
	stations.owner = root
	
	var create_station = func(n: String, st_id: String, p: Vector3):
		var s = StaticBody3D.new()
		s.name = n
		s.position = p
		var col = CollisionShape3D.new()
		col.name = "Col"
		col.shape = BoxShape3D.new()
		s.add_child(col)
		# Script anhängen
		s.set_script(load("res://scripts/systems/station_interactable.gd"))
		s.set("station_id", st_id)
		s.set("display_name", n)
		
		# Visual Placeholder
		var m = MeshInstance3D.new()
		m.name = "Placeholder"
		var box = BoxMesh.new()
		m.mesh = box
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.8, 0.2)
		box.material = mat
		s.add_child(m)
		
		stations.add_child(s)
		s.owner = root
		col.owner = root
		m.owner = root
	
	create_station.call("StationDrinks", "drinks_station", Vector3(-2, 0.5, -2))
	create_station.call("StationFood", "food_station", Vector3(-4, 0.5, -4))
	create_station.call("ServiceBell", "bell", Vector3(-1, 0.5, -2))
	create_station.call("LedgerDesk", "ledger", Vector3(5, 0.5, 4))
	create_station.call("ShopBoard", "shop_board", Vector3(6.5, 1.5, -1))
	create_station.call("RoomBoard", "room_board", Vector3(-6.5, 1.5, -2))
	create_station.call("CleaningBroom", "minigame_cleaning", Vector3(-6, 0.5, 5))
	
	# -- Routing & Spawn Points --
	var sp = Node3D.new()
	sp.name = "SpawnPoints"
	root.add_child(sp)
	sp.owner = root
	
	var create_marker = func(n: String, p: Vector3):
		var m = Marker3D.new()
		m.name = n
		m.position = p
		sp.add_child(m)
		m.owner = root
		
	create_marker.call("SpawnOutside", Vector3(2, 0, 8))
	create_marker.call("Entrance", Vector3(2, 0, 5))
	create_marker.call("Exit", Vector3(2, 0, 8))
	
	create_marker.call("SpawnPoint_Bar1", Vector3(-2, 0, -1))
	create_marker.call("SpawnPoint_Bar2", Vector3(-1, 0, -1))
	create_marker.call("SpawnPoint_Table1_A", Vector3(-4, 0, 2))
	create_marker.call("SpawnPoint_Table1_B", Vector3(-4, 0, 3))
	create_marker.call("SpawnPoint_Table2_A", Vector3(1, 0, 2))
	create_marker.call("SpawnPoint_Table2_B", Vector3(1, 0, 3))
	
	var scene = PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/world/tiers/Tier1_Base.tscn")
	print("=> Erfolgreich gespeichert als res://scenes/world/tiers/Tier1_Base.tscn")
