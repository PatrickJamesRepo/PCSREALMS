extends Control

@onready var character_selection_box = $VBoxContainer/HBoxContainer
@onready var start_button = $VBoxContainer/StartButton

func _ready():
	print("[SelectionScreen] Ready")
	print("[SelectionScreen] Current selection:", GlobalData.selectedCharacter)
	_check_textures()
	
	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)

func _check_textures():
	for node in character_selection_box.get_children():
		if node.has_node("TextureRect"):
			var texture_rect = node.get_node("TextureRect")
			if texture_rect.texture:
				print("[Texture Check] Texture found for:", node.name, "Path:", texture_rect.texture.resource_path)
			else:
				print("[Texture Check] MISSING texture for:", node.name)
		else:
			print("[Texture Check] MISSING TextureRect for:", node.name)

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var clicked_node = _get_char_node()
		if clicked_node:
			_set_char_selected(clicked_node)

func _get_char_node():
	var mouse_pos = get_viewport().get_mouse_position()
	for node in character_selection_box.get_children():
		if node.get_global_rect().has_point(mouse_pos):
			print("[SelectionScreen] Character clicked:", node.name)
			return node
	return null

func _set_char_selected(char_node):
	print("DEBUG: char_node.name =", char_node.name)
	match char_node.name:
		"Character1":
			GlobalData.selectedCharacter = GlobalData.EMPURROR_PUURRTY
		"Character2":
			GlobalData.selectedCharacter = GlobalData.PIRATE_PUURRTY
		_:
			push_error("No matching character for name: " + char_node.name)
			return
	print("[SelectionScreen] Selected character:", GlobalData.selectedCharacter)
	
	# Optionally, highlight the selected character (if nodes have a set_selected method)
	for node in character_selection_box.get_children():
		if node.has_method("set_selected"):
			node.call("set_selected", node == char_node)
		else:
			print("[SelectionScreen] WARNING: Node", node.name, "lacks 'set_selected' method!")

func _on_start_button_pressed():
	print("[SelectionScreen] Start button pressed!")
	if GlobalData.selectedCharacter == "":
		print("[SelectionScreen] ERROR: No character selected!")
		return
	
	print("[SelectionScreen] Starting game with character:", GlobalData.selectedCharacter)
	self.queue_free()  # Remove selection screen
	
	if LevelManager:
		LevelManager.change_level("res://levels/level1.tscn")
		print("[SelectionScreen] Level change initiated.")
	else:
		print("[SelectionScreen] ERROR: LevelManager not found!")
