extends CheckButton

@onready var MAIN_SCENE: PackedScene = load("res://main.tscn")
@onready var MOBILE_SCENE: PackedScene = load("res://mobile.tscn")

@onready var root = $"../.."

@onready var hard_mode_icon: Texture2D = load("res://hard_mode.svg")
@onready var easy_mode_icon: Texture2D = load("res://easy_mode.svg")

const HARD_MODE_TOOLTIP = "Puzzles in Hard Mode will\nalways require a multiplication."
const EASY_MODE_TOOLTIP = "Puzzles in Easy Mode will\nonly require addition and subtraction."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	button_pressed = root.difficulty as bool
	if root.difficulty == 1:
		text = "Hard Mode"
		tooltip_text = HARD_MODE_TOOLTIP
		icon = hard_mode_icon
	elif root.difficulty == 0:
		text = "Easy Mode"
		tooltip_text = EASY_MODE_TOOLTIP
		icon = easy_mode_icon
		
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_pressed() -> void:
	var new_scene: Root
	if root is Mobile:
		new_scene = MOBILE_SCENE.instantiate()
	else:
		new_scene = MAIN_SCENE.instantiate()
	new_scene.number_count = root.number_count
	Save.remove_user_data(root.save_name,"difficulty")
	new_scene.difficulty = button_pressed as int as Root.Difficulty
	print(new_scene.difficulty)
	new_scene.date = root.date
	new_scene.date_override = root.date_override
	get_tree().root.add_child(new_scene)
	new_scene.set_date()
	get_tree().paused = false
	root.queue_free()
	Events.PlaySound.emit("pick_up_number",root.size/2)
