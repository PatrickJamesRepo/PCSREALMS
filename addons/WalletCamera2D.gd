extends Camera2D

func _ready() -> void:
	# Set this camera as current for the wallet scene by calling make_current()
	make_current()
	# Set default zoom (no zoom in or out)
	zoom = Vector2(1, 1)
