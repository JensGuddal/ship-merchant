extends VBoxContainer

signal trade_closed
signal notification_requested(message: String, duration: float)

@onready var header_label: Label = $HeaderLabel
@onready var coins_label: Label = $CoinsLabel
@onready var goods_list: VBoxContainer = $GoodsScroll/GoodsList
@onready var error_label: Label = $ErrorLabel
@onready var close_button: Button = $CloseButton
@onready var error_timer: Timer = $ErrorTimer

var _current_port_id := ""
var _market: Dictionary = {}
var _goods_lookup: Dictionary = {}
var _row_refs: Dictionary = {}


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	error_timer.timeout.connect(_on_error_timeout)
	error_label.visible = false


## Prepares the market view for port_id and rebuilds all goods rows from EconomyManager.
## port_id: economy key such as "port_haven".
func setup(port_id: String) -> void:
	_current_port_id = port_id
	_market = EconomyManager.get_port_market(port_id)
	_goods_lookup = EconomyManager.get_all_goods()
	_build_rows()
	_refresh_header()
	refresh_ui()


## Buys one unit of good_id at the current port if the player can afford it.
## good_id: goods catalogue key, for example "wheat".
func buy_good(good_id: String) -> void:
	if not _market.has(good_id):
		_show_error("Good unavailable here")
		return
	var price := EconomyManager.get_buy_price(_current_port_id, good_id)
	if not GameData.remove_coins(price):
		_show_error("Not enough coins")
		return
	GameData.add_to_inventory(good_id, 1)
	refresh_ui()
	notification_requested.emit("Bought %s for %dg" % [_display_name(good_id), price], 1.6)


## Sells one unit of good_id at the current port if the player owns stock.
## good_id: goods catalogue key, for example "wheat".
func sell_good(good_id: String) -> void:
	if not GameData.remove_from_inventory(good_id, 1):
		_show_error("You don't have that")
		return
	var payout := EconomyManager.get_sell_price(_current_port_id, good_id)
	GameData.add_coins(payout)
	refresh_ui()
	notification_requested.emit("Sold %s for %dg" % [_display_name(good_id), payout], 1.6)


## Refreshes top coins text and per-row labels (buy/sell/owned) after transactions.
func refresh_ui() -> void:
	coins_label.text = "Coins: %dg" % GameData.coins
	for good_id in _row_refs.keys():
		var row_ref: Dictionary = _row_refs[good_id]
		var buy_price := EconomyManager.get_buy_price(_current_port_id, good_id)
		var sell_price := EconomyManager.get_sell_price(_current_port_id, good_id)
		row_ref["buy_label"].text = "Buy: %dg" % buy_price
		row_ref["sell_label"].text = "Sell: %dg" % sell_price
		row_ref["owned_label"].text = "Owned: %d" % _owned_qty(good_id)


func _refresh_header() -> void:
	var display_map := {
		"port_haven": "Port Haven",
		"port_ironhold": "Port Ironhold",
		"port_silverbay": "Silver Bay",
	}
	header_label.text = "Market — %s" % str(display_map.get(_current_port_id, _current_port_id))


func _build_rows() -> void:
	for child in goods_list.get_children():
		goods_list.remove_child(child)
		child.queue_free()
	_row_refs.clear()

	var ids: Array[String] = []
	for good_id in _market.keys():
		ids.append(str(good_id))
	ids.sort()

	for good_id in ids:
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 14)

		var name_label := Label.new()
		name_label.custom_minimum_size = Vector2(150, 0)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.text = str(_goods_lookup.get(good_id, {}).get("display_name", good_id.capitalize()))

		var buy_label := Label.new()
		buy_label.custom_minimum_size = Vector2(90, 0)
		var sell_label := Label.new()
		sell_label.custom_minimum_size = Vector2(90, 0)
		var owned_label := Label.new()
		owned_label.custom_minimum_size = Vector2(90, 0)

		var buy_button := Button.new()
		buy_button.text = "+1"
		buy_button.pressed.connect(_on_buy_pressed.bind(good_id))

		var sell_button := Button.new()
		sell_button.text = "-1"
		sell_button.pressed.connect(_on_sell_pressed.bind(good_id))

		row.add_child(name_label)
		row.add_child(buy_label)
		row.add_child(sell_label)
		row.add_child(owned_label)
		row.add_child(buy_button)
		row.add_child(sell_button)
		goods_list.add_child(row)

		_row_refs[good_id] = {
			"buy_label": buy_label,
			"sell_label": sell_label,
			"owned_label": owned_label,
		}


func _owned_qty(good_id: String) -> int:
	var total := 0
	for row in GameData.inventory:
		if row is Dictionary and str(row.get("id", "")) == good_id:
			total += int(row.get("qty", 0))
	return total


func _show_error(message: String) -> void:
	error_label.text = message
	error_label.visible = true
	error_timer.start(2.0)
	notification_requested.emit(message, 1.8)


func _on_error_timeout() -> void:
	error_label.visible = false


func _on_buy_pressed(good_id: String) -> void:
	buy_good(good_id)


func _on_sell_pressed(good_id: String) -> void:
	sell_good(good_id)


func _on_close_pressed() -> void:
	trade_closed.emit()


func _display_name(good_id: String) -> String:
	return str(_goods_lookup.get(good_id, {}).get("display_name", good_id.capitalize()))