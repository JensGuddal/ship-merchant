extends Node

const BASE_EVENT_CHANCE := 0.25

signal event_triggered(event: Dictionary)

## Last rolled pirate encounter; consumed by resolve_pirate_encounter.
var _pending_pirate: Dictionary = {}


func _ready() -> void:
	_pending_pirate = {}


## Rolls a random travel event between from_port and to_port.
## from_port / to_port: economy port ids (e.g. "port_haven") used to value cargo at departure.
## Returns {} about 75% of the time; otherwise a typed event Dictionary (see project_context).
func roll_travel_event(from_port: String, to_port: String) -> Dictionary:
	_pending_pirate = {}
	if randf() > BASE_EVENT_CHANCE:
		return {}

	var cargo_value := _estimate_cargo_value(from_port)
	var fleet_n := GameData.fleet.size()
	var navy_rep := FactionManager.get_rep("royal_navy")
	var pirate_rep := FactionManager.get_rep("pirates")

	var w_pirate := 1.0
	w_pirate *= 1.0 + clampf(float(cargo_value) / 500.0, 0.0, 2.0)
	w_pirate *= 1.0 / (1.0 + float(fleet_n) * 0.12)
	w_pirate *= 1.0 - clampf(navy_rep / 100.0, 0.0, 0.55)
	w_pirate *= 1.0 - clampf(pirate_rep / 100.0, 0.0, 0.45)
	w_pirate = maxf(w_pirate, 0.05)

	var w_storm := 1.0 + clampf((float(cargo_value) / 800.0), 0.0, 0.8)
	w_storm *= 1.0 / (1.0 + float(fleet_n) * 0.08)

	var w_merchant := 0.75 + clampf(FactionManager.get_rep("merchants_guild") / 200.0, -0.2, 0.35)
	var w_clear := 0.55 + clampf(navy_rep / 250.0, -0.15, 0.25)

	var total := w_pirate + w_storm + w_merchant + w_clear
	var pick := randf() * total
	var evt: Dictionary = {}
	if pick < w_pirate:
		evt = _make_pirate_event(from_port, cargo_value, fleet_n, navy_rep, pirate_rep)
		_pending_pirate = evt.duplicate(true)
	elif pick < w_pirate + w_storm:
		evt = _make_storm_event(cargo_value, fleet_n)
	elif pick < w_pirate + w_storm + w_merchant:
		evt = _make_merchant_distress_event()
	else:
		evt = _make_clear_sailing_event()

	event_triggered.emit(evt)
	return evt


## Resolves the last pirate_attack from roll_travel_event.
## choice: "fight", "flee", or "pay_toll". Unknown choice clears pending with no effect.
func resolve_pirate_encounter(choice: String) -> void:
	if _pending_pirate.is_empty() or str(_pending_pirate.get("type", "")) != "pirate_attack":
		push_warning("EventManager.resolve_pirate_encounter: no pending pirate encounter")
		return

	var severity := float(_pending_pirate.get("severity", 0.5))
	var toll: int = int(_pending_pirate.get("toll_cost", 20))

	match choice:
		"fight":
			var navy_bonus := clampf(FactionManager.get_rep("royal_navy") / 200.0, 0.0, 0.25)
			var win_chance := 0.35 + (1.0 - severity) * 0.35 + navy_bonus
			if randf() < win_chance:
				var loot := int(15 + (1.0 - severity) * 45)
				GameData.add_coins(loot)
				FactionManager.modify_rep("royal_navy", 3.0)
				FactionManager.modify_rep("pirates", -6.0)
			else:
				var loss := int(10 + severity * 35)
				GameData.remove_coins(loss)
				FactionManager.modify_rep("royal_navy", -2.0)
				FactionManager.modify_rep("pirates", 4.0)
		"flee":
			var can_flee := bool(_pending_pirate.get("can_flee", true))
			var flee_chance := 0.45 + clampf(FactionManager.get_rep("royal_navy") / 250.0, 0.0, 0.25)
			if can_flee and randf() < flee_chance:
				FactionManager.modify_rep("royal_navy", 1.0)
			else:
				var penalty := int(8 + severity * 22)
				GameData.remove_coins(penalty)
				FactionManager.modify_rep("pirates", 2.0)
		"pay_toll":
			var paid := mini(toll, GameData.coins)
			if paid > 0:
				GameData.remove_coins(paid)
			FactionManager.modify_rep("pirates", 4.0)
			FactionManager.modify_rep("royal_navy", -1.0)
		_:
			push_warning("EventManager.resolve_pirate_encounter: unknown choice '%s'" % choice)

	_pending_pirate = {}


func _estimate_cargo_value(port_id: String) -> int:
	var total := 0
	for row in GameData.inventory:
		if not row is Dictionary:
			continue
		var gid := str(row.get("id", ""))
		var qty := int(row.get("qty", 0))
		if qty <= 0 or gid.is_empty():
			continue
		var unit := EconomyManager.get_buy_price(port_id, gid)
		total += unit * qty
	return total


func _make_pirate_event(
	_from_port: String,
	cargo_value: int,
	fleet_n: int,
	navy_rep: float,
	pirate_rep: float
) -> Dictionary:
	var severity := randf_range(0.15, 0.95)
	severity = clampf(
		severity + float(cargo_value) / 1200.0 - float(fleet_n) * 0.04 - navy_rep / 220.0 + pirate_rep / 400.0,
		0.1,
		1.0
	)
	var toll_base := int(12 + severity * 40 + float(cargo_value) / 80.0)
	var can_flee := fleet_n > 0 or randf() > 0.25
	return {
		"type": "pirate_attack",
		"severity": severity,
		"description": "Sails on the horizon — black flag! Pirates close to board.",
		"can_flee": can_flee,
		"toll_cost": toll_base,
	}


func _make_storm_event(cargo_value: int, fleet_n: int) -> Dictionary:
	var severity := randf_range(0.2, 0.95)
	severity = clampf(severity - float(fleet_n) * 0.03, 0.1, 1.0)
	var cargo_loss := clampf(0.08 + severity * 0.35 - float(fleet_n) * 0.02, 0.05, 0.65)
	return {
		"type": "storm",
		"severity": severity,
		"description": "The sky tears open; waves hammer the hull and cargo shifts dangerously.",
		"cargo_loss_chance": cargo_loss,
	}


func _make_merchant_distress_event() -> Dictionary:
	var reward := int(randf_range(25, 90))
	return {
		"type": "merchant_distress",
		"description": "A limping merchant hails you — spare cordage could save their voyage.",
		"reward_coins": reward,
		"rep_gain_faction": "merchants_guild",
		"rep_gain": 10.0,
	}


func _make_clear_sailing_event() -> Dictionary:
	return {
		"type": "clear_sailing",
		"description": "Fair winds and following seas; the coast slides by without incident.",
	}
