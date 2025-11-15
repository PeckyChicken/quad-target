extends Control

var cache: Dictionary[String,AudioStream] = {}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.PlaySound.connect(play_sound)
	load_all_sounds()

func load_all_sounds():
	var sounds: Array[String] = _find_all_sounds("./Sounds")
	for sound in sounds:
		if sound.get_extension() == "import":
			sound = sound.replace(".import","")
		load_sound(sound)

func _find_all_sounds(directory) -> Array[String]:
	var dir = DirAccess.open(directory)
	var sounds: Array[String] = []
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				sounds.append_array(_find_all_sounds(directory + "/" + file_name))
			else:
				sounds.append(file_name)
			
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	
	return sounds

func play_sound(sound:String,location:Vector2=Vector2.INF):
	var player
	if location == Vector2.INF:
		player = AudioStreamPlayer.new()
	else:
		player = AudioStreamPlayer2D.new()
	add_child(player)
	
	player.stream = load_sound(sound)
	
	player.position = location
	player.play()
	player.finished.connect(player.queue_free)

func load_sound(sound:String):
	if sound.ends_with(".ogg"):
		sound = sound.replace(".ogg","")
	
	if sound not in cache:
		cache[sound] = load("res://Sounds/%s.ogg" % [sound])
	
	return cache[sound]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
