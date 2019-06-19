extends TileMap

export(int)var chunk_size = 8
export(bool)var island = false

var elevation_noise := OpenSimplexNoise.new()
var moisture_noise  := OpenSimplexNoise.new()
var generation_distance := 6
var generated_chunks := []
var chunk_queue := []
var generated_tiles := {} setget , _get_generation_tiles
var detection_areas := []
var current_chunk := Vector2(0,0)
var world_size = Vector2(200,200)
onready var world_center_x = (world_size.x * chunk_size) / 2
onready var world_center_y = (world_size.y * chunk_size) / 2
onready var world_center = Vector2(world_center_x, world_center_y)
onready var player = $Player
onready var camera = $Player/Camera2D
onready var player_tile setget , _get_player_tile
onready var player_chunk setget , _get_player_chunk
onready var debug_map = $DebugMap
signal remove_me(object)
signal add_me(object)

var data_gen_thread
var tile_setting_thread
var mutex
var semaphore

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

func _ready():
	data_gen_thread = Thread.new()
	tile_setting_thread = Thread.new()
	mutex = Mutex.new()
	semaphore = Semaphore.new()
	elevation_noise.period = 150
	elevation_noise.persistence = 0.4
	elevation_noise.octaves = 6
	elevation_noise.lacunarity = 2
	
	moisture_noise.period = 200
	moisture_noise.persistence = 0.5
	moisture_noise.octaves = 2
	randomize()
	elevation_noise.seed = randi()
	moisture_noise.seed = randi()
	debug_map.cell_size = cell_size
	debug_map.scale = scale
	generate_world()

func _add_to_chunk_queue(coords):
	if not generated_chunks.has(coords):
		if not chunk_queue.has(coords):
			chunk_queue.append(coords)

func get_visible_tiles():
	# Get view rectangle
	var ctrans = get_canvas_transform()
	var min_pos = -ctrans.get_origin() / ctrans.get_scale()
	var view_size = get_viewport_rect().size / ctrans.get_scale()
	var max_pos = min_pos + view_size
			

func _process(delta):
	DEBUG.set_text("chunk_queue", chunk_queue)
	DEBUG.set_text("player_tile", self.player_tile)
	DEBUG.set_text("tile_info", _get_player_tile_info_text())
	DEBUG.set_text("thread_active", tile_setting_thread.is_active())
	DEBUG.set_text("zoom", camera.zoom)
	DEBUG.set_text("camera_offset", camera.offset)
	for x in range(-generation_distance/2,generation_distance/2):
		for y in range(-generation_distance/2,generation_distance/2):
			_add_to_chunk_queue(self.player_chunk + Vector2(x,y))
	
	if chunk_queue.size() > 0:
		generate_queued_chunks()

func queue_chunks_in_view():
	pass

func generate_queued_chunks() -> void:
	var chunk = chunk_queue.pop_front()
	var chunk_contents = generate_chunk_contents(chunk)
	var new_chunk = TileMap.new()
	new_chunk.cell_size = cell_size
	new_chunk.tile_set = tile_set
	new_chunk.collision_mask = collision_mask
	new_chunk.collision_layer = collision_layer
	new_chunk.show_behind_parent = true
	generate_chunks(chunk_contents, new_chunk)

func generate_chunks(chunk,new_chunk):
	var coords
	for tile in chunk.keys():
		coords = _map_to_chunk(tile)
		new_chunk.set_cellv(tile, chunk[tile].type)
		DEBUG.set_text("generating_tile", tile)
		generated_tiles[tile] = chunk[tile]
		pass
	generated_chunks.append(coords)
	add_child(new_chunk)
	return new_chunk

func generate_world():
	pass

func generate_chunk_contents(chunk_coords):
	var contents := {}
	var x_off
	var y_off
	
	var tile_center_distance_max = Vector2(0,0).distance_to(world_center)
	var equator_distance_max = Vector2(0,0).distance_to(Vector2(0, world_center_y))
#	tile_setting_thread.wait_to_finish()
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
			
			elevation = noise_value_normalize(elevation)
			moisture = noise_value_normalize(moisture)
			
			
			if island:
				# squish distance value to between 0 and 1
				var tile_center_distance = world_coords.distance_to(world_center)
				var equator_distance = world_coords.distance_to(world_center)
				tile_center_distance /= tile_center_distance_max
				equator_distance /= equator_distance_max
				
				# push edges near the ground
				elevation = elevation_distance_shape(elevation, tile_center_distance)
				# center moisture near the equator
				moisture = moisture_distance_shape(moisture, equator_distance)

			
			
			# elevation = tile_center_distance
			# determine cell type
			var cell_type = choose_cell(elevation, moisture)
			
			# add cell type and position to tiles dict
			# use this to actually set the chunk's cells later
			# keep in mind you will need to establish what chunk this is in later
			# because the data only returns local coordinates for each chunk.
			# that being (0,0) through (15,15), for example.
			
			contents[world_coords] = {"type" : cell_type,
				"cell" : tile_set.tile_get_name(cell_type),
				"local_coordinates" : local_coords,
				"chunk_coordinates" : chunk_coords}
#			print(contents[world_coords])
#			call_deferred("generate_chunk", contents 
	return contents
	pass

	
func elevation_distance_shape(elevation, distance):
	return elevation_lower(distance) + elevation * (elevation_upper(distance) - elevation_lower(distance))

func elevation_lower(d):
	return (1 - d)/10
	return 0

func elevation_upper(d):
	return 1 - (pow(d,1.4))
	pass

func moisture_distance_shape(moisture, distance):
	return moisture_lower(distance) + moisture * (moisture_upper(distance) - moisture_lower(distance))

func moisture_lower(d):
	return (1 - d)/2

func moisture_upper(d):
	return 1 - pow(d, 2)
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
		return cell("sand")
		
	if threshold >= heights.grass and threshold < heights.jungle:
		if moisture >= 0.60:
			return cell("marsh")
		return cell("grass")
	
	if threshold >= heights.jungle and threshold < heights.mountain_cliff:
		if moisture >= 0.65:
			return cell("swamp")
		return cell("jungle")
		
	if threshold >= heights.mountain_cliff and threshold < heights.mountain:
		return cell("mountain_cliff")
	
	if threshold >= heights.mountain and threshold < heights.snowy_mountain:
		return cell("mountain")
	
	if threshold >= heights.snowy_mountain:
		return cell("snowy_mountain")
	return 0

func noise_value_normalize(value):
	# converts noise value from -1-1 to 0-1
	var result = value * 0.5 + 0.5
	return result
	
func _map_to_chunk(tile):
	var chunk = Vector2()
	chunk.x = int(tile.x) / chunk_size
	chunk.y = int(tile.y) / chunk_size
	if tile.x < 0:
		chunk.x -= 1
	if tile.y < 0:
		chunk.y -= 1
	return chunk
	pass
	
func _get_player_tile():
	return world_to_map($Player.position)

func _get_player_tile_info_text():
	var player_tile = _get_player_tile()
	var data = {"none" : null}
	if generated_tiles.keys().has(player_tile):
		data = self.generated_tiles[player_tile]
	var text = ""
	for key in data.keys():
		text = str(text, "\n    ", key, ": ", data[key])
	return text

func _get_generation_tiles():
	mutex.lock()
	var tiles = generated_tiles
	mutex.unlock()
	return tiles

func _get_player_chunk():
	var player_tile = _get_player_tile()
	var chunk = _map_to_chunk(player_tile)
	return chunk

func place_player(pos : Vector2, max_distance : int) -> Vector2:
	var available_tiles = find_starting_area(pos, max_distance)
	pos = available_tiles[randi() % int(max(available_tiles.size(), 1))]
	player.position = map_to_world(pos)
	return pos

func find_starting_area(pos : Vector2, max_distance : int) -> Array:
	var available_tiles := []
	for x in range(max_distance):
		for y in range(max_distance):
			var coords = Vector2(x + pos.x, y + pos.y)
#			if get_cellv(coords) == cell("grass"):
			available_tiles.append(coords)
			
	if available_tiles.size() == 0:
		available_tiles = find_starting_area(pos, max_distance + 5)
	return available_tiles

func clear_chunk(chunk_coords : Vector2):
	for x in range(chunk_size):
		for y in range(chunk_size):
			var x_off = (chunk_size * chunk_coords.x)
			var y_off = (chunk_size * chunk_coords.y)
			var world_coords = Vector2(x + x_off, y + y_off)
			set_cellv(world_coords, -1)

func regenerate():
	for x in range(world_size.x):
		for y in range(world_size.y):
			clear_chunk(Vector2(x, y))
	generate_world()
	
func _exit_tree():
	tile_setting_thread.wait_to_finish()
