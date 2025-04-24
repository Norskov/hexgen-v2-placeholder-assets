class_name Hex
extends Node2D

var _q: int
var _r: int
var _s: int

const _f0 := 3.0 / 2.0
const _f1 := 0.0
const _f2 := sqrt(3.0) / 2.0
const _f3 := sqrt(3.0)
const _b0 := 2.0 / 3.0
const _b1 := 0.0
const _b2 := -1.0 / 3.0
const _b3 := sqrt(3.0) / 3.0

const FLIPPEDH_UV = [Vector2(225,0), Vector2(675,0), Vector2(900,390), Vector2(675,780), Vector2(225,780), Vector2(0,390)]
const FLIPPEDHV_UV = [Vector2(225,0), Vector2(675,0), Vector2(900,390), Vector2(675,780), Vector2(225,780), Vector2(0,390)]
const FLIPPEDV_UV = [Vector2(675,780), Vector2(225,780), Vector2(0,390), Vector2(225,0), Vector2(675,0), Vector2(900,390)]
const REGULAR_UV = [Vector2(675,0), Vector2(225,0), Vector2(0,390), Vector2(225,780), Vector2(675,780), Vector2(900,390)]

var _origin: Vector2
var _size: int

var _polygon: Polygon2D

var _hex_config: HexConfig

var _original_transform: Transform2D

var valid_count: int = 0

signal clicked(mb: MouseButton)

func _init(q: int, r: int, size: int, origin: Vector2, texture: Texture2D, config: HexConfig) -> void:
	_q = q
	_r = r
	_s = -_q - _r
	_size = size
	_origin = origin
	_hex_config = config
	
	position = hex_to_pixel()
	_original_transform = transform
	
	_polygon = Polygon2D.new()
	_polygon.polygon = polygon_corners()
	_polygon.texture = texture
	_polygon.uv = REGULAR_UV
	var a = Area2D.new()
	a.input_pickable = true
	var s = CollisionPolygon2D.new()
	s.polygon = _polygon.polygon
	a.add_child(s)
	add_child(a)
	a.input_event.connect(handle_input)
	add_child(_polygon)
	

func _to_string() -> String:
	return "{0} - {1}".format([_q, _r])
	
	
func hex_corner_offset(corner: float) -> Vector2:
	var angle := 2.0 * PI * corner / 6;
	return Vector2(_size * cos(angle), _size * sin(angle));

func polygon_corners() -> Array[Vector2]:
	var corners: Array[Vector2] =  []
	var center := Vector2(0,0)
	for i in range(6):
		var offset := hex_corner_offset(i)
		corners.push_back(Vector2(center.x + offset.x,center.y + offset.y))
	corners.reverse()
	return corners

func update(config: HexConfig) -> void:
	reset_transform()
	_hex_config = config
	_polygon.texture = null
	
	if config == null:
		return
	
	_polygon.texture = config.texture
	
	if config.flipped_vertical:
		if config.flipped_horizontal:
			_polygon.uv = FLIPPEDHV_UV
		else:
			_polygon.uv = FLIPPEDV_UV
	elif config.flipped_horizontal:
		_polygon.uv = FLIPPEDH_UV
	
	for r in range(config.rotated):
		transform = transform.rotated_local(deg_to_rad(60))

func reset_transform():
	transform = _original_transform
	_polygon.uv = REGULAR_UV

func hex_to_pixel() -> Vector2:
	var x := (_f0 * float(_q) + _f1 * float(_r)) * float(_size)
	var y := (_f2 * float(_q) + _f3 * float(_r)) * float(_size)
	return Vector2(x + _origin.x, y + _origin.y)
	
func hash() -> String:
	return _to_string()
	
func handle_input(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			clicked.emit(mb.button_index)
