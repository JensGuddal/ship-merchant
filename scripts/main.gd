extends Node

const WORLD_MAP_SCENE := preload("res://scenes/WorldMap.tscn")
const PORT_SCENE := preload("res://scenes/Port.tscn")
const PORT_DISPLAY := {
	"port_haven": "Port Haven",
	"port_ironhold": "Port Ironhold",
	"port_silverbay": "Silver Bay",
}

@onready var scene_container: Node = $SceneContainer
@onready var player_hud: CanvasLayer = $PlayerHUD

var _world_map: Node2D


func _ready() -> void:
	_load_world_map()
	_refresh_hud()


## Instantiates WorldMap under SceneContainer and wires enter_port to this scene manager.
func _load_world_map() -> void:
	_clear_scene_container()
	_world_map = WORLD_MAP_SCENE.instantiate() as Node2D
	scene_container.add_child(_world_map)
	_world_map.enter_port.connect(_on_world_map_enter_port)
	_refresh_hud()


## Clears all children from SceneContainer (active gameplay scene slot).
func _clear_scene_container() -> void:
	for child in scene_container.get_children():
		scene_container.remove_child(child)
		child.queue_free()


## Forwards WorldMap dock intent into the port transition pipeline.
func _on_world_map_enter_port(port_id: String) -> void:
	go_to_port(port_id)


## Stores port id, swaps SceneContainer to Port.tscn, and listens for exit_port to return.
## port_id: economy id (e.g. "port_haven") from WorldMap.enter_port.
func go_to_port(port_id: String) -> void:
	GameData.current_port = port_id
	_clear_scene_container()
	var port_scene: Node = PORT_SCENE.instantiate()
	scene_container.add_child(port_scene)
	if port_scene.has_signal("exit_port"):
		port_scene.connect("exit_port", Callable(self, "return_to_world_map"))
	if port_scene.has_signal("notification_requested"):
		port_scene.connect("notification_requested", Callable(self, "_on_port_notification_requested"))
	player_hud.show_notification("Docked at %s" % str(PORT_DISPLAY.get(port_id, port_id)), 1.6)
	_refresh_hud()


## Removes Port, reloads WorldMap, and places the player at the last visited port.
func return_to_world_map() -> void:
	_clear_scene_container()
	_load_world_map()
	if _world_map and GameData.current_port != "":
		_world_map.show_player_at_port(GameData.current_port)
	player_hud.show_notification("Back at sea", 1.3)
	_refresh_hud()


## Shows the persistent PlayerHUD layer.
func show_hud() -> void:
	player_hud.show_hud()


## Hides the persistent PlayerHUD layer.
func hide_hud() -> void:
	player_hud.hide_hud()


func _refresh_hud() -> void:
	player_hud.refresh()


func _on_port_notification_requested(message: String, duration: float) -> void:
	player_hud.show_notification(message, duration)