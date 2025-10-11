extends CheckButton

@onready var MAIN_SCENE: PackedScene = load("res://main.tscn")
@onready var MOBILE_SCENE: PackedScene = load("res://mobile.tscn")

@onready var root = $"../.."

@onready var icons: Dictionary[Root.Difficulty,Texture2D] = {
	Root.Difficulty.easy : load("res://easy_mode.svg"),
	Root.Difficulty.hard : load("res://hard_mode.svg"),
	Root.Difficulty.quint_target : load("res://quint_target_mode.svg")
}

const TOOLTIPS = {
	Root.Difficulty.easy : "Puzzles in Easy Mode will\nonly require addition and subtraction.",
	Root.Difficulty.hard : "Puzzles in Hard Mode will\nalways require a multiplication.",
	Root.Difficulty.quint_target : "5 numbers, always requires a multiplication."
}
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame
	if root.difficulty == Root.Difficulty.quint_target:
		disabled = true
		add_theme_stylebox_override("focus",StyleBoxEmpty.new())
	button_pressed = root.difficulty as bool
	text = "%s Mode" % [Root.Difficulty.keys()[root.difficulty].capitalize()]
	icon = icons[root.difficulty]
	tooltip_text = TOOLTIPS[root.difficulty]

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
