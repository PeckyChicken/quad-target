class_name OperationContainer
extends NumberContainer

var operation_array = ["+","-","×","÷","(",")"]
@onready var operation_tile: PackedScene = load("res://Tiles/operation_tile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	reset_stock()

func tile_added(tile:Tile):
	super(tile)
	if tile.type == Root.Tiles.SHADOW:
		return
	reset_stock()

func reset_stock():
	while self.length() < len(operation_array):
		add_child(operation_tile.instantiate())
	
	var index = 0
	var shadows = 0
	for child in get_children():
		if child.type == Root.Tiles.SHADOW:
			shadows += 1
			index += 1
			continue
		if index >= len(operation_array):
			child.queue_free()
			
			index += 1
			continue
		if child.operation == operation_array.get(index-shadows):
			index += 1
			continue
		
		child.queue_free()

		
		var new_child: OperationTile = operation_tile.instantiate()
		new_child.operation = operation_array[index-shadows]
		new_child.draggable = true
		new_child.type = Root.Tiles.OPERATION
		add_child(new_child)
		move_child(new_child,index)
		index += 1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
	
	reset_stock()
		
		
