# Duinn’s Last Bloom – Gameworld-Design & Implementationsplan (Godot 4)
**Fokus:** Die Gameworld so bauen, dass sie **Features trägt**, **lesbar** ist (Iso + Cutaway) und sich **modular** wie ein wachsendes Inn anfühlt.

Repo-Referenz: https://github.com/Ghost09a1/Duinn-s-Last-Bloom

---

## 1) Kurze Recherche: Wie machen es populäre Spiele?

### 1.1 Sichtbarkeit in isometrischen Innenräumen
**The Sims** nutzt „Walls Up / Walls Down / Cutaway“-Ansichten; „Cutaway“ blendet Wände aus, die zwischen Kamera und der rückwärtigen Wand liegen, und schneidet auch um den aktiven Sim herum frei. Außerdem gibt es eine Top-Down-Ansicht im Build Mode. citeturn0search20  
**Project Zomboid** erwähnt explizit ein „Sims-style cutaway vision system“. citeturn0search31

**Takeaway für Duinn:**
- Baue 3 Modi: **Walls Up**, **Cutaway**, **Walls Down**.
- Zusätzlich: ein **Build/Management-Topdown** (oder sehr weit rausgezoomtes Iso) für Layout-Entscheidungen.

### 1.2 Flow, Wege, Engpässe (Management-Sims)
In **Two Point Hospital** ist dein Job explizit: Räume bauen, Amenities platzieren (Toiletten, Staff Room, Seating…), Personal einstellen/managen und mit Patient-Queues/Bewegung umgehen. citeturn0search32  
Der Two Point Hospital Wiki-Eintrag zu **Corridors** betont: Jede Tür muss mit einem Gang verbunden sein und es muss ein klarer Weg zwischen Türen existieren. citeturn0search22

**Takeaway für Duinn:**
- Plane deine Taverne wie ein „Flow-Diagramm“:
  - **Hot Path**: Entrance → Bar/Tische → Exit
  - **Staff Loop**: Küche/Pantry → Bar → Tische → Küche
- Engpässe sind das Hauptproblem. In Iso wirkt ein enger Durchgang doppelt schlimm.

### 1.3 Zonen/Logistik (Colony/Management)
RimWorlds **Stockpile priority** füllt zuerst High-Priority-Stockpiles; Hauler bewegen Items sogar um, um höhere Priorität zu bedienen. citeturn1search8turn1search11

**Takeaway für Duinn:**
- Baue echte **Zonen**:
  - Pantry/Storage (High priority)
  - Kitchen Prep (Medium)
  - Floor/General (Low)
- Dann kann Staff/AI später sehr gut „Theme Hospital“-mäßig funktionieren.

### 1.4 Tavern als zentraler Hub (genre-nah)
Travellers Rest beschreibt die Taverne als „player’s central hub“. citeturn1search12

**Takeaway für Duinn:**
- Die Welt soll klar signalisieren: *Hier ist der Hub, hier passieren alle Loops*.
- Expansion passiert modular (Anbau, neue Räume, Außenanlagen).

### 1.5 PSX/PS1-isometrische Umgebungen (Godot-spezifisch)
Eine aktuelle Thesis zu „PSX-Style Isometric Environments in Godot“ betont u. a. „Order“/Patterning im Environment-Design (Material/Shape Wiederholung), um Orientierung zu verbessern. citeturn0search1

**Takeaway für Duinn:**
- Arbeite mit **wiederkehrenden Formen** (z. B. Bar-Form, Türrahmen, Flurbreite) als Navigationshilfen.
- Der Look kann später kommen; aber die **Lesbarkeit** kommt jetzt.

---

## 2) World-Design: Functional Layout (was braucht die Welt, damit Features „wohnen“)

### Räume / Bereiche (Tier 1: Base Inn)
**Innen**
- Common Room (Tische + Bar)
- Kitchen (Prep + Stove/Ofen)
- Pantry/Storage (Zutaten & später Preservation)
- Stair + Upper Hallway
- 2–3 Guest Rooms (Placeholder)
- Ledger/Office Corner (Abrechnung / Management)

**Außen**
- Entrance + Yard
- Outhouse (Toilet/Janitor Tasks)
- 3 Garden Plots (Farming Hooks)
- Tower Base Spot (später Bird Range)
- Spawn/Exit Marker für Gäste

### Stations (alles, was UI öffnet, muss einen Ort haben)
- Drinks Station (Mix)
- Food Station (Küche/Serve)
- Service Bell (optional)
- Ledger Desk (EndNight)
- Shop/Build Board (Upgrades)
- Room Board (Zimmervergabe)
- Cleaning Station (Minigame Trigger)
- Garden Plots (Farming)
- Tower Window/Range Trigger (Shooting Minigame)

---

## 3) Implementationsplan in Godot (mit detaillierten To-dos)

## Phase A – Camera & Visibility (Iso + Cutaway + Build View)
**A1. Iso Camera Rig**
- [x] IsoCameraRig Szene erstellen (Pivot + Camera3D)
- [x] 2 Zoom-Stufen: Service (näher), Overview (weiter) (Implementiert in iso_camera.gd)
- [x] optional: 90° Rotation steps (Q/E)

**A2. Wall View Modes (Sims-like)**
- [x] 3 Modi:
  - Walls Up (alles sichtbar)
  - Cutaway (Wände zwischen Kamera und Player ausblenden/ausfaden)
  - Walls Down (alle Außenwände aus, Innenwände optional low)
- [x] Shortcut/Buttons: 1/2/3 (Implementiert in iso_camera.gd)

**A3. Cutaway Implementation**
- [x] Alle Außenwände in Group: `cutaway_wall`
- [x] CutawayController (Implementiert in iso_camera.gd):
  - [x] Raycast Camera→Player (multi-hit, far origin offset)
  - [x] Quadrant/Dot-Product Hiding (Beste Methode für Iso)
  - [x] Hide oder Fade die Treffer-Wände (per visiblity toggle)
- [x] Debug Toggle (F1): zeigt aktuell „cut“ walls (Implementiert in iso_camera.gd)

**DoD Phase A:** Player immer sichtbar; Innenraum immer lesbar. (Sims-Pattern) citeturn0search20turn0search31

---

## Phase B – Greybox Layout (Tier1 Base) + Navigation
**B1. Greybox (maßhaltig)**
- [x] Common Room Grundfläche setzen (20x20 skaliert)
- [x] Bar positionieren (mit Service-Stationen)
- [x] Kitchen als separater Raum mit Doorway (Enclosed)
- [x] Pantry als kleiner Raum nahe Küche (Enclosed)
- [x] Staircase + Upper hallway (Visual anchors)
- [x] NavMesh bake for Tier1 (NavigationRegion3D auto-bake)
- [x] Testlauf: SpawnOutside → Seat → Exit
- [x] Seating Design (Bar + Tables)
- [x] Clear lanes (Navigation zones defined)

**DoD Phase B:** 10 Gäste hintereinander ohne „stuck“, ohne chaotisches Stauen.

---

## Phase C – „Stations live in the world“ (Router statt Node-Name-Switch)
**Warum:** Skalierbarkeit. In Management-Sims wächst die Anzahl „Rooms/Stations“ schnell. citeturn0search32turn0search22

**C1. Station-Komponente**
- [x] `StationInteractable` Script (station_router handle)
- [x] StationRouter (Global Autoload)
- [x] Interaction System connected

**DoD Phase C:** Neue Station hinzufügen = Node platzieren + ID setzen (kein Code-Change).

---

## Phase D – Außenbereich + Facilities (Garden/Outhouse/Tower Hook)
**D1. Exterior Greybox**
- [x] Yard / Entrance / Exit / Spawn markers (Adjusted for 20x20)
- [x] Outhouse + Janitor task hook
- [x] 3 Garden plots (Farming StationInteractables)
- [x] Tower base spot + range trigger

**D2. Zonen für späteren Staff/Logistik (RimWorld-Pattern)**
- [x] Pantry Stockpile Zone (High)
- [x] Kitchen Prep Zone (Medium)
- [x] General Drop Zone (Low)

(Stockpile priority Konzept für künftiges Staff-Gameplay) citeturn1search8turn1search11

---

## Phase E – Modular Expansion (Tier2/Tier3) wie „Hub wächst“
**E1. InnTierManager**
- [x] `Tier1_Base` als eigene Scene (In `NavigationRegion3D`)
- [x] `Tier2_Addon` (Basement + Outhouse upgrade vorbereitet)
- [x] `Tier3_Addon` (Tower + extra rooms vorbereitet)
- [x] Load/Unload per Tier-Flag (InnTierManager)

**E2. Anchor Points (heute schon setzen)**
- [x] Trapdoor spot (Basement)
- [x] Stage spot (Theatre)
- [x] Door frame spot (Portal Door)
- [x] Extra Outhouse placeholders

**DoD Phase E:** Upgrade schaltet echte begehbare Bereiche frei (statt nur Zahlen).

---

## Phase F – World Polish (ohne finalen Artstyle)
**F1. Readability Props**
- [x] Signage: Bar / Kitchen / Rooms (visuelle Anker)
- [x] Lighting anchors: Hearth/fire spot, kitchen warm light, hallway dim

**F2. Debug-Tools**
- [x] Station debug: show station_id in Label3D (Standardmäßig an)

---

## Phase G – Basement & Logistics (Tier 2 Expansion)
**G1. Basement Interior**
- [x] Create `Basement_Base` node structure in `Tier2_Addons`
- [x] Implement floor -1 collision and mesh
- [x] Add lighting anchors (Cold, cellar-like)

**G2. Vertical Transition**
- [x] Connect Trapdoor to transition logic
- [x] Implement camera "snap" to basement level
- [x] Ensure NavMesh handles verticality

**G3. Expanded Logistics**
- [x] Move Pantry Stockpiles to Basement (Level 2 storage)
- [x] Add "Brewing Station" anchor (Station implemented)

**DoD Phase G:** Player can enter and leave the basement; basement is only active for Tier 2+.

---

## Phase H – Brewing & Advanced Logistics (Basement Tech)
- [x] Create `brewing_system.gd` (Timer/Selection based)
- [x] Implement Barrel Aging logic (Values increase over time / simulated)
- [x] Connect Brewing Station to `StationRouter`

**DoD Phase H:** Brewing processes run in the background; items can be produced.

---

## Phase I – Dumbwaiter & Logistics Flow (The "Lift")
**I1. Dumbwaiter (Speiseaufzug)**
- [x] Create `Dumbwaiter` node in `TavernPrototype.tscn`
- [x] Implement `transfer_item()` logic between Basement <-> Kitchen
- [x] Add visual "Ready-to-Serve" rack in the kitchen

**DoD Phase I:** Items can be moved between floors; Kitchen is the central pickup.

---

## Phase J – Entertainment & Ambience (Theatervene)
**J1. The Stage (Theatervene)**
- [x] Implement `performing` state for NPCs (WATCHING state in guests)
- [x] Add `PerformanceSystem` (Reputation triggers)
- [x] Create "Performance Station" at the `StageAnchor`

**J2. Popularity System**
- [x] Performances boost global `reputation`/`popularity`
- [x] Add guest reaction emojis (🎵, 👏) während der Show

**DoD Phase J:** Stage is interactive; Performances provide passive progression.

---

## Phase K – Room Rental (Tier 3 Preparation)
**K1. Room Rental**
- [x] Define `Room` nodes in `Tier3_Addons`
- [x] Implement `RoomManager` (Track occupancy and income)
- [x] Add "Rent Room" dialog branch for guests
- [x] NPCs "Disappear" into rooms at night
- [x] Payout at `DayGenerator` cycle start

**DoD Phase K:** Rooms can be rented; nightly income is generated.

---

## Phase L – Final Polish & "Juice"
**L1. UI & Feedback (Wow Factor)**
- [x] Implement Tween-based micro-animations for Emojis
- [x] Add Floating Gold Popups
- [x] AudioManager (Sound placeholders)

**L2. Balancing & Progression**
- [x] Tune patience decay based on reputation (+5% per 100 Rep)

**DoD Phase L:** Feedback system is juicy; Reputation scales difficulty.

---

## Phase M – The Portal (Tier 4 Expansion)
**M1. Portal Logic**
- [ ] Implement `PortalManager` (Activation conditions)
- [ ] Add visual effects (Particle placeholders) for the `PortalAnchor`
- [ ] Unique "Portal Events" (Random magic loot / special visitors)

**M2. Rare Guests**
- [ ] Define "Inter-dimensional" guest archetypes in `guests.json`
- [ ] Implement unique requirements (Strange items from the portal)

---

## 4) Abnahmetests (Praktisch)
- [x] 20 Nächte autoplay – keine stuck NPCs (NavMesh verifiziert)
- [x] Toggle Walls Up/Cutaway/Down in jeder Position
- [x] Stations: jedes UI nur über World-Station erreichbar
- [x] Expansion toggles: Tier1→Tier2→Tier3 ohne kaputte Collision/Navmesh

---

## 5) Empfohlene Reihenfolge (wenn du direkt loslegen willst)
1) Phase A (Iso + Wall modes)  
2) Phase B (Tier1 Greybox + Nav + Seating)  
3) Phase C (StationRouter + Migration)  
4) Phase D (Exterior + Garden/Outhouse/Tower hooks)  
5) Phase E (Tier Add-ons + anchor points)  
6) Phase F (Readability + Debug)
7) Phase G (Basement & Logistics)
8) Phase H (Brewing & Advanced Logistics)
9) Phase I (Dumbwaiter & Logistics)
10) Phase J (Entertainment & Ambience)
11) Phase K (Room Rental)
12) Phase L (Final Polish)
13) Phase M (The Portal)

---

## Quellen (aus der Recherche)
- Sims 4 Build Mode Lessons: Walls Cutaway + Top-Down Build View citeturn0search20  
- Project Zomboid Build Status: „Sims-style cutaway vision system“ citeturn0search31  
- Two Point Hospital Gameplay (Rooms, Amenities, Hiring, Queue/Movement) citeturn0search32  
- Two Point Hospital Wiki: Corridor connectivity requirement citeturn0search22  
- RimWorld Wiki + Ludeon Forum: Stockpile priority behavior citeturn1search8turn1search11  
- Travellers Rest Wiki: Tavern as central hub citeturn1search12  
- PSX-style isometric environments in Godot thesis (patterns/order for navigation) citeturn0search1
