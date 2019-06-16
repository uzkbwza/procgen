tool
extends TileMap

export(int)var chunk_size
export(float)var island_bias = 1 

var elevation_noise := OpenSimplexNoise.new()
var moisture_noise  := OpenSimplexNoise.new()
var generation_distance := 3
var generated_chunks := {}
var detection_areas := []
var current_chunk := Vector2(0,0)
var world_size
var world_center

var heights = {
	"water" : 0,
	"shore" : 37,
	"sand" : 40,
	"grass" : 44,
	"dirt" : 55,
	"mountain" : 60
	}

func _ready():
	elevation_noise.period = 18
	elevation_noise.persistence = 0.4
	elevation_noise.octaves = 5
	
	moisture_noise.period = 40
	moisture_noise.persistence = 0.5
	moisture_noise.octaves = 3
	randomize()
	elevation_noise.seed = randi()
	moisture_noise.seed = randi()

func _process(delta):
	pass
	
func elevation_distance_shape(elevation, distance):
	return elevation_lower(distance) + elevation * (elevation_upper(distance) - elevation_lower(distance))


func elevation_lower(d):
	return 0

func elevation_upper(d):
	return 1 - (pow(d,1.4))
	pass

func cell(cell_name):
	return tile_set.find_tile_by_name(cell_name)

func choose_cell(elevation, moisture) -> int:
	var threshold = elevation * 100
	if threshold < heights.shore:
		return cell("water")
		
	if threshold >= heights.shore and threshold < heights.sand:
		return cell("shore")
		
	if threshold >= heights.sand and threshold < heights.grass:
		if moisture >= 0.55:
			return cell("marsh")
		return cell("sand")
		
	if threshold >= heights.grass and threshold < heights.dirt:
		if moisture <= 0.6:
			return cell("grass")
		return cell("jungle")
		
	if threshold >= heights.dirt and threshold < heights.mountain:
		return cell("dirt")
	
	if threshold >= heights.mountain:
		return cell("mountain")
	return 0

func noise_value_normalize(value):
	# converts noise value float (from -1 to 1)
	# to 0-1
	var result = value * 0.5 + 0.5
	return result

func generate_chunk_contents(elevation_noise : OpenSimplexNoise, chunk_coords : Vector2) -> Dictionary:
	var contents := {}
	# init empty dict to contain all tile values
	var x_off
	var y_off
	
	# get max distance to world center
	var world_center_x = (world_size.x * chunk_size) / 2
	var world_center_y = (world_size.y * chunk_size) / 2
	world_center = Vector2(world_center_x, world_center_y)
	var tile_center_distance_max = common.distance(Vector2(0,0), world_center)
	var equator_distance_max = common.distance(Vector2(0,0), Vector2(0, world_center_y))
#	print(tile_center_distance_max)
#	var chunk_center_distance_normalized = chunk_center_distance / chunk_center_distance_max
#	"."yield(get_tree().create_timer(0.1), "timeout")
	for x in range(chunk_size):
		for y in range(chunk_size):
			x_off = (chunk_size * chunk_coords.x)
			y_off = (chunk_size * chunk_coords.y)
			var local_coords = Vector2(x, y)
			var world_coords = Vector2(x + x_off, y + y_off)
			
			# get distance of tile to center of world
			var tile_center_distance = common.distance(
				world_coords, 
				world_center)
				
			var equator_distance = common.distance(
			Vector2(0, world_coords.y), Vector2(0, world_center_y))
			
			# squish distance value to between 0 and 1
			tile_center_distance /= tile_center_distance_max
			
			# gets noise values for position
			var elevation = elevation_noise.get_noise_2dv(world_coords)
			var moisture = moisture_noise.get_noise_2dv(world_coords)
			
			elevation = noise_value_normalize(elevation)
			moisture = noise_value_normalize(moisture)
			
			# push edges near the ground
			elevation = elevation_distance_shape(elevation, tile_center_distance)

			# elevation = tile_center_distance
			# determine cell type
			var cell_type = choose_cell(elevation, moisture)
			
			
			# add cell type and position to tiles dict
			# use this to actually set the chunk's cells later
			# keep in mind you will need to establish what chunk this is in later
			# because the data only returns local coordinates for each chunk.
			# that being (0,0) through (15,15), for example.
#			if x % 8 == 0 and y % 8 == 0:
#				print([world_coords, tile_center_distance, elevation])
			contents[world_coords] = {"type" : cell_type, 
									  "local coordinates" : local_coords, 
									  "chunk coordinates" : chunk_coords,
									  "distance to center" : tile_center_distance}
	return contents
	pass

func generate_chunk(chunk_x : int, chunk_y : int) -> void:
	var chunk_coords = Vector2(chunk_x, chunk_y)
	var contents = generate_chunk_contents(elevation_noise, chunk_coords)
	for tile in contents.keys():
		set_cellv(tile, contents[tile].type)
	generated_chunks[chunk_coords] = contents

func generate_world():
	for x in range(world_size.x):
		for y in range(world_size.y):
			generate_chunk(x,y)