extends Control


signal generate
@onready var hex_picker: HexPicker = $PanelContainer/HexPicker
@onready var grid: Main = $PanelContainer/VBoxContainer/SubViewportContainer/SubViewport/Grid


var selected_hex: Hex

func _on_button_pressed() -> void:
	generate.emit()

func _on_hex_clicked(hex: Hex) -> void:
	selected_hex = hex
	hex_picker.update_configs(grid.get_valid_configs(hex))
	hex_picker.visible = true


func _on_hex_picker_hex_config_selected(hex_config: HexConfig) -> void:
	grid.update_config(selected_hex, hex_config)
	hex_picker.visible = false
