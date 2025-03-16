extends Control

signal found_server
signal server_removed
signal joinGame(ip)

@export var listenPort: int = 8911
@export var broadcastPort: int = 8912
@export var broadcastAddress: String = "192.168.1.255"
@export var serverInfo: PackedScene

var broadcastTimer: Timer
var listner: PacketPeerUDP
var broadcaster: PacketPeerUDP
var RoomInfo = {"name": "Server", "playerCount": 0}

@onready var status_label: Label = $Label2
@onready var vbox: Control = $Panel/VBoxContainer

func _ready():
	print("ServerBrowser _ready() called.")
	broadcastTimer = $BroadcastTimer
	setUp()

func setUp():
	listner = PacketPeerUDP.new()
	var ok = listner.bind(listenPort)
	if ok == OK:
		print("Bound to listen Port " + str(listenPort) + " Successful!")
		if status_label:
			status_label.text = "Bound To Listen Port: true"
	else:
		print("Failed to bind to listen port!")
		if status_label:
			status_label.text = "Bound To Listen Port: false"

func setUpBroadCast(server_name: String):
	print("Setting up broadcast for server:", server_name)
	RoomInfo["name"] = server_name
	RoomInfo["playerCount"] = GameManager.Players.size()
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(broadcastAddress, listenPort)
	var ok = broadcaster.bind(broadcastPort)
	if ok == OK:
		print("Bound to Broadcast Port " + str(broadcastPort) + " Successful!")
	else:
		print("Failed to bind to broadcast port!")
		return
	$BroadcastTimer.start()

func _process(delta):
	if listner.get_available_packet_count() > 0:
		var server_ip = listner.get_packet_ip()
		var server_port = listner.get_packet_port()
		var bytes = listner.get_packet()
		var data = bytes.get_string_from_ascii()
		print("server Ip: " + server_ip + " serverPort: " + str(server_port) + " room info: " + data)
		var roomInfoParsed = JSON.parse_string(data)
		if not roomInfoParsed or not roomInfoParsed is Dictionary:
			print("Invalid broadcast packet received.")
			return
		update_server_browser(roomInfoParsed, server_ip)
	
func _on_broadcast_timer_timeout():
	print("Broadcasting Game!")
	RoomInfo["playerCount"] = GameManager.Players.size()
	var data = JSON.stringify(RoomInfo)
	var packet = data.to_ascii_buffer()
	broadcaster.put_packet(packet)
	print("Broadcast packet sent successfully.")

func update_server_browser(room_info: Dictionary, server_ip: String):
	print("Updating Server Browser with:", room_info)
	var room_name = room_info.get("name", "Unknown Server")
	var player_count = str(room_info.get("playerCount", 0))
	
	# Update existing listing if found.
	for child in vbox.get_children():
		if child.name == room_name:
			var ip_node = child.get_node_or_null("Ip")
			var count_node = child.get_node_or_null("PlayerCount")
			if ip_node:
				ip_node.text = server_ip
			if count_node:
				count_node.text = player_count
			print("Updated existing server info for:", room_name)
			return
	
	# Instantiate new server info item.
	if serverInfo == null:
		push_error("serverInfo PackedScene is not assigned!")
		return
	var new_server_info = serverInfo.instantiate()
	new_server_info.name = room_name
	var name_node = new_server_info.get_node_or_null("Name")
	var ip_node = new_server_info.get_node_or_null("Ip")
	var count_node = new_server_info.get_node_or_null("PlayerCount")
	if name_node:
		name_node.text = room_name
	if ip_node:
		ip_node.text = server_ip
	if count_node:
		count_node.text = player_count
	vbox.add_child(new_server_info)
	print("Added server info instance to vbox:", new_server_info.name)
	
	if new_server_info.has_signal("joinGame"):
		var call = Callable(self, "_on_server_info_join_requested")
		if not new_server_info.is_connected("joinGame", call):
			new_server_info.connect("joinGame", call)
	else:
		print("WARNING: The serverInfo scene does not have a 'joinGame' signal.")

func _on_server_info_join_requested(ip: String):
	emit_signal("joinGame", ip)

func cleanUp():
	if listner:
		listner.close()
	$BroadcastTimer.stop()
	if broadcaster:
		broadcaster.close()

func _exit_tree():
	cleanUp()

func joinbyIp(ip):
	emit_signal("joinGame", ip)
