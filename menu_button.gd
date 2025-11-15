class_name MenuListButton
extends TextureButton

var open: bool = false

@onready var menu: Menu = $"../Menu"
@onready var close_img: Texture2D = load("res://close.svg")
@onready var menu_img: Texture2D = load("res://menu.svg")

const ANIMATION_SECONDS = 0.5
var tween: Tween


func _on_pressed() -> void:
	var menu_size = $"../Menu".size.x
	var move_pos: float
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	
	var rot: float
	
	pivot_offset = size/2
	
	if open:
		Events.PlaySound.emit("hide_menu",get_viewport().size/2)
		move_pos = -menu_size
		rot = -2 * PI
		tween.tween_property($Close,"modulate:a",0,ANIMATION_SECONDS)
		tween.tween_property($Menu,"modulate:a",1,ANIMATION_SECONDS)
	else:
		Events.PlaySound.emit("show_menu",get_viewport().size/2)
		move_pos = 0
		rot = 2 * PI
		tween.tween_property($Close,"modulate:a",1,ANIMATION_SECONDS)
		tween.tween_property($Menu,"modulate:a",0,ANIMATION_SECONDS)
	
	tween.tween_property(menu,"position:x",move_pos,ANIMATION_SECONDS)
	tween.tween_property(self,"position:x",move_pos+menu_size,ANIMATION_SECONDS)
	tween.tween_property(self,"rotation",rot,ANIMATION_SECONDS)
	
	open = !open
