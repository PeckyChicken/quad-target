class_name NumberCountSelect
extends Button

@onready var root: Root = $"../../../.."

@export var number: int = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	disabled = root.number_count == number

func _on_pressed() -> void:
	root.number_count = number
	$"../../../Difficulty"._on_pressed()
