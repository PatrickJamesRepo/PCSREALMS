@icon("res://actors/components/state_machine/state.png")
class_name State
extends Node

var state_machine: StateMachine = null
var actor: Actor = null

func _ready() -> void:
	# Remove "await ready" because _ready() is only called once the node is ready.
	# Assume that the state node's owner is the Actor.
	if owner is Actor:
		actor = owner as Actor
	else:
		push_error("State: owner is not an Actor!")
	
	# Assume that the parent of this state is the StateMachine.
	state_machine = get_parent() as StateMachine
	if state_machine == null:
		push_error("State: state_machine not found as parent!")
	
	print("State ready. Actor:", actor, " StateMachine:", state_machine)

func input(_event: InputEvent) -> void:
	# Override in child states if needed.
	pass

func process(_delta: float) -> void:
	# Override in child states if needed.
	pass

func physics_process(_delta: float) -> void:
	# Override in child states if needed.
	pass

func enter(_msg: Dictionary = {}) -> void:
	# Called when the state is entered. Override in child states.
	pass

func exit(_msg: Dictionary = {}) -> void:
	# Called when the state is exited. Override in child states.
	pass
