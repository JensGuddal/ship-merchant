extends Node2D

signal enter_port(port_id: String)

const MOVE_SPEED := 150.0
const INTERACT_RADIUS := 80.0

const PORT_IDS := {
	"PortHaven": "port_haven",
	"PortIronhold": "port_ironhold",
	"PortSilverbay": "port_silverbay",
}

const PORT_DISPLAY := {
	"port_haven": "Port Haven",
	"port_ironhold": "Port Ironhold",
	"port_silverbay": "Silver Bay",
}

@onready var player: CharacterBody2D = $Player
@onready var prompt_label: Label = $UILayer/PromptLabel

var _spawn_by_port_id: Dictionary = {}


func _ready() -> void:
	set_process_unhandled_input(true)
	_register_starting_port()
	_cache_spawn_points()
	prompt_label.visible = false


## Marks port_haven as discovered if missing (new game / first world load).
func _register_starting_port() -> void:
	if not GameData.discovered_ports.has("port_haven"):
		GameData.discovered_ports.append("port_haven")


func _physics_process(_delta: float) -> void:
	_handle_movement()


func _process(_delta: float) -> void:
	var nearest := _nearest_port_id()
	_update_port_prompt(nearest)


## Handles interact in the input stage so E / action fires reliably (not in _physics_process).
func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if not event.is_action_pressed(&"interact"):
		return
	var nearest := _nearest_port_id()
	if nearest.is_empty():
		return
	enter_port.emit(nearest)



## Reads WASD / arrow keys and moves the CharacterBody2D player at MOVE_SPEED via move_and_slide().
func _handle_movement() -> void:
	var dir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		dir.y -= 1.0
	if dir.length_squared() > 0.0001:
		player.velocity = dir.normalized() * MOVE_SPEED
	else:
		player.velocity = Vector2.ZERO
	player.move_and_slide()


## Shows or hides the bottom prompt for the nearest port in range.
func _update_port_prompt(nearest_port_id: String) -> void:
	if nearest_port_id.is_empty():
		prompt_label.visible = false
		return
	var display: String = str(PORT_DISPLAY.get(nearest_port_id, nearest_port_id))
	prompt_label.text = "Press E to enter %s" % display
	prompt_label.visible = true


func _nearest_port_id() -> String:
	var best_id := ""
	var best_d := INTERACT_RADIUS + 1.0
	for node_name in PORT_IDS:
		var p: Area2D = get_node(node_name) as Area2D
		var pid: String = str(PORT_IDS[node_name])
		var d := player.global_position.distance_to(p.global_position)
		if d <= INTERACT_RADIUS and d < best_d:
			best_d = d
			best_id = pid
	return best_id


func _cache_spawn_points() -> void:
	_spawn_by_port_id.clear()
	for node_name in PORT_IDS:
		var p: Area2D = get_node(node_name) as Area2D
		var pid: String = str(PORT_IDS[node_name])
		_spawn_by_port_id[pid] = p.global_position


## Teleports the map player to the given economy port_id (e.g. after leaving a port scene).
func show_player_at_port(port_id: String) -> void:
	if not _spawn_by_port_id.has(port_id):
		push_warning("WorldMap.show_player_at_port: unknown port_id '%s'" % port_id)
		return
	player.global_position = _spawn_by_port_id[port_id] as Vector2
