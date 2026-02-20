class_name Menu
extends PanelContainer
@onready var root: Root = $".."

@onready var MAIN_SCENE: PackedScene = load("res://main.tscn")
@onready var MOBILE_SCENE: PackedScene = load("res://mobile.tscn")


const MAIN_FONT_SIZE = 20
const MOBILE_FONT_SIZE = 50

var styles: Dictionary[String,StyleBox] = {
	"green_unpressed":load("res://Styleboxes/green_unpressed_button.tres"),
	"green_pressed":load("res://Styleboxes/green_pressed_button.tres"),
	"green_hover":load("res://Styleboxes/green_hover_button.tres"),
	"orange_unpressed":load("res://Styleboxes/orange_unpressed_button.tres"),
	"orange_pressed":load("res://Styleboxes/orange_pressed_button.tres"),
	"orange_hover":load("res://Styleboxes/orange_hover_button.tres")}

const DIFFICULTY_TOOLTIPS: Dictionary[Root.Difficulty,String] = {
	Root.Difficulty.easy: "Puzzles in easy mode only require addition and subtraction.",
	Root.Difficulty.hard: "Puzzles in hard mode always require a multiplication.",
	Root.Difficulty.harder: "Puzzles in harder mode use 3-digit numbers and always require a multiplication."}

func _ready() -> void:
	await get_tree().process_frame
	
	if root is Mobile:
		$VBox/Help.custom_minimum_size = Vector2(MOBILE_FONT_SIZE*1.5,MOBILE_FONT_SIZE*1.5)
	create_difficulty_buttons()
	position.x = -size.x

func change_difficulty(new_difficulty):
	var new_scene: Root
	if root is Mobile:
		new_scene = MOBILE_SCENE.instantiate()
	else:
		new_scene = MAIN_SCENE.instantiate()
	new_scene.difficulty = new_difficulty
	
	if root.save_active:
		Save.save_cache(new_scene.difficulty,root.wins)
	
	new_scene.wins = root.wins
	new_scene.date = root.date
	new_scene.date_override = root.date_override
	get_tree().root.add_child(new_scene)
	new_scene.set_date()
	get_tree().paused = false
	get_parent().queue_free()
	Events.PlaySound.emit("pick_up_number",root.size/2)

func create_difficulty_buttons():
	for child in $VBox/Difficulties.get_children():
		child.queue_free()
	var difficulties: Array[String]
	difficulties.append_array(root.Difficulty.keys())
	for difficulty in root.Difficulty.values():
		if difficulty == root.Difficulty.harder and root.Difficulty.hard not in root.wins:
			continue
		
		var title: String = root.Difficulty.keys()[difficulty]
		var new_button := Button.new()
		new_button.text = title.capitalize() + " Mode"
		
		
		if difficulty in root.wins:
			
			new_button.add_theme_stylebox_override("normal",styles["green_unpressed"])
			new_button.add_theme_stylebox_override("pressed",styles["green_pressed"])
			new_button.add_theme_stylebox_override("hover",styles["green_hover"])
		
		if difficulty == root.difficulty:
			new_button.add_theme_stylebox_override("normal",styles["orange_unpressed"])
			new_button.add_theme_stylebox_override("pressed",styles["orange_pressed"])
			new_button.add_theme_stylebox_override("hover",styles["orange_hover"])
		
		if root is Mobile:
			new_button.add_theme_font_size_override("font_size",MOBILE_FONT_SIZE)
		else:
			new_button.add_theme_font_size_override("font_size",MAIN_FONT_SIZE)
		
		new_button.tooltip_text = DIFFICULTY_TOOLTIPS[difficulty]
		
		new_button.pressed.connect(func(d=difficulty):change_difficulty(d))
			
		$VBox/Difficulties.add_child(new_button)
