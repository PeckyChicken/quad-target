class_name Tile
extends Control

@export var draggable: bool = false

var extra_data: Dictionary = {}

var movement: float = 0.0

var click_threshold: float ##Distance the mouse has to move before it registers as a drag.

var dragging: bool = false
var drag_offset: Vector2

var just_released: int = 0

@export var type: Root.Tiles

@onready var root: Root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
@onready var overlap: Control = root

@onready var shadow_tile: PackedScene = load("res://shadow_tile.tscn")

@onready var expression_container: ExpressionContainer = root.get_node("Equation/Expression/Symbols")
@onready var answer_container: AnswerContainer = root.get_node("Equation/Answer/Symbols")
@onready var storage_container: NumberContainer = root.get_node("Storage/Symbols")
@onready var operation_container: OperationContainer = root.get_node("Operations/Symbols")

var parent_container: NumberContainer
var previous_parent: NumberContainer

var shadow: Tile
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if root is Mobile:
		click_threshold = 20.0
	else:
		click_threshold = 5.0
	
	
	var start_size = custom_minimum_size
	rescale(start_size * root.tile_scale)
	
	await get_tree().process_frame
	rescale(start_size * root.tile_scale)

	for child in get_children():
		child.pivot_offset = custom_minimum_size/2
	
	Events.TileCreated.emit(self)
	if get_parent() is NumberContainer:
		parent_container = get_parent()
		previous_parent = parent_container
		
	Events.ResetTiles.connect(return_home)

func rescale(new_scale):
	custom_minimum_size = new_scale
	for child in get_children():
		child.pivot_offset = new_scale/2

func return_home():
	if not draggable:
		return
	if self is NumberTile:
		add_to_container(storage_container)
	elif self is OperationTile:
		if parent_container != operation_container:
			queue_free()

func add_to_container(container: NumberContainer,temp_position_override=null):
	if container.max_size >= 0:
		assert (container.length(false) <= container.max_size,"Container overflow error: Length: %s, Max Size: %s, Contents: %s" % [container.length(),container.max_size,str(container.get_children())])
	var temp_position
	
	if temp_position_override:
		temp_position = temp_position_override
	else:
		temp_position = global_position
	reparent(container)
	
	parent_container = container
	
	overlap = container
	
	container.tile_added(self)
	
	for node in container.get_children():
		if node == self:
			continue
		if node.global_position.x >= temp_position.x:
			container.move_child(node,container.get_child_count()-1)

func delete_shadow():
	if shadow:
		shadow.queue_free()
		shadow = null

func find_overlap():
	delete_shadow()
	
	for other in root.containers:
		if other == self:
			continue
		if other.get_child(0).length(false) >= other.get_child(0).max_size and other.get_child(0).max_size >= 0:
			continue
		if type not in other.get_child(0).allowed_tiles:
			continue
		
		if type == Root.Tiles.NUMBER:
			if other.get_child(0).container_type == NumberContainer.Type.ANSWER and not (self as NumberTile).expression:
				continue
		
		if get_global_rect().intersects(other.get_global_rect()):
			overlap = other
			create_shadow(overlap.get_child(0))
			
			return
	
	overlap = root

func create_shadow(container:NumberContainer):
	delete_shadow()
	if container is OperationContainer:
		return
	shadow = shadow_tile.instantiate()
	shadow.position = position
	shadow.type = Root.Tiles.SHADOW
	add_sibling(shadow)
	shadow.add_to_container(container,global_position)

func _process(_delta: float) -> void:
	if just_released == 1:
		await get_tree().process_frame
		just_released = 0

func end_drag():
	if not dragging: return
	
	just_released = -1 * just_released
	dragging = false
	delete_shadow()
	if just_released == 1:
		if movement <= click_threshold:
			root.moves += 1
			quick_move()
			return
	
	if overlap in root.containers:
		if not parent_container == overlap.get_child(0):
			root.moves += 1
			add_to_container(overlap.get_child(0))
			if parent_container is AnswerContainer:
				parent_container.recreate_expression()

func drag(event:InputEventMouseMotion):
	var old_position = position
	position = event.position + drag_offset
	movement += (position - old_position).length()
	
	old_position = position
	position = position.clamp(Vector2.ZERO,get_viewport_rect().size-self.size)
	
	find_overlap()


func _input(event:InputEvent) -> void:
	if not draggable:
		return
	await get_tree().process_frame
	
	if event is InputEventMouse:
		if event.button_mask == 0 or (event is InputEventMouseButton and not event.is_pressed()):
			end_drag()
		
		if event is InputEventMouseMotion:
			if dragging:
				drag(event)
	

func quick_move(container=null):
	if container == null:
		if previous_parent in [storage_container,operation_container]:
			container = expression_container
		elif previous_parent == answer_container:
			container = storage_container
		elif previous_parent == expression_container:
			if self is NumberTile:
				container = storage_container
			elif self is OperationTile:
				queue_free()
				return
	
	add_to_container(container,Vector2.INF)

func _on_click(event: InputEventMouseButton) -> void:
	await get_tree().process_frame
	movement = 0
	just_released = -1
	if parent_container:
		previous_parent = parent_container
		find_overlap()
		parent_container = null
	
	if type == Root.Tiles.ANSWER:
		type = Root.Tiles.NUMBER
		extra_data["expression"].clear()
		
	reparent(root)
	root.move_child(self,root.get_child_count()-1)

	drag_offset = position - event.global_position
	dragging = event.is_pressed()

func _on_gui_input(event: InputEvent) -> void:
	if not draggable:
		return
	if event is InputEventMouseButton:
		_on_click(event)
