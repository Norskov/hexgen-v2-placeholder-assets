class_name HexPicker
extends Control

signal hex_config_selected(hex_config: HexConfig)

@onready var h_flow_container: HFlowContainer = $PanelContainer/VBoxContainer/ScrollContainer/HFlowContainer

var control := preload("res://hex_control.tscn")

var config_map = {}

var selected_hex: HexConfig

func update_configs(configs: Array[HexConfig]) -> void:
	for c in h_flow_container.get_children():
		c.queue_free()
	config_map = {}
	
	for c in configs:
		if !config_map.has(c.name):
			config_map[c.name] = [c]
		else:
			config_map[c.name].append(c)
	
	for c in config_map.values():
		var child := control.instantiate()
		child.hex = c[0]
		child.picked_hex.connect(update_selected_hex)
		h_flow_container.add_child(child)

func update_selected_hex(hex: HexConfig) -> void:
	print("Selected hex updated")
	if selected_hex == hex:
		hex_config_selected.emit(selected_hex)
	selected_hex = hex
	hex_config_selected.emit(selected_hex)

func _on_choose_button_pressed() -> void:
	hex_config_selected.emit(selected_hex)
