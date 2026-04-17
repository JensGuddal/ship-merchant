extends Node2D

const TS   := 16     # tile size in pixels
const MAP_W := 80    # map width in tiles

# ── Tile indices ──────────────────────────────────────────────────────────────
# (each index maps to assets/tiles/tile_XXXX.png)
const T_GRASS      := 0
const T_GRASS_B    := 1
const T_STONE      := 50
const T_STONE_B    := 51
const T_WOOD       := 70
const T_WOOD_B     := 71
const T_WALL       := 60
const T_WALL_B     := 90
const T_ROOF       := 80
const T_ROOF_B     := 81
const T_DOOR       := 100
const T_WINDOW     := 110
const T_FENCE      := 120
const T_TREE_T     := 10
const T_TREE_B     := 22

# ── Preloaded textures keyed by tile index ────────────────────────────────────
var _tex: Dictionary = {}

# Rows (in tiles):
#   0 – 11  : grass  (trees + buildings sit here)
#  12 – 19  : cobblestone plaza  (walkable)
#  20 – 26  : wooden dock        (walkable)
#  27 +     : water (code-drawn)


func _ready() -> void:
	_preload([T_GRASS, T_GRASS_B, T_STONE, T_STONE_B,
			  T_WOOD, T_WOOD_B, T_WALL, T_WALL_B,
			  T_ROOF, T_ROOF_B, T_DOOR, T_WINDOW,
			  T_FENCE, T_TREE_T, T_TREE_B])
	_build_collision()
	queue_redraw()


func _preload(indices: Array) -> void:
	for i in indices:
		var path := "res://assets/tiles/tile_%04d.png" % i
		if ResourceLoader.exists(path):
			_tex[i] = load(path)


# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	# Sky
	draw_rect(Rect2(-100, -300, MAP_W * TS + 300, MAP_W * TS),
		Color(0.50, 0.70, 0.90))

	# ── Grass rows 0–11 ───────────────────────────────────────────
	for y in range(12):
		for x in range(MAP_W):
			var t := T_GRASS if (x + y) % 3 != 0 else T_GRASS_B
			_dt(t, x, y)

	# ── Trees ─────────────────────────────────────────────────────
	for tx in [3, 8, 14, 22, 35, 45, 55, 63, 72, 77]:
		_dt(T_TREE_T, tx, 1)
		_dt(T_TREE_B, tx, 2)

	# ── Buildings ─────────────────────────────────────────────────
	_building(2,  3, 5, 5)
	_building(10, 3, 4, 5)
	_building(18, 3, 6, 5)
	_building(28, 3, 5, 5)
	_building(38, 3, 4, 5)
	_building(46, 3, 5, 5)
	_building(55, 3, 6, 5)
	_building(65, 3, 5, 5)

	# ── Fence at top of plaza ──────────────────────────────────────
	for x in range(MAP_W):
		_dt(T_FENCE, x, 12)

	# ── Stone cobblestone plaza rows 13–19 ─────────────────────────
	for y in range(13, 20):
		for x in range(MAP_W):
			var t := T_STONE if (x + y) % 2 == 0 else T_STONE_B
			_dt(t, x, y)

	# ── Wooden dock rows 20–26 ────────────────────────────────────
	for y in range(20, 27):
		for x in range(MAP_W):
			var t := T_WOOD if y % 2 == 0 else T_WOOD_B
			_dt(t, x, y)

	# ── Water (below row 27) ──────────────────────────────────────
	var wy := 27 * TS
	draw_rect(Rect2(-100, wy, MAP_W * TS + 300, 400),
		Color(0.10, 0.34, 0.58))
	for i in range(18):
		draw_line(
			Vector2(-100, wy + 10.0 + i * 15.0),
			Vector2(MAP_W * TS + 200, wy + 10.0 + i * 15.0),
			Color(0.18, 0.48, 0.72, 0.28), 1.5)

	# Dock posts into water
	for i in range(2, MAP_W, 6):
		draw_rect(Rect2(i * TS + 5, wy, 5, 70),
			Color(0.28, 0.18, 0.08))


func _dt(tile_id: int, gx: int, gy: int) -> void:
	if _tex.has(tile_id):
		draw_texture(_tex[tile_id], Vector2(gx * TS, gy * TS))


func _building(bx: int, by: int, w: int, h: int) -> void:
	# Roof row
	for x in range(bx, bx + w):
		_dt(T_ROOF if x < bx + w / 2 else T_ROOF_B, x, by)
	# Wall rows
	for y in range(by + 1, by + h - 1):
		for x in range(bx, bx + w):
			var mid := bx + w / 2
			if y == by + 1 and (x == mid - 1 or x == mid):
				_dt(T_WINDOW, x, y)
			else:
				_dt(T_WALL, x, y)
	# Ground floor with door
	for x in range(bx, bx + w):
		_dt(T_DOOR if x == bx + w / 2 else T_WALL_B, x, by + h - 1)


# ── Collision ─────────────────────────────────────────────────────────────────

func _build_collision() -> void:
	# Water (below dock)
	_wall(Vector2(MAP_W * TS * 0.5, 27 * TS + 300), Vector2(MAP_W * TS + 400, 600))
	# Building zone (top rows)
	_wall(Vector2(MAP_W * TS * 0.5, 4 * TS), Vector2(MAP_W * TS + 400, 8 * TS))
	# Left edge
	_wall(Vector2(-30, 20 * TS), Vector2(60, 2000))
	# Right edge
	_wall(Vector2(MAP_W * TS + 30, 20 * TS), Vector2(60, 2000))


func _wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var col  := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = center
	body.add_child(col)
	add_child(body)
