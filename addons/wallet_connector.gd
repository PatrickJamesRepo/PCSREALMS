extends Node

# Core WalletConnector functionality for the plugin

var wallet_connected = false
var wallet_assets = []

# This function will be triggered when the plugin is enabled
func _ready():
	print("Godot-Cardano Plugin Initialized!")

# Function to check wallet connection status
func is_wallet_connected() -> bool:
	return wallet_connected

# Function to prompt the user to connect their wallet
func connect_wallet():
	# Simulate wallet connection (Replace with actual logic)
	wallet_connected = true
	print("Wallet connected!")

# Function to generate a new wallet (replace with actual Cardano logic)
func generate_wallet():
	print("Generating a new wallet...")
	wallet_connected = true
	wallet_assets = ["New Wallet Asset"]
	return wallet_assets

# Function to fetch wallet assets
func get_wallet_assets():
	return wallet_assets
