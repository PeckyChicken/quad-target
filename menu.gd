class_name Menu
extends PanelContainer
@onready var root: Root = $".."

@onready var MAIN_SCENE = load("res://main.tscn")


var styles: Dictionary[String,StyleBox] = {
	"green_unpressed":load("res://Styleboxes/green_unpressed_button.tres"),
	"green_pressed":load("res://Styleboxes/green_pressed_button.tres"),
	"green_hover":load("res://Styleboxes/green_hover_button.tres"),
	"orange_unpressed":load("res://Styleboxes/orange_unpressed_button.tres"),
	"orange_pressed":load("res://Styleboxes/orange_pressed_button.tres"),
	"orange_hover":load("res://Styleboxes/orange_hover_button.tres")}

func _ready() -> void:
	await get_tree().process_frame
	create_difficulty_buttons()
	position.x = -size.x

func change_difficulty(new_difficulty):
	var new_scene: Root
	new_scene = MAIN_SCENE.instantiate()
	new_scene.difficulty = new_difficulty
	
	if root.save_active:
		Save.save_cache(new_scene.difficulty,root.wins)
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
	for difficulty in difficulties:
		var new_button := Button.new()
		new_button.text = difficulty.capitalize() + " Mode"
		if root.Difficulty[difficulty] in root.wins:
			new_button.add_theme_stylebox_override("normal",styles["green_unpressed"])
			new_button.add_theme_stylebox_override("pressed",styles["green_pressed"])
			new_button.add_theme_stylebox_override("hover",styles["green_hover"])
		if root.Difficulty[difficulty] == root.difficulty:
			new_button.add_theme_stylebox_override("normal",styles["orange_unpressed"])
			new_button.add_theme_stylebox_override("pressed",styles["orange_pressed"])
			new_button.add_theme_stylebox_override("hover",styles["orange_hover"])
		
		new_button.pressed.connect(func(d=difficulty):change_difficulty(root.Difficulty[d]))
			
		$VBox/Difficulties.add_child(new_button)
