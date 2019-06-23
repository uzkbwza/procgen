extends Node

export(bool)var island = true
export(int)var chunk_size = 8

var tile_set
var elevation_noise = OpenSimplexNoise.new()
var moisture_noise = OpenSimplexNoise.new()

var world_size = Vector2(200,200)
onready var world_center_x = (world_size.x * chunk_size) / 2
onready var world_center_y = (world_size.y * chunk_size) / 2
onready var world_center = Vector2(world_center_x, world_center_y)

var heights = {
	"water" : 0,
	"shore" : 34,
	"sand" : 37,
	"grass" : 43,
	"jungle" : 46,
	"mountain_cliff" : 53,
	"mountain" : 57,
	"snowy_mountain" : 63
	}

func init():
	pass

func _ready():
	
	elevation_noise.period = 700
	elevation_noise.persistence = 0.8
	elevation_noise.octaves = 20
	elevation_noise.lacunarity = 2
	
	moisture_noise.period = 200
	moisture_noise.persistence = 0.5
	moisture_noise.octaves = 2
	
	randomize()
	
	elevation_noise.seed = randi()
	moisture_noise.seed = randi()

func generate_chunk_contents(chunk_coords):
	var contents := {}
	var x_off
	var y_off
	
	var tile_center_distance_max = Vector2(0,0).distance_to(world_center)
	var equator_distance_max = Vector2(0,0).distance_to(Vector2(0, world_center_y))
	
	DEBUG.set_text("generating_chunk", chunk_coords)
	for x in range(chunk_size):
		for y in range(chunk_size):
			x_off = (chunk_size * chunk_coords.x)
			y_off = (chunk_size * chunk_coords.y)
			var local_coords = Vector2(x, y)
			var world_coords = Vector2(x + x_off, y + y_off)

			# get distance of tile to center of world
			
			# gets noise values for position
			var elevation = elevation_noise.get_noise_2dv(world_coords)
			var moisture = moisture_noise.get_noise_2dv(world_coords)
			
			elevation = _noise_value_normalize(elevation)
			moisture = _noise_value_normalize(moisture)
			
			var tile_center_distance
			
			if island:
				# squish distance value to between 0 and 1
				tile_center_distance = world_coords.distance_to(world_center)
				var equator_distance = world_coords.distance_to(world_center)
				tile_center_distance /= tile_center_distance_max
				equator_distance /= equator_distance_max
				
				# push edges near the ground
				elevation = _elevation_distance_shape(elevation, tile_center_distance)
				# center moisture near the equator
				moisture = _moisture_distance_shape(moisture, equator_distance)

			
			
			# elevation = tile_center_distance
			# determine _cell type
			var cell_type = _choose_cell(elevation, moisture)
			
			# add _cell type and position to tiles dict
			# use this to actually set the chunk's cells later
			# keep in mind you will need to establish what chunk this is in later
			# because the data only returns local coordinates for each chunk.
			# that being (0,0) through (15,15), for example.
			
			var tile_info = {"type" : cell_type,
				"_cell" : tile_set.tile_get_name(cell_type),
				"local_coordinates" : local_coords,
				"chunk_coordinates" : chunk_coords}

			if island:
				tile_info["distance_to_center"] = tile_center_distance
				
			contents[world_coords] = tile_info
#			print(contents[world_coords])
#			call_deferred("generate_chunk", contents 
	return contents
	pass

func _cell(cell_name):
	return tile_set.find_tile_by_name(cell_name)

func _choose_cell(elevation, moisture) -> int:
	var threshold = elevation * 100
	if threshold < heights.shore:
		return _cell("water")
		
	if threshold >= heights.shore and threshold < heights.sand:
		return _cell("shore")
		
	if threshold >= heights.sand and threshold < heights.grass:
		return _cell("sand")
		
	if threshold >= heights.grass and threshold < heights.jungle:
		if moisture >= 0.60:
			return _cell("marsh")
		return _cell("grass")
	
	if threshold >= heights.jungle and threshold < heights.mountain_cliff:
		if moisture >= 0.65:
			return _cell("swamp")
		return _cell("jungle")
		
	if threshold >= heights.mountain_cliff and threshold < heights.mountain:
		return _cell("mountain_cliff")
	
	if threshold >= heights.mountain and threshold < heights.snowy_mountain:
		return _cell("mountain")
	
	if threshold >= heights.snowy_mountain:
		return _cell("snowy_mountain")
	return 0

func _noise_value_normalize(value):
	# converts noise value from -1-1 to 0-1
	var result = value * 0.5 + 0.5
	return result

func _elevation_distance_shape(elevation, distance):
	return _elevation_lower(distance) + elevation * (_elevation_upper(distance) - _elevation_lower(distance))

func _elevation_lower(d):
	return (1 - d)/10

func _elevation_upper(d):
	return 1 - (pow(d,1.4))
	pass

func _moisture_distance_shape(moisture, distance):
	return _moisture_lower(distance) + moisture * (_moisture_upper(distance) - _moisture_lower(distance))

func _moisture_lower(d):
	return (1 - d)/2

func _moisture_upper(d):
	return 1 - pow(d, 2)
	pass