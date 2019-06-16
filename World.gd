extends Node2D

export (int) var render_distance = 2
export (Vector2) var world_size = Vector2(6,4)

# Called when the node enters the scene tree for the first time.
func _ready():
	var tilemap = $TileMap
	tilemap.world_size = world_size
	tilemap.generate_world()
	var center_pos_pixels = tilemap.map_to_world(tilemap.world_center)
	$Player.position = center_pos_pixels
	var camera = $Player/Camera2D
	var world_height_pixels = tilemap.cell_size.y * tilemap.chunk_size * world_size.y
	camera.limit_top = -world_height_pixels/2 + center_pos_pixels.y
	camera.limit_bottom = world_height_pixels/2 + center_pos_pixels.y 
	# $TileMap.free()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# $TileMap.check_player_location($Player)
	pass