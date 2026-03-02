# Duinn’s Last Bloom – Master-Arbeitsplan (Godot 4)
**World-Integration + H1–H4 (Seed/Generator, Zimmer, Memory, Balancing) – TWI-inspiriert**

Dieser Plan kombiniert:
1) deinen bisherigen **World-Build/Feature→Ort**-Plan fileciteturn0file0  
2) die **repo-basierten** nächsten Schritte (Seed-Härte, StationRouter, Zimmer-UI, Memory-Key-Fix, Balancing Harness).

Ziel: Alle Systeme haben **echte Orte** in der Welt, und jede Nacht ist **reproduzierbar** (Seed → identische Gäste/Skins/Room-Wants/Events).

---

## 0) Definition of Done (für diese Ausbau-Runde)

### DoD-A (Reproduzierbarkeit)
- Gleicher `global_seed + day_index` → identische:
  - Guest-Sequenz
  - wants_room Entscheidungen
  - Guest-Skins/Random-Varianten
  - Event-Auswahl
- Debug-HUD zeigt: `day_index`, `night_seed`, `event_id`, `guest_ids`

### DoD-B (World-Integration)
- Mix/Serve/Shop/Ledger/RoomAssignment sind **World-Stations**, nicht nur UI
- Gäste laufen zuverlässig: **SpawnOutside → Entrance → Seat → Exit**
- Isometrische Kamera + Cutaway Walls: Player niemals verdeckt

### DoD-C (Inn wächst modular)
- Tier1 ist sauber blockoutet (Innen + kleines Außen)
- Tier2/Tier3 sind als **Add-on Scenes** vorbereitet (Basement/Outhouse/Tower)

---

## 1) Projektstruktur (Godot) – solide Basis

### To-dos
- [ ] Ordner anlegen/aufräumen:
```text
res://scenes/world/
res://scenes/world/tiers/
res://scenes/world/stations/
res://scenes/ui/
res://scripts/core/
res://scripts/systems/
res://scripts/world/
res://data/
```

- [ ] Drei Kern-Szenen definieren:
  - `WorldRoot.tscn`
  - `tiers/Tier1_Base.tscn`
  - `camera/IsoCameraRig.tscn`

---

## 2) H1 – Seeded Night Generator „hart“ machen (wichtigster Fix)

### Problem
Ein Teil deines Zufalls kommt noch aus unseeded `randf()/randi()`. Damit sind Nächte nicht 100% reproduzierbar.

### Ziel
**Alle** Zufallsentscheidungen laufen über deterministische RNGs, die aus Seed + Kontext abgeleitet sind.

### To-dos (konkret)

#### 2.1 `GameRNG` einführen (zentrale RNG-Quelle)
- [ ] `scripts/core/game_rng.gd` erstellen (Autoload optional)
- [ ] `night_seed = hash("%s|%s" % [global_seed, day_index])`
- [ ] `rng_for(key)` liefert `RandomNumberGenerator` mit:
  - `seed = hash("%s|%s" % [night_seed, key])`

#### 2.2 DayPlan bekommt alle Rolls (Spawner würfelt nicht mehr)
- [ ] `DayGenerator.generate_day()` erweitert:
  - `guest_sequence[]` inkl. `guest_instance_seed` pro SpawnIndex
  - `wants_room` pro Gast (bool) oder Roll-Wert
  - `skin_index` optional (oder via guest_instance_seed)
- [ ] `GuestSpawner` nutzt nur Plan-Daten (keine eigenen randf)

#### 2.3 Guest nutzt instance RNG
- [ ] `Guest.setup(data, instance_seed)`:
  - `self._rng.seed = instance_seed`
  - `_apply_random_skin()` und Reaction-Picks via `self._rng`

#### 2.4 Staff/Side RNG
- [ ] StaffSpawner/Minigame-Varianten ebenfalls via `rng_for("staff_spawn")` etc.

**DoD:** Du kannst einen Seed notieren, neu starten, und bekommst dieselbe Nacht.

---

## 3) World-Integration – Stations sauber routen (kein Node-Name-Switch)

### Problem
Wenn `interaction_system.gd` über Node-Namen switched, wird World-Ausbau (Küche, Zimmer, Garten, etc.) schnell chaotisch.

### Ziel
Jede Interaktion ist:
- `station_id` + optional `payload`
- Router entscheidet, welches System/UI aufgerufen wird

### To-dos

#### 3.1 `StationInteractable` Script
- [ ] `scripts/systems/station_interactable.gd`
  - `@export var station_id:String`
  - `@export var payload:Dictionary`
  - `interact()` → ruft `StationRouter.activate(...)`

#### 3.2 `StationRouter` (Autoload oder in GameManager)
- [ ] Mapping definieren:
  - `drinks_station` → `ServiceSystem.open("drinks")`
  - `food_station` → `ServiceSystem.open("food")`
  - `bell` → `ServiceSystem.ring_bell()`
  - `ledger` → `EndNightUI.open()`
  - `shop_board` → `BuildMenuUI.open()` / ShopUI
  - `room_board` → `RoomAssignmentUI.open()`
  - `garden_plot_*` → `FarmingUI.open(plot_id)`
  - `minigame_cleaning` → start cleaning scene
  - `tower_range` → start shooting-range scene

#### 3.3 Migration in `TavernPrototype`
- [ ] StationNodes umstellen:
  - StationDrinks/StationFood/ServiceBell → `StationInteractable` + IDs
- [ ] interaction_system nur noch:
  - „nearest interactable“ finden
  - Prompt anzeigen
  - `interact()`

**DoD:** neue Stations fügst du hinzu, ohne Code-Switches zu erweitern.

---

## 4) Phase A/B World-Build (Tier1) – Blockout + Kamera + Cutaway

Basierend auf deinem World-Build-Plan: Common Room + Bar + Küche + Treppe + Flur + 2 Zimmer, plus Isometrie & Cutaway. fileciteturn0file0

### 4.1 Isometrische Kamera (Godot)
- [ ] `IsoCameraRig.tscn`:
  - yaw 45°, pitch 30–40°, Perspective
  - 2 Zoom-Modi: Overview / Service
- [ ] Input:
  - Zoom toggle
  - optional rotate 90° steps

### 4.2 Cutaway Walls (vordere Wände)
- [ ] Außenwände in Gruppe `cutaway_wall`
- [ ] Raycast Kamera→Player:
  - Hits in group → hide oder fade
- [ ] Debug: „currently cut“ list

### 4.3 Tier1 Base Blockout
- [ ] `tiers/Tier1_Base.tscn`:
  - Common Room: Bar, Tische, Treppe, Tür zur Küche
  - Küche: Stove/Oven Placeholder + Prep Counter
  - Upper: Flur + 2 Zimmer (Doors)
  - Collisions + NavMesh bake

**DoD:** begehbarer Rundgang, Player immer sichtbar.

---

## 5) Phase C – Feature→Ort Mapping (World Stations platzieren)

### Pflicht-Stations (v0.1)
- [ ] `drinks_station` (Bar_MixStation)
- [ ] `food_station` (Kitchen oder Serving station)
- [ ] `bell` (Service bell)
- [ ] `ledger` (Ledger/Desk)
- [ ] `shop_board` (Build/Upgrades)
- [ ] `room_board` (Zimmervergabe – H2)
- [ ] `minigame_cleaning` (BroomStation)

### Seating & Routing
- [ ] SeatSlots:
  - BarSeats (4–6)
  - Tables (2–3 Tische)
- [ ] Guest route:
  - SpawnOutside → Entrance → Seat → Exit
- [ ] Navmesh: keine Lücken zwischen Küche/Bar/Treppe/Flur

**DoD:** Jede UI-Aktion hat einen physischen Trigger im Inn.

---

## 6) H2 – Zimmervergabe (Inn-Signature) minimal integrieren

Du hast die Daten/Logik bereits (rooms, applicants, assign_room). Es fehlt UI + Flow + World-Ort.

### To-dos

#### 6.1 `RoomAssignmentUI.tscn`
- [ ] UI zeigt:
  - freie Zimmer
  - Bewerber (Name, Budget, Stay, Trust optional)
- [ ] Buttons:
  - „Zimmer vergeben“
  - „Ablehnen“
  - „Weiter“

#### 6.2 EndNight Flow
- [ ] EndNightUI:
  - Summary → dann RoomAssignmentUI, wenn applicants > 0
  - danach „Next Night“

#### 6.3 Upper Floor World-Hooks
- [ ] 2 Zimmer-Türen (später mehr)
- [ ] RoomBoard unten (oder oben am Flur)

**DoD:** Spieler vergibt Zimmer als Teil der Loop (spürbare Konsequenz).

---

## 7) H3 – Wiederkehrende Gäste + Memory Flags „sauber“ machen

### Problem
Memory/Dialog sollten stable IDs nutzen (guest_id aus JSON), nicht Node.name.

### To-dos
- [ ] `guest_id` property in Guest setzen (aus JSON)
- [ ] DialogSystem: immer `guest_id` nutzen
- [ ] Memory keys:
  - `met`, `visits`, `last_outcome`, `last_seen_day`
  - `given_room` (bool)
- [ ] Wiederkehr-Logik:
  - spawn_weight boost, wenn last_outcome gut
  - cooldown, damit nicht immer dieselbe Person kommt

**DoD:** Wiederkehrer fühlt sich konsistent an (und reproducible).

---

## 8) H4 – Balancing Harness & Validator Upgrades

### 8.1 Validator erweitern (Boot)
- [ ] JSON IDs uniqueness: items/recipes/guests/events/furniture
- [ ] recipe refs exist (required_items)
- [ ] furniture scene paths exist (FileAccess.file_exists)
- [ ] dialog node refs exist (next nodes)
- [ ] weights > 0

### 8.2 AutoSimulator realistischer machen
- [ ] Simulation nutzt dieselbe Scoring-Logik wie echte Night
- [ ] Seed sweep 100 Nights:
  - avg gold, median gold
  - perfect rate
  - debt_malus frequency
  - walkouts
- [ ] „Golden Seeds“ (10 Seeds) als Regression Tests speichern

### 8.3 Economy Sanity
- [ ] Formel-Reihenfolge fixieren:
  1) base_total
  2) bonus_total (perfect/big/size)
  3) tips = (base+bonus)*tip_multiplier
  4) tips *= debt_malus
  5) final = base+bonus+tips
- [ ] clamp extreme multipliers (optional)

**DoD:** Balanceänderungen sind messbar & reproduzierbar.

---

## 9) Repo-spezifische Fixes (Quick Wins)

### 9.1 Gold API konsistent
Wenn irgendwo `get_gold()/add_gold()` erwartet wird, aber du `global_money` nutzt:
- [ ] `GameManager.get_gold()` + `GameManager.add_gold(delta)` hinzufügen

### 9.2 NavMesh Bake stutter vermeiden
Wenn Runtime-Bake stottert:
- [ ] bake nach Placement entfernen (oder nur beim Day-End Screen)
- [ ] für Möbel: NavigationObstacle3D + avoidance nutzen

---

## 10) Umsetzung als Sessions (ohne Zeit-Schätzen)

### Session 1
- GameRNG + DayPlan enthält alle Rolls (2.1–2.3)

### Session 2
- StationInteractable + StationRouter + Migration der bestehenden Stations (3.1–3.3)

### Session 3
- IsoCameraRig + Cutaway Walls stabil (4.1–4.2)

### Session 4
- Tier1 Base Blockout + Navmesh + Seats + Routing (4.3 + 5)

### Session 5
- RoomAssignmentUI + EndNight Flow + RoomBoard in World (6)

### Session 6
- Memory-Key cleanup + Wiederkehrer polish (7)

### Session 7
- Validator + AutoSimulator Upgrade + Golden Seeds (8)

---

## 11) Datei-Checkliste (was neu/angepasst wird)

**Neu**
- `scripts/core/game_rng.gd`
- `scripts/systems/station_router.gd`
- `scripts/systems/station_interactable.gd`
- `scenes/ui/RoomAssignmentUI.tscn` + script

**Ändern**
- `DayGenerator` (DayPlan erweitert)
- `GuestSpawner` (kein randf, nur Plan)
- `Guest` (instance rng, guest_id)
- `interaction_system.gd` (Router statt Node-Name Switch)
- `EndNightUI` (RoomAssignment Schritt)
- ggf. `BuildManager` (Gold API / Navmesh bake)

---

## Nächster Schritt (direkt starten)
**Priorität 1:** H1 Reproduzierbarkeit (GameRNG + DayPlan Rolls).  
Solange das nicht sitzt, sind Balancing, AutoSimulator und wiederkehrende Story-Events unzuverlässig.

