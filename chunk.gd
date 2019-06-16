class_name Chunk
# node that represents the contents of a chunk. Occupies space as an area2d 
# but is used to store chunk data in the ChunkMap and has the code
# to generate such data. This node is separate to make sure creating
# and destroying chunks have their own explicit, standard behaviors as
# consistently as possible. A chunk is not aware of its tiles global positions,
# just where they are in itself.

var coordinates : Vector2
var tile_ids : int
var size : int
var detection_rect := RectangleShape2D.new()
var detection_area := CollisionShape2D.new()
var real_size : int

func init(coordinates : Vector2, ids : int, chunk_size : int, cell_size : int) -> void:
	self.coordinates = coordinates
	self.tile_ids = ids
	self.size = chunk_size
	self.real_size = chunk_size * cell_size

func generate_chunk_contents(noise : OpenSimplexNoise) -> Dictionary:
	var contents := {}
	# init empty dict to contain all tile values
	var x_off
	var y_off
	# move position to center
	for y in range(size):
		for x in range(size):
			x_off = (size * coordinates.x)
			y_off = (size * coordinates.y)
			# gets noise values for chunk at offset position
			var value = noise.get_noise_2d(x + x_off, y + y_off)
			
			# determine cell type by normalizing the noise value to the 
			# number of tile types
			value = (value * (tile_ids / 2.0) + tile_ids / 2.0)
			
			# add cell type and position to tiles dict
			# use this to actually set the chunk's cells later
			# keep in mind you will need to establish what chunk this is in later
			# because the data only returns local coordinates for each chunk.
			# that being (0,0) through (15,15), for example.
			contents[Vector2(x, y)] = floor(value)
	return contents
	pass