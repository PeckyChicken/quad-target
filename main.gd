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

var difficulty: int = 1
#0 = easy, 1 = hard

var number_count: int = 4

var starting_numbers: Array[int]

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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not date_override:
		date = Time.get_datetime_dict_from_system()
	
	date["hour"] = 0
	date["minute"] = 0
	date["second"] = 0
	puzzle_seed = Time.get_unix_time_from_datetime_dict(date)
	set_date()
	Events.TileCreated.connect(check_win)

func create_solution(history) -> String:
	var solution: String = ""
	for component in history:
		if component is Array:
			solution += " (%s)" % [create_solution(component)]
			continue
		solution += " " + component
	
	return solution.strip_edges().replace("( ","(").replace(" )",")")

func check_win(tile:Tile):
	if tile is NumberTile and tile is not TargetTile and tile.number == target:
		Events.PlaySound.emit("win",tile.global_position)
		tile.get_node("Outline").color = Color("#737C63")
		tile.get_node("Fill").color = Color("#1B3A1B")
		
		var win_screen: WinScreen = WIN_SCENE.instantiate()
		win_screen.time = timer
		win_screen.moves = moves
		win_screen.solution = create_solution(tile.history) + " = " + str(tile.number)
		add_child(win_screen)
		
		get_tree().paused = true

func set_date():
	$Date.text = "Quad Target\n%s, %d %s %d" % [
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

func create_number_tiles(numbers: Array[int]):
	for number in numbers:
		var new_tile: NumberTile = NUMBER_TILE_SCENE.instantiate()
		new_tile.type = Tiles.NUMBER
		new_tile.number = number
		new_tile.expression = ""
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
