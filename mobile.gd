class_name Mobile
extends Root



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mobile = true
	tile_scale *= 1.4
	WIN_SCENE = load("res://Menus/win_screen_mobile.tscn")
	super()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
