extends Node2D

var tile_set = preload("res://tileset.tres")
var elevation_noise := OpenSimplexNoise.new()
var moisture_noise  := OpenSimplexNoise.new()

func _ready():
	$Generator.tile_set = tile_set
	$TileMap.tile_set = tile_set
	pass # Replace with function body.