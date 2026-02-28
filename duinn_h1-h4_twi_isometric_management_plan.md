# Duinn’s Last Bloom – H1–H4 Detailplan (TWI-inspiriert, isometrisch, Management-first)

**Kontext / Leitstern:** *The Wandering Inn* startet damit, dass Erin ein verlassenes Inn findet, es **sauber macht** und dadurch **[Innkeeper]** wird; sie bekommt u. a. **Basic Cleaning** und **Basic Cooking**. Das ist ein perfektes Vorbild für „Inn wächst durch Arbeit + Events + Leute“.  
*(Story/Art später – wir bauen jetzt System-Fundament + Loops, die Story später „füllen“ kann.)*

---

## A) Inn-Progression wie im Roman (als System, nicht als Plot)

### Progression-Tiers (Vorschlag)
1. **Abandoned / Survival**
   - Kernloop: reinigen, essen machen, 1–2 Gäste
   - „Innkeeper XP“ kommt vor allem aus *Arbeit* (clean/cook/host)
2. **Open Inn**
   - stabile Öffnungszeiten, kleines Menü, 3–4 Gäste
3. **Staffed Inn**
   - 1–3 Mitarbeitende übernehmen Teilaufgaben (Service/Küche/Reinigung)
4. **Known Hub**
   - Events, Bühne, Spezialgäste, Reputation/Fraktionen
5. **Magical/Unique Inn** (später)
   - Garden/Portal-Door/Theatre/Preservation als Endgame-Systeme

**Gate-Regeln:** Tier-Aufstieg nur über **(a) Reputation**, **(b) Geld/Material**, **(c) Story-Flags**.

---

## B) Kamera / Perspektive (isometrisch, PS1/PSOne-Look bleibt möglich)

### Kamera-Rig
- **Isometrisch (Perspective)** statt Orthographic, damit PS1-Look später leichter wirkt:
  - Yaw: 45°
  - Pitch: 30–40°
  - FOV eher klein (z. B. 30–45)
- **Zoom-Stufen**:
  - `Overview` (Management)
  - `Service Zoom` (für Dialog/Servieren nah genug)
- Optional: 4 feste Kamera-Winkel (PS1-feeling) + isometrische Grundausrichtung

---

# H1 – Data-driven Content + Night-Generator (Seed, reproduzierbar)

## Ziel
Alles Content-lastige ist Daten:
- Items
- Rezepte
- Gäste (Archetypen + Named NPCs)
- Events (Tages-/Story-Events)
- Minigames (welche Scene, welche Parameter)
- Nights/DaySchedule

Und jede Nacht ist über **Seed** reproduzierbar.

---

## H1.1 Daten-Dateien (Minimal)
```text
data/
  items.json
  recipes.json
  guests/
    archetypes.json
    named_npcs.json
  staff_roles.json
  events.json
  day_generator_rules.json
```

### items.json
- id, label, tags[], base_price
- tags: drink/food/warm/cold/alcohol/sweet/bitter/cheap/fancy

### recipes.json
- id, units{}, flags{ice,aged,blended}, tags[], base_value
- optional: size_thresholds (für small/big)

### guests_archetypes.json
- id, tags[], request (literal + intent_tags), size_pref, likes/dislikes, spawn_weight
- optional: “service_style” (talk-heavy / order-heavy)

### named_npcs.json
- id, name, portrait (placeholder), memory_keys, unique_traits
- spawn_rules: min_day, prerequisites, cooldown, weight

### staff_roles.json
- role_id, display_name, tasks[], default_wage, unlock_tier
- tasks: serve, cook, clean, manage, account, security, garden, door, build, stage

### events.json
- id, type: day_event | story_event | facility_event
- trigger:
  - day_range
  - prerequisites (flags/rep/tier)
  - weight, cooldown_days
- payload:
  - guest_modifiers
  - item_lockouts (knappheit)
  - minigame_to_run (id + context)
  - flags to set

---

## H1.2 Night/Day Generator (Seeded)
### Algorithmus (einfach & robust)
1. `rng = RNG(seed = day_index + global_seed)`
2. Ziehe 0–1 **Event** (weighted, prüfe prerequisites + cooldown)
3. Bestimme **guest_count** (Basis + Upgrades + Event-Mods)
4. Ziehe Gäste (weighted), mit Constraints:
   - keine doppelten IDs in der Nacht
   - „avoid same tag 3x“ (z. B. nicht 3× guard)
5. Erzeuge `DayPlan`:
   - seed
   - event_id
   - guest_sequence
   - optional: minigame_queue

### Debug-Requirements
- HUD zeigt: seed, event, guest IDs
- „Reroll“ nur im Debug (ändert seed), normal ist deterministisch

---

## H1.3 Content Validator (schon in H1 starten!)
Beim Boot:
- doppelte IDs
- fehlende recipe refs
- fehlende dialog roots
- unknown tags
- weight <= 0
- event prerequisites referenzieren existierende flags/rep

---

# H2 – Inn-Signature-Mechanik (minimal): Zimmervergabe

## Ziel
**Zimmer** machen dein Spiel „Inn“ (nicht nur Bar).

### Datenmodell
- `Room`:
  - id, tier (basic/good), cleanliness, comfort, occupancy_state
- `Guest`:
  - wants_room (bool)
  - room_pref (tier/quiet/near_fire)
  - risk (troublemaker? valuables?)

### Gameplay-Loop Zimmer (pro Nacht)
1. Am Abend kommen 0–2 Gäste mit Zimmerwunsch
2. Du weist Zimmer zu (oder lehnst ab)
3. Konsequenz:
   - Geld + Zufriedenheit
   - Memory-Flag beim Named NPC
   - nächste Nacht: Bonusdialog / special request / Gerücht

### „Minigame“-Form (minimal)
- UI-Puzzle: 2 Zimmer, 3 Bewerber → du wählst
- Zusatzregeln (später): Zimmer muss sauber sein; sonst „Cleaning Task“ erzeugen

### Warum es TWI-feels gibt
TWI ist stark darin, dass “wer bleiben darf” echte Konsequenzen hat.  
Zimmervergabe ist exakt das – ohne Storytext zu brauchen.

---

# H3 – Wiederkehrende Gäste + Memory-Flags

## Ziel
Die Welt merkt sich dich.

### Minimaler Memory-Satz
Pro Named NPC:
- `met`
- `last_night_outcome` (perfect/ok/bad)
- `given_room` (true/false)
- `favorite_tag` (optional)
- `grudge` (0..N)

### Was Memory sofort bewirkt (ohne Story)
- Intro-Zeile variiert
- 1 zusätzlicher Branch freigeschaltet/gesperrt
- Spawnweight leicht hoch/runter
- kann Event triggern (“kommt mit Freund”, “beschwert sich”, “bringt Gerücht”)

### Persistenz
- Save minimal: day_index, global_seed, flags{}, rep{}, npc_memory{}

---

# H4 – Balancing Harness (Validator + Economy Sanity)

## Ziel
Du kannst 100 Nächte simulieren/testen, ohne manuell alles zu spielen.

### H4.1 Economy-Sanity (Formel fixieren)
Empfohlene Reihenfolge:
1) `base_total = sum(base_drink_gold)`
2) `bonus_total = perfect_bonus + big_bonus + size_bonus`
3) `tip_total = (base_total + bonus_total) * tip_multiplier`
4) `tip_total *= debt_malus`
5) `final_total = base_total + bonus_total + tip_total`

Checks:
- `tip_multiplier` clamp (z. B. 0..3)
- `final_total` nie negativ
- debt_malus greift immer (auch bei flawless)

### H4.2 Test-Runs (Seed Sweep)
- Run 1..N Seeds:
  - logge event-frequency
  - average gold/night
  - perfect rate
  - big-drink rate
  - room-assign profit (ab H2)
- Export als JSON/CSV

### H4.3 Content QA
- „golden seeds“: 10 Seeds, die du als Regressionstest nutzt
- wenn sich Werte stark ändern, bewusst (Balance Patch Notes)

---

# C) Jobs / Rollen (TWI-inspiriert, für Theme-Hospital-ähnliches Management)

> In **1.00** bekommt Erin durch Cleaning/Cooking die Innkeeper-Klasse (Basic Cleaning/Cooking). Das ist dein Early-Game.  
> Später skaliert TWI das Inn über echte Rollen im Betrieb.

## Kernrollen (für dein Management)
Front-of-house:
- Innkeeper
- Inn Manager
- Head Waiter
- Waiter/Waitress/Server
- Barmaid/Bartender/Barkeep

Back-of-house:
- Cook/Chef
- Dishwasher
- Cleaner/Janitor

Operations:
- Accountant
- Floor Boss / Shift Lead
- Builders/Laborers (für Ausbau/Repair)

Security:
- Guard / Head of Security
- Bouncer

Special Facilities (für spätere Loops):
- Plants Waterer (Garden/Farming)
- Magical Door Attendant / Door-Operator
- Stage Manager / Singing Instructor (Events/Performance)

---

# D) Events & Aktivitäten → als Game Loops / Minigames

## 1) Cleaning & Repair (Roman-Startgefühl)
- Trigger: Start-Tier „Abandoned“, nach Kämpfen, nach Event „Sturm“
- Minigame: „clean zones“ (Wischpuzzle / Timing / Routing)
- Output: cleanliness↑, rep↑, unlocks (Basic Cleaning)

## 2) Cooking / Menu Expansion
- Trigger: neue Zutaten, neue Köche, Event „Karawane“
- Minigame: Rezept-Puzzle (dein bestehendes Mix-System kann 1:1 als Kochsystem dienen)

## 3) Garden → Farming Sim
- Facility: Garden door / Garden area
- Minigame: Pflanzen, wässern, ernten (Staff role „Plants Waterer“)
- Output: ingredients, buffs (z. B. bessere Tips), rare plants

## 4) Bird’s Tower → Shooting Range
- Facility: Tower/Range
- Minigame: Zielscheiben, Wind, moving targets (short sessions)
- Output: trophies, security bonus, special items (feathers etc.)

## 5) Grand Theatre / Bühne
- Facility: Stage/Theatre
- Minigame: Event-Hosting (Sitzordnung, Ticketing, Crowd mood)
- Output: big profit nights, reputation spikes, unique guest spawns

## 6) Portal Door Logistics (später)
- Facility: Door
- Minigame: routing + inspection (smuggling risk, mana cost)
- Output: neue Gäste, supply chain, danger events

---

# E) Implementations-Reihenfolge (empfohlen)

1. **H1**: JSON Loader + Seeded DayPlan + Validator (stabil, debugbar)
2. **H2**: Zimmer-System minimal (2 Zimmer, UI-Assign)
3. **H3**: Named NPC Memory + Spawnweight modifiers
4. **H4**: Simulation Runner + Economy sanity + golden seeds
5. Danach: erstes Facility-Minispiel (Garden ODER Tower – nur eins)

---

## Nächster konkreter Schritt (Start H1)
- `items.json` & `recipes.json` auslagern und im Spiel laden
- DayPlan-Generator bauen (seed, event, guests)
- Debug-HUD: seed + guest list anzeigen
- Boot-Validator: IDs/Refs prüfen
