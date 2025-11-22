class_name StorageContainer
extends NumberContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	super()
	
	Events.ResetTiles.connect(sort_tiles)

func sort_tiles():
	await get_tree().process_frame
	var children: Array[NumberTile] = []
	children.assign(get_children())
	
	children.sort_custom(func(x:NumberTile,y:NumberTile): return x.number < y.number)
	
	children.reverse()
	
	for child in children:
		move_child(child,0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
