extends Control

signal joinGame(ip)
signal wallet_address_updated(new_address: String)

@export var Address: String = "204.48.28.159"
@export var port: int = 8910
var peer
var player_wallet_address: String = ""
var game_started: bool = false 

# Multiplayer UI nodes (adjust paths if needed)
@onready var line_edit: LineEdit = get_node_or_null("LineEdit")
@onready var server_browser: Control = get_node_or_null("ServerBrowser")
@onready var wallet_details: RichTextLabel = get_node_or_null("WalletDetails")
@onready var address_input: LineEdit = get_node_or_null("UI/AddressInput")

@onready var amount_input: LineEdit = get_node_or_null("AmountInput")
@onready var password_input: LineEdit = get_node_or_null("WalletMain/SendAdaForm/Password/PasswordInput")
@onready var password_warning: Label = get_node_or_null("WalletMain/SendAdaForm/Password/Status")
@onready var phrase_input: TextEdit = get_node_or_null("PhraseInput")
@onready var timers_details: Label = get_node_or_null("WalletTimers")
@onready var send_ada_button: Button = get_node_or_null("SendAdaButton")
@onready var mint_token_button: Button = get_node_or_null("MintTokenButton")
@onready var create_script_output_button: Button = get_node_or_null("CreateScriptOutput")
@onready var consume_script_input_button: Button = get_node_or_null("ConsumeScriptInput")
@onready var set_button: Button = get_node_or_null("SetButton")
@onready var generate_button: Button = get_node_or_null("GenerateButton")
@onready var join_server_button: Button = get_node_or_null("UI/JoinServerButton")


# Multiplayer signals
@onready var game_state = get_node("/root/GlobalManager")

func _ready() -> void:
	print("MultiplayerController _ready() started.")
	
	# Initialize LineEdit with default Address.
	if line_edit:
		line_edit.text = Address
		line_edit.editable = false
	
	# Make AddressInput read-only.
	if address_input:
		address_input.editable = false
	
	# Connect address_input text_changed signal (for debugging)
	if address_input and not address_input.is_connected("text_changed", Callable(self, "_on_address_input_text_changed")):
		address_input.connect("text_changed", Callable(self, "_on_address_input_text_changed"))
	
	# Setup Join Server button.
	if join_server_button:
		join_server_button.disabled = true
		join_server_button.connect("pressed", Callable(self, "_on_join_server_button_pressed"))
	
	# Connect multiplayer signals.
	if multiplayer:
		multiplayer.peer_connected.connect(peer_connected)
		multiplayer.peer_disconnected.connect(peer_disconnected)
		multiplayer.connected_to_server.connect(connected_to_server)
		multiplayer.connection_failed.connect(connection_failed)
	
	# Start hosting if --server flag is present.
	if "--server" in OS.get_cmdline_args():
		host_game()

func peer_connected(id):
	print("Player Connected: " + str(id))

func peer_disconnected(id):
	print("Player Disconnected: " + str(id))

func connected_to_server():
	print("Connected to Server!")
	SendPlayerInformation.rpc_id(1, line_edit.text, multiplayer.get_unique_id())

func connection_failed():
	print("Couldn't Connect")

@rpc("any_peer")
func SendPlayerInformation(name, id):
	if not GameManager.Players.has(id):
		GameManager.Players[id] = {"name": name, "id": id, "score": 0}
	if multiplayer.is_server():
		for key in GameManager.Players:
			SendPlayerInformation.rpc(GameManager.Players[key].name, key)

@rpc("any_peer", "call_local")
func StartGame() -> void:
	if game_started:
		print("StartGame already triggered; ignoring duplicate call.")
		return
	game_started = true
	print("StartGame() called.")
	
	# First, switch to the main game scene (game.tscn).
	var main_game_scene = preload("res://scenes/game.tscn")
	var err = get_tree().change_scene_to(main_game_scene)
	if err != OK:
		push_error("Failed to switch to game.tscn. Error code: " + str(err))
		return
	
	# Use call_deferred to load the level after game.tscn is fully active.
	call_deferred("_deferred_start_level", "res://components/level1.tscn")

	# Optionally wait to let the scene load, then remove this controller.
	await get_tree().create_timer(0.5).timeout
	print("Removing MultiplayerController from scene.")
	self.queue_free()

# Loads the first level after the main game scene is active.
func _deferred_start_level(first_level_path: String) -> void:
	if LevelManager:
		print("Calling LevelManager.start_game() with level:", first_level_path)
		LevelManager.start_game(first_level_path)
	else:
		print("ERROR: LevelManager not found!")

func host_game():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("Cannot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players!")

func _on_host_button_down():
	host_game()
	SendPlayerInformation.rpc_id(1, line_edit.text, multiplayer.get_unique_id())
	if server_browser and server_browser.has_method("setUpBroadCast"):
		server_browser.setUpBroadCast(line_edit.text + "'s server")

func _on_join_button_down():
	join_by_ip(Address)

func join_by_ip(ip):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Attempting to join server at: " + ip)

func _on_start_game_button_down():
	StartGame.rpc()

func _on_button_button_down():
	GameManager.Players[GameManager.Players.size() + 1] = {"name": "test", "id": 1, "score": 0}

func _on_address_input_text_changed(new_text: String) -> void:
	print("AddressInput text changed:", new_text)

func set_wallet_address(addr: String) -> void:
	player_wallet_address = addr
	if address_input:
		address_input.text = addr
		address_input.editable = false
	if line_edit:
		line_edit.text = addr
		line_edit.editable = false
	emit_signal("wallet_address_updated", addr)
