class_name Mobile
extends Root


const MENU_OPEN_DRAG_DISTANCE := 50
const MENU_DOWNWARD_DRAG_DISTANCE_CANCEL := 200
var drag_distance = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	mobile = true
	tile_scale *= 1.4
	WIN_SCENE = load("res://Menus/win_screen_mobile.tscn")
	super()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		
		if event.is_pressed():
			drag_distance = Vector2.ZERO
		else:
			if $MenuListButton.open:
				$MenuListButton._on_pressed()
				return
			
			var dragged: bool = false
			dragged = drag_distance.x >= MENU_OPEN_DRAG_DISTANCE
			if dragged and abs(drag_distance.y) < MENU_DOWNWARD_DRAG_DISTANCE_CANCEL:
				$MenuListButton._on_pressed()
	if event is InputEventMouseMotion:
		drag_distance += event.relative

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
