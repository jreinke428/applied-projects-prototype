extends TileMap

@onready var world_boundaries = $WorldBoundaries

var noise: FastNoiseLite
var world_size = Vector2i(50, 50)
var water_altitude = 0.20
var water_cells = []
var grass_cells = []
var object_cells = []

var ground_layer = 0
var object_layer = 1
var water_tileset = 1
var grass_tileset = 0
var object_tileset = 2
var object_tiles = [1, 2]
var object_chance = 0.06

func _ready():
	if multiplayer.is_server(): generate_terrain()
	set_boundaries()

func initialize_noise():
	noise = FastNoiseLite.new()
	noise.set_seed(randi())
	noise.set_noise_type(FastNoiseLite.TYPE_SIMPLEX)
	noise.set_fractal_gain(0.4)
	noise.set_fractal_octaves(3)
	noise.set_frequency(0.04)

func generate_terrain():
	initialize_noise()
	
	# Place down placeholder tiles for each surface tile
	for x in range(-1, world_size.x+1):
		for y in range(-1, world_size.y+1):
			var altitude = abs(noise.get_noise_2d(x, y))
			var world_position = Vector2i(x, y)
			if altitude < water_altitude:
				place_water.rpc(world_position)
			else:
				place_grass.rpc(world_position)
		await get_tree().create_timer(0.1).timeout
	
	for cell in grass_cells:
		for tile in object_tiles:
			if randf() <= object_chance:
				place_object.rpc(cell, tile)
	
	connect_terrain.rpc()
	Signals.world_loaded.emit()
	
func set_boundaries():
	for boundary in [[Vector2.ZERO, Vector2.RIGHT], [Vector2.ZERO, Vector2.DOWN], [world_size*16, Vector2.UP], [world_size*16, Vector2.LEFT]]:
		var b = CollisionShape2D.new()
		b.shape = WorldBoundaryShape2D.new()
		b.shape.normal = boundary[1]
		b.global_position = boundary[0]
		world_boundaries.add_child(b)
	
func is_in_water(pos):
	var map_pos = local_to_map(pos)
	if get_cell_source_id(ground_layer, map_pos) == 1:
		if get_cell_source_id(ground_layer, map_pos+Vector2i.UP) == 0 and int(pos.y) % 16 < 4: return false
		if get_cell_source_id(ground_layer, map_pos+Vector2i.RIGHT) == 0 and int(pos.x) % 16 > 12: return false
		if get_cell_source_id(ground_layer, map_pos+Vector2i.DOWN) == 0 and int(pos.y) % 16 > 8: return false
		if get_cell_source_id(ground_layer, map_pos+Vector2i.LEFT) == 0 and int(pos.x) % 16 < 4: return false
		if get_cell_source_id(ground_layer, map_pos+Vector2i.UP+Vector2i.RIGHT) == 0 and int(pos.y) % 16 < 4 and int(pos.x) % 16 > 12: return false
		if get_cell_source_id(ground_layer, map_pos+Vector2i.RIGHT+Vector2i.DOWN) == 0 and int(pos.x) % 16 > 12 and int(pos.y) % 16 > 8: return false
		if get_cell_source_id(ground_layer, map_pos+Vector2i.DOWN+Vector2i.LEFT) == 0 and int(pos.y) % 16 > 8 and int(pos.x) % 16 < 4: return false
		if get_cell_source_id(ground_layer, map_pos+Vector2i.LEFT+Vector2i.UP) == 0 and int(pos.x) % 16 < 4 and int(pos.y) % 16 < 4: return false
		return true
	return false

@rpc("any_peer", "call_local", "reliable")
func place_water(coords):
	water_cells.append(coords)
	set_cell(ground_layer, position, water_tileset, Vector2i(0,0))
	
@rpc("any_peer", "call_local", "reliable")
func place_grass(coords):
	grass_cells.append(coords)
	set_cell(ground_layer, coords, grass_tileset, Vector2i(0,0))
	
@rpc("any_peer", "call_local", "reliable")
func place_object(coords, tile):
	object_cells.append(coords)
	set_cell(object_layer, coords, object_tileset, Vector2i.ZERO, tile)
	
@rpc("any_peer", "call_local", "reliable")
func connect_terrain():
	set_cells_terrain_connect(ground_layer, water_cells, 0, 0)
	set_cells_terrain_connect(ground_layer, grass_cells, 0, 1)
