extends Node2D

var _text_lines = {}
var _tiles = []
onready var _canvas = CanvasLayer.new()
onready var _label = Label.new()
onready var _canvas_painter = CanvasItem.new()
var theme = preload("res://Theme.tres")

func _ready():
	add_child(_canvas)
	_canvas.add_child(_label)
	_canvas.add_child(_canvas_painter)
	_label.theme = theme

func _process(delta):
	var text = ""
	for key in _text_lines.keys():
		var value = _text_lines[key]
		text = str(text, key, ": ", value, "\n")
	_label.text = text
	update()


func draw_tile(coordinates,size):
	var rect = Rect2(coordinates,size)
	_tiles.append(rect)

func _draw():
	for rect in _tiles:
		draw_rect(rect, Color(1,1,0))
	pass
	
func set_text(key, text):
	_text_lines[key] = text
