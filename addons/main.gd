extends Node

@export
var mint_token_conf: Cip68Config

var provider: Provider
var wallet: OnlineWallet.OnlineSingleAddressWallet = null
var correct_password: String = ""
var loader := SingleAddressWalletLoader.new(ProviderApi.Network.MAINNET)  # Set to MAINNET
var wallet_address: String = ""
signal wallet_address_updated(new_address: String)
@export var line_edit_path: NodePath = "MultiplayerScene/UI/LineEdit"
var line_edit: LineEdit


@onready
var wallet_details: RichTextLabel = %WalletDetails
@onready
var address_input: LineEdit = %AddressInput
@onready
var amount_input: LineEdit = %AmountInput
@onready
var password_input: LineEdit = $WalletMain/SendAdaForm/Password/PasswordInput
@onready
var password_warning: Label =  $WalletMain/SendAdaForm/Password/Status
@onready
var phrase_input: TextEdit = %PhraseInput
@onready
var timers_details: Label = %WalletTimers
@onready
var send_ada_button: Button = %SendAdaButton
@onready
var mint_token_button: Button = %MintTokenButton
@onready
var create_script_output_button: Button = %CreateScriptOutput
@onready
var consume_script_input_button: Button = %ConsumeScriptInput
@onready
var set_button: Button = %SetButton
@onready
var generate_button: Button = %GenerateButton
@export var join_server_button_path: NodePath = "WalletMain/SendAdaForm/Buttons/JoinServerButton"
@onready var join_server_button: Button = get_node_or_null(join_server_button_path) as Button

@onready
var wallet_control: Node = get_tree().root.get_node_or_null("WalletMainControl")

var test_spend_script: PlutusScript = PlutusScript.create("581b0100003222253330043330043370e900124008941288a4c2cae681".hex_decode())
@onready var game_state = get_node("/root/GlobalManager")

func _ready() -> void:
	print("WalletMain _ready() started.")
	
	# Retrieve the MultiplayerScene LineEdit if needed.
	line_edit = get_tree().root.get_node(line_edit_path) as LineEdit
	if line_edit:
		print("LineEdit found:", line_edit.name)
	else:
		print("LineEdit not found!")
	
	# Set address_input to read-only.
	address_input.editable = false
	if not address_input.is_connected("text_changed", Callable(self, "_on_address_input_text_changed")):
		address_input.connect("text_changed", Callable(self, "_on_address_input_text_changed"))
		
	if join_server_button:
		if not join_server_button.is_connected("pressed", Callable(self, "_on_join_server_button_pressed")):
			join_server_button.connect("pressed", Callable(self, "_on_join_server_button_pressed"))
			print("Connected JoinServerButton signal.")
		join_server_button.disabled = true
		print("Join Server button disabled in _ready().")
	else:
		push_error("JoinServerButton node not found at path: " + str(join_server_button_path))
	
	# Initialize provider API and provider.
	var token: String = ""
	var token_file := FileAccess.open("res://addons/mainnet_token.txt", FileAccess.READ)
	if token_file != null:
		token = token_file.get_as_text(true).replace("\n", "")
		print("Token read:", token)
	else:
		print("Token file not found!")
	
	var provider_api := BlockfrostProviderApi.new(ProviderApi.Network.MAINNET, token)
	if provider_api == null:
		print("Failed to initialize provider API.")
		return
	provider = Provider.new(provider_api)
	add_child(provider_api)
	add_child(provider)
	
	wallet_details.text = "No wallet set"
	
	var seed_phrase_file := FileAccess.open("./seed_phrase.txt", FileAccess.READ)
	if seed_phrase_file != null:
		phrase_input.text = seed_phrase_file.get_as_text(true)
		print("Seed phrase read; attempting wallet creation.")
		_create_wallet_from_seedphrase(phrase_input.text)
	else:
		print("Seed phrase file not found.")
	
	if mint_token_conf != null:
		await mint_token_conf.init_script(provider)
		print("mint_token_conf initialized.")
	else:
		print("mint_token_conf is not initialized.")


func _on_join_server_button_pressed() -> void:
	var wallet_addr = address_input.text
	print("JoinServerButton pressed! Wallet address: " + wallet_addr)
	
	if wallet_control:
		wallet_control.visible = false
		print("WalletMainControl hidden.")
	else:
		push_error("WalletMainControl not found!")
	
	# Call the global state manager's start_multiplayer() method
	if Engine.has_singleton("GlobalManager"):
		var gm = Engine.get_singleton("GlobalManager")
		gm.start_multiplayer(wallet_addr)
		print("GlobalManager.start_multiplayer() called with wallet address: " + wallet_addr)
	else:
		push_error("GlobalManager autoload not found! Please set GlobalManager as autoload.")



func _on_wallet_set() -> void:
	if wallet == null:
		push_error("Error: wallet is null.")
		return
	
	if wallet.has_signal("got_updated_utxos"):
		wallet.got_updated_utxos.connect(Callable(self, "_on_utxos_updated"))
	else:
		push_error("Warning: wallet does not have got_updated_utxos signal.")
	
	var addr: String = ""
	if wallet.has_method("get_address"):
		addr = wallet.get_address().to_bech32()
	else:
		push_error("Error: wallet does not implement get_address().")
		return
	
	if addr == "":
		push_error("Error: Retrieved address is empty.")
		return
	
	if wallet_details:
		wallet_details.text = "Using wallet %s" % addr
	else:
		push_error("Warning: wallet_details node not found.")
	
	if address_input:
		address_input.text = addr
		address_input.editable = false
	else:
		push_error("Warning: address_input node not found.")
	
	wallet_address = addr
	emit_signal("wallet_address_updated", wallet_address)
	
	if join_server_button:
		join_server_button.disabled = false
	else:
		push_error("Warning: join_server_button node not found.")
	
	print("Wallet is set; Join Server button enabled. Wallet address: %s" % wallet_address)
	
	if Engine.has_singleton("MultiplayerScene"):
		var ms = Engine.get_singleton("MultiplayerScene")
		if ms and ms.has_method("set_wallet_address"):
			ms.set_wallet_address(addr)
			print("Passed wallet address to MultiplayerScene autoload:", addr)
		else:
			push_error("MultiplayerScene does not implement set_wallet_address().")
	else:
		push_error("MultiplayerScene autoload not found!")


# ----------------------------------------------------------------
# Wallet Update: _on_utxos_updated()
# ----------------------------------------------------------------
func _on_utxos_updated(utxos: Array[Utxo]) -> void:
	var num_utxos := utxos.size()
	var total_lovelace: BigInt = utxos.reduce(
		func (acc: BigInt, utxo: Utxo) -> BigInt:
			return acc.add(utxo.coin()),
		BigInt.zero()
	)
	wallet_details.text = "Using wallet %s" % wallet._get_change_address().to_bech32()
	if num_utxos > 0:
		wallet_details.text += "\n\nFound %s UTxOs with %s lovelace" % [str(num_utxos), total_lovelace.to_str()]
		send_ada_button.disabled = false
		mint_token_button.disabled = false
		create_script_output_button.disabled = false
		consume_script_input_button.disabled = false

# ----------------------------------------------------------------
# Play Button Handler: Launch Multiplayer Scene
# ----------------------------------------------------------------

func _on_send_ada_button_pressed() -> void:
	var amount_result: BigInt.ConversionResult = BigInt.from_str(amount_input.text)
	if amount_result.is_err():
		push_error("Error parsing amount as BigInt", amount_result.error)
		return
	var address_result := Address.from_bech32(address_input.text)
	if address_result.is_err():
		push_error("Error parsing address: %s", address_result.error)
		return
	var create_tx_result := await wallet.new_tx()
	if create_tx_result.is_err():
		push_error("Error creating transaction: %s", create_tx_result.error)
		return
	var tx := create_tx_result.value
	tx.pay_to_address(address_result.value, amount_result.value, MultiAsset.empty())
	tx.valid_after(Time.get_unix_time_from_system() - 120)
	tx.valid_before(Time.get_unix_time_from_system() + 180)
	var result := await tx.complete()
	if result.is_ok():
		result.value.sign(password_input.text)
		var submit_result = await result.value.submit()
		if submit_result.is_err():
			print('Failed to submit transaction: %s' % submit_result.error)
		else:
			await provider.await_tx(submit_result.value)

func _on_mint_token_button_pressed() -> void:
	var address_result := Address.from_bech32(address_input.text)
	if address_result.is_err():
		push_error("Could not convert Bech32 to address: %s" % address_result.error)
		return
	var address := address_result.value
	var create_tx_result := await wallet.new_tx()
	if create_tx_result.is_err():
		push_error("Error creating transaction: %s" % create_tx_result.error)
		return
	var tx: TxBuilder = create_tx_result.value
	tx.mint_cip68_pair(VoidData.to_data(), mint_token_conf)
	tx.pay_cip68_ref_token(address, mint_token_conf)
	var result := await tx.complete()
	if result.is_ok():
		result.value.sign(password_input.text)
		var submit_result := await result.value.submit()
		if submit_result.is_err():
			push_error("Failed to submit transaction: %s" % submit_result.error)
		else:
			print("Token minted successfully. Tx hash: ", submit_result.value.to_hex())
	else:
		push_error("Failed to complete transaction: %s" % result.error)



func set_wallet(key_ring: SingleAddressWallet) -> void:
	# If a wallet already exists, remove it.
	if wallet != null:
		wallet.queue_free()
	
	# Create a new online wallet using the provided key ring and provider.
	wallet = OnlineWallet.OnlineSingleAddressWallet.new(key_ring, provider)
	add_child(wallet)
	
	# Save the current password for future transactions.
	correct_password = password_input.text
	password_warning.text = ""
	
	# Trigger the wallet setup callback to update UI and other signals.
	_on_wallet_set()

	
# Asynchronously load the wallet from a seedphrase
func _create_wallet_from_seedphrase(seedphrase: String) -> void:
	var old_text := set_button.text
	set_button.text = "Loading wallet..."
	set_button.disabled = true
	generate_button.disabled = true
	var res := await loader.import_from_seedphrase(
		seedphrase,
		"",
		password_input.text,
		0,
		"First account",
		"The first account created"
	)
	if res.is_ok():
		set_wallet(res.value.wallet)
	else:
		push_error("Could not set wallet, error:", res.error)
	set_button.text = old_text
	set_button.disabled = false
	generate_button.disabled = false

func _on_create_script_output_pressed() -> void:
	var tx := await wallet.new_tx()
	if tx.is_err():
		push_error("Could not create tx_builder", tx.error)
		return
	var script_address = provider.make_address(Credential.from_script(test_spend_script))
	tx.value.pay_to_address_with_datum_hash(
		script_address,
		BigInt.from_int(5_000_000),
		MultiAsset.empty(),
		BigInt.from_int(66)
	)
	var result: TxBuilder.CompleteResult = await tx.value.complete()
	if result.is_err():
		print("Could not complete transaction", result.error)
		return
	if result.is_ok():
		result.value.sign(password_input.text)
		var hash := await result.value.submit()
		print("Transaction hash:", hash.value.to_hex())

func _on_consume_script_input_pressed() -> void:
	# Create the script address from the test script.
	var script_address = provider.make_address(Credential.from_script(test_spend_script))
	
	# Retrieve UTxOs at the script address.
	var utxos := await provider.get_utxos_at_address(script_address)
	# Filter only those UTxOs that have associated datum.
	var utxos_filtered = utxos.filter(func(u: Utxo) -> bool:
		return u.datum_info().has_datum()
	)
	
	# Create a new transaction builder.
	var tx_result := await wallet.new_tx()
	if tx_result.is_err():
		push_error("Could not create tx_builder: %s" % tx_result.error)
		return

	var tx = tx_result.value
	# Collect funds from the script using the filtered UTxOs.
	tx.collect_from_script(
		PlutusScriptSource.from_script(test_spend_script),
		utxos_filtered,
		BigInt.from_int(0)
	)
	
	# Complete the transaction building process.
	var result : TxBuilder.CompleteResult = await tx.complete()
	if result.is_err():
		push_error("Could not complete transaction: %s" % result.error)
		return

	# If transaction is ready, sign and submit it.
	result.value.sign(password_input.text)
	var submit_result := await result.value.submit()
	if submit_result.is_err():
		push_error("Transaction submission failed: %s" % submit_result.error)
	else:
		print("Transaction hash:", submit_result.value.to_hex())


func _on_password_input_text_changed(new_text: String) -> void:
	# If a wallet is set and the input password does not match, warn the user.
	if wallet != null and new_text != correct_password:
		password_warning.text = "Password incorrect, transaction signing will fail"
	else:
		password_warning.text = ""


func _on_set_button_pressed() -> void:
	# Trigger wallet creation from the entered seed phrase.
	_create_wallet_from_seedphrase(phrase_input.text)


func _on_generate_button_pressed() -> void:
	# Cache current button text to restore later.
	var old_text := generate_button.text
	generate_button.text = "Generating wallet..."
	set_button.disabled = true
	generate_button.disabled = true
	
	# Create a new wallet using the provided password and network settings.
	var create_result := SingleAddressWalletLoader.create(
		password_input.text,
		0,
		"",
		"",
		ProviderApi.Network.MAINNET  # Set network to MAINNET
	)
	
	if create_result.is_ok():
		# Update the seed phrase field and set the wallet.
		phrase_input.text = create_result.value.seed_phrase
		set_wallet(create_result.value.wallet)
	else:
		push_error("Creating wallet failed: %s" % create_result.error)
	
	# Restore button text and re-enable the buttons.
	set_button.text = old_text
	generate_button.text = old_text
	set_button.disabled = false
	generate_button.disabled = false
