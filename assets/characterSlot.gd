extends Panel

@export var characterPath: String
@export var characterTexture: CompressedTexture2D

var default_scale = Vector2(1, 1)

func _ready():
	if characterTexture:
		$TextureRect.texture = characterTexture
		_apply_rounded_corners()
		print("Texture set for:", self.name)
	else:
		print("ERROR: No texture found for:", self.name)

	default_scale = scale
	set_mouse_filter(Control.MOUSE_FILTER_PASS)  # Allows hover detection

func _apply_rounded_corners():
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = Color(1, 1, 1, 1)
	stylebox.border_color = Color(0, 0, 0, 1)
	stylebox.border_width_all = 1

	stylebox.corner_radius_top_left = 5
	stylebox.corner_radius_top_right = 5
	stylebox.corner_radius_bottom_left = 5
	stylebox.corner_radius_bottom_right = 5

	$TextureRect.add_theme_stylebox_override("panel", stylebox)

func set_selected(isSelected: bool):
	print("set_selected called on:", self.name, "isSelected:", isSelected)
	var stylebox = get_theme_stylebox("panel").duplicate()
	if isSelected:
		stylebox.border_color = Color(1, 1, 0)  # Yellow border
	else:
		stylebox.border_color = Color(0, 0, 0)  # Black border
	add_theme_stylebox_override("panel", stylebox)

# Hover effects
func _on_mouse_entered():
	$TextureRect.rect_scale = default_scale * 1.1
	$TextureRect.modulate = Color(1, 1, 1, 0.9)

func _on_mouse_exited():
	$TextureRect.rect_scale = default_scale
	$TextureRect.modulate = Color(1, 1, 1, 1)
