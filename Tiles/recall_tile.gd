class_name RecallTile
extends Tile

@export var operation: String = ""

var clicked: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()

func rescale(new_scale):
	super(new_scale)

func return_home():
	return
	
func _on_click(event: InputEvent):
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		return
	if event.is_pressed():
		Events.PlaySound.emit("recall",global_position)
		Events.ResetTiles.emit()
		await get_tree().process_frame
		add_move()
	
	if draggable and event.is_pressed():
		super(event)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_click(event)

func _input(event: InputEvent):
	super(event)
