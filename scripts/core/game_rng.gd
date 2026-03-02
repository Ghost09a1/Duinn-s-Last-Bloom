extends Node

## GameRNG (Autoload)
## Stellt deterministische Zufallszahlen-Generatoren (RNGs) für die Nacht bereit.

var night_seed: int = 0

## Wird zu Beginn des Tages/der Nacht aufgerufen, um den Seed für die aktuelle Nacht festzulegen.
func init_night(global_seed: int, day_index: int) -> void:
	night_seed = hash("%s|%s" % [global_seed, day_index])
	print("[GameRNG] Initialize night with global_seed=%d, day_index=%d -> night_seed=%d" % [global_seed, day_index, night_seed])

## Liefert einen RandomNumberGenerator für einen speziellen Key in der aktuellen Nacht.
## Sichert reproduzierbare Ergebnisse für dieselbe Nacht, egal in welcher Reihenfolge abgefragt wird.
func rng_for(key: String) -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash("%s|%s" % [night_seed, key])
	return rng
