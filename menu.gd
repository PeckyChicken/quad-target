class_name Menu
extends PanelContainer
@onready var root: Root = $".."

func _ready() -> void:
	create_difficulty_buttons()

func create_difficulty_buttons():
	var difficulties: Array[String]
	difficulties.append_array(root.Difficulty.keys())
	for difficulty in difficulties:
		var new_button := Button.new()
		new_button.text = difficulty.capitalize() + " Mode"
		$VBox/Difficulties.add_child(new_button)
