extends Tile
class_name NumberTile

@export var number: int = 0
@export var expression: String = ""
var history: Array[Variant] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Number.text = str(number)
	if len(str(number)) > 2:
		rescale(custom_minimum_size)
	$Equation.text = expression
	if expression:
		$Number.anchor_bottom = 0.9
		if not history:
			history = expression.split(" ")
	else:
		$Number.anchor_bottom = 1
	
	super()
	Events.MakeNumberList.connect(add_self_to_number_list)

func find_overlap():
	super()
	
	if get_global_rect().intersects(answer_container.get_global_rect()):
		if not answer_container.get_children().any(func(x):return x is ErrorTile):
			return
		if not self.expression:
			return
		overlap = answer_container
		create_shadow(overlap)
		
		return

func add_self_to_number_list():
	if not draggable:
		return
	await get_tree().process_frame
	if history:
		root.total_numbers.append(history)
	else:
		root.total_numbers.append(number)

func end_drag():
	if not dragging:
		return
	
	super()
	Events.PlaySound.emit("drop_number",global_position)
	
	if get_global_rect().intersects(answer_container.get_global_rect()):
		if parent_container == null:
			if not answer_container.get_children().any(func(x):return x is ErrorTile):
				return
			if not self.expression:
				return
			add_move()
			for child in answer_container.get_children():
				child.queue_free()
			add_to_container(answer_container)
			answer_container.recreate_expression()


func rescale(new_scale):
	super(new_scale)
	$Number.add_theme_font_size_override("normal_font_size", (50 - 5*(len(str(number))-2)) * new_scale.x/100)
	$Equation.add_theme_font_size_override("normal_font_size",12 * new_scale.x/100)
	

func _on_click(event: InputEvent):
	if not draggable: return
	if event.is_pressed():
		Events.PlaySound.emit("pick_up_number",global_position)

	super(event)

func return_home():
	if not draggable:
		return
	reparent(root)
	
	add_to_container(storage_container)

	
	super()

func _input(event: InputEvent):
	super(event)
