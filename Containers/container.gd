extends HBoxContainer
class_name NumberContainer

enum Type {
	OPERATION,
	STORAGE,
	EXPRESSION,
	ANSWER
}

@export var max_size: int = -1 ## The maximum size of the container. Negative means infinite.
@export var allowed_tiles: Array[Root.Tiles] = [Root.Tiles.SHADOW]


@export var container_type: Type

@onready var root: Root = get_tree().root.get_child(get_tree().root.get_child_count()-1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().process_frame

	custom_minimum_size *= root.tile_scale
	if max_size >= 0:
		assert (length() <= max_size,"Too many children: Length: %s, Max: %s, Children: %s"%[length(),max_size,get_children()])

func tile_added(_tile: Tile):
	pass

func length(include_shadow=true) -> int:
	var _length = 0
	for child in get_children():
		if include_shadow or child.type != Root.Tiles.SHADOW:
			_length += 1
			continue
	return _length
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:

	pivot_offset = size/2
	pivot_offset = size/2
	
