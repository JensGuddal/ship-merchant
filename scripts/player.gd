extends CharacterBody2D

const SPEED := 100.0

enum Dir { DOWN, UP, LEFT, RIGHT }
var facing := Dir.DOWN

var walk_cycle := 0.0
var is_moving := false


func _physics_process(delta: float) -> void:
	var input := Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		input.x = 1.0
		facing = Dir.RIGHT
	elif Input.is_action_pressed("ui_left"):
		input.x = -1.0
		facing = Dir.LEFT

	if Input.is_action_pressed("ui_down"):
		input.y = 1.0
		facing = Dir.DOWN
	elif Input.is_action_pressed("ui_up"):
		input.y = -1.0
		facing = Dir.UP

	is_moving = input.length() > 0.0

	if is_moving:
		input = input.normalized()
		walk_cycle += delta * 9.0
		queue_redraw()

	velocity = input * SPEED
	move_and_slide()


func _draw() -> void:
	var bob := sin(walk_cycle) * 1.5 if is_moving else 0.0
	var ll  := sin(walk_cycle) * 5.0 if is_moving else 0.0
	var rl  := -sin(walk_cycle) * 5.0 if is_moving else 0.0

	_draw_shadow()

	# Legs and boots
	draw_rect(Rect2(-8, -4 + ll, 7, 16), Color(0.16, 0.16, 0.34))
	draw_rect(Rect2(1,  -4 + rl, 7, 16), Color(0.16, 0.16, 0.34))
	draw_rect(Rect2(-9, 10 + ll, 9, 5),  Color(0.13, 0.08, 0.05))
	draw_rect(Rect2(0,  10 + rl, 9, 5),  Color(0.13, 0.08, 0.05))

	# Coat body
	draw_rect(Rect2(-11, -44 + bob, 22, 50), Color(0.20, 0.38, 0.62))
	draw_rect(Rect2(-5,  -44 + bob, 10, 22), Color(0.88, 0.84, 0.70))
	for i in range(3):
		draw_circle(Vector2(0, -34.0 + i * 9.0 + bob), 1.5, Color(0.65, 0.50, 0.12))
	draw_rect(Rect2(-11, -10 + bob, 22, 5), Color(0.50, 0.32, 0.10))
	draw_rect(Rect2(-3,  -10 + bob,  6, 5), Color(0.70, 0.54, 0.14))
	draw_rect(Rect2(-11,  4 + bob,  9, 14), Color(0.18, 0.34, 0.56))
	draw_rect(Rect2(2,    4 + bob,  9, 14), Color(0.18, 0.34, 0.56))

	# Head and neck
	draw_rect(Rect2(-3, -50 + bob, 6, 8), Color(0.88, 0.72, 0.58))
	draw_circle(Vector2(0, -60 + bob), 12, Color(0.88, 0.72, 0.58))

	# Face details depending on direction
	match facing:
		Dir.DOWN:
			draw_circle(Vector2(-4, -62 + bob), 2.0, Color(0.14, 0.10, 0.08))
			draw_circle(Vector2( 4, -62 + bob), 2.0, Color(0.14, 0.10, 0.08))
			draw_circle(Vector2(-3, -63 + bob), 0.8, Color(1, 1, 1, 0.55))
			draw_circle(Vector2( 5, -63 + bob), 0.8, Color(1, 1, 1, 0.55))
			draw_arc(Vector2(0, -56 + bob), 3.5, 0.25, PI - 0.25, 8,
				Color(0.55, 0.34, 0.28), 1)
		Dir.LEFT:
			draw_circle(Vector2(-6, -62 + bob), 2.0, Color(0.14, 0.10, 0.08))
			draw_circle(Vector2(-5, -63 + bob), 0.8, Color(1, 1, 1, 0.55))
			draw_line(Vector2(-9, -60 + bob), Vector2(-11, -56 + bob),
				Color(0.75, 0.55, 0.42), 1)
		Dir.RIGHT:
			draw_circle(Vector2(6, -62 + bob), 2.0, Color(0.14, 0.10, 0.08))
			draw_circle(Vector2(7, -63 + bob), 0.8, Color(1, 1, 1, 0.55))
			draw_line(Vector2(9, -60 + bob), Vector2(11, -56 + bob),
				Color(0.75, 0.55, 0.42), 1)
		Dir.UP:
			pass  # shows back of head only

	# Hat
	draw_rect(Rect2(-14, -74 + bob, 28,  6), Color(0.16, 0.10, 0.05))
	draw_rect(Rect2( -9, -92 + bob, 18, 22), Color(0.16, 0.10, 0.05))
	draw_rect(Rect2( -9, -76 + bob, 18,  5), Color(0.58, 0.44, 0.10))
	draw_line(Vector2(-8, -91 + bob), Vector2(-8, -78 + bob),
		Color(0.28, 0.18, 0.09, 0.45), 2)


func _draw_shadow() -> void:
	var pts := PackedVector2Array()
	for i in range(16):
		var a := float(i) / 16.0 * TAU
		pts.append(Vector2(cos(a) * 11.0, sin(a) * 4.0 + 5.0))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.20))
