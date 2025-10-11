class_name WinScreen
extends Control

@onready var MAIN_SCENE: PackedScene = load("res://main.tscn")


@onready var root: Root = $".."

var time: float
var moves: int
var solution: String

var image_load_string: String = "[img width=25]"

const SWITCHES: Dictionary[Root.Difficulty,Root.Difficulty] = {Root.Difficulty.easy:Root.Difficulty.hard,Root.Difficulty.hard:Root.Difficulty.quint_target}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Fade.modulate.a = 0
	$Stats.modulate.a = 0
	$Stats/VBoxContainer/HBoxContainer/Time.text = "%shourglass.png[/img] %s" % [image_load_string,format_time(int(time))]
	$Stats/VBoxContainer/HBoxContainer/Moves.text = "%sswapping.png[/img] %s " % [image_load_string,str(moves)]
	$Stats/VBoxContainer/Panel/Solution.text = solution
	
	var mode: String = Root.Difficulty.keys()[root.difficulty]
	var switch_mode: String = Root.Difficulty.keys()[SWITCHES[root.difficulty]]
	
	$Stats/VBoxContainer/Mode.text = "%s%s_mode.svg[/img] %s Mode" % [image_load_string,mode,mode.capitalize()]
	$Stats/VBoxContainer/Switch.text = "Play %s?" % [switch_mode.capitalize()]
	$Stats/VBoxContainer/Switch.icon = load("res://%s_mode.svg" % switch_mode)
	
	fade_on()

func format_time(seconds: int):
	@warning_ignore("integer_division")
	var minutes = seconds / 60
	var secs = seconds % 60
	return str(minutes) + ":" + str(secs).pad_zeros(2)

func fade_on():
	var tween: Tween = create_tween()
	
	var tween_offs: Array = root.containers + [$"../Target",$"../Equation/equals"]
	tween_offs.shuffle()
	
	for container in tween_offs:
		tween.tween_property(container,"modulate:a",0.0,0.25)
	
	tween.tween_property($Fade,"modulate:a",1.0,0.25)
	
	tween.tween_property($Stats,"modulate:a",1.0,0.5)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_switch_pressed() -> void:
	var new_scene: Root
	new_scene = MAIN_SCENE.instantiate()
	
	new_scene.difficulty = SWITCHES[root.difficulty]
	Save.save_cache(new_scene.difficulty,false)
	new_scene.date = root.date
	new_scene.date_override = root.date_override
	get_tree().root.add_child(new_scene)
	new_scene.set_date()
	get_tree().paused = false
	get_parent().queue_free()
	Events.PlaySound.emit("pick_up_number",root.size/2)
