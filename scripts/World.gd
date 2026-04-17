extends Node2D

# World layout (pixel coordinates):
#   y=0   - y=300  : sky
#   y=300 - y=320  : building tops (roof line)
#   y=320 - y=440  : cobblestone plaza (walkable)
#   y=440 - y=532  : wooden dock / pier (walkable)
#   y=532 +        : ocean water (not walkable)


func _ready() -> void:
	_build_collision()


func _build_collision() -> void:
	# Water — player cannot walk below the dock
	_add_wall(Vector2(1000, 666), Vector2(2200, 268))
	# Building zone — player cannot walk into buildings (yet)
	_add_wall(Vector2(1000, 150), Vector2(2200, 300))
	# Left world boundary
	_add_wall(Vector2(-60, 450), Vector2(120, 1200))
	# Right world boundary
	_add_wall(Vector2(2060, 450), Vector2(120, 1200))


func _add_wall(center: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.position = center
	body.add_child(col)
	add_child(body)


func _draw() -> void:
	# ── Sky ──────────────────────────────────────────────────────
	draw_rect(Rect2(0, 0, 2000, 800), Color(0.50, 0.70, 0.90))

	# Clouds
	_draw_cloud(150, 70, 120, 40)
	_draw_cloud(460, 45, 95, 32)
	_draw_cloud(780, 80, 140, 46)
	_draw_cloud(1100, 55, 105, 36)
	_draw_cloud(1420, 78, 118, 40)
	_draw_cloud(1750, 50, 90, 30)

	# ── Distant sea horizon ───────────────────────────────────────
	draw_rect(Rect2(0, 270, 2000, 70), Color(0.26, 0.50, 0.72, 0.5))

	# ── Ocean water ───────────────────────────────────────────────
	draw_rect(Rect2(0, 532, 2000, 400), Color(0.10, 0.34, 0.58))
	for i in range(20):
		var wy := 542.0 + i * 15.0
		draw_line(Vector2(0, wy), Vector2(2000, wy),
			Color(0.16, 0.46, 0.72, 0.30), 1.5)
	# Shimmer highlights
	for i in range(9):
		draw_line(
			Vector2(80.0 + i * 210.0, 556.0 + i * 8.0),
			Vector2(220.0 + i * 210.0, 556.0 + i * 8.0),
			Color(0.65, 0.85, 0.98, 0.22), 2)

	# ── Cobblestone plaza ─────────────────────────────────────────
	draw_rect(Rect2(0, 320, 2000, 120), Color(0.54, 0.51, 0.47))
	for row in range(8):
		for col_i in range(48):
			var cx := col_i * 44.0 + (row % 2) * 22.0
			var cy := 324.0 + row * 15.0
			draw_rect(Rect2(cx, cy, 40, 13), Color(0.50, 0.46, 0.42))
			draw_rect(Rect2(cx, cy, 40, 13), Color(0.40, 0.36, 0.32), false, 0.8)

	# ── Wooden dock/pier ──────────────────────────────────────────
	draw_rect(Rect2(0, 440, 2000, 93), Color(0.46, 0.33, 0.17))
	for i in range(7):
		draw_line(Vector2(0, 444.0 + i * 12.0), Vector2(2000, 444.0 + i * 12.0),
			Color(0.35, 0.24, 0.11, 0.55), 1)
	for i in range(0, 2000, 54):
		draw_line(Vector2(i, 440), Vector2(i, 533),
			Color(0.32, 0.22, 0.10, 0.42), 1)
	draw_line(Vector2(0, 440), Vector2(2000, 440), Color(0.62, 0.48, 0.24), 3)
	draw_line(Vector2(0, 533), Vector2(2000, 533), Color(0.24, 0.15, 0.07), 2)

	# Dock posts into water
	for i in range(80, 2000, 120):
		draw_rect(Rect2(i - 6, 524, 12, 92), Color(0.28, 0.18, 0.08))
		draw_rect(Rect2(i - 4, 616, 8, 26), Color(0.14, 0.26, 0.44, 0.38))

	# Mooring bollards
	for i in range(100, 2000, 200):
		draw_circle(Vector2(i, 520), 9, Color(0.30, 0.21, 0.10))
		draw_circle(Vector2(i, 516), 10, Color(0.36, 0.26, 0.12))
		draw_circle(Vector2(i, 516), 10, Color(0.22, 0.14, 0.06), false, 1.5)

	# ── Buildings ─────────────────────────────────────────────────
	_draw_warehouse(80, 180, 240, 145)
	_draw_building(400, 200, 170, 125, Color(0.54, 0.49, 0.43), "Harbormaster")
	_draw_building(650, 210, 145, 115, Color(0.50, 0.47, 0.41), "Tavern")
	_draw_building(880, 195, 185, 130, Color(0.52, 0.46, 0.40), "Market")
	_draw_building(1150, 185, 205, 140, Color(0.48, 0.44, 0.39), "Warehouse")
	_draw_building(1440, 205, 155, 118, Color(0.53, 0.49, 0.43), "Smithy")
	_draw_building(1680, 195, 180, 128, Color(0.50, 0.45, 0.40), "Inn")

	# ── Ship moored at dock ───────────────────────────────────────
	_draw_ship(880, 462)

	# Mooring ropes from ship to bollards
	draw_line(Vector2(902, 510), Vector2(900, 524), Color(0.62, 0.48, 0.26, 0.85), 2)
	draw_line(Vector2(1152, 508), Vector2(1100, 522), Color(0.62, 0.48, 0.26, 0.85), 2)

	# ── Dock props ────────────────────────────────────────────────
	_draw_crate_stack(330, 440)
	_draw_crate_stack(388, 440)
	_draw_barrel_group(1320, 438)
	_draw_net(1530, 458)
	_draw_crate_stack(1680, 440)
	_draw_rope_coil(620, 480)
	_draw_rope_coil(640, 486)


# ── Draw helpers ──────────────────────────────────────────────────────────────

func _draw_cloud(x: float, y: float, w: float, h: float) -> void:
	var c := Color(1.0, 1.0, 1.0, 0.75)
	draw_circle(Vector2(x, y), h * 0.62, c)
	draw_circle(Vector2(x + w * 0.28, y - h * 0.18), h * 0.52, c)
	draw_circle(Vector2(x + w * 0.55, y), h * 0.68, c)
	draw_circle(Vector2(x + w * 0.80, y + h * 0.12), h * 0.46, c)


func _draw_warehouse(x: float, y: float, w: float, h: float) -> void:
	draw_rect(Rect2(x, y, w, h), Color(0.46, 0.40, 0.34))
	var roof := PackedVector2Array([
		Vector2(x - 12, y), Vector2(x + w / 2, y - 38), Vector2(x + w + 12, y),
	])
	draw_colored_polygon(roof, Color(0.34, 0.20, 0.10))
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2]]), Color(0.26, 0.14, 0.06), 2)
	draw_rect(Rect2(x + w / 2 - 22, y + h - 58, 44, 58), Color(0.22, 0.14, 0.07))
	draw_rect(Rect2(x + w / 2 - 22, y + h - 58, 44, 58), Color(0.34, 0.22, 0.11), false, 1.5)
	for i in range(3):
		draw_rect(Rect2(x + 18 + i * 66, y + 22, 38, 28), Color(0.62, 0.70, 0.80))
		draw_rect(Rect2(x + 18 + i * 66, y + 22, 38, 28), Color(0.28, 0.18, 0.09), false, 1.5)
	draw_rect(Rect2(x, y, w, h), Color(0.32, 0.26, 0.20), false, 1.5)


func _draw_building(x: float, y: float, w: float, h: float, clr: Color, _name: String) -> void:
	draw_rect(Rect2(x, y, w, h), clr)
	var roof := PackedVector2Array([
		Vector2(x - 8, y), Vector2(x + w / 2, y - 30), Vector2(x + w + 8, y),
	])
	draw_colored_polygon(roof, Color(0.30, 0.17, 0.08))
	draw_polyline(PackedVector2Array([roof[0], roof[1], roof[2]]), Color(0.24, 0.12, 0.05), 1.5)
	draw_rect(Rect2(x + w / 2 - 15, y + h - 44, 30, 44), Color(0.22, 0.14, 0.07))
	draw_rect(Rect2(x + 14, y + 20, 30, 22), Color(0.62, 0.70, 0.80))
	draw_rect(Rect2(x + w - 44, y + 20, 30, 22), Color(0.62, 0.70, 0.80))
	draw_rect(Rect2(x, y, w, h), Color(0.32, 0.26, 0.20), false, 1.5)


func _draw_ship(x: float, y: float) -> void:
	# Hull
	var hull := PackedVector2Array([
		Vector2(x - 20, y + 22), Vector2(x + 295, y + 22),
		Vector2(x + 316, y + 48), Vector2(x + 272, y + 86),
		Vector2(x + 14, y + 86), Vector2(x - 26, y + 50),
	])
	draw_colored_polygon(hull, Color(0.22, 0.15, 0.08))
	draw_polyline(PackedVector2Array([
		hull[0], hull[1], hull[2], hull[3], hull[4], hull[5], hull[0],
	]), Color(0.38, 0.28, 0.14), 2)
	for i in range(1, 4):
		draw_line(Vector2(x - 8 + i * 3, y + 34.0 + i * 14.0),
			Vector2(x + 296 - i * 2, y + 34.0 + i * 14.0),
			Color(0.30, 0.20, 0.10, 0.45), 1)
	# Deck
	draw_rect(Rect2(x, y + 12, 295, 14), Color(0.40, 0.29, 0.15))
	draw_line(Vector2(x, y + 12), Vector2(x + 295, y + 12), Color(0.54, 0.42, 0.20), 2)
	for i in range(0, 295, 20):
		draw_line(Vector2(x + i, y + 12), Vector2(x + i, y), Color(0.30, 0.20, 0.10), 2)
	draw_line(Vector2(x, y), Vector2(x + 295, y), Color(0.30, 0.20, 0.10), 2)
	# Masts
	draw_line(Vector2(x + 165, y + 12), Vector2(x + 165, y - 185), Color(0.26, 0.18, 0.08), 5)
	draw_line(Vector2(x + 88, y + 12), Vector2(x + 88, y - 140), Color(0.26, 0.18, 0.08), 4)
	draw_line(Vector2(x + 110, y - 152), Vector2(x + 220, y - 152), Color(0.26, 0.18, 0.08), 3)
	draw_line(Vector2(x + 60, y - 112), Vector2(x + 116, y - 112), Color(0.26, 0.18, 0.08), 2)
	# Main sail
	var sail := PackedVector2Array([
		Vector2(x + 112, y - 152), Vector2(x + 218, y - 152),
		Vector2(x + 212, y - 26), Vector2(x + 118, y - 26),
	])
	draw_colored_polygon(sail, Color(0.90, 0.86, 0.74, 0.88))
	draw_polyline(PackedVector2Array([sail[0], sail[1], sail[2], sail[3], sail[0]]),
		Color(0.62, 0.56, 0.44), 1)
	# Fore sail
	var fsail := PackedVector2Array([
		Vector2(x + 62, y - 112), Vector2(x + 114, y - 112),
		Vector2(x + 110, y - 24), Vector2(x + 64, y - 24),
	])
	draw_colored_polygon(fsail, Color(0.90, 0.86, 0.74, 0.80))
	# Flag
	draw_colored_polygon(PackedVector2Array([
		Vector2(x + 165, y - 185), Vector2(x + 196, y - 173),
		Vector2(x + 165, y - 161),
	]), Color(0.78, 0.16, 0.10))


func _draw_crate_stack(x: float, y: float) -> void:
	draw_rect(Rect2(x, y - 28, 42, 28), Color(0.44, 0.32, 0.16))
	draw_rect(Rect2(x, y - 28, 42, 28), Color(0.28, 0.18, 0.09), false, 1.5)
	draw_line(Vector2(x + 21, y - 28), Vector2(x + 21, y), Color(0.28, 0.18, 0.09, 0.65), 1)
	draw_line(Vector2(x, y - 14), Vector2(x + 42, y - 14), Color(0.28, 0.18, 0.09, 0.65), 1)
	draw_rect(Rect2(x + 4, y - 50, 34, 22), Color(0.46, 0.34, 0.18))
	draw_rect(Rect2(x + 4, y - 50, 34, 22), Color(0.28, 0.18, 0.09), false, 1.5)
	draw_line(Vector2(x + 21, y - 50), Vector2(x + 21, y - 28), Color(0.28, 0.18, 0.09, 0.65), 1)


func _draw_barrel_group(x: float, y: float) -> void:
	_draw_barrel(x, y - 4)
	_draw_barrel(x + 22, y)
	_draw_barrel(x + 44, y - 4)


func _draw_barrel(x: float, y: float) -> void:
	var pts := PackedVector2Array()
	for i in range(24):
		var a := float(i) / 24.0 * TAU
		pts.append(Vector2(x + cos(a) * (8.0 + abs(sin(a)) * 2.0), y + sin(a) * 14.0))
	draw_colored_polygon(pts, Color(0.36, 0.25, 0.11))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.22, 0.14, 0.07), 1)
	for i in range(3):
		draw_line(Vector2(x - 9, y - 8.0 + i * 8.0), Vector2(x + 9, y - 8.0 + i * 8.0),
			Color(0.50, 0.38, 0.16), 2)


func _draw_net(x: float, y: float) -> void:
	var c := Color(0.55, 0.47, 0.30, 0.72)
	for i in range(8):
		draw_line(Vector2(x + i * 13.0, y), Vector2(x + i * 13.0 - 10.0, y + 50.0), c, 1)
	for j in range(5):
		draw_line(Vector2(x, y + j * 12.0), Vector2(x + 95.0, y + j * 10.0), c, 1)


func _draw_rope_coil(x: float, y: float) -> void:
	for i in range(3):
		var r := 14.0 - i * 4.0
		var pts := PackedVector2Array()
		for j in range(20):
			var a := float(j) / 20.0 * TAU
			pts.append(Vector2(x + cos(a) * r, y + sin(a) * r * 0.42))
		draw_polyline(pts + PackedVector2Array([pts[0]]),
			Color(0.58, 0.46, 0.26, 0.80), 2)
