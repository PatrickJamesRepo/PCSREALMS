extends Node

signal level_changed(old_level: String, new_level: String)

var wallet_address: String = ""
var is_logged_in: bool = false

# Called when login is successful in main.tscn.
func start_multiplayer(wallet_addr: String) -> void:
	is_logged_in = true
	wallet_address = wallet_addr
	print("GlobalManager: Starting multiplayer with wallet address:", wallet_addr)
	var multiplayer_scene = preload("res://scenes/multiplayerScene.tscn")
	get_tree().change_scene_to(multiplayer_scene)

# Called from the multiplayer scene when ready to transition to the game.
# The parameter first_level_path lets you choose which level to load.
func start_game(first_level_path: String = "res://components/level1.tscn") -> void:
	print("GlobalManager: start_game() called. Loading game.tscn and then level:", first_level_path)
	var game_scene = preload("res://scenes/game.tscn")
	var err = get_tree().change_scene_to(game_scene)
	if err != OK:
		push_error("GlobalManager: Failed to change to game.tscn. Error code: " + str(err))
		return
	# Defer the call so that game.tscn is fully active.
	call_deferred("_deferred_start_level", first_level_path)

func _deferred_start_level(first_level_path: String) -> void:
	if Engine.has_singleton("LevelManager"):
		var lm = Engine.get_singleton("LevelManager")
		if lm.has_method("start_game"):
			print("GlobalManager: Calling LevelManager.start_game() with:", first_level_path)
			lm.start_game(first_level_path)
			# Connect to LevelManager's level_changed signal if not already connected.
			if not lm.is_connected("level_changed", Callable(self, "_on_level_changed")):
				lm.connect("level_changed", Callable(self, "_on_level_changed"))
		else:
			push_error("GlobalManager: LevelManager does not implement start_game().")
	else:
		push_error("GlobalManager: LevelManager autoload not found!")

func _on_level_changed(old_level: String, new_level: String) -> void:
	print("GlobalManager: Level changed from", old_level, "to", new_level)
	emit_signal("level_changed", old_level, new_level)
