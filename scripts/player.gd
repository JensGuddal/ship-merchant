extends Node2D

const SPEED := 220.0
const DOCK_Y := 462.0
const MIN_X := 30.0
const MAX_X := 1250.0

var walk_cycle := 0.0
var is_walking := false


func _process(delta: float) -> void:
	var dir := 0.0

	if Input.is_action_pressed("ui_right"):
		dir = 1.0
		scale.x = 1.0
	elif Input.is_action_pressed("ui_left"):
		dir = -1.0
		scale.x = -1.0

	is_walking = dir != 0.0
	if is_walking:
		walk_cycle += delta * 9.0

	position.x += dir * SPEED * delta
	position.x = clamp(position.x, MIN_X, MAX_X)
	position.y = DOCK_Y

	if is_walking:
		queue_redraw()


func _draw() -> void:
	var leg_swing := sin(walk_cycle) * 6.0 if is_walking else 0.0

	# Drop shadow
	var shadow := PackedVector2Array()
	for i in range(16):
		var a := float(i) / 16.0 * TAU
		shadow.append(Vector2(cos(a) * 13.0, sin(a) * 4.0) + Vector2(0, 4))
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.22))

	# Left leg
	draw_rect(Rect2(-9, -4 + leg_swing, 8, 20), Color(0.16, 0.16, 0.35))
	# Right leg
	draw_rect(Rect2(1, -4 - leg_swing, 8, 20), Color(0.16, 0.16, 0.35))
	# Boots
	draw_rect(Rect2(-10, 12 + leg_swing, 10, 6), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(0, 12 - leg_swing, 10, 6), Color(0.12, 0.08, 0.05))

	# Coat body
	draw_rect(Rect2(-12, -48, 24, 52), Color(0.20, 0.38, 0.62))
	# Coat front panel
	draw_rect(Rect2(-5, -48, 10, 52), Color(0.26, 0.46, 0.72))
	# Coat lapels
	draw_rect(Rect2(-5, -48, 5, 16), Color(0.88, 0.84, 0.70))
	draw_rect(Rect2(0, -48, 5, 16), Color(0.88, 0.84, 0.70))
	# Coat buttons
	for i in range(3):
		draw_circle(Vector2(0, -35 + i * 10), 2, Color(0.65, 0.50, 0.12))
	# Belt
	draw_rect(Rect2(-12, -12, 24, 6), Color(0.48, 0.30, 0.10))
	draw_rect(Rect2(-3, -12, 6, 6), Color(0.68, 0.52, 0.14))
	# Coat tails
	draw_rect(Rect2(-12, 2, 10, 16), Color(0.20, 0.38, 0.62))
	draw_rect(Rect2(2, 2, 10, 16), Color(0.20, 0.38, 0.62))

	# Cravat / neck
	draw_rect(Rect2(-4, -54, 8, 8), Color(0.88, 0.84, 0.70))
	# Head
	draw_circle(Vector2(0, -64), 13, Color(0.88, 0.72, 0.58))
	# Ear
	draw_circle(Vector2(10, -64), 4, Color(0.82, 0.66, 0.52))
	# Eye
	draw_circle(Vector2(6, -66), 2.5, Color(0.14, 0.10, 0.08))
	draw_circle(Vector2(7, -67), 1, Color(1, 1, 1, 0.6))
	# Eyebrow
	draw_line(Vector2(3, -70), Vector2(9, -69), Color(0.28, 0.18, 0.10), 1)
	# Nose
	draw_line(Vector2(8, -65), Vector2(9, -61), Color(0.75, 0.58, 0.44), 1)
	# Mouth
	draw_line(Vector2(4, -59), Vector2(9, -58), Color(0.68, 0.44, 0.36), 1)

	# Hat brim
	draw_rect(Rect2(-16, -80, 32, 7), Color(0.16, 0.10, 0.05))
	# Hat crown
	draw_rect(Rect2(-10, -100, 20, 24), Color(0.16, 0.10, 0.05))
	# Hat band
	draw_rect(Rect2(-10, -82, 20, 5), Color(0.58, 0.44, 0.10))
	# Hat highlight
	draw_line(Vector2(-9, -99), Vector2(-9, -84), Color(0.28, 0.18, 0.09, 0.5), 2)
