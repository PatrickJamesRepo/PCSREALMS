extends Item
class_name InventoryItem

# NOTE: IT IS not SLOT AMOUNT, but currently carried amount
@export var amount: int = 0  # Amount being carried in inventory

@export var sprite: Sprite2D
@export var label: Label

func set_data(_name: String, _icon: Texture2D, _is_stackable: bool, _amount: int):
	self.item_name = _name
	self.name = _name
	self.icon = _icon
	self.is_stackable = _is_stackable
	self.amount = _amount
	if sprite:
		sprite.texture = _icon
	else:
		print("Warning: sprite not assigned in InventoryItem", self.name)

func _process(delta):
	if sprite and icon:
		sprite.texture = icon
		set_sprite_size_to(sprite, Vector2(42, 42))
	else:
		print("Error: Sprite or icon missing in InventoryItem", self.name)
	
	if is_stackable:
		if label:
			label.text = str(amount)
		else:
			print("Warning: label not assigned in InventoryItem", self.name)
	else:
		if label:
			label.visible = false

func set_sprite_size_to(sprite: Sprite2D, size: Vector2):
	if not sprite or not sprite.texture:
		print("Error: Sprite or texture is missing in InventoryItem", self.name)
		return  # Exit if sprite or texture is null
	var texture_size = sprite.texture.get_size()
	if texture_size.x > 0 and texture_size.y > 0:
		var scale_factor = Vector2(size.x / texture_size.x, size.y / texture_size.y)
		sprite.scale = scale_factor
	else:
		print("Error: Invalid texture size in InventoryItem", self.name)

func fade():
	if sprite:
		sprite.modulate = Color(1, 1, 1, 0.4)
	else:
		print("Warning: sprite not assigned in fade for InventoryItem", self.name)
	if label:
		label.modulate = Color(1, 1, 1, 0.4)
	else:
		print("Warning: label not assigned in fade for InventoryItem", self.name)
