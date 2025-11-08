class_name WinScreen
extends Control

@onready var MAIN_SCENE: PackedScene = load("res://main.tscn")


@onready var root: Root = $".."

var time: float
var moves: int
var solution: String

var image_load_string: String = "[img width=25]"

const MONTHS := ["January","February","March","April","May","June","July","August","September","October","November","December"]

const SWITCHES: Dictionary[Root.Difficulty,Root.Difficulty] = {Root.Difficulty.easy:Root.Difficulty.hard,Root.Difficulty.hard:Root.Difficulty.quint_target,Root.Difficulty.quint_target:Root.Difficulty.quint_target}
const DIFFICULTY_EMOJIS = {Root.Difficulty.easy:"😌 ",Root.Difficulty.hard:"😖 ",Root.Difficulty.quint_target:"💀 "}

var text_fade_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Fade.modulate.a = 0
	$Stats.modulate.a = 0
	$Stats/Share/copied.modulate.a = 0
	
	$Stats/VBoxContainer/HBoxContainer/Time.text = "%shourglass.png[/img] %s" % [image_load_string,format_time(int(time))]
	$Stats/VBoxContainer/HBoxContainer/Moves.text = "%sswapping.png[/img] %s " % [image_load_string,str(moves)]
	$Stats/VBoxContainer/Panel/Solution.text = solution
	
	var mode: String = Root.Difficulty.keys()[root.difficulty]
	var switch_mode: String = Root.Difficulty.keys()[SWITCHES[root.difficulty]]
	
	$Stats/VBoxContainer/Mode.text = "%s%s_mode.svg[/img] %s Mode" % [image_load_string,mode,mode.capitalize()]
	$Stats/VBoxContainer/Switch.text = "Play %s?" % [switch_mode.capitalize()]
	$Stats/VBoxContainer/Switch.icon = load("res://%s_mode.svg" % switch_mode)
	
	if root.difficulty == Root.Difficulty.quint_target:
		$Stats/VBoxContainer/Switch.hide()
		$Stats/VBoxContainer/Congratulations.text = "Quint Target solved!"
	
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

func share():
	const SOLUTION_TEMPLATE = '''🔢 {name} Target {date}
{mode}
🧩 {solution}
⏰ {time}'''
	var number_replacement := "a"
	const operation_replacement = "#"
	var formatted_solution := ""
	var censored_solution := []
	formatted_solution = solution.substr(0,solution.find("=")).replace("(","( ").replace(")"," )")
	for character in formatted_solution.split(" "):
		if character.is_valid_int():
			censored_solution.append(number_replacement)
			number_replacement = char(ord(number_replacement)+1)
			continue
		if character in ["+","-","×","÷"]:
			censored_solution.append(operation_replacement)
			continue
		censored_solution.append(character)
	
	var formatted_censored_solution := " ".join(censored_solution).replace("( ","(").replace(" )",")") + solution.substr(solution.find("="))
	
	var date = Time.get_datetime_dict_from_system()
	var formatted_date = "%d %s %d" % [
		date.day,
		MONTHS[date.month - 1],
		date.year
	]
	
	var formatted_name = "Quint" if root.difficulty == Root.Difficulty.quint_target else "Quad"
	
	var mode: String

	mode = DIFFICULTY_EMOJIS[root.difficulty] + Root.Difficulty.keys()[root.difficulty].capitalize() + " Mode"
	
	var formatted_time = format_time(int(time))
	
	var shared_text := SOLUTION_TEMPLATE.format({"name":formatted_name,"date":formatted_date,"mode":mode,"time":formatted_time,"solution":formatted_censored_solution})
	share_text(shared_text,formatted_name,formatted_censored_solution)

func share_text(text,_name,_solution):
	DisplayServer.clipboard_set(text)
	if text_fade_tween and text_fade_tween.is_running():
		text_fade_tween.kill()
	text_fade_tween = create_tween()
	text_fade_tween.tween_property($Stats/Share/copied,"modulate:a",1,0.1)
	await text_fade_tween.finished
	text_fade_tween = create_tween()
	text_fade_tween.tween_property($Stats/Share/copied,"modulate:a",0,2)

func _on_switch_pressed() -> void:
	var new_scene: Root
	new_scene = MAIN_SCENE.instantiate()
	
	new_scene.difficulty = SWITCHES[root.difficulty]
	if root.save_active:
		Save.save_cache(new_scene.difficulty,false)
	new_scene.date = root.date
	new_scene.date_override = root.date_override
	get_tree().root.add_child(new_scene)
	new_scene.set_date()
	get_tree().paused = false
	get_parent().queue_free()
	Events.PlaySound.emit("pick_up_number",root.size/2)
