extends Control

@onready var MAIN_SCENE: PackedScene = load("res://main.tscn")
@onready var MOBILE_SCENE: PackedScene = load("res://mobile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		load_scene(MOBILE_SCENE)
	else:
		load_scene(MAIN_SCENE)

func load_scene(scene: PackedScene):
	var new_scene: Root = scene.instantiate()
	new_scene.web = OS.has_feature("web")
	get_tree().root.add_child.call_deferred(new_scene)
	
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
