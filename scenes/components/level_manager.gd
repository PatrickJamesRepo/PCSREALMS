extends Node

signal level_changed(old_level_path: String, new_level_path: String)

@onready var game: Node = null
var level_root: Node2D
var current_level: Node2D

func _ready() -> void:
	# Defer initialization until the scene tree is ready.
	call_deferred("_init_level_manager")

func _init_level_manager() -> void:
	# Instead of searching from the root, use the current scene.
	game = get_tree().get_current_scene()
	if game == null:
		push_error("LevelManager: Current scene not found. Is your game loaded?")
		return
	
	# Assume "LevelRoot" is a direct child of the current scene.
	level_root = game.get_node_or_null("LevelRoot")
	if level_root == null:
		push_error("LevelManager: 'LevelRoot' not found as a child of the current scene.")
		return
	
	# If there's already a level loaded under LevelRoot, use it.
	current_level = level_root.get_child_or_null(0) as Node2D
	if current_level == null:
		print("LevelManager: No initial child found under 'LevelRoot'.")
	else:
		print("LevelManager: Initialized with current_level =", current_level.name)


# Accepts a level path (for example, "res://components/level1.tscn" or "res://components/level2.tscn")
func start_game(level_path: String) -> void:
	print("LevelManager: start_game() called with level_path:", level_path)
	change_level(level_path)

func change_level(next_level_path: String) -> void:
	if level_root == null:
		push_error("LevelManager: level_root is null, cannot change level.")
		return
	
	var next_level_res = load(next_level_path)
	if not next_level_res:
		push_error("LevelManager: Failed to load resource at %s" % next_level_path)
		return
	
	var next_level = next_level_res.instantiate() as Node2D
	if next_level == null:
		push_error("LevelManager: Could not instantiate next level from %s" % next_level_path)
		return
	
	# Optional: reposition the player if needed.
	var player = game.get_node_or_null("World/Player")
	if player:
		# (Add your portal/spawn logic here if applicable.)
		pass
	
	# Remove the previous level.
	if current_level:
		current_level.queue_free()
	
	# Defer adding the new level to avoid scene tree conflicts.
	level_root.call_deferred("add_child", next_level)
	
	# Define the old level path safely.
	var old_level_path: String = ""
	if current_level:
		old_level_path = current_level.scene_file_path
	emit_signal("level_changed", old_level_path, next_level_path)
	
	current_level = next_level
	print("LevelManager: Changed level to:", next_level_path)
