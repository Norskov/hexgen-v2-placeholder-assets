class_name HexGrid
extends Node2D

signal processing(process: bool)

var _grid_size := 15
var _hex_size := 10

const TOP := ["top", Vector2i(0, -1)]
const TOP_RIGHT := ["top_right", Vector2i(1, -1)]
const TOP_LEFT := ["top_left", Vector2i(-1, 0)]
const BOTTOM := ["bottom", Vector2i(0, 1)]
const BOTTOM_RIGHT := ["bottom_right", Vector2i(1, 0)]
const BOTTOM_LEFT := ["bottom_left", Vector2i(-1, 1)]

const NEIGHBOUR_DIRECTIONS := [TOP, TOP_RIGHT, BOTTOM_RIGHT, BOTTOM, BOTTOM_LEFT, TOP_LEFT]
const OPPOSITE_DIRECTION := {
	"top" = BOTTOM,
	"top_right" = BOTTOM_LEFT,
	"top_left" = BOTTOM_RIGHT,
	"bottom" = TOP,
	"bottom_right" = TOP_LEFT,
	"bottom_left" = TOP_RIGHT
}

var grid := {}

var _origin: Vector2

const ICON = preload("res://icon.svg")

var _hexes: Array[HexConfig]

var fill := false:
	set(new_fill):
		if new_fill:
			fill_random = true
		fill = new_fill
var fill_random := false	

var PLACEHOLDER := Texture2D.new()

var _edge_types
var border_edge_type: HexConfig.EdgeType
var border_edge: HexConfig.HexEdge

signal hex_clicked(hex: Hex)

func _init(hexes: Array[HexConfig], edge_types: Dictionary):
	_hexes = hexes
	_edge_types = edge_types

var loaded := false

# Called when the node enters the scene tree for the first time.
func init_everything() -> void:
	set_size("5")
			
func init_grid() -> void:
	var start := (_grid_size - 1) / 2
	_origin = position
	
	for i in range(-start, start + 1):
		for j in range(-start, start + 1):
			var q = j-i
			var r = i
			var hex := Hex.new(q,r, _hex_size, _origin, PLACEHOLDER, null)
			hex.clicked.connect(clicked.bind(hex))
			grid[hex_key(q, r)] = hex
			add_child(hex)
	
	for h in grid.values():
		set_valid_hexes(h)

func update_border_type(type: String) -> void:
	clear_grid()
	if type == "None":
		border_edge_type = null
		border_edge = null
	else:
		border_edge_type = _edge_types[type.to_lower()]
		border_edge = HexConfig.HexEdge.new(border_edge_type)
	restrict_valid_dict = {}

func update_hex_size(something := 300, _update_hexes := false) -> void:
	_hex_size = something / _grid_size

func set_size(size: String) -> void:
	print("Changing size {0}".format([size]))
	clear_grid(true)
	_grid_size = int(size)
	update_hex_size()
	init_grid()

func toggle_backtracking(toggled_on: bool) -> void:
	backtrack = toggled_on

func stop_process() -> void:
	processing.emit(false)
	fill = false

func fill_grid() -> void:
	print("Fill grid!")
	processing.emit(true)
	fill = true

func clear_grid(fully: bool = false) -> void:
	stop_process()
	success_count = 0
	backtrack_count = 0
	backtrack_remaining = 0
	temp_hex = null
	temp_valid = []
	temp_index = -1
	backtrack_list = []
	for h in grid.values():
		if fully:
			h.queue_free()
		else:
			clear_hex(h)
	if fully:
		grid = {}

func clear_hex(hex: Hex, include_neighbours: bool = false) -> void:
	hex.update(null)
	set_valid_hexes(hex)
	update_neighbours(hex, include_neighbours)
	
func update_neighbours(hex: Hex, clear: bool = false) -> void:
	for n in get_neighbours(hex._q, hex._r).values():
		if n != null:
			if clear:
				clear_hex(n, false)
			else:
				set_valid_hexes(n)

func cloned_edges(edges: HexConfig.HexEdges) -> HexConfig.HexEdges:
	var temp = HexConfig.HexEdges.new(null)
	temp.top = edges.top
	temp.top_right = edges.top_right
	temp.top_left = edges.top_left
	temp.bottom = edges.bottom
	temp.bottom_right = edges.bottom_right
	temp.bottom_left = edges.bottom_left
	return temp


var temp_hex: Hex
var temp_valid: Array[HexConfig] = []
var temp_index := -1

func clicked(mb: MouseButton, hex: Hex) -> void:
	if mb == MOUSE_BUTTON_RIGHT:
		clear_hex(hex)
		return
	
	if mb == MOUSE_BUTTON_WHEEL_DOWN:
		hex_rotated(hex, "down")
		return
		
	if mb == MOUSE_BUTTON_WHEEL_UP:
		hex_rotated(hex, "up")
		return
		
	if mb == MOUSE_BUTTON_MIDDLE:
		hex_flip(hex)
		return
	
	if mb == MOUSE_BUTTON_LEFT:
		hex_clicked.emit(hex)
		return
	
	var valid: Array[HexConfig]
	
	if temp_hex != null and temp_hex._q == hex._q and temp_hex._r == hex._r and temp_hex._s == hex._s:
		var t := temp_hex
		var h := hex
		valid = temp_valid
	else:
		valid = get_valid_hexes(hex)
		valid.shuffle()
		print("shuffle")
		temp_hex = hex
		temp_valid = valid
		temp_index = valid.find(valid.pick_random())
	
	if valid.is_empty():
		print("No match!")
		return
	
	var config: HexConfig = valid[temp_index]
	update_hex_config(hex, config)

func sort_rotation(a: HexConfig, b: HexConfig):
	if a.rotated < b.rotated:
		return true
	return false	

func hex_rotated(hex: Hex, direction: String) -> void:
	var conf := hex._hex_config
	var valid := get_valid_hexes(hex)
	var possible: Array[HexConfig] = []
	if (conf != null):
		for c in valid:
			if c.name == conf.name and c.flipped_horizontal == conf.flipped_horizontal and c.flipped_vertical == conf.flipped_vertical:
				possible.append(c)
	else:
		conf = valid.pick_random()
	if not possible.is_empty():
		possible.sort_custom(sort_rotation)
		var idx: int = possible.find(conf)
		if direction == "down":
			idx = (idx + 1) % possible.size()
		else:
			idx = (idx - 1) % possible.size()
		conf = possible[idx]
	update_hex_config(hex, conf)
	
func hex_flip(hex: Hex) -> void:
	var conf := hex._hex_config
	var valid := get_valid_hexes(hex)
	if conf == null:
		conf = valid.pick_random()
	var flip_directions : Array[Vector2i] = [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(0,1)]
	var current_direction := Vector2i(int(conf.flipped_horizontal), int(conf.flipped_vertical))
	var current_idx := flip_directions.find(current_direction)
	var idx := current_idx
	
	var possible: Array[HexConfig] = []
	while possible.is_empty():
		idx = (idx + 1) % flip_directions.size()
		var direction := flip_directions[idx]
		for c in valid:
			if c.name == conf.name and c.flipped_horizontal == bool(direction.x) and c.flipped_vertical == bool(direction.y):
				possible.append(c)
				conf = c
				break
		if idx == current_idx:
			break
	
	update_hex_config(hex, conf)
	

func update_hex_config(hex: Hex, hex_config: HexConfig) -> void:
	hex.update(hex_config)
	backtrack_list.push_front(hex)
	update_neighbours(hex)

func get_restriction(hex: Hex) -> Dictionary:
	var neighbours := get_neighbours(hex._q, hex._r)
	var restriction := {}
	for n in neighbours:
		if neighbours[n] == null:
			if border_edge != null:
				restriction[n] = border_edge
		else:
			var config: HexConfig = neighbours[n]._hex_config
			if config != null:
				var dir = OPPOSITE_DIRECTION[n][0]
				restriction[n] = config.edges.edge(dir)
	return restriction

func get_valid_hexes(hex: Hex) -> Array[HexConfig]:
	if hex == null:
		return []
	var neighbours := get_neighbours(hex._q, hex._r)
	var restriction := get_restriction(hex)
			
	
	var r_hash: int = restriction.hash()
	
	if restrict_valid_dict.has(r_hash):
		var valid = restrict_valid_dict[r_hash]
		return valid
	else:
		var valid: Array[HexConfig] = []
		for c in _hexes:
			var is_match := true
			for r in restriction:
				var edge := c.edges.edge(r)
				var restriction_edge = restriction[r]
				var neighbour_name := ""
				
				var neighbour = neighbours[r]
				
				if neighbour != null and neighbour._hex_config != null:
					neighbour_name = neighbour._hex_config.name
				
				if not restriction_edge.matches(edge, c.name, neighbour_name):
					is_match = false
					break
					
			if is_match:
				valid.append(c)
		restrict_valid_dict[r_hash] = valid
		return valid

func set_valid_hexes(hex: Hex) -> void:
	var valid := get_valid_hexes(hex)
	hex.valid_count = valid.size()

func get_suggested_hex_config(hex: Hex, valid_configs: Array[HexConfig]) -> HexConfig:
	var neighbours := get_neighbours(hex._q, hex._r, false).values()
	neighbours.shuffle()
	
	if neighbours.is_empty():
		return valid_configs.pick_random()
	
	var valid_types: Array[String] = []
	for c in valid_configs:
		if c.type.name not in valid_types:
			valid_types.append(c.type.name)
	
	for h: Hex in neighbours:
		if h._hex_config == null:
			continue
		var h_type := h._hex_config.type
		var weight_table := construct_type_weight_table(h_type)
		var max_sum = weight_table.values().back()
		var selected: HexConfig
		
		var r = randi_range(0, max_sum)
		for w in weight_table:
			if r < weight_table[w] and valid_types.has(w):
				valid_configs.shuffle()
				for c in valid_configs:
					if c.type.name == w:
						return c
			
	return valid_configs.pick_random()
		
		
var weight_table_map := {}

func construct_type_weight_table(hex_type: HexConfig.HexType) -> Dictionary:
	if weight_table_map.has(hex_type):
		return weight_table_map[hex_type]
	var weight_table := {}
	var weight_sum := 0
	var weights = hex_type.neighbour_weights
	for n in weights:
		weight_sum += weights[n]
		weight_table[n] = weight_sum
	
	weight_table_map[hex_type] = weight_table
	
	return weight_table

func get_neighbours(q: int, r: int, with_null_neighbours := true) -> Dictionary:
	var neighbours := {}
	for n in NEIGHBOUR_DIRECTIONS:
		var nq = q + n[1].x
		var nr = r + n[1].y
		var key := hex_key(nq, nr)
		if grid.has(key):
			neighbours[n[0]] = grid[key]
		elif with_null_neighbours:
			neighbours[n[0]] = null
	return neighbours

var backtrack := true
var success_count := 0
var backtrack_count := 0
var backtrack_remaining := 0
var backtrack_list := []

var restrict_valid_dict := {}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not loaded:
		loaded = true
		init_everything()
	
	if fill_random:
		var count = 0
		for h: Hex in grid.values():
			if h._hex_config != null:
				count +=1
		if count < min(3, _grid_size * 2):
			var h: Hex = grid.values().pick_random()
			var valid = get_valid_hexes(h);
			valid.shuffle()
			for c in valid:
				if c.type.name == "plains":
					update_hex_config(h, c)
					return
		fill_random = false
	if fill:
		if backtrack_remaining > 0:
			var hex = backtrack_list.pop_front()
			if !is_instance_valid(hex):
				backtrack_remaining = 0
				backtrack_count = 0
				success_count = 0
				return
			clear_hex(hex, true)
			backtrack_remaining -= 1
			return
		
		var lowest_entropy = 1000000
		var chosen_hex = null
		var l = grid.values()
		l.shuffle()
		var done = true
		for h in l:
			if h._hex_config == null:
				done = false
				#var v = get_valid_hexes(h)
				var v_count = h.valid_count
				if v_count < lowest_entropy:
					lowest_entropy = v_count
					chosen_hex = h
		if done:
			stop_process()
			return
		
		var chosen_valid = get_valid_hexes(chosen_hex)
		if chosen_valid.is_empty() or lowest_entropy < 1 or (lowest_entropy == 1 and backtrack_count > 0):
			if !done:
				print()
				print("No matches: " + str(chosen_hex))
				print(get_restriction(chosen_hex))
				print()
			
			fill = !done and backtrack
			if success_count > backtrack_count * 2:
				backtrack_count = 1
			else:
				backtrack_count = max(1, backtrack_count * 1.25 + 1)
				backtrack_remaining = backtrack_count
			success_count = 0
			return
		
		var config: HexConfig = get_suggested_hex_config(chosen_hex, chosen_valid)
		success_count += 1
		update_hex_config(chosen_hex, config)
	pass

func find_hex(pos: Vector2) -> Hex:
	var pt = Vector2((pos.x - _origin.x) / _hex_size, 
					 (pos.y - _origin.y) / _hex_size);
	var q = Hex._b0 * pt.x + Hex._b1 * pt.y;
	var r = Hex._b2 * pt.x + Hex._b3 * pt.y;
	return grid[str(roundi(q)) + " - " +str(roundi(r))]

func hex_key(q: int, r: int) -> String:
	return str(q) + " - " + str(r)
