class_name Player
extends Actor

@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: StateMachine = $StateMachine
@export var inventory: Inventory
@export var test_hint_item: InventoryItem

func _ready() -> void:
	anim_tree.active = true
	# Ensure the inventory is assigned. If not, instantiate it gracefully.
	if not inventory:
		var inv_scene: PackedScene = preload("res://Inventory/Inventory.tscn")
		inventory = inv_scene.instantiate() as Inventory
		add_child(inventory)
		print("Player _ready: Instantiated inventory:", inventory.name)
	else:
		print("Player _ready: Inventory is assigned:", inventory.name)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		state_machine.change_state("Attack")

func get_direction() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func _on_health_health_depleted() -> void:
	# Gracefully handle health depletion.
	is_alive = false
	anim_tree.active = false
	anim_player.play("death")
	await anim_player.animation_finished
	queue_free()

func _on_area_2d_body_entered(body):
	print("Player _on_area_2d_body_entered: Detected body:", body.name, "Groups:", body.get_groups())
	if body in get_tree().get_nodes_in_group("items"):
		print("Player: Detected world item (body):", body.name)
		if inventory:
			inventory.add_item(body as Item, 1)
		else:
			print("ERROR: Inventory is null; cannot add item.")
	else:
		print("Player: Body not in 'items' group:", body.name)

func _on_area_2d_area_entered(area):
	print("Player _on_area_2d_area_entered: Detected area:", area.name, "Groups:", area.get_groups())
	if area in get_tree().get_nodes_in_group("items"):
		print("Player: Detected world item (area):", area.name)
		if inventory:
			inventory.add_item(area as Item, 1)
		else:
			print("ERROR: Inventory is null; cannot add item.")
	else:
		print("Player: Area not in 'items' group:", area.name)
