extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	DEBUG.draw_tile(Vector2(0,0), Vector2(20, 20))
	DEBUG.set_text("hello","hello")
	pass # Replace with function body.
