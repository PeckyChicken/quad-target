extends Node

var cache_loaded: bool = false

func save_cache(difficulty,won_games: Array):
	var cache := ConfigFile.new()
	cache.set_value("last_play","difficulty",difficulty)
	cache.set_value("last_play","wins",won_games)
	
	cache.set_value("metadata","date",_get_save_date())
	cache.save("user://cache.cfg")

func load_cache():
	var data := {}
	var cache := ConfigFile.new()
	cache.load("user://cache.cfg")
	if cache.has_section_key("metadata","date") and cache.get_value("metadata","date") == _get_save_date():
		if cache.has_section("last_play"):
			var keys: Array = Array(cache.get_section_keys("last_play"))
			for key in keys:
				data[key] = cache.get_value("last_play",key,ERR_DOES_NOT_EXIST)
	
	cache_loaded = true
	return data

func _get_save_date() -> int:
	var save_date := Time.get_datetime_dict_from_system()
	
	save_date["hour"] = 0
	save_date["minute"] = 0
	save_date["second"] = 0
	return Time.get_unix_time_from_datetime_dict(save_date)

func save(file_name:String,stats:Dictionary,date:Dictionary,
			numbers:Array,target:int,hard_mode_beaten:bool):
	var save_file := ConfigFile.new()
	save_file.set_value("user_data","stats",stats)
	save_file.set_value("user_data","date",Time.get_unix_time_from_datetime_dict(date))
	save_file.set_value("user_data","target",target)
	save_file.set_value("user_data","numbers",numbers)
	save_file.set_value("user_data","hard_mode_beaten",hard_mode_beaten)
	
	save_file.set_value("metadata","date",_get_save_date())
	
	save_file.save("user://%s.cfg" % [file_name])
	

func remove_user_data(file_name:String,data:String):
	var save_file := ConfigFile.new()
	if save_file.load("user://%s.cfg" % [file_name]) != OK:
		return
	
	if save_file.has_section_key("user_data",data):
		save_file.erase_section_key("user_data",data)
	
	save_file.save("user://%s.cfg" % [file_name])

func load_save(file_name:String) -> Dictionary:
	var data: Dictionary = {}
	data["success"] = true
	
	var save_file := ConfigFile.new()
	
	if save_file.load("user://%s.cfg" % [file_name]) != OK:
		data["success"] = false
	
	var timesave = save_file.get_value("metadata","date",ERR_DOES_NOT_EXIST)	
	
	if save_file.has_section("user_data"):
		var keys: Array = Array(save_file.get_section_keys("user_data"))
		for key in keys:
			data[key] = save_file.get_value("user_data",key,ERR_DOES_NOT_EXIST)
	
	if timesave == ERR_DOES_NOT_EXIST or _get_save_date() != timesave:
		data["success"] = false
	
	return data
