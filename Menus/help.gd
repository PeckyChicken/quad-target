extends TextureRect

var tween: Tween
var hover_count: int = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$HelpMenu.hide()
	fade_help(0,0,true)


func fade_help(alpha:float,time:float,async:bool=false):
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.set_parallel(async)
	var tweeners: Array[Node] = $HelpMenu.get_node("VBox").get_children()
	if alpha <= $HelpMenu.modulate.a:
		tweeners.append($HelpMenu)
	else:
		tweeners.insert(0,$HelpMenu)
	for child in tweeners:
		tween.tween_property(child,"modulate:a",alpha,time)
	
	await tween.finished
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_mouse_entered() -> void:
	fade_help(0,0,true)
	await tween.finished
	$HelpMenu.show()
	Events.PlaySound.emit("show_rules",global_position)
	fade_help(1,0.1)


func _on_mouse_exited() -> void:
	Events.PlaySound.emit("hide_rules",global_position)
	await fade_help(0,0.1,true)
	$HelpMenu.hide()
	
