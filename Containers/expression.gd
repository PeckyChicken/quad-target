class_name ExpressionContainer
extends NumberContainer

var operation_array = ["+","-","×","÷","(",")","*","/"]

var answer: Tile
@onready var number_tile: PackedScene = load("res://Tiles/number_tile.tscn")
@onready var error_tile: PackedScene = load("res://Tiles/error_tile.tscn")

var parser := Parser.new()

var error_outputs: Dictionary[String,String] = {"Division by 0":"###","Unparsable":"!","Not whole":"###"}

var num_components: int = 0

func _ready() -> void:
	super()
	await get_tree().process_frame
	$"../Label".add_theme_font_size_override("normal_font_size",16 * root.tile_scale.x)
	
func _tile_added():
	pass

func delete_previous_answer():
	answer.queue_free()
	answer = null

func create_answer(output: int, expression: String, history:Array) -> NumberTile:
	var tile: NumberTile = number_tile.instantiate()
	tile.number = output
	tile.expression = expression
	tile.history = history
	tile.type = Root.Tiles.ANSWER
	tile.draggable = true
	tile.extra_data["expression"] = self
	add_sibling(tile)
	tile.add_to_container($"../../Answer/Symbols")
	
	return tile

func create_error(message):
	var tile: ErrorTile = error_tile.instantiate()
	tile.message = message
	tile.output = error_outputs.get(message,"!")
	tile.draggable = false
	add_sibling(tile)
	tile.add_to_container($"../../Answer/Symbols")
	
	return tile

func clear():
	for child in get_children():
		child.queue_free()
	get_children().clear()
	answer = null

func create_expression() -> String:
	var components: Array[String] = []
	for child in get_children():
		if child.type == Root.Tiles.SHADOW:
			continue
		if child.type == Root.Tiles.NUMBER:
			components.append(str(child.number))
		elif child.type == Root.Tiles.OPERATION:
			components.append(child.operation)
	var expression: String
	if parser.is_tokenizable(" ".join(components)):
		expression = parser.tokenize(" ".join(components)).as_string().replace("/","÷").replace("*","×")
	else:
		expression = " ".join(components)
	return expression

func godotify_expression(expression: String) -> String:
	var components = expression.split(" ")
	var index = 0
	for component in components:
		if component.is_valid_int():
			components[index] = str(float(component))
		index += 1
	expression = " ".join(components)
	
	expression = expression.replace("×","*")
	expression = expression.replace("÷","/")
	return expression

func create_history() -> Array:
	var history: Array = []
	for child in get_children():
		if child.type == Root.Tiles.SHADOW:
			continue
		if child.type == Root.Tiles.NUMBER:
			if child.history:
				history.append(child.history)
				continue
		history.append(child.get_child(2).text)
	
	return history

func return_numbers():
	for tile in get_children():
		tile.previous_parent = tile.parent_container
		tile.quick_move()

func remove_ops(expression: String) -> String:
	for op in operation_array:
		expression = expression.replace(" "+op,"")
	return expression

func check_operators(expression: String) -> bool:
	var components: PackedStringArray = expression.split(" ")
	if len(components) < 2:
		return true
	var index = 0
	for component in components:
		if component in operation_array:
			#print("Component %s is in operation array, running checks." % [component])
			#print("DEBUG DATA: components: %s index: %s operation_array: %s" % [components,index,operation_array])
			if component in "()":
				#print("Component is a bracket, ignoring")
				index += 1
				continue
			if index == 0 or index == len(components)-1:
				#print("Operation found at start, invalid.")
				return true
			elif components[index-1] in ["+","-","×","÷","(","*","/"] or components[index+1] in ["+","-","×","÷",")","*","/"]:
				#print("Previous or next component is also operation, invalid")
				return true
			#print("No issues were found with component, continuing")
		index += 1
	return false

func check_repeating_numbers(expression: String) -> bool:
	var components: PackedStringArray = expression.replace(" (","").replace(" )","").split(" ")
	if len(components) < 2:
		return true
	var index = 0
	for component in components:
		if component.is_valid_float():
			if index != 0 and components[index-1].is_valid_float():
				
				return true
		index += 1
	return false

func validate_expression(expression: String) -> Array:
	#print(expression)
	if not parser.is_tokenizable(expression):
		return [false,"Unparsable"]
	
	var expr = parser.tokenize(expression)
	var is_parsable = parser.is_parsable(expr)
	if not is_parsable:
		return [false,"Unparsable"]
	
	var result = parser.parse_tokenized_expression(expr).evaluate()
	
	if abs(result) == INF:
		return [false,"Division by 0"]
	
	if round(result) != result:
		return [false,"Not whole"]
	
	return [true,""]

func tile_added(_tile):
	$"../Label".hide()
	await get_tree().process_frame
	contents_changed(_tile)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	super._process(_delta)
	if get_child_count() == 0:
		$"../Label".show()
	
	num_components = length()
	for child in get_children():
		if child.type == Root.Tiles.SHADOW:
			num_components -= 1
	
	if num_components == 0:
		$"../../Recall Tile".hide()
	else:
		$"../../Recall Tile".show()
	

func contents_changed(_node=null):
	
	#if node is ShadowTile:
		#return
	
	var expression = create_expression()
	var history = create_history()
	
	if num_components > 1:
		var parse_check = validate_expression(expression)
		if parse_check[0]:
			var output = parser.parse_tokenized_expression(parser.tokenize(expression)).evaluate()
			if answer:
				if answer is NumberTile and answer.number == output and answer.expression == expression:
					return
				delete_previous_answer()
			answer = create_answer(output,expression,history)
			
		else:
			if answer:
				if answer is ErrorTile and answer.message == parse_check[1]:
					return
				delete_previous_answer()
			answer = create_error(parse_check[1])
			
	else:
		if answer:
			delete_previous_answer()
