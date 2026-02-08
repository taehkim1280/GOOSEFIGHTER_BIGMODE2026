extends AudioStreamPlayer

# Call this from anywhere: Music.play_track("res://music/boss_theme.mp3")
func play_track(new_stream_path: String):
	var new_stream = load(new_stream_path)
	
	# Don't restart if it's already playing this song!
	if stream == new_stream:
		return
		
	stream = new_stream
	play()
