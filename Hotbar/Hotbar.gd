extends Control
class_name Hotbar

@export var underlying_inventory: Inventory

static var all_hotbars_slots: Array[InventorySlot] = []
static var highlighted_slot: InventorySlot = null




# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("hotbars")

	if all_hotbars_slots.size() == 0:
		for hotbar in get_tree().get_nodes_in_group("hotbars"):
			var hotbar_slots: Array[InventorySlot] = underlying_inventory.slots
			for slot in hotbar_slots:
				all_hotbars_slots.append(slot)






# Hotbars-wide GUI input (for changing highlighted slots)
func _input(event):
	# Update highlighted slot
	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var current_slot_index: int = 0
			for i in range(all_hotbars_slots.size()):
				if all_hotbars_slots[i] == highlighted_slot:
					current_slot_index = i
					break
			if highlighted_slot:
				highlighted_slot.modulate = Color(1, 1, 1) # Reset
			highlighted_slot = all_hotbars_slots[(current_slot_index - 1) % all_hotbars_slots.size()]
			highlighted_slot.modulate = Color(0.7, 0.7, 0.7)
		

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var current_slot_index: int = 0
			for i in range(all_hotbars_slots.size()):
				if all_hotbars_slots[i] == highlighted_slot:
					current_slot_index = i
					break
			if highlighted_slot:
				highlighted_slot.modulate = Color(1, 1, 1) # Reset
			highlighted_slot = all_hotbars_slots[(current_slot_index + 1) % all_hotbars_slots.size()]
			highlighted_slot.modulate = Color(0.7, 0.7, 0.7)





"""
# Hotbars-wide GUI input (for changing highlighted slots)
func _input(event):
	# Update highlighted slot
	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			var current_slot_index: int = 0
			for i in range(slots.size()):
				if slots[i] == highlighted_slot:
					current_slot_index = i
					break
			if highlighted_slot:
				highlighted_slot.modulate = Color(1, 1, 1) # Reset
			highlighted_slot = slots[(current_slot_index - 1) % slots.size()]
			highlighted_slot.modulate = Color(0.7, 0.7, 0.7)
		

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var current_slot_index: int = 0
			for i in range(slots.size()):
				if slots[i] == highlighted_slot:
					current_slot_index = i
					break
			if highlighted_slot:
				highlighted_slot.modulate = Color(1, 1, 1) # Reset
			highlighted_slot = slots[(current_slot_index + 1) % slots.size()]
			highlighted_slot.modulate = Color(0.7, 0.7, 0.7)
"""
