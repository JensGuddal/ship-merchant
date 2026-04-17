extends Node2D

# Tile size from Kenney Tiny Town pack
const TS := 16

# Tile indices (each maps to res://assets/tiles/tile_XXXX.png)
const T_GRASS       := 0    # green grass
const T_GRASS_B     := 1    # grass variant
const T_STONE       := 50   # blue-grey cobblestone
const T_STONE_B     := 51   # cobblestone variant
const T_WOOD        := 70   # brown wooden plank (dock)
const T_WOOD_B      := 71   # wooden plank variant
const T_WALL_STONE  := 60   # stone building wall
const T_WALL_BRICK  := 90   # dark brick wall
const T_ROOF_L      := 80   # roof tile left
const T_ROOF_R      := 81   # roof tile right
const T_DOOR        := 100  # door
const T_WINDOW      := 110  # window
const T_FENCE_H     := 120  # horizontal fence
const T_TREE_TOP    := 10   # tree top
const T_TREE_BOT    := 22   # tree bottom

# Map dimensions in tiles
const MAP_W := 80
# Ground rows (in tiles, top to bottom):
#   0–11  : grass (behind buildings)
#  12–19  : stone cobblestone plaza  (walkable)
#  20–26  : wooden dock              (walkable)
# 27+     : water (code-drawn)

var _tile_cache := {}


func _ready() -> void:
	_build_tiles()
	_build_collision()


# ── Tile rendering ─────────────────────────────────────────────────────────────

func _build_tiles() -> void:
	# Grass rows 0-11
	for y in range(12):
		for x in range(MAP_W):
			var t := T_GRASS if (x + y) % 3 != 0 else T_GRASS_B
			_place_tile(t, x, y)

	# Stone plaza rows 12-19
	for y in range(12, 20):
		for x in range(MAP_W):
			var t := T_STONE if (x + y) % 2 == 0 else T_STONE_B
			_place_tile(t, x, y)

	# Wooden dock rows 20-26
	for y in range(20, 27):
		for x in range(MAP_W):
			var t := T_WOOD if y % 2 == 0 else T_WOOD_B
			_place_tile(t, x, y)

	# Trees along the top grass band
	var tree_positions := [3, 8, 14, 22, 35, 45, 55, 63, 72, 77]
	for tx in tree_positions:
		_place_tile(T_TREE_TOP, tx, 2)
		_place_tile(T_TREE_BOT, tx, 3)

	# Buildings
	_place_building(2,  4, 5, 4, "Harbormaster")
	_place_building(10, 4, 4, 4, "Tavern")
	_place_building(18, 4, 6, 4, "Market")
	_place_building(28, 4, 5, 5, "Warehouse")
	_place_building(38, 4, 4, 4, "Smithy")
	_place_building(46, 4, 5, 4, "Inn")
	_place_building(55, 4, 6, 4, "Goods Store")
	_place_building(65, 4, 5, 4, "Customs")

	# Fences along top of plaza
	for x in range(MAP_W):
		_place_tile(T_FENCE_H, x, 12)


func _place_tile(tile_id: int, grid_x: int, grid_y: int) -> void:
	var sprite := Sprite2D.new()
	if not _tile_cache.has(tile_id):
		_tile_cache[tile_id] = load("res://assets/tiles/tile_%04d.png" % tile_id)
	sprite.texture = _tile_cache[tile_id]
	sprite.centered = false
	sprite.position = Vector2(grid_x * TS, grid_y * TS)
	add_child(sprite)


func _place_building(bx: int, by: int, w: int, h: int, _label: String) -> void:
	# Roof row
	for x in range(bx, bx + w):
		_place_tile(T_ROOF_L if x == bx else (T_ROOF_R if x == bx + w - 1 else 85), x, by)
	# Wall rows
	for y in range(by + 1, by + h - 1):
		for x in range(bx, bx + w):
			if x == bx or x == bx + w - 1:
				_place_tile(T_WALL_STONE, x, y)
			elif y == by + 1 and (x == bx + w // 2 - 1 or x == bx + w // 2):
				_place_tile(T_WINDOW, x, y)
			else:
				_place_tile(T_WALL_STONE, x, y)
	# Ground floor / door row
	for x in range(bx, bx + w):
		if x == bx + w // 2:
			_place_tile(T_DOOR, x, by + h - 1)
		else:
			_place_tile(T_WALL_BRICK, x, by + h - 1)


# ── Collision ──────────────────────────────────────────────────────────────────

func _build_collision() -> void:
	# Water below dock (row 27 downward)
	_add_wall(Vector2(MAP_W * TS / 2, 27 * TS + 300), Vector2(MAP_W * TS + 200, 600))
	# Building zone (rows 0-11)
	_add_wall(Vector2(MAP_W * TS / 2, 6 * TS), Vector2(MAP_W * TS + 200, 12 * TS))
	# Left boundary
	_add_wall(Vector2(-20, 20 * TS), Vector2(40, 2000))
	# Right boundary
	_add_wall(Vector2(MAP_W * TS + 20, 20 * TS), Vector2(40, 2000))


func _add_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = center
	body.add_child(col)
	add_child(body)


# ── Sky and water (code-drawn) ─────────────────────────────────────────────────

func _draw() -> void:
	# Sky behind everything
	draw_rect(Rect2(0, -200, MAP_W * TS + 200, 500), Color(0.50, 0.70, 0.90))

	# Water below the dock
	var water_y := 27 * TS
	draw_rect(Rect2(-50, water_y, MAP_W * TS + 200, 600), Color(0.10, 0.34, 0.58))
	for i in range(20):
		draw_line(
			Vector2(-50, water_y + 10.0 + i * 15.0),
			Vector2(MAP_W * TS + 150, water_y + 10.0 + i * 15.0),
			Color(0.16, 0.46, 0.72, 0.30), 1.5)

	# Dock posts into water
	for i in range(2, MAP_W, 8):
		draw_rect(Rect2(i * TS + 4, water_y, 6, 80), Color(0.28, 0.18, 0.08))
