extends Control

signal game_started

func _ready() -> void:
	# Simple title
	var title = Label.new()
	title.text = "♠ SLOT ♥"
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.8, 0.7, 0.2))
	title.position = Vector2(
		get_viewport().get_visible_rect().size.x / 2 - 150,
		150
	)
	add_child(title)
	
	# Play button
	var play_btn = Button.new()
	play_btn.text = "PLAY"
	play_btn.add_theme_font_size_override("font_size", 32)
	play_btn.position = Vector2(
		get_viewport().get_visible_rect().size.x / 2 - 80,
		300
	)
	play_btn.size = Vector2(160, 60)
	play_btn.pressed.connect(_on_play_pressed)
	add_child(play_btn)
	
	# Tutorial button
	var tutorial_btn = Button.new()
	tutorial_btn.text = "HOW TO PLAY"
	tutorial_btn.add_theme_font_size_override("font_size", 20)
	tutorial_btn.position = Vector2(
		get_viewport().get_visible_rect().size.x / 2 - 80,
		380
	)
	tutorial_btn.size = Vector2(160, 40)
	tutorial_btn.pressed.connect(_on_tutorial_pressed)
	add_child(tutorial_btn)

func _on_play_pressed() -> void:
	emit_signal("game_started")
	queue_free()

func _on_tutorial_pressed() -> void:
	# Simple popup - add to tree first
	var dialog = AcceptDialog.new()
	dialog.title = "HOW TO PLAY"
	dialog.dialog_text = "1. Select your bet hand\n2. Press S or click SPIN\n3. Press SPACE to stop reels\n4. Win if your hand matches or beats your bet!"
	dialog.size = Vector2(400, 300)
	add_child(dialog)  # <-- Add to tree first
	dialog.popup_centered()  # <-- Then popup
