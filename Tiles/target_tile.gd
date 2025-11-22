class_name TargetTile
extends NumberTile


func _ready() -> void:
	super()

func rescale(new_scale):
	super(new_scale)
	$Number.add_theme_font_size_override("normal_font_size",50 * new_scale.x/100)
	$Equation.add_theme_font_size_override("normal_font_size",20 * new_scale.x/100)

func _process(delta: float) -> void:
	super(delta)
