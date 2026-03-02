extends Node

## AutoSimulator
## Erlaubt das "headless" Simulieren von Nächten für das Balancing, 
## ohne Ingame-Zeit verstreichen zu lassen.

signal simulation_finished(filename: String)

var _results : Array[Dictionary] = []

func run_simulation(seed_val: int, num_nights: int = 100, save_to_disk: bool = true) -> void:
	print("[Simulator] Starte Headless-Simulation... Seed: %d, Nächte: %d" % [seed_val, num_nights])
	
	# Status sichern oder zurücksetzen
	var old_money = GameManager.global_money
	var old_night = GameManager.night_index
	var old_seed = GameManager.global_seed
	var old_upgrades = GameManager.active_upgrades.duplicate()
	var old_staff = GameManager.active_staff.duplicate()
	var old_memory = GameManager.npc_memory.duplicate()
	var old_inventory = GameManager.global_inventory.duplicate()
	
	GameManager._reset_all_data() # Clear everything
	GameManager.global_seed = seed_val
	
	# Optional: Basis-Upgrades / Staff für diesen Test forcieren
	# GameManager.active_upgrades.append("comfy_chairs")
	
	_results.clear()
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	for i in range(1, num_nights + 1):
		GameManager.night_index = i
		var plan = DayGenerator.generate_day(GameManager.global_seed, i)
		
		# 1. Simuliere jeden Gast der Nacht
		var night_guests = plan.get("guest_sequence", [])
		var perfect_count = 0
		var bad_count = 0
		var walkout_count = 0
		
		var earned_tips = 0
		
		for guest_id in night_guests:
			# DUMMY Wahrscheinlichkeits-Ergebnis (wird mit Upgrades besser)
			# Standard: 50% OK, 30% Perfect, 15% Bad, 5% Walkout
			var roll = rng.randf()
			var chance_perfect = 0.30
			var chance_bad = 0.15
			var chance_walkout = 0.05
			
			if "comfy_chairs" in GameManager.active_upgrades:
				chance_walkout -= 0.03
			if "fancy_bar" in GameManager.active_upgrades:
				chance_perfect += 0.10
				
			var _outcome = ""
			var _is_perfect = false
			var _success = true
			var mood_delta = 0
			var gold_val = 15 # Basispreis pro Drink
			var multiplier = GameManager.get_tip_multiplier()
			
			if roll < chance_walkout:
				_outcome = "walkout"
				_success = false
				walkout_count += 1
				ScoreSystem.record_guest_skipped(guest_id)
			elif roll < chance_walkout + chance_bad:
				_outcome = "bad"
				mood_delta = -5
				_success = false
				bad_count += 1
				ScoreSystem.record_service({"guest_id": guest_id, "success": false, "served_item": "water", "mood_delta": mood_delta})
			elif roll < chance_walkout + chance_bad + chance_perfect:
				_outcome = "perfect"
				_is_perfect = true
				perfect_count += 1
				var money = int((gold_val + 5) * multiplier) # +5 Perfect Bonus
				earned_tips += money
				ScoreSystem.record_service({"guest_id": guest_id, "success": true, "served_item": "beer", "is_perfect": true, "earned_money": money, "base_price": gold_val, "tip_mult": multiplier, "mood_delta": 5})
			else:
				_outcome = "ok"
				var money = int(gold_val * multiplier)
				earned_tips += money
				ScoreSystem.record_service({"guest_id": guest_id, "success": true, "served_item": "beer", "is_perfect": false, "earned_money": money, "base_price": gold_val, "tip_mult": multiplier, "mood_delta": 2})

		# 2. Rechnungen / Miete am Ende der Nacht
		var rent = 25 + (i * 5)
		var staff_cost = _get_total_staff_cost()
		var total_bills = rent + staff_cost
		
		# ROOM RENTALS (Mock: 1 out of 5 guests rents a room for 15G if active)
		var room_income = 0
		if i > 2:
			var rentals = randi() % 2
			room_income = rentals * 15 * 7 # 1 week advance
		
		GameManager.global_money += room_income
		GameManager.global_money -= total_bills # Kann negativ werden
		
		# Schulden-Prüfung
		var debt_flag = "debt_malus" in GameManager.active_upgrades
		if GameManager.global_money < 0 and not debt_flag:
			GameManager.active_upgrades.append("debt_malus")
		elif GameManager.global_money >= 0 and debt_flag:
			GameManager.active_upgrades.erase("debt_malus")
			
		# Farming Sim-Wachstum simulieren
		FarmingSystem.process_growth()
		
		# 3. Tagesstatistik ablegen
		_results.append({
			"night": i,
			"event": plan.get("event_data", {}).get("label", "None"),
			"guests_total": night_guests.size(),
			"perfect": perfect_count,
			"bad": bad_count,
			"walkouts": walkout_count,
			"gross_income": earned_tips, # Nur durch Drinks
			"bills": total_bills,
			"net_wealth": GameManager.global_money, # Totaler Stand nach Abzug in der Nacht
			"has_debt": ("debt_malus" in GameManager.active_upgrades)
		})
		
		# Reset ScoreSystem for next simulated night
		ScoreSystem.reset()
	
	if save_to_disk:
		_export_csv("user://simulation_results.csv")
		
	print("[Simulator] 100 Nächte simuliert. End-Gold: %dG" % GameManager.global_money)
	
	# Alten Status wiederherstellen
	GameManager.global_money = old_money
	GameManager.night_index = old_night
	GameManager.global_seed = old_seed
	GameManager.active_upgrades = old_upgrades
	GameManager.active_staff = old_staff
	GameManager.npc_memory = old_memory
	GameManager.global_inventory = old_inventory
	
	emit_signal("simulation_finished", "user://simulation_results.csv")


func _get_total_staff_cost() -> int:
	var total = 0
	# Lade DB falls nicht im RAM
	var db_path = "res://data/staff/staff_roles.json"
	if FileAccess.file_exists(db_path):
		var f = FileAccess.open(db_path, FileAccess.READ)
		var json = JSON.new()
		if json.parse(f.get_as_text()) == OK:
			var db = json.data
			for s_id in GameManager.active_staff:
				if db.has(s_id):
					total += int(db[s_id].get("daily_wage", 0))
	return total


func _export_csv(path: String) -> void:
	var f = FileAccess.open(path, FileAccess.WRITE)
	if not f:
		push_error("[Simulator] Fehler beim Schreiben der CSV!")
		return
		
	# Header
	f.store_line("Night;Event;Guests;Perfects;Bads;Walkouts;Gross_Income;Bills;Net_Wealth;Has_Debt")
	
	for r in _results:
		var line = "%d;%s;%d;%d;%d;%d;%d;%d;%d;%s" % [
			r.night,
			r.event,
			r.guests_total,
			r.perfect,
			r.bad,
			r.walkouts,
			r.gross_income,
			r.bills,
			r.net_wealth,
			str("Yes" if r.has_debt else "No")
		]
		f.store_line(line)
		
	f.close()
	print("[Simulator] CSV erfolgreich exportiert nach: %s" % ProjectSettings.globalize_path(path))


func run_seed_sweep(num_seeds: int = 10, num_nights: int = 100) -> void:
	print("[Simulator] Starte Sweep über %d Seeds (jeweils %d Nächte)..." % [num_seeds, num_nights])
	var sweep_results = []
	
	for s in range(num_seeds):
		# Deterministischer, aber unterschiedlicher Seed für Test
		var test_seed = 10000 + s
		run_simulation(test_seed, num_nights, false) # save_to_disk = false
		
		var final_wealth = 0
		if _results.size() > 0:
			final_wealth = _results.back().get("net_wealth", 0)
			
		var total_guests = 0
		var total_perfects = 0
		var total_walkouts = 0
		
		for r in _results:
			total_guests += r.guests_total
			total_perfects += r.perfect
			total_walkouts += r.walkouts
			
		var perf_rate = 0.0
		var walkout_rate = 0.0
		if total_guests > 0:
			perf_rate = float(total_perfects) / float(total_guests)
			walkout_rate = float(total_walkouts) / float(total_guests)
			
		sweep_results.append({
			"seed": test_seed,
			"final_wealth": final_wealth,
			"perf_rate": perf_rate,
			"walkout_rate": walkout_rate
		})
	
	# Sortieren nach Reichtum absteigend
	sweep_results.sort_custom(func(a, b): return a.final_wealth > b.final_wealth)
	
	var export_path = "user://sweep_results.csv"
	var f = FileAccess.open(export_path, FileAccess.WRITE)
	if f:
		f.store_line("Seed;FinalWealth;PerfectRate;WalkoutRate;IsGolden")
		for i in range(sweep_results.size()):
			var res = sweep_results[i]
			var is_golden = "Yes" if i < 3 else "No" # Top 3 are golden
			f.store_line("%d;%d;%.2f;%.2f;%s" % [res.seed, res.final_wealth, res.perf_rate, res.walkout_rate, is_golden])
		f.close()
		print("[Simulator] Sweep beendet. Top Seed: %d (%dG). Ergebnisse in: %s" % [sweep_results[0].seed, sweep_results[0].final_wealth, ProjectSettings.globalize_path(export_path)])
