extends CanvasLayer

@onready var label = $Panel/Label
@onready var anim = $AnimationPlayer

func display(text: String, color: Color = Color.WHITE):
	label.text = text
	label.modulate = color
	show()
	if anim.has_animation("pop"):
		anim.play("pop")
	else:
		# Fallback fade
		var tween = create_tween()
		# CanvasLayer itself has no modulate. We should modulate the Panel instead.
		$Panel.modulate.a = 0
		tween.tween_property($Panel, "modulate:a", 1.0, 0.3)
		tween.tween_interval(2.0)
		tween.tween_property($Panel, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
