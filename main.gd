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

@onready var NUMBER_TILE_SCENE: PackedScene = load("res://Tiles/number_tile.tscn")
@onready var TARGET_TILE_SCENE: PackedScene = load("res://Tiles/target_tile.tscn")
@onready var WIN_SCENE: PackedScene = load("res://Menus/win_screen.tscn")
@onready var PANEL_CONTAINER_SCENE: PackedScene = load("res://Menus/panel_container.tscn")

var date_override: bool = false
var date: Dictionary
var puzzle_seed: int

var timer: float = 0.0
var moves: int = 0

var mobile: bool = false
var web: bool = false
var tile_scale = Vector2.ONE

const WEEKDAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
const MONTHS = ["January", "February", "March", "April", "May", "June",
			  "July", "August", "September", "October", "November", "December"]

var __ := 0

var save_data: Dictionary

var save_active := true

var wins: Array[Difficulty] = []
var solution: String

@onready var answer_container = $Equation/Answer/Symbols


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("web"):
		print("Here")
		get_web_params()
	
	if Save.cache_loaded:
		save_cache()
	else:
		reload_cache(Save.load_cache())
	if difficulty == Difficulty.quint_target:
		number_count = 5
	save_name = "%s_mode_save" % [Difficulty.keys()[difficulty]]
	save_data = Save.load_save(save_name)
	if save_data["success"]:
		reload_save(save_data)
		if save_data.get("mode_beaten"):
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
	
	Events.SaveCache.connect(save_cache)

func get_web_params():
	var query := _get_url_query()
	var params := _parse_query_params(query)

	# Front-end "API" mode: ?api=1 or ?api=true or ?api=json
	if params.get("api", "") in ["1", "true", "json"]:
		var info := get_puzzle_info(params)
		var json_text := JSON.stringify(info)
		var doc := JavaScriptBridge.get_interface("document")
		if doc:
			# replace page content with json text (no header changes possible from client-side)
			doc.open()
			doc.write(json_text)
			doc.close()
		# stop the game / avoid normal UI init (quit engine in HTML5 to leave JSON page)
		get_tree().quit()
		return

	var param_as_list := []
	for param in params:
		param_as_list.append(param +"="+params[param])

# return a serialisable dictionary describing the puzzle (basic)
func get_puzzle_info(params: Dictionary) -> Dictionary:
	var info: Dictionary = {}
	# decide date / seed using provided date param or system date
	var used_date: Dictionary
	if params.has("date"):
	# expect YYYY-MM-DD (best-effort)
		var parts = params["date"].split("-")
		if parts.size() >= 3:
			used_date = {
			"year": int(parts[0]),
			"month": int(parts[1]),
			"day": int(parts[2]),
			"hour": 0, "minute": 0, "second": 0
			}
		else:
			used_date = Time.get_datetime_dict_from_system()
	else:
		used_date = Time.get_datetime_dict_from_system()
		used_date["hour"] = 0
		used_date["minute"] = 0
		used_date["second"] = 0

	var _seed := Time.get_unix_time_from_datetime_dict(used_date)
	# return available runtime values if set, otherwise minimal info
	info["ok"] = true
	info["params"] = params
	info["seed"] = seed
	info["date"] = used_date
	info["difficulty"] = Difficulty.keys()[difficulty] if difficulty != null else null
	info["target"] = target
	info["numbers"] = starting_numbers if starting_numbers != null else (total_numbers if total_numbers != null else [])
	return info

func _get_url_query() -> String:
	var js := JavaScriptBridge.get_interface("window")
	if js:
		# window.location.search returns the query string like "?day=42"
		return js.location.search
	return ""


func _parse_query_params(query: String) -> Dictionary:
	var result: Dictionary = {}

	if query.begins_with("?"):
		query = query.substr(1)

	if query == "":
		return result

	for pair in query.split("&"):
		var parts = pair.split("=")
		if parts.size() == 2:
			var key = parts[0].uri_decode()
			var value = parts[1].uri_decode()
			result[key] = value

	return result

func save_cache():
	if save_active:
		Save.save_cache(difficulty,wins)


func _notification(what):
	if what in [NOTIFICATION_WM_CLOSE_REQUEST,NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		save_cache()
		if what == NOTIFICATION_WM_CLOSE_REQUEST and ((not OS.has_feature("mobile")) or OS.has_feature("web")):
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
	starting_numbers.sort()

func reload_cache(cache):
	if "difficulty" in cache:
		difficulty = cache.get("difficulty") as Difficulty
	if "wins" in cache and cache["wins"]:
		wins = cache["wins"]

func create_solution(history) -> String:
	var _solution: String = ""
	for component in history:
		if component is Array:
			_solution += " (%s)" % [create_solution(component)]
			continue
		_solution += " " + str(component)
	
	return _solution.strip_edges().replace("( ","(").replace(" )",")")

func create_win_screen(time,move_count,_solution):
	if difficulty not in wins:
		wins.append(difficulty)
	var win_screen: WinScreen = WIN_SCENE.instantiate()
	win_screen.time = time
	win_screen.moves = move_count
	win_screen.solution = _solution
	add_child(win_screen)

func check_win(tile:Tile):
	if tile is NumberTile and tile is not TargetTile and tile.number == target:
		tile.get_node("Outline").color = Color("#737C63")
		tile.get_node("Fill").color = Color("#1B3A1B")
		if difficulty in wins:
			return
		Events.PlaySound.emit("win",tile.global_position)
		solution = create_solution(tile.history) + " = " + str(tile.number)
		create_win_screen(timer,moves,solution)
		if save_active:
			Save.save(save_name,{"moves":moves,"time":timer,"solution":solution},date,total_numbers,target,difficulty in wins)
			Save.save_cache(difficulty,wins)
		
		get_tree().paused = true

func set_date():
	if difficulty == Difficulty.quint_target:
		$Info/Title.text = "Quint Target"
	else:
		$Info/Title.text = "Quad Target"
	$Info/Date.text = "%s, %d %s %d" % [
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
