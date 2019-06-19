extends KinematicBody2D
var max_speed = 1000
var accel = 0
var current_speed = 0
onready var environment : Node = get_node("../TileMap")

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	move_and_slide(move() * max_speed)
	
	if Input.is_action_just_pressed("zoom_in"):
		$Camera2D.zoom_in()
	if Input.is_action_just_pressed("zoom_out"):
		$Camera2D.zoom_out()
	pass

func move():
	var move_vec = Vector2(0,0)
	if Input.is_action_pressed("move_up"):
		move_vec.y = -1
	if Input.is_action_pressed("move_down"):
		move_vec.y = 1
	if Input.is_action_pressed("move_left"):
		move_vec.x = -1
	if Input.is_action_pressed("move_right"):
		move_vec.x = 1
	return move_vec.normalized()
