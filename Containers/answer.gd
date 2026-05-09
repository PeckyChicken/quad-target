class_name AnswerContainer
extends NumberContainer

@onready var number_tile: PackedScene = load("res://Tiles/number_tile.tscn")
@onready var operation_tile: PackedScene = load("res://Tiles/operation_tile.tscn")

var parser = Parser.new()

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
		var expression: Parser.TokenizedExpression = parser.tokenize(" ".join(item))
		var parsing_possible = parser.is_parsable(expression)
		assert (parsing_possible, "Error parsing history component '%s'" % [item])
		history.append(int(parser.parse_tokenized_expression(expression).evaluate()))
	
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
	
	print(child.expression," Before tokenization")
	var expression = parser.tokenize(child.expression)
	var history = child.history.duplicate()
	
	print(expression.as_string()," After tokenization")
	
	
	assert (len(history) == len(expression.stack),"Expression %s and history %s are not the same length. Good luck debugging this, I don't know why this happened." % [expression, history])
	
	for index in range(len(history)):
		var e_component = expression.stack[index]
		var h_component = history[index]
		var new_tile: Tile
		
		if e_component is int or e_component is float:
			new_tile = number_tile.instantiate() as NumberTile
			new_tile.number = int(e_component)
			new_tile.type = Root.Tiles.NUMBER
			if h_component is Array:
				new_tile.extra_data["expression"] = expression_container
				new_tile.expression = parser.tokenize(" ".join(h_component)).as_string().replace("/","÷").replace("*","×")
				new_tile.history = h_component
		else:
			new_tile = operation_tile.instantiate() as OperationTile
			new_tile.operation = e_component.replace("/","÷").replace("*","×")
			new_tile.type = Root.Tiles.OPERATION
		
		new_tile.draggable = true
		
		add_child(new_tile)
		new_tile.add_to_container(expression_container,Vector2.INF)
	
	for tile in get_children():
		tile.queue_free()
	
	expression_container.contents_changed()
