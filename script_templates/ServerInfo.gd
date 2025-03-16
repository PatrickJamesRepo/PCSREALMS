extends HBoxContainer

signal joinGame(ip)

@onready var ip_label: Label = $Ip
@onready var join_button: Button = $Button

func _ready():
	join_button.connect("pressed", Callable(self, "_on_join_button_pressed"))

func _on_join_button_pressed():
	emit_signal("joinGame", ip_label.text)
