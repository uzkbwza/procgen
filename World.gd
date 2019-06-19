extends Node

var center_pos

export (int) var render_distance = 2
onready var tilemap = $TileMap
onready var player =  $TileMap/Player
onready var camera = $TileMap/Player/Camera2D
# Called when the node enters the scene tree for the first time.
func _ready():
	var world_size = tilemap.world_size
	center_pos = tilemap.world_center
	var center_pos_pixels = tilemap.map_to_world(center_pos) * tilemap.scale
	var world_width_pixels = tilemap.scale.x * tilemap.cell_size.x * tilemap.chunk_size * world_size.x
	var world_height_pixels = tilemap.scale.y * tilemap.cell_size.y * tilemap.chunk_size * world_size.y
#	camera.limit_top = -world_height_pixels/2 + center_pos_pixels.y
#	camera.limit_bottom = world_height_pixels/2 + center_pos_pixels.y 
#	camera.limit_left = -world_width_pixels/2 + center_pos_pixels.x
#	camera.limit_right = world_width_pixels/2 + center_pos_pixels.x
	tilemap.place_player(Vector2(0,0), tilemap.chunk_size)
	tilemap.connect("remove_me", self, "remove_")
	tilemap.connect("add_me", self, "add_")

	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		tilemap.elevation_noise.seed = randi()
		tilemap.moisture_noise.seed = randi()
		tilemap.regenerate()
		tilemap.place_player(center_pos, tilemap.chunk_size)
	pass
func remove_(tilemap):
	remove_child(tilemap)
func add_(tilemap):
	add_child(tilemap)
