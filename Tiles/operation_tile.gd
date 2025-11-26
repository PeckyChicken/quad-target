extends Tile
class_name OperationTile

@export var operation: String = ""

var clicked: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	$Operation.text = operation

func rescale(new_scale):
	super(new_scale)
	$Operation.add_theme_font_size_override("normal_font_size",70 * new_scale.x/100)

func find_overlap():
	super()
	if overlap == root:
		operation_container.reset_stock()

func quick_move(container=null):
	super(container)
	if previous_parent is OperationContainer:
		operation_container.reset_stock()

func return_home():
	if not draggable:
		return
	if parent_container != operation_container:
		queue_free()
	super()
	
func _on_click(event: InputEvent):
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		return
	if draggable and event.is_pressed():
		Events.PlaySound.emit("pick_up_operation",global_position)
		super(event)

func end_drag():
	if not dragging:
		return
	super()
	
	Events.PlaySound.emit("drop_operation",global_position)
	
	if parent_container == null:
		if get_global_rect().intersects(operation_container.get_global_rect()):
			queue_free()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_on_click(event)

func _input(event: InputEvent):
	super(event)
