# Horizontale Erweiterung – Inn-Prototyp (v0.2 → v0.4)

## Was „horizontale Erweiterung“ hier bedeutet
**Horizontal** = mehr **Breite / Vielfalt / Replayability**, ohne neue große Kernmechaniken zu erfinden.  
Du nimmst die bestehende Loop (Tag startet → Gäste → reden/servieren → Tagesabschluss) und machst sie:
- abwechslungsreicher,
- besser skalierbar (Content-Pipeline),
- testbarer (Debug + deterministische Runs),
- bereit für späteren Story-/Art-Ausbau.

---

# 1) Zielbild für die nächste Stufe

## Ziel (v0.4)
- **15–25 Gast-Archetypen** (data-driven)
- **10–20 Night-Varianten** (oder ein Night-Generator mit Regeln)
- **8–12 Items** (Drinks/Food/„Nothing“)
- **8–12 Event-Modifikatoren** (z. B. „Sturm“, „VIP“, „Knappheit“)
- **3–5 Faction/Tags**, die Spawn + Dialog leicht beeinflussen
- **Reproduzierbarkeit:** jede Nacht hat einen **Seed** (für Debug & Balancing)

## Ergebnis:  
Du kannst 30–60 Minuten testen, ohne dass sich Nächte gleich anfühlen – **ohne** Storykapitel zu schreiben.

---

# 2) Grundprinzipien (damit es nicht explodiert)

## 2.1 80/20-Regel für Content
Jeder neue Gast bekommt nur:
- 1 Wunsch (Item oder Kategorie)
- 1 „Quirk“ (z. B. ungeduldig / redselig / misstrauisch)
- 1 kleiner Branch (eine Entscheidung)
- 1–2 Tags (Faction/Role)

Mehr erst später.

## 2.2 Keine neuen großen Systeme
Kein Inventar, kein Crafting-Tree, kein Housing – nur:
- **Varianten** innerhalb der bestehenden Systeme.

## 2.3 Data-driven first
Alles, was Content ist, kommt aus Daten (JSON/Resources):
- Gäste
- Dialoge
- Nächte
- Events
- Items

---

# 3) Content-Pipeline (die wichtigste horizontale Erweiterung)

## 3.1 Empfohlene Datenordner
```text
res://data/
  items/items.json
  guests/*.json
  dialogs/*.json
  events/*.json
  nights/*.json   (oder generator_rules.json)
  factions/factions.json
```

## 3.2 Minimal-Schemas (Startversion)

### items.json
```json
{
  "items": [
    {"id":"ale", "label":"Ale", "tags":["drink","alcohol"]},
    {"id":"water", "label":"Water", "tags":["drink"]},
    {"id":"stew", "label":"Stew", "tags":["food","warm"]}
  ]
}
```

### guest.json
```json
{
  "id": "merchant_01",
  "name": "Merchant",
  "tags": ["merchant","civilian"],
  "request": {"type":"item", "id":"stew"},
  "quirk": {"id":"chatty", "value": 1},
  "dialog_root": "merchant_intro",
  "likes": ["warm","food"],
  "dislikes": ["alcohol"],
  "spawn_weight": 1.0
}
```

### event.json
```json
{
  "id": "storm_night",
  "label": "Storm outside",
  "effects": [
    {"type":"modify_patience_all", "delta": -1},
    {"type":"add_spawn_tag", "tag":"soaked"}
  ]
}
```

### night.json (fixe Night)
```json
{
  "id":"night_01",
  "seed": 12345,
  "event_id": "storm_night",
  "guest_sequence": ["merchant_01","guard_01","traveler_01"]
}
```

### night generator rules (alternative)
```json
{
  "guest_count": 3,
  "allowed_tags": ["merchant","guard","traveler","civilian"],
  "avoid_same_tag_in_row": true,
  "event_chance": 0.5
}
```

---

# 4) Horizontale Systeme (klein, aber wirkungsvoll)

## 4.1 Night-Generator (statt feste Liste)
**Warum:** Du brauchst nicht 50 handgeschriebene Nächte.

### Minimal-Generator-Features
- wählt 3 Gäste aus Pool (weighted)
- optional 0–1 Event-Modifikator
- Regeln:
  - nicht zweimal exakt gleichen Gast hintereinander
  - nicht 3× gleiche Rolle (z. B. 3× guard)
  - optional: 1 „spicy slot“ (seltene Gäste)

### Debug
- zeige Seed + gewählte Gäste im HUD
- „Reroll“-Button im Debug-Menü

---

## 4.2 Tags/Factions (leichte Meta-Varianz)
Nicht „Story-Fraktionen“, sondern **Tags**, die etwas bewirken.

### Beispiel-Tags
- roles: `merchant`, `guard`, `traveler`, `healer`, `bard`
- factions: `city`, `guild`, `outsider`
- mood: `anxious`, `drunk`, `soaked`

### Minimal-Effekt
- Spawngewicht abhängig von `reputation_city`, `reputation_guild`, etc.
- Dialogzeile ändert sich bei `flag` oder `rep >= threshold`

---

## 4.3 Preferences statt komplexer Rezepte
Du hast Items – mach daraus Variation:

- Gast wünscht „Stew“, aber eigentlich mag er „warm food“ (Kategorie)
- falsches Item kann trotzdem „okay“ sein, wenn es Tags matcht

**Regelvorschlag:**
- exakter Treffer: +2
- Tag-Treffer (Kategorie): +1
- neutral: 0
- disliked: -1 oder -2

Damit gewinnt das System Tiefe, ohne neue Features.

---

## 4.4 Wiederkehrender Gast (super effizient)
Einfacher Memory-State:
- `met_guest_<id>`
- `served_correct_<id>`
- `insulted_<id>` (optional)

Effekt:
- 1 neue Zeile im Intro
- 1 kleiner Branch wird freigeschaltet/gesperrt

Das erzeugt sofort „Welt lebt“.

---

# 5) Content-Plan (was du konkret baust)

## 5.1 Gast-Archetypen-Set (Start: 12)
Baue 12 Gäste mit klaren Unterschieden:
- 3× „neutral / easy“
- 3× „impatient / time pressure“
- 3× „chatty / choice-heavy“
- 3× „picky / preferences matter“

### Beispielliste
- Merchant (chatty)
- Guard (strict)
- Traveler (tired)
- Healer (observant)
- Bard (chaotic)
- Scholar (picky)
- Farmer (simple)
- Courier (hasty)
- Smuggler (secretive)
- Noble incognito (testy)
- Mercenary (blunt)
- Refugee (anxious)

> Kein Storyroman nötig – nur 10–20 Zeilen + 1 Branch.

---

## 5.2 Events (Start: 8)
Events sind Multiplikatoren für Abwechslung.

Beispiele:
- **Storm Night**: Patience sinkt schneller
- **Festival**: mehr Trinkwünsche
- **Short Supplies**: 1 Item ist gesperrt
- **VIP Visit**: 1 Gast hat doppelte Auswirkung
- **Brawl Risk**: falsches Serving triggert Konflikttext
- **Late Caravan**: Gäste kommen schneller hintereinander
- **Rumor Wave**: mehr Dialog statt Service
- **Quiet Night**: weniger Gäste, aber mehr Branch

---

## 5.3 Items (Start: 8)
- water
- ale
- stew
- bread
- tea
- soup
- cheap_wine
- nothing

Tags sorgfältig setzen (`warm`, `alcohol`, `food`, `cheap`, `fancy`).

---

# 6) Implementations-Reihenfolge (sichere Reihenfolge)

## Sprint H1 – Generator + Datenstruktur
- [ ] Items aus Datei laden
- [ ] Gäste aus Datei laden
- [ ] Events aus Datei laden
- [ ] Night-Generator mit Seed
- [ ] Debug-HUD zeigt Seed + Auswahl

**Done:** Du kannst per Seed exakt reproduzieren, welche Gäste/Events kommen.

---

## Sprint H2 – 12 Gäste + 8 Events + 8 Items
- [ ] 12 Gäste-Datensätze
- [ ] 8 Events
- [ ] Item-Tagging + preference scoring
- [ ] Tagesreport zeigt: Event, Gäste, Trefferquote, Trust/Mood

**Done:** Nächte fühlen sich unterschiedlich an.

---

## Sprint H3 – Wiederkehr + leichte Progression
- [ ] wiederkehrender Gast (Flags)
- [ ] reputation (1–3 Werte) beeinflusst Spawnweight
- [ ] 1–2 Gäste „unlock“ ab Reputation

**Done:** Deine Handlungen verändern zukünftige Nächte.

---

## Sprint H4 – Stabilität & Balancing
- [ ] Edge cases fixen
- [ ] Generator-Regeln feinjustieren
- [ ] Tuning: patience, scoring, event intensity
- [ ] 10 Runs testen, Notizen machen

**Done:** Du hast ein robustes Testbett für Story/Art später.

---

# 7) Debug & Tools (empfohlen)

## 7.1 Debug-Menü (F1)
- aktuelle Nacht: seed, event
- aktiver Gast: id, request, patience, mood, likes/dislikes
- Buttons:
  - reroll night
  - skip guest
  - force event
  - force guest

## 7.2 Content-Validator (beim Start)
- prüft: doppelte IDs, fehlende Items, fehlende Dialog Roots
- meldet Fehler klar in Konsole + optional UI

Das spart dir später Tage.

---

# 8) “Definition of Done” für horizontale Erweiterung
Du bist fertig mit der horizontalen Ausbaustufe, wenn:

- du 10 Nächte am Stück spielen kannst
- du pro Nacht mindestens 1 Variation spürst (anderer Gast/anderes Event/andere Wünsche)
- du per Seed eine Nacht exakt reproduzieren kannst
- dein Tagesreport genug Infos liefert, um Balancing zu machen

---

# 9) Nächster Schritt (konkret, heute)
**Empfehlung:** Sprint H1 starten.

1. `items.json` laden + im Service-Menü anzeigen
2. `guests/*.json` laden
3. `events.json` laden
4. Night-Generator: pick 3 guests + optional event
5. Seed im HUD anzeigen

Wenn du willst, kann ich dir als nächstes:
- ein konkretes JSON-Schema + Beispiel-Datensätze (12 Gäste, 8 Events, 8 Items) schreiben, oder
- dir eine “Generator-Regel-Logik” (weighted + constraints) sauber formulieren.
