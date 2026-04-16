extends Node2D

@onready var status_label: Label = $HUD/StatusLabel
@onready var world_map: Node2D = $WorldMap


func _ready() -> void:
	world_map.enter_port.connect(_on_world_map_enter_port)
	_refresh_hud()


func _process(_delta: float) -> void:
	_refresh_hud()


## Receives port entry intent from WorldMap; Main owns scene transitions (none yet).
func _on_world_map_enter_port(port_id: String) -> void:
	GameData.current_port = port_id


func _refresh_hud() -> void:
	var inv_stacks := GameData.inventory.size()
	var line1 := "Coins: %d  |  Cargo stacks: %d  |  Ships: %d" % [GameData.coins, inv_stacks, GameData.fleet.size()]
	var line2 := "Navy %+.0f  Pirates %+.0f  Guild %+.0f (%s)" % [
		FactionManager.get_rep("royal_navy"),
		FactionManager.get_rep("pirates"),
		FactionManager.get_rep("merchants_guild"),
		FactionManager.get_rep_tier("merchants_guild"),
	]
	var line3 := "At sea — Wheat: haven buy %d / ironhold buy %d  |  Near: %s" % [
		EconomyManager.get_buy_price("port_haven", "wheat"),
		EconomyManager.get_buy_price("port_ironhold", "wheat"),
		GameData.current_port if GameData.current_port != "" else "(none)",
	]
	status_label.text = "%s\n%s\n%s" % [line1, line2, line3]
