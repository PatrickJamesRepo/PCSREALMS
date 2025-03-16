extends Node2D

@onready var spawn_point: Node2D = $SpawnPoint

func _ready():
	print("[Spawner] _ready called!")
	load_player()

func load_player():
	if GlobalData.selectedCharacter == "":
		push_error("No player character selected!")
		return
	
	# Load your single player scene
	var player_scene = load("res://actors/player/player.tscn")
	if not player_scene:
		push_error("Failed to load player scene!")
		return

	var player_instance = player_scene.instantiate()
	if not player_instance:
		push_error("Failed to instantiate player scene!")
		return

	if spawn_point:
		player_instance.position = spawn_point.position
	else:
		player_instance.position = Vector2(100, 100)
	
	add_child(player_instance)
	print("[Spawner] Player spawned successfully. Character:", GlobalData.selectedCharacter)
