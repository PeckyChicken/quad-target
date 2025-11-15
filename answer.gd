class_name AnswerContainer
extends NumberContainer

@onready var number_tile: PackedScene = load("res://number_tile.tscn")
@onready var operation_tile: PackedScene = load("res://operation_tile.tscn")

func _ready() -> void:
	super()
	await get_tree().process_frame
	$"../Label".add_theme_font_size_override("normal_font_size",16 * root.tile_scale.x)


func compress_history_component(component) -> Array:
	var history: Array = []
	for item in component:
		if item is String or item is int:
			history.append(str(item))
			continue
		
		item = compress_history_component(item)
		var parser := Expression.new()
		var expression: String = ExpressionContainer.new().godotify_expression(" ".join(item))
		var parser_out = parser.parse(expression)
		assert (parser_out == OK, "Error parsing history component '%s', %s" % [item,parser.get_error_text()])
		history.append(int(parser.execute()))
	
	return history

func tile_added(_tile):
	$"../Label".hide()

func _process(delta):
	super(delta)
	if get_child_count() == 0:
		$"../Label".show()

func recreate_expression():
	var child: NumberTile
	for children in get_children():
		if children is NumberTile:
			child = children
			break
	assert (child.history, "Tile was passed into answer with no history. This signifies a serious problem with the \"find_overlap()\" function in tile.gd")
	var expression_container: ExpressionContainer = child.expression_container
	expression_container.return_numbers()
	
	var expression = child.expression.split(" ")
	var history = child.history.duplicate()
	
	expression.reverse()
	history.reverse()
	
	assert (len(history) == len(expression),"Expression %s and history %s are not the same length. Good luck debugging this, I don't know why this happened." % [expression, history])
	
	for index in range(len(expression)):
		var e_component = expression[index]
		var h_component = history[index]
		
		var new_tile: Tile
		
		if e_component.is_valid_int():
			new_tile = number_tile.instantiate() as NumberTile
			new_tile.number = int(e_component)
			new_tile.type = Root.Tiles.NUMBER
			if typeof(h_component) != typeof(e_component):
				new_tile.extra_data["expression"] = expression_container
				new_tile.expression = " ".join(compress_history_component(h_component))
				new_tile.history = h_component
		else:
			new_tile = operation_tile.instantiate() as OperationTile
			new_tile.operation = e_component
			new_tile.type = Root.Tiles.OPERATION
		
		new_tile.draggable = true
		
		add_child(new_tile)
		new_tile.add_to_container(expression_container)
	
	for tile in get_children():
		tile.queue_free()
		
