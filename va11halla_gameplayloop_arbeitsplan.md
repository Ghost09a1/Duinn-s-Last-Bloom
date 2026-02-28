# VA-11 HALL-A Gameplay Loop – Arbeitsplan zum Nachbauen (mechanisch, ohne Story)

> Ziel: Die **Spielschleife** von *VA-11 HALL-A* so zerlegen, dass du sie als **Systeme + Screens + Datenfluss** in deinem Inn-Prototyp nachbauen kannst.  
> Fokus: **Ablauf + Mechanik + Konsequenzen**, nicht Text/Story.

Quellenhinweise zu Mechanikdetails (Ingredienzen, Mix-Regeln, Meta-Mechaniken) sind am Ende verlinkt.  
(Alle Beschreibungen hier sind **paraphrasiert**, keine wörtlichen Spieltexte.)

---

## 0) High-Level Loop (Makro-Schleife „Tag“)

VA-11 HALL-A wiederholt im Kern einen **Tageszyklus**:

1. **Start des Tages (Apartment / Meta-Phase)**
   - Hinweise/Reminder (z. B. Rechnungen/Fälligkeiten)
   - Optionale Käufe/Upgrades (z. B. Deko/Items) → beeinflussen später kleine Boni/Komfort/„Fokus“
2. **Arbeitsschicht (Bar / Kernphase)**
   - Kunden kommen in einer vorgegebenen oder event-getriggerten Reihenfolge
   - Dialogabschnitte werden regelmäßig von **Bestellungen** unterbrochen
   - Spieler mixt & serviert Drinks; Qualität/Passung wirkt auf Reaktionen, Flags, ggf. Geld/Tipps
3. **Schicht-Ende**
   - Tageszusammenfassung (Einnahmen, Tips, Bonus bei „perfekt“)
4. **Zurück in Meta-Phase**
   - Geld ausgeben (Rechnungen, Deko/Komfort, ggf. neue Möglichkeiten)
   - Nächster Tag

Wichtig: Das Spiel ist **kein Zeitdruck-Bartender** – es gibt **keinen harten Timer** fürs Mixen; du kannst Orders auch resetten. Spannung entsteht aus **Interpretation** (was *wirklich* gewünscht ist) und aus **Konsequenzen**. citeturn1search12

---

## 1) Kernschleife in der Schicht (Mikro-Loop pro Kunde)

In der Bar läuft das Ganze in wiederkehrenden „Kunden-Beats“:

### Mikro-Loop (ein Kunden-Beat)
1. **Kunde erscheint / setzt sich**
2. **Dialog-Block**
   - Spieler liest Dialog (optional: History/Log)
3. **Bestellung (Trigger)**
   - Kunde bestellt entweder:
     - ein konkretes Getränk („Mach mir X“)
     - oder eine Beschreibung („was Süßes“, „was Starkes“, „was ohne Alkohol“)
     - oder etwas indirektes (Stimmung/Anspielung → du sollst interpretieren) citeturn1search12
4. **Mix-Screen**
   - Spieler stellt Drink zusammen (Ingredient Units + Flags wie Ice/Aged)
5. **Serve**
   - Drink wird serviert → Spiel bewertet (passend/unpassend/„perfekt“)
6. **Reaktions-Dialog**
   - Ergebnis beeinflusst:
     - nächsten Dialogknoten / Ton
     - evtl. Flags (z. B. Beziehung/Vertrauen)
     - Geld/Tipps (besonders bei „flawless/perfect“) citeturn1search12turn0search2
7. **Nächster Dialog-Block / nächster Kunde**

**Design-Kern:**  
Du wechselst ständig zwischen **Lesen/Interpretieren** und **Handeln (Mixen/Servieren)**.

---

## 2) Drink-Mixing Loop (die „Minigame“-Schleife)

### 2.1 Zutatenmodell (VA-11 HALL-A)
Es gibt **fünf Zutaten** (Units), die jeweils eine Geschmacks-/Funktionsebene repräsentieren:  
- Adelhyde (süß)  
- Bronson Extract (bitter/kräftig)  
- Powdered Delta (sauer)  
- Flanergide (scharf)  
- Karmotrine (macht alkoholisch / Alkoholgehalt) citeturn1search12turn1search4

> Für deinen Nachbau heißt das: Du brauchst nur **5 „Regler“** + 2–3 Zubereitungs-Flags.

### 2.2 Rezeptlogik (einfach, aber effektiv)
Ein Drink-Rezept in VA-11 HALL-A besteht aus:
- Anzahl Units pro Zutat (Summe meist im Bereich 1–12+)
- optionalen Zubereitungsmodifikatoren:
  - **On the Rocks** (mit Eis)
  - **Aged** (gealtert)
  - **Blended** (länger mixen / „Mixer schneller“) citeturn0search10

**Big vs. Small:**
- Ein „Big Drink“ ist im Kern ein Drink mit **>10 Units insgesamt** (egal welche Zutat); oft wird das im Guide als Faustregel beschrieben. citeturn0search20  
- Manche Drinks werden „big“, indem man entsprechend die Units erhöht (oder – wenn das Rezept es erlaubt – mit optionaler Karmotrine auffüllt). citeturn0search20

### 2.3 Ablauf im Mix-Screen (Implementationslogik)
1. Player setzt Units (Add/Remove)
2. Player toggelt Flags (Ice / Aged)
3. Player startet Mixen (Shaker/Timer-Visual)
4. Player stoppt Mixen:
   - < kurzer Schwelle = „mixed“
   - > Schwelle = „blended“ citeturn0search10turn0search1
5. Serve / Reset

**Wichtig fürs Feeling:**  
Der Mix-Screen ist kurz, klar, wiederholbar. Kein Menü-Wust.

---

## 3) Bewertung: „Was hat der Kunde wirklich gemeint?“ (der entscheidende Twist)

VA-11 HALL-A lebt davon, dass Kunden nicht immer exakt sagen, was mechanisch „richtig“ ist. Du sollst:
- aus Dialog/Stimmung ableiten, ob er wirklich **stark**, **süß**, **alkoholisch**, **kalt** etc. will
- manchmal ist das „beste“ Ergebnis ein anderer Drink als der literal bestellte citeturn1search12

### Für deinen Nachbau (minimal)
Baue ein **Intent-System**:

- Kunden-Request hat:
  - `literal_request` (z. B. „Beer“ oder „something sweet“)
  - `intent_tags` (z. B. `sweet`, `non_alcohol`, `strong`, `warm`)
- Das Getränk hat:
  - `drink_tags` (aus Rezept abgeleitet)

**Scoring-Vorschlag**
- Exakter Treffer (Rezept/ID): +2
- Tag-Match (Intent): +1
- Neutral: 0
- Konflikt (Dislike/No-go): -1 bis -2

Damit bekommst du die VA-11 Essenz ohne riesige Komplexität.

---

## 4) Geld/Meta-Loop (zwischen den Schichten)

### 4.1 Einnahmen
Geld wird am **Ende des Tages** gutgeschrieben – typischerweise als Mischung aus:
- Umsatz/Anteil pro Drink
- Preis des Drinks
- Tips
- Bonus für „perfect/flawless service“ citeturn0search2turn1search12

### 4.2 Bills & Shopping (Motivation/Fokus)
Zwischen den Schichten gibt es Meta-Entscheidungen:
- Rechnungen zahlen (Failure → schlechtes Outcome/Ende wird begünstigt) citeturn1search2
- Items/Deko kaufen, die „Jill focused“ halten (ein System, das beeinflusst, ob die UI Orders zuverlässig anzeigt/ob sie abgelenkt ist) citeturn1search0turn1search6turn1search16

> Für deinen Inn-Prototyp ist das ein super Muster:
> - Meta-Käufe geben **kleine QoL-Boni** oder „Service-Boni“.
> - Wichtig: Es bleibt optional und unterstützt das Kerngame, ersetzt es nicht.

---

# 5) Nachbau als Arbeitsplan (Sprints)

## Sprint A – Screens & States (1–2 Tage)
**Ziel:** Dein Spiel hat die gleichen „großen Zustände“.

- [ ] GameState-Machine:
  - `MORNING_META`
  - `IN_SHIFT_DIALOG`
  - `IN_SHIFT_MIX`
  - `SHIFT_END`
- [ ] Screen-Flow:
  - Meta-Screen → Shift → Endscreen → Meta

**Done:** Du kannst durch den kompletten Tageszyklus klicken (auch ohne echte Inhalte).

---

## Sprint B – Drink-System (2–4 Tage)
**Ziel:** VA-11-artiges Drink-Minispiel.

- [ ] Datenmodell `Ingredient` (5 Stück) + `units`
- [ ] Flags: `ice`, `aged`, `blended`
- [ ] Mix-UI:
  - + / - für Units
  - Toggle Ice/Aged
  - Mix-Button mit „Shaker“-Progress
  - Blend-Schwelle (z. B. 5s)
- [ ] Serve/Reset
- [ ] Rezept-Prüfung:
  - exakter Match
  - oder Tag-basiert (Intent)

**Done:** Du kannst Drinks bauen und bekommst ein Scoring-Resultat.

---

## Sprint C – Kunden-Beat-Loop (2–3 Tage)
**Ziel:** Kunden-Beat (Dialog → Order → Mix → Reaktion).

- [ ] Customer spawnt
- [ ] Dialog-System triggert `Order`
- [ ] Order enthält `literal_request` + `intent_tags`
- [ ] Nach Serve:
  - Reaktionsdialog (1–2 Zeilen reichen)
  - Flags setzen (z. B. trust+1)
  - Money/Tip-Berechnung vorbereiten

**Done:** 3 Kunden pro Schicht fühlen sich wie VA-11-„Beats“ an.

---

## Sprint D – End-of-Shift Money & Summary (1–2 Tage)
**Ziel:** Der Tag fühlt sich „abgerechnet“ an.

- [ ] Money berechnen:
  - base payout pro Drink
  - tip bei gutem Score
  - perfect bonus
- [ ] Summary zeigt:
  - drinks served / correct / intent matches
  - tips/bonus
  - flags changed

**Done:** Spieler sieht, dass „perfekt“ lohnt.

---

## Sprint E – Meta-Käufe als kleine Modifikatoren (2–3 Tage)
**Ziel:** VA-11 „Apartment/Shop“-Muster als System, ohne Story.

- [ ] Shop-Liste (3–6 Items)
- [ ] Item-Effekte klein halten:
  - +X tip multiplier
  - +X patience für Gäste
  - +X „focus“ (z. B. Order bleibt immer sichtbar)
- [ ] Bills/Costs:
  - einfache tägliche/periodische Kosten
  - wenn nicht bezahlt: Malus / Bad Outcome Flag

**Done:** Zwischen den Schichten gibt es sinnvolle Entscheidungen.

---

# 6) Datenmodelle (Minimal)

## Item
```text
id, label, tags[], base_price (optional)
```

## DrinkRecipe
```text
id, units{adelhyde,bronson,delta,flanergide,karmotrine}, flags{ice,aged,blended}, tags[]
```

## CustomerRequest
```text
literal: drink_id OR null
intent_tags[]  (z.B. sweet, strong, non_alcohol, warm, cold)
size_pref: small|big|any  (optional)
```

## CustomerProfile
```text
id, name, likes_tags[], dislikes_tags[], tip_profile, dialog_root
```

## ShiftResult
```text
drinks_served, perfect_count, intent_match_count, money_earned, flags_set[]
```

---

# 7) „VA-11 Feeling“-Checkliste (wichtig fürs Nachbauen)

- [ ] Kunden kommen **in Beats**, nicht als Crowd
- [ ] Dialog ist **Hauptteil**, Mixing ist **Rhythmus-Wechsel**
- [ ] Bestellungen sind teils **wörtlich**, teils **interpretativ** citeturn1search12
- [ ] Mixing hat **5 Regler** + 2–3 Flags (Ice/Aged/Blended) citeturn1search4turn0search10
- [ ] „Perfect“ gibt spürbar **mehr Geld** citeturn0search2turn1search12
- [ ] Zwischen Schichten: **kleine Käufe** beeinflussen Service/Focus citeturn1search0turn1search6turn1search16

---

## Quellen (Mechanik-Referenzen)
- Wikipedia – Gameplay-Überblick, keine Zeitlimits, Zutatenliste, Ice/Aged/Big, „infer what they actually want“: citeturn1search12  
- VA-11 Hall-A Wiki (Drinktionary) – fünf Zutaten: citeturn1search4  
- Guides – Big drink rule (>10 units), blending/ice Hinweise: citeturn0search20turn0search10turn0search1  
- Geld/End-of-day payout + perfect service: citeturn0search2  
- Jill’s room / Focus / Shop-Mechanik: citeturn1search0turn1search6turn1search16
