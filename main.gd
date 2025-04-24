class_name Main
extends Node2D

var grid: HexGrid

signal processing(process: bool)
signal hex_clicked(hex: Hex)

@onready var sub_viewport_container: SubViewportContainer = $"../.."

var edge_types = {}
var edge_sub_types = {}
var hex_types = {}

var hexagon_textures := {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_hexagon_textures()
	var hexes = init_hex_configs()
	grid = HexGrid.new(hexes, edge_types)
	grid.processing.connect(processing.emit)
	grid.hex_clicked.connect(hex_clicked.emit)
	add_child(grid)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func load_hexagon_textures() -> void:
	var path := "res://assets/hexagons"
	var dir := DirAccess.get_files_at(path)
	for file in dir:
		if file.ends_with(".png.import"):
			var loaded = ResourceLoader.load(path + "/" + file.split(".import")[0], "CompressedTexture2D")
			hexagon_textures[file.split(" ")[0].split(".")[0]] = loaded

func init_hex_configs() -> Array[HexConfig]:
	var types_json = JSON.parse_string(FileAccess.get_file_as_string("res://config/types.json"))
	var hexagons_json = JSON.parse_string(FileAccess.get_file_as_string("res://config/hexagons.json"))
	
	var hexes: Array[HexConfig] = []
	
	for edge_type in types_json["edgeTypes"]:
		var name = edge_type.get("name", "")
		var description = edge_type.get("description", "")
		var e = HexConfig.EdgeType.new(name, description)
		edge_types[e.name] = e
	
	for edge_sub_type in types_json["edgeSubTypes"]:
		var name = edge_sub_type.get("name", "")
		var description = edge_sub_type.get("description", "")
		var matches = edge_sub_type.get("matches", "")
		var e = HexConfig.EdgeSubType.new(name, matches, description)
		edge_sub_types[e.name] = e
	
	for hex_type in types_json["vertexTypes"]:
		var name: String = hex_type.get("name", "")
		var default: HexConfig.EdgeType = edge_types.get(hex_type.get("defaultEdgeType", ""), edge_types.values()[0])
		var neighbour_weights: Dictionary = hex_type.get("neighbours", {})
		
		var h = HexConfig.HexType.new(name, default, neighbour_weights)
		hex_types[h.name] = h
	
	for hex in hexagons_json:
		var name = hex.get("name", "")
		var type = hex_types.get(hex.get("type", ""), hex_types.values()[0])
		
		var edges_json = hex.get("edges", {})
		
		var edges = HexConfig.HexEdges.new(type.default_edge_type)
		
		for edge in edges_json:
			var edge_type = edge_types.get(edges_json[edge].get("type", ""))
			var edge_sub_type = edge_sub_types.get(edges_json[edge].get("subType", ""))
			var match_val = edges_json[edge].get("match", "")
			var e = HexConfig.HexEdge.new(edge_type, edge_sub_type, match_val)
			var s = edge.to_snake_case()
			edges.set(s, e)
		
		# Replace hexagon_textures["Placeholder"] with hexagon_textures[name]
		var h = HexConfig.new(name, hexagon_textures["Placeholder"], type, edges)
		
		hexes.append_array(rotate_and_flip_hex(h))
			
	
	return hexes
	
func cloned_edges(edges: HexConfig.HexEdges) -> HexConfig.HexEdges:
	var temp = HexConfig.HexEdges.new(null)
	temp.top = edges.top.clone()
	temp.top_right = edges.top_right.clone()
	temp.top_left = edges.top_left.clone()
	temp.bottom = edges.bottom.clone()
	temp.bottom_right = edges.bottom_right.clone()
	temp.bottom_left = edges.bottom_left.clone()
	return temp
	
func rotate_and_flip_hex(hex: HexConfig) -> Array[HexConfig]:
	var result: Array[HexConfig] = []
	for i in range(6):
		# Replace hexagon_textures["Placeholder"] with hexagon_textures[hex.name]
		result.append(HexConfig.new(hex.name, hexagon_textures["Placeholder"], hex.type, cloned_edges(hex.edges), false, false, i))
		result.append(HexConfig.new(hex.name, hexagon_textures["Placeholder"], hex.type, cloned_edges(hex.edges), true, false, i))
		result.append(HexConfig.new(hex.name, hexagon_textures["Placeholder"], hex.type, cloned_edges(hex.edges), false, true, i))
		result.append(HexConfig.new(hex.name, hexagon_textures["Placeholder"], hex.type, cloned_edges(hex.edges), true, true, i))
	return result


func _on_interface_generate() -> void:
	grid.fill_grid()


func _on_clear_grid_pressed() -> void:
	grid.clear_grid()


func _on_check_button_toggled(toggled_on: bool) -> void:
	grid.toggle_backtracking(toggled_on)

@onready var option_button: OptionButton = $"../../../AspectRatioContainer/HFlowContainer/Control/OptionButton"
func _on_option_button_item_selected(index: int) -> void:
	grid.set_size(option_button.get_item_text(index))


func _on_button_pressed() -> void:
	grid.stop_process()


func _on_sub_viewport_container_resized() -> void:
	position = sub_viewport_container.size / 2

@onready var border_selection: OptionButton = $"../../../AspectRatioContainer/HFlowContainer/Control2/OptionButton"
func _on_border_edge_selected(index: int) -> void:
	grid.update_border_type(border_selection.get_item_text(index))

func get_valid_configs(hex: Hex) -> Array[HexConfig]:
	return grid.get_valid_hexes(hex)

func update_config(hex: Hex, hex_config: HexConfig) -> void:
	grid.update_hex_config(hex, hex_config)
