extends CenterContainer
class_name InventorySlot

@export var inventory_item_scene: PackedScene = preload("res://Inventory/InventorySlot/InventorySlot.tscn")
@export var item: InventoryItem
@export var hint_item: InventoryItem = null

enum InventorySlotAction {
	SELECT, SPLIT
}

signal slot_input(which: InventorySlot, action: InventorySlotAction)
signal slot_hovered(which: InventorySlot, is_hovering: bool)

func _ready():
	add_to_group("inventory_slots")
	print("InventorySlot _ready:", self.name)

func _on_texture_button_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			print("InventorySlot:", self.name, "left clicked")
			emit_signal("slot_input", self, InventorySlotAction.SELECT)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			print("InventorySlot:", self.name, "right clicked")
			emit_signal("slot_input", self, InventorySlotAction.SPLIT)

func _on_texture_button_mouse_entered():
	print("Mouse entered slot:", self.name)
	emit_signal("slot_hovered", self, true)

func _on_texture_button_mouse_exited():
	print("Mouse exited slot:", self.name)
	emit_signal("slot_hovered", self, false)

func is_respecting_hint(new_item: InventoryItem, in_amount_as_well: bool = true) -> bool:
	if not hint_item:
		return true
	if in_amount_as_well:
		return (new_item.item_name == hint_item.item_name and new_item.amount >= hint_item.amount)
	else:
		return new_item.item_name == hint_item.item_name

func set_item_hint(new_item_hint: InventoryItem):
	if hint_item:
		hint_item.free()
	hint_item = new_item_hint
	add_child(new_item_hint)
	update_slot()
	print("Set hint in slot", self.name, "to", new_item_hint.item_name)

func clear_item_hint():
	if hint_item:
		hint_item.free()
	hint_item = null
	update_slot()
	print("Cleared hint in slot", self.name)

func remove_item():
	if item:
		if has_node(item.get_path()):
			remove_child(item)
		item.free()
		item = null
		update_slot()
		print("Removed item from slot", self.name)

func select_item() -> InventoryItem:
	var inventory = get_parent().get_parent()  # Assuming Inventory is the grandparent.
	var tmp_item = item
	if tmp_item:
		tmp_item.reparent(inventory)
		item = null
		tmp_item.z_index = 128
		print("Selected item", tmp_item.name, "from slot", self.name)
	return tmp_item

func deselect_item(new_item: InventoryItem) -> InventoryItem:
	if not is_respecting_hint(new_item):
		return new_item  # Do nothing if hint is not respected.
	var inventory = get_parent().get_parent()
	if is_empty():
		new_item.reparent(self)
		item = new_item
		item.z_index = 64
		print("Placed new item", new_item.name, "in empty slot", self.name)
		return null
	else:
		if has_same_item(new_item):
			print("Stacking items in slot", self.name)
			item.amount += new_item.amount
			new_item.free()
			update_slot()
			return null
		else:
			new_item.reparent(self)
			item.reparent(inventory)
			var tmp_item = item
			item = new_item
			new_item.z_index = 64
			tmp_item.z_index = 128
			print("Swapped item in slot", self.name)
			update_slot()
			return tmp_item

func split_item() -> InventoryItem:
	if is_empty():
		return null
	var inventory = get_parent().get_parent()
	if item.amount > 1:
		var new_item: InventoryItem = inventory_item_scene.instantiate() as InventoryItem
		new_item.set_data(item.item_name, item.icon, item.is_stackable, item.amount)
		new_item.amount = item.amount / 2
		item.amount -= new_item.amount
		inventory.add_child(new_item)
		new_item.z_index = 128
		print("Split item in slot", self.name, "new amount:", new_item.amount)
		update_slot()
		return new_item
	elif item.amount == 1:
		return select_item()
	else:
		return null

func is_empty() -> bool:
	return item == null

func has_same_item(_item: InventoryItem) -> bool:
	return item and (_item.item_name == item.item_name)

func update_slot():
	print("Updating slot", self.name)
	if item:
		if not get_children().has(item):
			add_child(item)
			print("Added item", item.name, "to slot", self.name)
		else:
			print("Item", item.name, "already present in slot", self.name)
		print("Item z_index:", item.z_index)
		for child in get_children():
			print("Child in slot", self.name, ":", child.name, "z_index:", child.z_index)
		if item.amount < 1:
			item.fade()
	if hint_item:
		if not get_children().has(hint_item):
			add_child(hint_item)
			print("Added hint item", hint_item.name, "to slot", self.name)
		else:
			print("Hint item", hint_item.name, "already present in slot", self.name)
		hint_item.fade()
