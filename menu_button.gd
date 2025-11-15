class_name MenuListButton
extends TextureButton

var open: bool = false

@onready var menu: VBoxContainer = $"../Menu"
@onready var close_img: Texture2D = load("res://close.svg")
@onready var menu_img: Texture2D = load("res://menu.svg")

const ANIMATION_SECONDS = 0.5

func _on_pressed() -> void:
	var move_distance = menu.size.x
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	
	var rel_pos: float
	var rel_rot: float
	
	pivot_offset = size/2
	
	if open:
		rel_pos = -move_distance
		rel_rot = -2 * PI
		tween.tween_property($Close,"modulate:a",0,ANIMATION_SECONDS)
		tween.tween_property($Menu,"modulate:a",1,ANIMATION_SECONDS)
	else:
		rel_pos = move_distance
		rel_rot = 2 * PI
		tween.tween_property($Close,"modulate:a",1,ANIMATION_SECONDS)
		tween.tween_property($Menu,"modulate:a",0,ANIMATION_SECONDS)
	
	tween.tween_property(menu,"position:x",menu.position.x+rel_pos,ANIMATION_SECONDS)
	tween.tween_property(self,"position:x",position.x+rel_pos,ANIMATION_SECONDS)
	tween.tween_property(self,"rotation",rotation+rel_rot,ANIMATION_SECONDS)
	
	open = !open
