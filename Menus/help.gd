extends TextureRect

var tween: Tween
var hover_count: int = 0

@onready var help_menu = $HelpMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("mobile"):
		help_menu = $HelpMenuMobile
	help_menu.hide()
	fade_help(0,0,true)


func fade_help(alpha:float,time:float,async:bool=false):
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.set_parallel(async)
	var tweeners: Array[Node] = help_menu.get_node("VBox").get_children()
	if alpha <= help_menu.modulate.a:
		tweeners.append(help_menu)
	else:
		tweeners.insert(0,help_menu)
	for child in tweeners:
		tween.tween_property(child,"modulate:a",alpha,time)
	
	await tween.finished
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	fade_help(0,0,true)
	await tween.finished
	help_menu.show()
	Events.PlaySound.emit("show_rules",global_position)
	fade_help(1,0.1)


func _on_mouse_exited() -> void:
	Events.PlaySound.emit("hide_rules",global_position)
	await fade_help(0,0.1,true)
	help_menu.hide()
	
