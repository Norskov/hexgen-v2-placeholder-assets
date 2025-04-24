extends Control

signal picked_hex(hex: HexConfig)

@export var hex: HexConfig = HexConfig.new():
	set(new_hex):
		if new_hex != hex:
			if hex != null and hex.changed.is_connected(update_hex):
				print("Disconnecting")
				hex.changed.disconnect(update_hex)
			hex = new_hex
			if hex != null:
				print("Connecting")
				hex.changed.connect(update_hex)
			update_hex()
			
@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var type_label: Label = $VBoxContainer/TypeLabel
@onready var texture: TextureRect = $VBoxContainer/Texture

func _gui_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
			print("Picked " + str(hex))
			picked_hex.emit(hex)
func update_hex():
	print("Updating")
	if hex != null and name_label != null:
		name_label.text = hex.name
		if hex.type != null:
			type_label.text = hex.type.name
		texture.texture = hex.texture
		texture.scale = Vector2(0.5, 0.5)

func _ready() -> void:
	if !Engine.is_editor_hint():
		mouse_entered.connect(something.bind(true))
		mouse_exited.connect(something.bind(false))
	update_hex()
	
func _init(_hex: HexConfig = hex) -> void:
	hex = _hex

func something(here: bool) -> void:
	pass
