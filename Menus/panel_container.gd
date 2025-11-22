extends PanelContainer


@onready var MAIN_SCENE: PackedScene = load("res://main.tscn")
@onready var MOBILE_SCENE: PackedScene = load("res://main.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#$CalendarButton._create_calendar()
	pass

func get_weekday(date:Dictionary) -> int:
	var dt = Time.get_datetime_dict_from_unix_time(
		Time.get_unix_time_from_datetime_dict(date)
	)
	var weekday_index: int = dt["weekday"] # 0=Sunday, 1=Monday, ..., 6=Saturday

	return weekday_index

func date_selected(date,__):
	date["hour"] = 0
	date["minute"] = 0
	date["second"] = 0
	date["weekday"] = get_weekday(date)
	var new_scene: Root
	if $".." is Mobile:
		new_scene = MOBILE_SCENE.instantiate()
	else:
		new_scene = MAIN_SCENE.instantiate()
	
	new_scene.difficulty = $"..".difficulty
	new_scene.number_count = $"..".number_count
	new_scene.date = date
	new_scene.date_override = true
	get_tree().root.add_child(new_scene)
	new_scene.set_date()
	new_scene.save_active = false
	get_tree().paused = false
	get_parent().queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
