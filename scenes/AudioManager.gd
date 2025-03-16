extends Node

@export var music_volume: float = 1.0
var audio_player: AudioStreamPlayer2D

func _ready() -> void:
	# Clamp music_volume between 0.0 and 1.0.
	music_volume = clamp(music_volume, 0.0, 1.0)
	
	# Create an AudioStreamPlayer2D node and add it as a child.
	audio_player = AudioStreamPlayer2D.new()
	audio_player.name = "AudioPlayer2D"
	add_child(audio_player)
	
	# Use the "res://" path for your audio file.
	var track_path = "res://audio/theme.ogg"
	var stream = load(track_path)
	
	# Check if the resource loaded successfully.
	if stream == null:
		push_error("[AudioManager] Failed to load audio file from: " + track_path)
		return  # Stop further execution if file loading fails.
	
	# Verify that the loaded resource is indeed an AudioStream.
	if not stream is AudioStream:
		push_error("[AudioManager] Loaded resource is not an AudioStream! Check the file format.")
		return
	   
	# Assign the stream to the audio player.
	audio_player.stream = stream
	
	# Set the volume using the custom conversion function.
	audio_player.volume_db = linear_to_db(music_volume)
	
	# Attempt to play the audio.
	audio_player.play()
	print("[AudioManager] Music started playing from:", track_path)

func linear_to_db(linear: float) -> float:
	# Return a typical minimum dB value if the input is zero or negative.
	if linear <= 0:
		return -80.0
	# Convert the linear volume to decibels using base-10 logarithm.
	return 20 * (log(linear) / log(10))
