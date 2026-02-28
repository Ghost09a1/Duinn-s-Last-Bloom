# Arbeitsplan: Game-World „Duinn’s Last Bloom“ – Orte/Flächen/Items für bestehende Features (TWI-inspiriert)

**Ziel:** Deine Features (VA-11 Loop + Shop + Abrechnung + Upgrades + später Management/Minigames) bekommen **echte Orte, Flächen, Stationen und Wege** in der Spielwelt, so dass sich das Inn **wie im Roman** (Wandering Inn) „anfühlt“ und **modular** wachsen kann.

> Hinweis: TWI ist riesig (viele Millionen Wörter). Statt „alles“ zu lesen, basiert dieser Plan auf den **konkret beschriebenen Inn-Details** aus Kapitel **1.00** sowie **späteren Inn-Upgrades** (Tower/zusätzliche Floors/Outhouses), plus den **Wiki-Zusammenfassungen** zu Inn-Iterationen, Staff-Rollen und Notable Properties.  
> Wichtige Textstellen:
> - Common Room + Bar + Treppe + Küche in 1.00 citeturn1view0turn3view2turn3view0  
> - Kitchen (Steinofen, Backofen/Chimney, Schränke) citeturn3view0  
> - Creaky stairs / upper corridor / guest rooms citeturn3view1turn1view1  
> - Inn-Upgrades: größerer Ground Floor, 3rd floor, Tower, 2 neue Outhouses citeturn5view0  
> - 1 Outhouse + 9 private rooms (Lyonette Beobachtung), Trapdoor-Basement citeturn5view2  
> - Basement + Outhouse + Tower/2nd floor in Inn-Historie citeturn2view2turn2view3turn1view2  
> - Notable Properties: Magical Door, Field of Preservation, Grand Theatre, Garden etc. citeturn2view4turn2view0turn1view3  
> - Staff-Rollen (Inn Manager, Head Waiter, Chef, Door Attendant, Plants Waterer, Guards) citeturn2view1turn2view4  
> - Schicht-Alltag: Tables bedienen + Outhouse reinigen citeturn5view3  

---

## 0) Output / Deliverables (was am Ende „fertig“ ist)

- 1 spielbarer **Inn-Lot** (Innen + kleines Außen) mit:
  - **Common Room** (Tische, Bar, Treppe)
  - **Küche** (Herd/Ofen/Prep)
  - **Zimmer-Flur + 2–3 Zimmer** (zunächst Platzhalter; später 9+)
  - **Outhouse** draußen
  - **Basement Trapdoor** (zunächst gesperrt oder leer)
- Alle bestehenden Systeme sind an **Stations** gebunden:
  - Mix/Serve/Reaction an der Bar / Tisch-Service
  - Shop-Upgrades an „Shop/Procurement“-Ort
  - Abrechnung am Ledger/Desk + EndNight Screen
- **Navigation/Seating**: Gäste finden Sitze, laufen zur Bar/zu Tischen, verlassen das Gebäude
- **Isometrische Kamera** + **Cutaway Walls** (vordere Wände ausblenden/ausfaden)

---

## 1) World-Bible: Inn-Layout nach Vorlage (als modulare Baupläne)

### 1.1 Tier 1: „Abandoned Inn“ (Kapitel 1.00 Feeling)
**Common Room (Ground Floor)**
- großer zentraler Raum
- Tische/Stühle (verstaubt), Bar an einer Wand, Treppe nach oben, Raum/Tür zur Küche citeturn1view0turn3view2  
- shuttered windows ohne Glas, keine Deckenbeleuchtung citeturn1view0  

**Küche**
- counters mit integrierten cutting boards, cupboards, stone stove mit Fire-Hatch, großer Backofen mit Chimney; erste Utensilien (Topf, Gusseisenpfanne, rostige Kelle) citeturn3view0  

**Upper Floor**
- dunkles Treppenhaus, knarzende Stufen; oben Flur mit Gästezimmern citeturn3view1turn1view1  

### 1.2 Tier 2: „Operational Inn“ (Outhouse + Basement + mehr Zimmer)
- 1 Outhouse, ca. 9 private rooms (später skalieren) citeturn5view2turn1view2  
- Trapdoor zum Basement wird entdeckt; Basement groß genug für Vorräte/Party citeturn2view2turn5view2  

### 1.3 Tier 3: „Expanded Inn“ (Tower + Third Floor + mehr Outhouses)
- Ground Floor ~ ein Drittel größer, 2 neue Rooms im 2. Stock, kompletter 3. Stock, Tower mit offenem Dach + gutters citeturn5view0  
- 2 neue Outhouses citeturn5view0turn2view2  

### 1.4 Tier 4+: „Magical/Hub Inn“ (später)
- Magical Door, Field of Preservation, Grand Theatre, Garden of Sanctuary citeturn2view4turn1view3  

---

## 2) Phase A: Isometrisches Grundgerüst + Cutaway Walls

### A1 – Isometrische Kamera
- [ ] Kamera-Rig erstellen (Yaw 45°, Pitch 30–40°, Perspective-FOV moderat)
- [ ] 2 Zoom-Stufen: Overview (Management) / Service Zoom (Dialog & Bar)
- [ ] Kamera-Kollisions-Check (nicht durch Wände clippen)

### A2 – Cutaway Walls (vordere Wände ausblenden)
- [ ] Alle Außenwände in Gruppen taggen (z. B. `Wall_Cutaway`)
- [ ] „Player-Behind“-Test: wenn Player im Raum ist und Wand die Kamera blockt → hide/fade
- [ ] 2 Modi:
  - Hard Hide (Mesh off)
  - Smooth Fade (Material Alpha)
- [ ] Debug-Visual: welche Wände werden gerade ausgeblendet?

**Done:** Player ist immer sichtbar, Innenraum immer lesbar.

---

## 3) Phase B: Blockout Tier 1 (Common Room + Küche + Treppe + Flur)

### B1 – Common Room (Ground Floor)
- [ ] Raumform + Maße festlegen (großer zentraler Raum)
- [ ] Bar gegen eine Wand setzen citeturn3view2  
- [ ] Treppe nach oben citeturn3view1  
- [ ] Tür/Öffnung zur Küche direkt bei der Bar citeturn3view2turn3view0  
- [ ] Fenster mit Shutters (ohne Glas) citeturn1view0  
- [ ] Keine Deckenlampen (Licht später) citeturn1view0  
- [ ] Collisions + Navigation

### B2 – Küche (Nebenraum)
- [ ] Counter + cutting boards + cupboards
- [ ] Stone Stove + Baker’s Oven + Chimney citeturn3view0  
- [ ] Utensilien (Pot, Pan, Ladle) citeturn3view0  
- [ ] Küchen-Navigation

### B3 – Upper Floor
- [ ] Flur-Blockout
- [ ] 2–3 Zimmer (placeholder; später ~9) citeturn5view2  
- [ ] Treppenhaus-Layout citeturn3view1  

**Done:** begehbarer Rundgang + saubere Kamera.

---

## 4) Phase C: Feature→Ort Mapping (Stations)

### C1 – Stations (interaktive Hotspots)
**Bar / Service**
- [ ] `Bar_MixStation` (Mix-Minispiel)
- [ ] `Table_ServiceZones` (Area pro Tisch)

**Management / Meta**
- [ ] `Ledger_Desk` (DayEnd Trigger)
- [ ] `Shop_NoticeBoard` (Upgrades kaufen)
- [ ] `Debt_Notice` (Miete/Schulden sichtbar)

**Rooms**
- [ ] `Room_AssignmentBoard` (H2: Zimmervergabe UI)

**Kitchen**
- [ ] `Kitchen_PrepStation`
- [ ] `Pantry_PreservationShelf` (VFX Hook) citeturn1view1turn2view4  

**Cleaning**
- [ ] `Cleaning_Closet`
- [ ] `DirtySpot_Spawner`

### C2 – Seating & Routing
- [ ] SeatSlots (Bar + Tische)
- [ ] Guest Path: SpawnOutside → Entrance → Seat → Exit
- [ ] Staff Path: Kitchen ↔ Bar ↔ Storage

**Done:** Jede UI hat einen World-Trigger.

---

## 5) Phase D: Außenbereich Tier 2 (Outhouse + Hof)

- [ ] Vorplatz + Weg Richtung „Liscor“
- [ ] 1 Outhouse (Tier 2) citeturn5view2turn2view2  
- [ ] Platzhalter für 2 weitere Outhouses (Tier 3) citeturn5view0turn2view2  
- [ ] `RuleSign` am Eingang (später Rule Board) citeturn2view4  
- [ ] `Outhouse_CleanTask` Hook (Management)

---

## 6) Phase E: Basement (Tier 2) + Trapdoor

- [ ] Trapdoor im Common Room platzieren citeturn5view2  
- [ ] Basement-Raum (Lager + „Adventure Corner“) citeturn2view2  
- [ ] Storage-Racks + Capacity placeholder
- [ ] Navmesh + Licht minimal

---

## 7) Phase F: Staff/Theme-Hospital-Management – Welt-Hooks

- [ ] `Staff_RosterBoard` (Schichtplan/Einstellen placeholder)
- [ ] `Staff_BreakCorner`
- [ ] Task Sources:
  - Serve (Bar/Tables)
  - Cook (Kitchen)
  - Clean (Common/Kitchen/Outhouse)
  - Security (Entrance/Tower später)
  - Plants (Garden später) citeturn2view1  
- [ ] Sichtbare Routine-Tasks (z. B. „Ishkr holt Wasser/putzt Outhouse“) als Platzhalter-AI citeturn5view3  

---

## 8) Phase G: Tier 3 Add-ons (3rd Floor + Tower)

- [ ] `InnTierManager` (lädt Add-on-Scenes)
- [ ] Tower-Geometry + stairs + open roof + gutters citeturn5view0  
- [ ] `Tower_RangeTrigger` (Bird’s Range Minigame später)
- [ ] `Tower_SecurityPost`

---

## 9) Phase H: Magical Facilities als Platzhalter (Garden/Door/Theatre/Preservation)

- [ ] `PortalDoor_Frame` + `ManaStone_Sockets` placeholder citeturn2view4  
- [ ] 3–5 Garden-Door Spawnpoints im Inn citeturn2view4turn1view3  
- [ ] Stage-Spot + Expand trigger (Grand Theatre) citeturn2view4  
- [ ] Preservation VFX Hook (Pantry) citeturn2view4turn1view1  

---

## 10) QA Checklist

- [ ] Cutaway: Player nie verdeckt
- [ ] Gäste: spawn → seat → served → exit ohne stuck
- [ ] Navmesh: Küche/Treppe/Flur ok
- [ ] Stations: alle Features haben Orte
- [ ] Tier-Toggle: keine doppelten Colliders

---

## 11) Kompakter Wochenplan

### Woche 1 – Lesbarkeit + Blockout
- [ ] Isometric camera + 2 zoom levels
- [ ] Cutaway walls
- [ ] Tier 1 blockout: common room + kitchen + stairs + 2 rooms
- [ ] Navmesh + collisions

### Woche 2 – Stations + Routing
- [ ] Bar station + table zones + ledger + shop board + debt notice
- [ ] Seating + routing + exit
- [ ] Exterior: outhouse + rule sign
- [ ] Basement trapdoor + placeholder basement

### Woche 3 – Management Hooks + Tier Modules
- [ ] Staff workstations + roster board placeholder
- [ ] InnTierManager + Tier2/Tier3 add-ons
- [ ] Tower placeholder + range trigger

### Woche 4 – Magical Placeholders + Validator
- [ ] Portal door frame + sockets
- [ ] Garden spawnpoints + empty garden scene
- [ ] Stage spot placeholder
- [ ] World validator (missing stations / missing nav areas)

---

## Nächster Schritt (sofort)
**Phase A + B**: Kamera/Cutaway + Tier1-Blockout.  
Wenn das sitzt, sind H1–H4-Content/Events später extrem leicht „andockbar“.
