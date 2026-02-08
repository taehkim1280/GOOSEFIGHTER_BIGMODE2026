extends Node

# --- Load your Sound Files ---
# Make sure these paths match exactly where they are in your FileSystem!
var sounds = {
	"dash": preload("res://assets/dash.mp3"),
	"freeze": preload("res://assets/freeze.mp3"),
	"snow_bomb": preload("res://assets/snow bomb.mp3"),
	"stick_hit": preload("res://assets/stick hit.mp3"),
	"wall_hit": preload("res://assets/wall collision.mp3")
}

# Pool of players to reuse
var num_players = 8
var bus = "Master"

func _ready():
	# Create the pool of AudioStreamPlayers
	for i in range(num_players):
		var p = AudioStreamPlayer.new()
		p.bus = bus
		add_child(p)

func play_sfx(sound_name: String, pitch_scale: float = 1.0):
	if not sounds.has(sound_name):
		print("ERROR: Sound not found: ", sound_name)
		return

	# Find an available player
	for child in get_children():
		if child is AudioStreamPlayer and not child.playing:
			child.stream = sounds[sound_name]
			child.pitch_scale = pitch_scale
			child.play()
			return
			
	# Optional: If all busy, force the first one (or just ignore)
	print("Too many sounds playing at once!")
