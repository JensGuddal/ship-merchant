extends Node

## Master list of trade goods: good_id -> { display_name, base_price, weight, category }.
const GOODS_CATALOGUE: Dictionary = {
	"wheat": {"display_name": "Wheat", "base_price": 8, "weight": 2, "category": "Food"},
	"salt": {"display_name": "Salt", "base_price": 15, "weight": 1, "category": "Food"},
	"timber": {"display_name": "Timber", "base_price": 20, "weight": 5, "category": "Materials"},
	"iron": {"display_name": "Iron", "base_price": 35, "weight": 4, "category": "Materials"},
	"cloth": {"display_name": "Cloth", "base_price": 25, "weight": 2, "category": "Luxury"},
	"spices": {"display_name": "Spices", "base_price": 80, "weight": 1, "category": "Luxury"},
	"rum": {"display_name": "Rum", "base_price": 40, "weight": 2, "category": "Luxury"},
	"cannon": {"display_name": "Cannon", "base_price": 120, "weight": 8, "category": "Military"},
}

## port_id -> good_id -> { "buy": player pays shop, "sell": shop pays player }.
## Prices chosen so arbitrage exists between ports (e.g. buy wheat low, sell higher elsewhere).
const PORT_PRICES: Dictionary = {
	"port_haven": {
		"wheat": {"buy": 5, "sell": 3},
		"salt": {"buy": 12, "sell": 9},
		"timber": {"buy": 24, "sell": 18},
		"iron": {"buy": 42, "sell": 32},
		"cloth": {"buy": 28, "sell": 21},
		"spices": {"buy": 95, "sell": 72},
		"rum": {"buy": 45, "sell": 34},
		"cannon": {"buy": 130, "sell": 98},
	},
	"port_ironhold": {
		"wheat": {"buy": 14, "sell": 10},
		"salt": {"buy": 18, "sell": 14},
		"timber": {"buy": 16, "sell": 12},
		"iron": {"buy": 28, "sell": 21},
		"cloth": {"buy": 26, "sell": 19},
		"spices": {"buy": 78, "sell": 59},
		"rum": {"buy": 42, "sell": 31},
		"cannon": {"buy": 105, "sell": 79},
	},
	"port_silverbay": {
		"wheat": {"buy": 11, "sell": 8},
		"salt": {"buy": 16, "sell": 12},
		"timber": {"buy": 22, "sell": 17},
		"iron": {"buy": 38, "sell": 29},
		"cloth": {"buy": 20, "sell": 15},
		"spices": {"buy": 58, "sell": 44},
		"rum": {"buy": 32, "sell": 24},
		# Buy cheap at ironhold, sell higher here — enables cannon arbitrage vs ironhold.
		"cannon": {"buy": 128, "sell": 112},
	},
}


## Coins the player pays to buy one unit of good_id at port_id.
## port_id: port key (e.g. "port_haven"). good_id: good key (e.g. "wheat").
## Falls back to GOODS_CATALOGUE base_price when the port or row is missing.
func get_buy_price(port_id: String, good_id: String) -> int:
	var row := _get_price_row(port_id, good_id)
	if row.is_empty():
		return _fallback_buy(good_id)
	return int(row["buy"])


## Coins the port pays the player for one unit when selling good_id at port_id.
## Falls back to a conservative fraction of base_price if data is missing.
func get_sell_price(port_id: String, good_id: String) -> int:
	var row := _get_price_row(port_id, good_id)
	if row.is_empty():
		return _fallback_sell(good_id)
	return int(row["sell"])


## Returns a deep copy of GOODS_CATALOGUE so callers cannot mutate the catalogue.
func get_all_goods() -> Dictionary:
	return GOODS_CATALOGUE.duplicate(true)


## Returns a deep copy of the market at port_id (good_id -> { buy, sell }), or {} if unknown.
func get_port_market(port_id: String) -> Dictionary:
	if not PORT_PRICES.has(port_id):
		return {}
	var market: Dictionary = PORT_PRICES[port_id]
	var out: Dictionary = {}
	for good_id in market.keys():
		var inner: Variant = market[good_id]
		if inner is Dictionary:
			out[good_id] = (inner as Dictionary).duplicate(true)
	return out


func _get_price_row(port_id: String, good_id: String) -> Dictionary:
	if not PORT_PRICES.has(port_id):
		return {}
	var port_market: Variant = PORT_PRICES[port_id]
	if not port_market is Dictionary:
		return {}
	var inner: Variant = port_market.get(good_id, {})
	if inner is Dictionary:
		return inner as Dictionary
	return {}


func _fallback_buy(good_id: String) -> int:
	if GOODS_CATALOGUE.has(good_id):
		return int(GOODS_CATALOGUE[good_id]["base_price"])
	push_warning("EconomyManager.get_buy_price: unknown good '%s'" % good_id)
	return 0


func _fallback_sell(good_id: String) -> int:
	if GOODS_CATALOGUE.has(good_id):
		return floori(int(GOODS_CATALOGUE[good_id]["base_price"]) * 0.75)
	return 0
