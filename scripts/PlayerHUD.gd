extends CanvasLayer

@onready var coins_label: Label = $TopLeftPanel/InfoVBox/CoinsLabel
@onready var cargo_label: Label = $TopLeftPanel/InfoVBox/CargoLabel
@onready var rep_label: Label = $TopLeftPanel/InfoVBox/RepLabel
@onready var notification_label: Label = $NotificationLabel

var _notification_tween: Tween
var _last_coins := -1
var _last_cargo_items := -1
var _last_rep_tier := ""


func _ready() -> void:
	if FactionManager.has_signal("reputation_changed") and not FactionManager.reputation_changed.is_connected(_on_reputation_changed):
		FactionManager.reputation_changed.connect(_on_reputation_changed)
	if GameData.has_signal("coins_changed") and GameData.coins_changed is Signal and not GameData.coins_changed.is_connected(_on_game_data_changed):
		GameData.coins_changed.connect(_on_game_data_changed)
	if GameData.has_signal("inventory_changed") and GameData.inventory_changed is Signal and not GameData.inventory_changed.is_connected(_on_game_data_changed):
		GameData.inventory_changed.connect(_on_game_data_changed)
	notification_label.visible = false
	refresh()


func _process(_delta: float) -> void:
	# Fallback polling for GameData, since it currently has no change signals.
	if _snapshot_changed():
		refresh()


## Updates all persistent HUD labels from GameData and FactionManager state.
func refresh() -> void:
	var cargo_items := _cargo_item_count()
	var tier := FactionManager.get_rep_tier("merchants_guild")
	coins_label.text = "Coins: %dg" % GameData.coins
	cargo_label.text = "Cargo: %d items" % cargo_items
	rep_label.text = "Rep: %s" % tier.capitalize()
	_last_coins = GameData.coins
	_last_cargo_items = cargo_items
	_last_rep_tier = tier


## Shows the HUD layer.
func show_hud() -> void:
	visible = true


## Hides the HUD layer.
func hide_hud() -> void:
	visible = false


## Displays a temporary top-centre notification and fades it out after duration.
## message: text to display. duration: visible time before fade starts.
func show_notification(message: String, duration: float = 2.0) -> void:
	notification_label.text = message
	notification_label.visible = true
	notification_label.modulate = Color(1, 1, 1, 1)
	if _notification_tween != null and _notification_tween.is_valid():
		_notification_tween.kill()
	_notification_tween = create_tween()
	_notification_tween.tween_interval(maxf(duration, 0.0))
	_notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.35)
	_notification_tween.tween_callback(func() -> void:
		notification_label.visible = false
	)


func _cargo_item_count() -> int:
	var total := 0
	for row in GameData.inventory:
		if row is Dictionary:
			total += int(row.get("qty", 0))
	return total


func _snapshot_changed() -> bool:
	return (
		GameData.coins != _last_coins
		or _cargo_item_count() != _last_cargo_items
		or FactionManager.get_rep_tier("merchants_guild") != _last_rep_tier
	)


func _on_reputation_changed(_faction_id: String, _new_value: float) -> void:
	refresh()


func _on_game_data_changed() -> void:
	refresh()