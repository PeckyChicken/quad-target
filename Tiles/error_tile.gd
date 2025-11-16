class_name ErrorTile
extends Tile

var message: String
var output: String = "###"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super()
	$Output.text = output
	$Message.text = message

func rescale(new_scale):
	super(new_scale)
	$Output.add_theme_font_size_override("normal_font_size",50 * new_scale.x/100)
	$Message.add_theme_font_size_override("normal_font_size",12 * new_scale.x/100)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super(delta)
