extends Control

signal exit_port
signal notification_requested(message: String, duration: float)

const PORT_DISPLAY := {
	"port_haven": "Port Haven",
	"port_ironhold": "Port Ironhold",
	"port_silverbay": "Silver Bay",
}

@onready var menu_box: VBoxContainer = $CenterContainer/MenuBox
@onready var welcome_label: Label = $CenterContainer/MenuBox/WelcomeLabel
@onready var visit_market_button: Button = $CenterContainer/MenuBox/VisitMarketButton
@onready var leave_button: Button = $CenterContainer/MenuBox/LeaveButton
@onready var trade_ui: VBoxContainer = $TradeUI


func _ready() -> void:
	_refresh_welcome()
	visit_market_button.pressed.connect(_on_visit_market_pressed)
	leave_button.pressed.connect(_on_leave_button_pressed)
	trade_ui.trade_closed.connect(_on_trade_closed)
	trade_ui.notification_requested.connect(_on_trade_notification_requested)


## Sets the welcome line from GameData.current_port and the display-name table.
func _refresh_welcome() -> void:
	var pid := GameData.current_port
	var display_name: String = str(PORT_DISPLAY.get(pid, pid))
	welcome_label.text = "Welcome to %s" % display_name


func _on_visit_market_pressed() -> void:
	menu_box.visible = false
	trade_ui.visible = true
	trade_ui.setup(GameData.current_port)
	notification_requested.emit("Market opened", 1.2)


func _on_trade_closed() -> void:
	trade_ui.visible = false
	menu_box.visible = true
	_refresh_welcome()
	notification_requested.emit("Left market", 1.2)


func _on_leave_button_pressed() -> void:
	exit_port.emit()


func _on_trade_notification_requested(message: String, duration: float) -> void:
	notification_requested.emit(message, duration)