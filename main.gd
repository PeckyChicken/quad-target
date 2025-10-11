class_name Root
extends Control

enum Tiles{
	NUMBER,
	OPERATION,
	SHADOW,
	STATIC,
	ANSWER
}
@onready var containers: Array[Control] = [$Equation/Expression,$Storage,$Operations,$Equation/Answer]

var target: int
var target_tile: NumberTile

enum Difficulty {
	easy,
	hard,
	quint_target
}
var difficulty := Difficulty.hard

var save_name: String


var number_count: int = 4

var starting_numbers: Array
var total_numbers: Array

@onready var NUMBER_TILE_SCENE: PackedScene = load("res://number_tile.tscn")
@onready var TARGET_TILE_SCENE: PackedScene = load("res://target_tile.tscn")
@onready var WIN_SCENE: PackedScene = load("res://win_screen.tscn")
@onready var PANEL_CONTAINER_SCENE: PackedScene = load("res://panel_container.tscn")

var date_override: bool = false
var date: Dictionary
var puzzle_seed: int

var timer: float = 0.0
var moves: int = 0

var mobile: bool = false
var tile_scale = Vector2.ONE

const WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const MONTHS = ["January", "February", "March", "April", "May", "June",
			  "July", "August", "September", "October", "November", "December"]

var __ := 0

var save_data: Dictionary

var win_screen_shown := false

@onready var answer_container = $Equation/Answer/Symbols


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reload_cache(Save.load_cache())
	if difficulty == Difficulty.quint_target:
		number_count = 5
	save_name = "%s_mode_save" % [Difficulty.keys()[difficulty]]
	print(save_name)
	save_data = Save.load_save(save_name)
	if save_data["success"]:
		reload_save(save_data)
		if win_screen_shown:
			Events.PlaySound.emit("win",get_viewport().get_visible_rect().size/2)
			create_win_screen(timer,moves,save_data["stats"]["solution"])
	else:
		if not date_override:
			date = Time.get_datetime_dict_from_system()
		
		date["hour"] = 0
		date["minute"] = 0
		date["second"] = 0
		puzzle_seed = Time.get_unix_time_from_datetime_dict(date)
	set_date()
	Events.TileCreated.connect(check_win)
	Events.MakeNumberList.connect(func():total_numbers=[])

func _notification(what):
	if what in [NOTIFICATION_WM_CLOSE_REQUEST,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		print("Saving cache....")
		Save.save_cache(difficulty,win_screen_shown)
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			get_tree().quit()

func reload_save(data:Dictionary):
	puzzle_seed = data["date"]
	var stats = data["stats"]
	moves = stats["moves"]
	timer = stats["time"]
	date = Time.get_datetime_dict_from_unix_time(data["date"])
	target = data["target"]
	
	number_count = 5 if difficulty == Difficulty.quint_target else 4
	starting_numbers = data["numbers"]

func reload_cache(cache):
	if "difficulty" in cache:
		difficulty = cache.get("difficulty") as Difficulty
	if "win_screen_shown" in cache and cache["win_screen_shown"]:
		win_screen_shown = true

func create_solution(history) -> String:
	var solution: String = ""
	for component in history:
		if component is Array:
			solution += " (%s)" % [create_solution(component)]
			continue
		solution += " " + str(component)
	
	return solution.strip_edges().replace("( ","(").replace(" )",")")

func create_win_screen(time,move_count,solution):
	var win_screen: WinScreen = WIN_SCENE.instantiate()
	win_screen.time = time
	win_screen.moves = move_count
	win_screen.solution = solution
	add_child(win_screen)
	win_screen_shown = true

func check_win(tile:Tile):
	if tile is NumberTile and tile is not TargetTile and tile.number == target:
		Events.PlaySound.emit("win",tile.global_position)
		tile.get_node("Outline").color = Color("#737C63")
		tile.get_node("Fill").color = Color("#1B3A1B")
		var solution = create_solution(tile.history) + " = " + str(tile.number)
		create_win_screen(timer,moves,solution)
		Save.save(save_name,{"moves":moves,"time":timer,"solution":solution},date,total_numbers,target,difficulty == Difficulty.hard)
		Save.save_cache(difficulty,true)
		
		get_tree().paused = true

func set_date():
	if difficulty == Difficulty.quint_target:
		$Date.text = "Quint Target"
	else:
		$Date.text = "Quad Target"
	$Date.text += "\n%s, %d %s %d" % [
		WEEKDAYS[date.weekday],
		date.day,
		MONTHS[date.month - 1],
		date.year
	]

func create_target_tile():
	for prev_tile in $Target/Symbols.get_children():
		prev_tile.queue_free()
	target_tile = TARGET_TILE_SCENE.instantiate()
	target_tile.type = Tiles.STATIC
	target_tile.number = target
	target_tile.expression = "Target"
	$Target/Symbols.add_child(target_tile)

#func evaluate_expression(expression):
	#var exp := ExpressionContainer.new()
	#var parse_check = exp.validate_expression(exp.godotify_expression(expression))
	#if parse_check[0]:
		#var output = exp.calcuate_answer()
		#return output

func create_number_tiles(numbers: Array):
	for number in numbers:
		var new_tile: NumberTile = NUMBER_TILE_SCENE.instantiate()
		new_tile.type = Tiles.NUMBER
		if number is int:
			new_tile.number = number
			new_tile.expression = ""
		else:
			var temp_exp = ExpressionContainer.new()
			var parser := Expression.new()
			var expression: String = temp_exp.godotify_expression(" ".join(answer_container.compress_history_component(number)))
			parser.parse(expression)
			new_tile.number = parser.execute()
			new_tile.history = number
			new_tile.expression = " ".join(answer_container.compress_history_component(new_tile.history))
			#new_tile.extra_data["expression"] = $Equation/Expression/Symbols
			
		new_tile.draggable = true
		add_child(new_tile)
		new_tile.add_to_container($Storage/Symbols,Vector2.INF)

func _input(_event: InputEvent) -> void:
	if __ == 11:
		return
	if Input.is_action_just_pressed("ui_up"):
		if __ in [0,1]:
			__ += 1
		else:
			__ = 1
	if Input.is_action_just_pressed("ui_down"):
		if __ in [2,3]:
			__ += 1
		else:
			__ = 0
	if Input.is_action_just_pressed("ui_left"):
		if __ in [4,6]:
			__ += 1
		else:
			__ = 0
	if Input.is_action_just_pressed("ui_right"):
		if __ in [5,7]:
			__ += 1
		else:
			__ = 0
	if Input.is_action_just_pressed("ui_b"):
		if __ == 8:
			__ += 1
		else:
			__ = 0
	if Input.is_action_just_pressed("ui_a"):
		if __ == 9:
			__ += 1	
		else:
			__ = 0
	if Input.is_action_just_pressed("ui_start"):
		if __ == 10:
			__ += 1
			Events.PlaySound.emit("mysterious",size/2+global_position)
			add_child(PANEL_CONTAINER_SCENE.instantiate())
	

func _process(delta: float) -> void:
	timer += delta
