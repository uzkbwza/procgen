extends Camera2D

export (Array) var zoom_array = [2, 1, 0.5]
var current_zoom_index = 0
onready var tween = $ZoomTween

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	change_zoom(current_zoom_index)
	pass # Replace with function body.

func change_zoom(index):
	tween.interpolate_property(
		self, 
		"zoom", 
		zoom, 
		Vector2(
			zoom_array[current_zoom_index], 
			zoom_array[current_zoom_index]), 
			0.5, 
			Tween.TRANS_CUBIC, 
			Tween.EASE_OUT)
	tween.start()

func zoom_in():
	if current_zoom_index == len(zoom_array) - 1:
		return
	current_zoom_index = clamp((current_zoom_index + 1), 0, len(zoom_array) - 1)
	change_zoom(current_zoom_index)
	
func zoom_out():
	if current_zoom_index == 0:
		return
	current_zoom_index = clamp((current_zoom_index - 1), 0, len(zoom_array))
	change_zoom(current_zoom_index)
	