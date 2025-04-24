extends Resource
class_name HexConfig

static var PLACEHOLDER_NAME = "PLACEHOLDER"
static var PLACEHOLDER_HEX_TYPE = HexType.new()
static var PLACEHOLDER_EDGE_TYPE = EdgeType.new()
static var PLACEHOLDER_HEX_EDGES = HexEdges.new()

@export var name: String:
	set(new_name):
		if new_name != name:
			name = new_name
			emit_changed()
@export var type: HexType:
	set(new_type):
		if new_type != type:
			type = new_type
			emit_changed()
@export var edges: HexEdges
@export var flipped_horizontal: bool
@export var flipped_vertical: bool
@export var rotated: int
@export var texture: Texture2D:
	set(new_texture):
		if new_texture != texture:
			texture = new_texture
			emit_changed()

func _init(_name: String = HexConfig.PLACEHOLDER_NAME, _texture: Texture2D = PlaceholderTexture2D.new(), _type: HexType = PLACEHOLDER_HEX_TYPE, _edges: HexEdges = PLACEHOLDER_HEX_EDGES, _flipped_horizontal: bool = false, _flipped_vertical: bool = false, _rotated: int = 0) -> void:
	name = _name
	texture = _texture
	type = _type
	edges = _edges
	flipped_horizontal = _flipped_horizontal
	flipped_vertical = _flipped_vertical
	rotated = _rotated
	
	if flipped_horizontal:
		var temp = HexEdges.new(null)
		temp.top = edges.top
		temp.top_right = edges.top_left
		temp.top_left = edges.top_right
		temp.bottom = edges.bottom
		temp.bottom_right = edges.bottom_left
		temp.bottom_left = edges.bottom_right
		edges = temp
	elif flipped_vertical:
		var temp = HexEdges.new(null)
		temp.top = edges.bottom
		temp.top_right = edges.bottom_right
		temp.top_left = edges.bottom_left
		temp.bottom = edges.top
		temp.bottom_right = edges.top_right
		temp.bottom_left = edges.top_left
		edges = temp
	elif flipped_horizontal and flipped_vertical:
		var temp = HexEdges.new(null)
		temp.top = edges.bottom
		temp.top_right = edges.bottom_left
		temp.top_left = edges.bottom_right
		temp.bottom = edges.top
		temp.bottom_right = edges.top_left
		temp.bottom_left = edges.top_right
		edges = temp
		
	for r in range(rotated):
		var temp = HexEdges.new(null)
		temp.top = edges.top_left
		temp.top_right = edges.top
		temp.bottom_right = edges.top_right
		temp.bottom = edges.bottom_right
		temp.bottom_left = edges.bottom
		temp.top_left = edges.bottom_left
		edges = temp
		
	for e in edges.as_list():
		if !e.named_match.is_empty():
			e.special = true
			e.characteristics = {"flipped_horizontal": flipped_horizontal, "flipped_vertical": flipped_vertical}
	
func _to_string() -> String:
		return name

class HexType extends Resource:
	@export var name: String
	@export var default_edge_type: EdgeType
	@export var neighbour_weights: Dictionary
	
	func _init(_name: String = HexConfig.PLACEHOLDER_NAME, _default_edge_type: EdgeType = HexConfig.PLACEHOLDER_EDGE_TYPE, _neighbour_weights: Dictionary = {}) -> void:
		name = _name
		default_edge_type = _default_edge_type
		neighbour_weights = _neighbour_weights
	
	func _to_string() -> String:
		return name

class HexEdges extends Resource:
	@export var top: HexEdge
	@export var top_left: HexEdge
	@export var top_right: HexEdge
	@export var bottom: HexEdge
	@export var bottom_left: HexEdge
	@export var bottom_right: HexEdge
	
	func _init(_default_type: EdgeType = HexConfig.PLACEHOLDER_EDGE_TYPE) -> void:
		top = HexEdge.new(_default_type, null)
		top_left = HexEdge.new(_default_type, null)
		top_right = HexEdge.new(_default_type, null)
		bottom = HexEdge.new(_default_type, null)
		bottom_left = HexEdge.new(_default_type, null)
		bottom_right = HexEdge.new(_default_type, null)
		
	func edge(dir: StringName) -> HexEdge:
		return get(dir)
		
	func as_list() -> Array[HexEdge]:
		return [top, top_right, bottom_right, bottom, bottom_left, top_left]
		
	func _to_string() -> String:
		return "top - {0}, top_left: {1}, top_right - {2}, bottom: {3}, bottom_left - {4}, bottom_right: {5}".format([top, top_left, top_right, bottom, bottom_left, bottom_right])

class HexEdge extends Resource:
	@export var type: EdgeType
	@export var sub_type: EdgeSubType
	@export var named_match: String
	var special := false
	var characteristics := {}
	
	func _init(_type: EdgeType = HexConfig.PLACEHOLDER_EDGE_TYPE, _sub_type: EdgeSubType = null, _named_match: String = "") -> void:
		type = _type
		sub_type = _sub_type
		named_match = _named_match
	
	func _to_string() -> String:
		return str(type) + " - " + str(sub_type) + " - " + named_match
	
	func clone() -> HexEdge:
		return HexEdge.new(type, sub_type, named_match)
		
	func matches(other: HexEdge, name: String, neighbour_name: String) -> bool:
		if other.special or self.special:
			if other.special != self.special:
				return false
				
			if other.characteristics.hash() != self.characteristics.hash():
				return false
			
			if named_match == name and other.named_match == neighbour_name:
				return true
			else:
				return false

		if !other.named_match.is_empty() and named_match.is_empty():
			return false
		
		if type != other.type:
			return false
		
		if sub_type == other.sub_type:
			return sub_type == null or sub_type.matches == "same"
			
		if sub_type != null and other.sub_type != null:
			return sub_type.matches == other.sub_type.name
			
		return false

class EdgeType extends Resource:
	@export var name: String
	@export var description: String
	
	func _init(_name: String = HexConfig.PLACEHOLDER_NAME, _description: String = "") -> void:
		name = _name
		description = _description
	
	func _to_string() -> String:
		return name
	
class EdgeSubType extends EdgeType:
	@export var matches: String
	@export var priority: int
	
	func _init(_name: String = HexConfig.PLACEHOLDER_NAME, _matches: String = "", _description: String = ""):
		super(_name, _description)
		matches = _matches
