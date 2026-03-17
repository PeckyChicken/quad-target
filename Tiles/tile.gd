class_name Tile
extends Control

@export var draggable: bool = false

var extra_data: Dictionary = {}

var movement: float = 0.0

var click_threshold: float ##Distance the mouse has to move before it registers as a drag.

var dragging: bool = false
var drag_offset: Vector2

enum DragState {
	NONE,
	DRAGGING,
	JUST_RELEASED
}

const ANIMATION_TIME = 0.1

var drag_state: DragState = DragState.NONE

@export var type: Root.Tiles

@onready var root: Root = get_tree().root.get_child(get_tree().root.get_child_count()-1)
@onready var overlap: Control = root

@onready var shadow_tile: PackedScene = load("res://Tiles/shadow_tile.tscn")

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

func _sort_in_container(object:Control,container:NumberContainer,temp_position=null):
	temp_position = temp_position if temp_position else object.global_position
	for node in container.get_children():
		
		if node == object:
			continue
		if node.global_position.x >= temp_position.x:
			container.move_child(node,container.get_child_count()-1)

func add_to_container(container: NumberContainer,temp_position_override=null):
	if container.max_size >= 0:
		assert (container.length(false) <= container.max_size,"Container overflow error: Length: %s, Max Size: %s, Contents: %s" % [container.length(),container.max_size,str(container.get_children())])
	
	var temp_position: Vector2
	
	if temp_position_override:
		temp_position = temp_position_override
	else:
		temp_position = global_position
	
	reparent(container)
	parent_container = container
	
	overlap = container
	
	
	_sort_in_container(self,container,temp_position)
	
	container.tile_added(self)

func smooth_add_to_container(container: NumberContainer,time:float,temp_position_override=null):
	var start_pos := global_position
	
	var switching_container = (container != parent_container)
	
	add_to_container(container,temp_position_override)
	await get_tree().process_frame
	
	var end_pos := global_position
	
	var tween = get_tree().create_tween()
	if switching_container:
		reparent(root)
	global_position = start_pos
	tween.tween_property(self,"global_position",end_pos,time)
	await tween.finished
	add_to_container(container,temp_position_override)

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
	if drag_state == DragState.JUST_RELEASED:
		await get_tree().process_frame
		
		drag_state = DragState.NONE

func add_move():
	root.moves += 1
	Events.MakeNumberList.emit()
	await get_tree().process_frame
	if root.save_active:
		Save.save(root.save_name,{"moves":root.moves,"time":root.timer,"solution":root.solution} if root.solution else {"moves":root.moves,"time":root.timer},root.date,root.total_numbers,root.target,root.difficulty in root.wins)
	

func end_drag():
	if not dragging: return
	
	if drag_state == DragState.DRAGGING:
		drag_state = DragState.JUST_RELEASED
	dragging = false
	delete_shadow()
	if drag_state == DragState.JUST_RELEASED:
		if movement <= click_threshold:
			add_move()
			quick_move()
			return
	
	if overlap in root.containers:
		if parent_container != overlap.get_child(0):
			#print("----------------------------")
			#print("Adding to container ",overlap)
			
			add_move()
			add_to_container(overlap.get_child(0))
			if parent_container is AnswerContainer:
				parent_container.recreate_expression()
		
func drag(event:InputEventMouseMotion):
	var old_position = position
	position = event.global_position + drag_offset
	movement += (position - old_position).length()
	
	old_position = position
	position = position.clamp(Vector2.ZERO,get_viewport_rect().size-self.size)
	
	find_overlap()


func _input(event:InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		return
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
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		return
	await get_tree().process_frame
	movement = 0
	drag_state = DragState.DRAGGING
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
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		return
	if not draggable:
		return
	if event is InputEventMouseButton and event.is_pressed():
		_on_click(event)
