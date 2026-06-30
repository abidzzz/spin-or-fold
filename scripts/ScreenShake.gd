extends Camera2D
class_name ScreenShake

var shake_amount = 0.0
var shake_decay = 5.0

func shake(amount: float) -> void:
	shake_amount = amount

func _process(delta: float) -> void:
	if shake_amount > 0:
		offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
	else:
		offset = Vector2.ZERO
