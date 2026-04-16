extends Node

## Canonical faction keys used across the game (trade, travel, dialogue).
const FACTIONS: Array[String] = [
	"merchants_guild",
	"royal_navy",
	"pirates",
	"port_locals",
]

## faction_id -> reputation score in [-100.0, 100.0].
var reputation: Dictionary = {}

signal reputation_changed(faction_id: String, new_value: float)


func _ready() -> void:
	for faction_id in FACTIONS:
		if not reputation.has(faction_id):
			reputation[faction_id] = 0.0


## Adds amount to faction_id, clamps to [-100, 100], then applies Navy/Pirate tension:
## a change to royal_navy also moves pirates by -half that delta (and the reverse).
## faction_id: must be one of FACTIONS. amount: positive or negative rep change.
func modify_rep(faction_id: String, amount: float) -> void:
	if not faction_id in FACTIONS:
		push_warning("FactionManager.modify_rep: unknown faction '%s'" % faction_id)
		return
	var before_navy := float(reputation.get("royal_navy", 0.0))
	var before_pirates := float(reputation.get("pirates", 0.0))

	_apply_rep_change(faction_id, amount)

	if faction_id == "royal_navy":
		var navy_delta := float(reputation.get("royal_navy", 0.0)) - before_navy
		_apply_rep_change("pirates", -0.5 * navy_delta)
	elif faction_id == "pirates":
		var pirate_delta := float(reputation.get("pirates", 0.0)) - before_pirates
		_apply_rep_change("royal_navy", -0.5 * pirate_delta)


## Returns the current reputation for faction_id, or 0.0 if unknown.
func get_rep(faction_id: String) -> float:
	return float(reputation.get(faction_id, 0.0))


## Maps numeric rep to a discrete tier string for UI and game logic.
## Tiers: allied > 50, friendly > 10, neutral [-10, 10], unfriendly [-50, -10), hostile < -50.
func get_rep_tier(faction_id: String) -> String:
	var rep := get_rep(faction_id)
	if rep > 50.0:
		return "allied"
	if rep > 10.0:
		return "friendly"
	if rep >= -10.0:
		return "neutral"
	if rep >= -50.0:
		return "unfriendly"
	return "hostile"


## Trade price multiplier from Merchants Guild standing; other factions return 1.0.
## allied/hostile use spec values; friendly/unfriendly blend toward neutral (1.0).
func get_price_modifier(faction_id: String) -> float:
	if faction_id != "merchants_guild":
		return 1.0
	match get_rep_tier("merchants_guild"):
		"allied":
			return 0.85
		"friendly":
			return 0.925
		"neutral":
			return 1.0
		"unfriendly":
			return 1.10
		"hostile":
			return 1.20
		_:
			return 1.0


func _apply_rep_change(faction_id: String, delta: float) -> void:
	if not faction_id in FACTIONS:
		return
	var new_val := clampf(float(reputation.get(faction_id, 0.0)) + delta, -100.0, 100.0)
	reputation[faction_id] = new_val
	reputation_changed.emit(faction_id, new_val)
