extends Camera2D

var tilemap: TileMap

func _ready() -> void:
	# Defer initialization to avoid conflicts if LevelManager is changing scenes.
	call_deferred("_deferred_init_camera")

func _deferred_init_camera() -> void:
	# Connect to LevelManager's level_changed signal if it's available.
	if Engine.has_singleton("LevelManager"):
		var lm = Engine.get_singleton("LevelManager")
		# Use CONNECT_DEFERRED so the signal's callback is also invoked safely.
		lm.connect("level_changed", Callable(self, "_on_level_changed"), Object.CONNECT_DEFERRED)
		
		# Attempt to find the tilemap and set up the camera.
		if not tilemap:
			find_tilemap()
			setup_camera()
	else:
		push_error("Camera2D: LevelManager autoload not found!")

func find_tilemap() -> void:
	if not Engine.has_singleton("LevelManager"):
		push_error("Camera2D: LevelManager not found; cannot find tilemap.")
		return
	
	var lm = Engine.get_singleton("LevelManager")
	var current_level = lm.current_level
	if current_level == null:
		push_error("Camera2D: current_level is null; cannot find tilemap.")
		return
	
	tilemap = current_level.find_child("TileMap") as TileMap
	if tilemap == null:
		push_error("Camera2D: No 'TileMap' child found in current level.")
	else:
		print("Camera2D: Found tilemap:", tilemap.name)

func _on_level_changed(_old_level: String, _new_level: String) -> void:
	# Defer updating the tilemap and camera so we don't conflict with the scene tree.
	call_deferred("_update_camera_for_new_level")

func _update_camera_for_new_level() -> void:
	find_tilemap()
	setup_camera()

func setup_camera() -> void:
	if tilemap == null:
		push_warning("Camera2D: Cannot set up camera because tilemap is null.")
		return
	
	var map_rect = tilemap.get_used_rect()
	# cell_quadrant_size might be large if you're using quadrant-based culling;
	# if you actually need the tile size, you may need tilemap.cell_size instead.
	var tile_size = tilemap.cell_quadrant_size
	
	# Convert from tilemap coordinates to pixel coordinates.
	var world_size_in_px = Vector2(map_rect.size.x, map_rect.size.y) * Vector2(tile_size, tile_size)
	
	# For demonstration, we offset all limits by the negative of tile_size.
	# Adjust as needed based on how you want the camera to behave.
	limit_top = -tile_size
	limit_left = limit_top
	limit_right = world_size_in_px.x + limit_left
	limit_bottom = world_size_in_px.y + limit_top
	
	print("Camera2D: Camera limits updated to:",
		"top =", limit_top,
		"left =", limit_left,
		"right =", limit_right,
		"bottom =", limit_bottom)
