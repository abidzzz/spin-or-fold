extends CanvasLayer

signal bet_placed(hand: HandEvaluator.Hand)
signal upgrade_chosen(index: int)

@onready var gold_label = $TopBar/GoldLabel
@onready var round_label = $TopBar/RoundLabel
@onready var hands_label = $TopBar/HandsLabel
@onready var progress_bar = $ProgressBar
@onready var upgrade_screen = $UpgradeScreen
@onready var upgrade_options = $UpgradeScreen/UpgradeOptions
@onready var upgrade_title = $UpgradeScreen/UpgradeTitle
@onready var bet_selector = $BetSelector
@onready var round_status = $RoundStatus
@onready var spin_button = $SpinButton
@onready var boss_overlay = $BossOverlay
@onready var transition_overlay = $TransitionOverlay
@onready var transition_label = $TransitionOverlay/TransitionLabel
@onready var streak_label = $StreakLabel
@onready var hand_history = $HandHistory
@onready var score_label = $ProgressContainer/ScoreContainer/ScoreLabel
@onready var target_label = $ProgressContainer/ScoreContainer/TargetLabel
@onready var progress_text = $ProgressContainer/ProgressText

var displayed_gold: int = 0
var current_bet: HandEvaluator.Hand = HandEvaluator.Hand.PAIR
var auto_bet: bool = true
var hand_history_list: Array = []

const BET_HANDS = [
	HandEvaluator.Hand.PAIR,
	HandEvaluator.Hand.TWO_PAIR,
	HandEvaluator.Hand.THREE_OF_A_KIND,
	HandEvaluator.Hand.STRAIGHT,
	HandEvaluator.Hand.FLUSH,
	HandEvaluator.Hand.FULL_HOUSE,
	HandEvaluator.Hand.FOUR_OF_A_KIND,
]

# Add these variables at the top
var current_round: int = 1

# Add this function for round-based styling
func update_round_styling(round_num: int) -> void:
	current_round = round_num
	
	# Get colors based on round
	var colors = _get_round_colors(round_num)
	
	# Update progress bar
	var fill_style = StyleBoxFlat.new()
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	fill_style.bg_color = colors.progress_color
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Update bet buttons
	for i in range(bet_selector.get_child_count()):
		var btn = bet_selector.get_child(i)
		var style = StyleBoxFlat.new()
		style.bg_color = colors.button_color
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = colors.button_border
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", style)
	
	# Update spin button
	var spin_style = StyleBoxFlat.new()
	spin_style.bg_color = colors.spin_color
	spin_style.border_width_left = 3
	spin_style.border_width_right = 3
	spin_style.border_width_top = 3
	spin_style.border_width_bottom = 3
	spin_style.border_color = colors.spin_border
	spin_style.corner_radius_top_left = 12
	spin_style.corner_radius_top_right = 12
	spin_style.corner_radius_bottom_left = 12
	spin_style.corner_radius_bottom_right = 12
	spin_button.add_theme_stylebox_override("normal", spin_style)
	
	# Update round label color
	round_label.modulate = colors.text_color
	gold_label.modulate = colors.gold_color

func _get_round_colors(round_num: int) -> Dictionary:
	match round_num:
		1:
			return {
				"progress_color": Color(0.1, 0.3, 0.6),  # Blue
				"button_color": Color(0.05, 0.1, 0.2),
				"button_border": Color(0.2, 0.4, 0.8),
				"spin_color": Color(0.1, 0.2, 0.5),
				"spin_border": Color(0.3, 0.5, 1.0),
				"text_color": Color(0.4, 0.7, 1.0),
				"gold_color": Color.GOLD
			}
		2:
			return {
				"progress_color": Color(0.3, 0.1, 0.5),  # Purple
				"button_color": Color(0.1, 0.05, 0.2),
				"button_border": Color(0.5, 0.2, 0.8),
				"spin_color": Color(0.3, 0.1, 0.5),
				"spin_border": Color(0.6, 0.3, 1.0),
				"text_color": Color(0.6, 0.3, 1.0),
				"gold_color": Color.GOLD
			}
		3:
			return {
				"progress_color": Color(0.6, 0.5, 0.1),  # Gold
				"button_color": Color(0.2, 0.15, 0.02),
				"button_border": Color(0.8, 0.6, 0.1),
				"spin_color": Color(0.5, 0.4, 0.05),
				"spin_border": Color(0.8, 0.7, 0.2),
				"text_color": Color(0.8, 0.7, 0.2),
				"gold_color": Color(0.9, 0.8, 0.3)
			}
		4:
			return {
				"progress_color": Color(0.0, 0.8, 0.8),  # Cyan
				"button_color": Color(0.0, 0.1, 0.15),
				"button_border": Color(0.0, 0.8, 0.8),
				"spin_color": Color(0.0, 0.3, 0.3),
				"spin_border": Color(0.0, 1.0, 1.0),
				"text_color": Color(0.0, 1.0, 1.0),
				"gold_color": Color.GOLD
			}
		5:
			return {
				"progress_color": Color(0.6, 0.05, 0.05),  # Red
				"button_color": Color(0.2, 0.02, 0.02),
				"button_border": Color(0.8, 0.1, 0.1),
				"spin_color": Color(0.5, 0.02, 0.02),
				"spin_border": Color(0.8, 0.1, 0.1),
				"text_color": Color(0.8, 0.1, 0.1),
				"gold_color": Color(0.8, 0.6, 0.2)
			}
		6:  # Boss
			return {
				"progress_color": Color(0.8, 0.2, 0.0),  # Orange-red
				"button_color": Color(0.3, 0.05, 0.0),
				"button_border": Color(0.8, 0.2, 0.0),
				"spin_color": Color(0.6, 0.1, 0.0),
				"spin_border": Color(1.0, 0.3, 0.0),
				"text_color": Color(1.0, 0.3, 0.0),
				"gold_color": Color(0.9, 0.7, 0.2)
			}
		_:
			return {
				"progress_color": Color(0.2, 0.6, 0.2),
				"button_color": Color(0.1, 0.15, 0.1),
				"button_border": Color(0.3, 0.6, 0.3),
				"spin_color": Color(0.2, 0.5, 0.2),
				"spin_border": Color(0.3, 0.8, 0.3),
				"text_color": Color(0.4, 0.8, 0.4),
				"gold_color": Color.GOLD
			}

	
func _ready() -> void:
	upgrade_screen.visible = false
	_build_bet_buttons()
	_setup_labels()
	_setup_spin_button()
	spin_button.pressed.connect(_on_spin_pressed)
	round_status.text = ""
	streak_label.visible = false
	_setup_hand_history()
	_setup_progress_style()
	_center_everything()

func _center_everything() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	
	# --- Center Transition Overlay ---
	transition_overlay.size = viewport_size
	transition_overlay.position = Vector2.ZERO
	
	# Transition label - use Control positioning
	transition_label.anchor_left = 0.5
	transition_label.anchor_right = 0.5
	transition_label.anchor_top = 0.5
	transition_label.anchor_bottom = 0.5
	transition_label.offset_left = -300
	transition_label.offset_right = 300
	transition_label.offset_top = -60
	transition_label.offset_bottom = 60
	transition_label.position = Vector2.ZERO
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# --- Center Boss Overlay ---
	boss_overlay.size = viewport_size
	boss_overlay.position = Vector2.ZERO
	
	# --- Center Upgrade Screen ---

func _setup_progress_style() -> void:
	# Style progress bar like Balatro
	progress_bar.add_theme_color_override("font_color", Color.WHITE)
	progress_bar.add_theme_color_override("font_outline_color", Color.BLACK)
	progress_bar.add_theme_constant_override("outline_size", 2)
	progress_bar.show_percentage = false
	
	# Create Balatro-style progress bar style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.5)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("background", style)
	
	# Fill style with gradient
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.6, 0.2)
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	progress_bar.add_theme_stylebox_override("fill", fill_style)

func _setup_labels() -> void:
	# Style the labels with better fonts and effects
	_style_label(gold_label, "💰", Color.GOLD)
	_style_label(round_label, "🎯", Color.WHITE)
	_style_label(hands_label, "🃏", Color.CYAN)
	_style_label(streak_label, "🔥", Color.ORANGE)
	
	# Style score labels (Balatro style)
	if score_label:
		score_label.add_theme_font_size_override("font_size", 36)
		score_label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		score_label.add_theme_color_override("font_outline_color", Color.BLACK)
		score_label.add_theme_constant_override("outline_size", 3)
		score_label.text = "0"
		score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if target_label:
		target_label.add_theme_font_size_override("font_size", 24)
		target_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
		target_label.add_theme_color_override("font_outline_color", Color.BLACK)
		target_label.add_theme_constant_override("outline_size", 2)
		target_label.text = "/ 100"
		target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	if progress_text:
		progress_text.add_theme_font_size_override("font_size", 14)
		progress_text.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
		progress_text.add_theme_color_override("font_outline_color", Color.BLACK)
		progress_text.add_theme_constant_override("outline_size", 2)
		progress_text.text = "PROGRESS"
		progress_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Add shadow effects
	_add_shadow_to_label(gold_label)
	_add_shadow_to_label(round_label)
	_add_shadow_to_label(hands_label)
	if score_label:
		_add_shadow_to_label(score_label)
	if target_label:
		_add_shadow_to_label(target_label)

func _style_label(label: Label, icon: String, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	
	# Add icon if not already there
	if not label.text.begins_with(icon):
		label.text = icon + " " + label.text

func _add_shadow_to_label(label: Label) -> void:
	var shadow = Label.new()
	shadow.text = label.text
	shadow.add_theme_color_override("font_color", Color.BLACK)
	shadow.add_theme_color_override("font_outline_color", Color.BLACK)
	shadow.position = Vector2(2, 2)
	shadow.modulate.a = 0.3
	label.add_child(shadow)

func _setup_spin_button() -> void:
	# Make the spin button bigger and more stylish
	spin_button.text = "🔄 SPIN"
	spin_button.add_theme_font_size_override("font_size", 32)
	spin_button.add_theme_color_override("font_color", Color.WHITE)
	spin_button.add_theme_color_override("font_outline_color", Color.BLACK)
	spin_button.add_theme_constant_override("outline_size", 4)
	
	# Create a glowing style for the spin button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.8, 0.2, 0.2)  # Casino red
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color.GOLD
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	spin_button.add_theme_stylebox_override("normal", style)
	
	# Hover effect
	var hover_style = style.duplicate()
	hover_style.bg_color = Color(1.0, 0.3, 0.3)
	spin_button.add_theme_stylebox_override("hover", hover_style)
	
	# Pressed effect
	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.5, 0.1, 0.1)
	spin_button.add_theme_stylebox_override("pressed", pressed_style)
	
	# Add pulsing animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(spin_button, "scale", Vector2(1.05, 1.05), 0.5)
	tween.tween_property(spin_button, "scale", Vector2(1.0, 1.0), 0.5)

func _setup_hand_history() -> void:
	# Clear any existing children
	for child in hand_history.get_children():
		child.queue_free()
	
	# Create small history display with proper spacing
	for i in range(5):
		var history_icon = TextureRect.new()
		history_icon.size = Vector2(24, 24)
		history_icon.position = Vector2(i * 30, 0)
		history_icon.modulate = Color.GRAY
		hand_history.add_child(history_icon)

func _build_bet_buttons() -> void:
	# Clear any existing buttons
	for child in bet_selector.get_children():
		child.queue_free()
	
	# Add spacing between bet buttons
	bet_selector.add_theme_constant_override("separation", 10)
	
	for hand in BET_HANDS:
		var btn = Button.new()
		var mult = HandEvaluator.get_hand_multiplier(hand)
		var hand_name = HandEvaluator.get_hand_name(hand)
		
		# Style button with hand name and multiplier
		btn.text = "%s ×%d" % [hand_name, mult]
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func(): _on_bet_pressed(hand))
		
		# Add tooltip with description
		btn.tooltip_text = _get_hand_description(hand)
		
		# Style button
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_theme_constant_override("outline_size", 1)
		
		# Create button style
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.15, 0.15, 0.3)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.3, 0.3, 0.6)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", style)
		
		# Hover style
		var hover_style = style.duplicate()
		hover_style.bg_color = Color(0.25, 0.25, 0.5)
		btn.add_theme_stylebox_override("hover", hover_style)
		
		bet_selector.add_child(btn)
	
	_highlight_bet(HandEvaluator.Hand.PAIR)

func _get_hand_description(hand: HandEvaluator.Hand) -> String:
	var descriptions = {
		HandEvaluator.Hand.PAIR: "Two cards of the same rank",
		HandEvaluator.Hand.TWO_PAIR: "Two different pairs",
		HandEvaluator.Hand.THREE_OF_A_KIND: "Three cards of the same rank",
		HandEvaluator.Hand.STRAIGHT: "Five cards in sequence",
		HandEvaluator.Hand.FLUSH: "Five cards of the same suit",
		HandEvaluator.Hand.FULL_HOUSE: "Three of a kind + a pair",
		HandEvaluator.Hand.FOUR_OF_A_KIND: "Four cards of the same rank",
	}
	return descriptions.get(hand, "")

func _on_bet_pressed(hand: HandEvaluator.Hand) -> void:
	current_bet = hand
	_highlight_bet(hand)
	if auto_bet:
		emit_signal("bet_placed", hand)
		_animate_bet_selection(hand)

func _animate_bet_selection(hand: HandEvaluator.Hand) -> void:
	for i in range(bet_selector.get_child_count()):
		var btn = bet_selector.get_child(i)
		if i == BET_HANDS.find(hand):
			var tween = create_tween()
			tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.1)
			tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)

func _highlight_bet(hand: HandEvaluator.Hand) -> void:
	for i in range(bet_selector.get_child_count()):
		var btn = bet_selector.get_child(i)
		if i == BET_HANDS.find(hand):
			btn.modulate = Color.YELLOW
			btn.add_theme_color_override("font_color", Color.BLACK)
			# Update style to gold border
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.8, 0.7, 0.1)
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = Color.GOLD
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			btn.add_theme_stylebox_override("normal", style)
		else:
			btn.modulate = Color.WHITE
			btn.add_theme_color_override("font_color", Color.WHITE)
			# Reset style
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.15, 0.15, 0.3)
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.border_color = Color(0.3, 0.3, 0.6)
			style.corner_radius_top_left = 6
			style.corner_radius_top_right = 6
			style.corner_radius_bottom_left = 6
			style.corner_radius_bottom_right = 6
			btn.add_theme_stylebox_override("normal", style)

func _on_spin_pressed() -> void:
	_animate_spin_button()
	emit_signal("bet_placed", current_bet)

func _animate_spin_button() -> void:
	# More dramatic spin button animation
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(spin_button, "scale", Vector2(0.8, 0.8), 0.05)
	tween.tween_property(spin_button, "modulate", Color(0.5, 0.5, 0.5), 0.05)
	tween.tween_property(spin_button, "scale", Vector2(1.1, 1.1), 0.1).set_delay(0.05)
	tween.tween_property(spin_button, "modulate", Color(1.5, 1.5, 0.5), 0.1).set_delay(0.05)
	tween.tween_property(spin_button, "scale", Vector2(1.0, 1.0), 0.1).set_delay(0.15)
	tween.tween_property(spin_button, "modulate", Color.WHITE, 0.1).set_delay(0.15)

# --- Update functions with better label animations ---

func update_gold(target: int) -> void:
	var previous = displayed_gold
	var tween = create_tween()
	tween.tween_method(
		func(val: int): 
			gold_label.text = "💰 %d" % val
			_update_gold_color(val, previous),
		displayed_gold,
		target,
		0.4
	)
	displayed_gold = target
	
	# Animate gold label
	var pulse = create_tween()
	pulse.set_parallel(true)
	pulse.tween_property(gold_label, "scale", Vector2(1.3, 1.3), 0.1)
	pulse.tween_property(gold_label, "modulate", Color(1.5, 1.5, 0.5), 0.1)
	pulse.tween_property(gold_label, "scale", Vector2(1.0, 1.0), 0.2).set_delay(0.1)
	pulse.tween_property(gold_label, "modulate", Color.WHITE, 0.2).set_delay(0.1)

func _update_gold_color(current: int, previous: int) -> void:
	if current > previous:
		gold_label.modulate = Color.GREEN
	elif current < previous:
		gold_label.modulate = Color.RED
	else:
		gold_label.modulate = Color.WHITE

func update_round(round_num: int, is_boss: bool) -> void:
	if is_boss:
		round_label.text = "⚠️ BOSS ROUND"
		round_label.modulate = Color.RED
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(round_label, "modulate", Color(2, 0.5, 0.5), 0.5)
		tween.tween_property(round_label, "modulate", Color.RED, 0.5)
	else:
		round_label.text = "🎯 Round %d / 6" % round_num
		round_label.modulate = Color.WHITE

func update_hands(hands_left: int) -> void:
	var text = "🃏 Hands: "
	for i in range(5):
		if i < hands_left:
			text += "♠"
		else:
			text += "♢"
	hands_label.text = text
	
	# Color based on remaining hands
	if hands_left <= 1:
		hands_label.modulate = Color.RED
	elif hands_left <= 2:
		hands_label.modulate = Color.ORANGE
	else:
		hands_label.modulate = Color.CYAN

func update_progress(score: int, target: int) -> void:
	# Update Balatro-style progress
	progress_bar.max_value = target
	progress_bar.value = min(score, target)
	progress_bar.tooltip_text = "%d / %d" % [score, target]
	
	# Update score labels (Balatro style)
	if score_label:
		score_label.text = str(score)
	
	if target_label:
		target_label.text = "/ %d" % target
	
	# Update progress bar color based on percentage
	var percent = score / float(target)
	var fill_style = StyleBoxFlat.new()
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4
	
	if percent >= 1.0:
		fill_style.bg_color = Color(0.2, 0.8, 0.2)  # Bright green - cleared!
	elif percent >= 0.8:
		fill_style.bg_color = Color(0.2, 0.7, 0.2)
	elif percent >= 0.5:
		fill_style.bg_color = Color(0.7, 0.7, 0.2)  # Yellow
	elif percent >= 0.3:
		fill_style.bg_color = Color(0.7, 0.4, 0.2)  # Orange
	else:
		fill_style.bg_color = Color(0.5, 0.2, 0.2)  # Red
	
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
	# Animate progress bar on significant changes
	var tween = create_tween()
	tween.tween_property(progress_bar, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(progress_bar, "scale", Vector2(1.0, 1.0), 0.1)

func update_streak(streak: int) -> void:
	if streak > 0:
		streak_label.visible = true
		streak_label.text = "🔥 Streak: %d" % streak
		
		# Color based on streak length
		if streak >= 5:
			streak_label.modulate = Color(1, 0.5, 0)  # Orange
		elif streak >= 3:
			streak_label.modulate = Color.YELLOW
		else:
			streak_label.modulate = Color.WHITE
			
		# Animate streak
		var tween = create_tween()
		tween.tween_property(streak_label, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(streak_label, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		streak_label.visible = false

func add_hand_history(hand: HandEvaluator.Hand) -> void:
	hand_history_list.append(hand)
	if hand_history_list.size() > 5:
		hand_history_list.pop_front()
	
	# Update history icons
	for i in range(hand_history.get_child_count()):
		var icon = hand_history.get_child(i)
		if i < hand_history_list.size():
			var hand_value = hand_history_list[i] as int
			var colors = {
				0: Color.GRAY,      # High Card
				1: Color.BLUE,      # Pair
				2: Color.CYAN,      # Two Pair
				3: Color.YELLOW,    # Three of a Kind
				4: Color.ORANGE,    # Straight
				5: Color.GREEN,     # Flush
				6: Color.PURPLE,    # Full House
				7: Color.RED,       # Four of a Kind
				8: Color(1, 0.5, 1), # Straight Flush
				9: Color.GOLD,      # Royal Flush
			}
			icon.modulate = colors.get(hand_value, Color.GRAY)
		else:
			icon.modulate = Color.GRAY

func set_round_status(text: String, color: Color = Color.WHITE) -> void:
	round_status.text = text
	round_status.modulate = color
	
	# Animate status
	var tween = create_tween()
	tween.tween_property(round_status, "scale", Vector2(0.5, 0.5), 0.0)
	tween.tween_property(round_status, "scale", Vector2(1.1, 1.1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(round_status, "scale", Vector2(1.0, 1.0), 0.1)

func show_result(outcome: Dictionary) -> void:
	var color = Color.GREEN if outcome.won else Color.RED
	var amount = outcome.payout if outcome.won else -outcome.payout / 2
	var sign = "+" if outcome.won else "-"
	
	# Show detailed score info
	var hand_score = outcome.get("hand_score", 0)
	var hand_bonus = outcome.get("hand_bonus", 0)
	var streak_bonus = outcome.get("streak_bonus", 0)
	var perfect_bonus = outcome.get("perfect_bonus", 0)
	
	var msg = "%s %s$%d" % [outcome.result_name, sign, abs(amount)]
	
	# Add bonus info if significant
	if hand_bonus > 0 or streak_bonus > 0 or perfect_bonus > 0:
		var bonus_parts = []
		if hand_bonus > 0:
			bonus_parts.append("+%d" % hand_bonus)
		if streak_bonus > 0:
			bonus_parts.append("+%d" % streak_bonus)
		if perfect_bonus > 0:
			bonus_parts.append("+%d" % perfect_bonus)
		msg += " (%s)" % " ".join(bonus_parts)
	
	_flash_message(msg, color)
	
	# Add to hand history
	add_hand_history(outcome.result_hand)
	update_streak(outcome.get("streak", 0))

func _flash_message(text: String, color: Color) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	
	var label = Label.new()
	label.text = text
	label.modulate = color
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Center the flash message
	label.position = Vector2(viewport_size.x / 2 - 200, viewport_size.y / 2)
	add_child(label)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", Vector2(viewport_size.x / 2 - 200, viewport_size.y / 2 - 60), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.4)
	tween.tween_property(label, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_callback(label.queue_free)


func _get_upgrade_icon(type: int) -> String:
	match type:
		0: return "⚖️"  # WEIGHT
		1: return "🔒"  # LOCK
		2: return "🐢"  # SLOW
		3: return "🃏"  # WILD
		4: return "2x"  # DOUBLE
		_: return "⬆️"

func _get_upgrade_color(type: int) -> Color:
	match type:
		0: return Color(0.2, 0.4, 0.8)   # Blue - WEIGHT
		1: return Color(0.8, 0.6, 0.2)   # Gold - LOCK
		2: return Color(0.2, 0.8, 0.4)   # Green - SLOW
		3: return Color(0.8, 0.2, 0.8)   # Purple - WILD
		4: return Color(0.8, 0.2, 0.2)   # Red - DOUBLE
		_: return Color(0.3, 0.3, 0.5)

func _create_stylebox(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	style.border_color.a = 0.3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style

func show_round_transition(text: String, color: Color = Color.WHITE, is_boss: bool = false) -> void:
	transition_overlay.visible = true
	transition_label.text = text
	transition_label.modulate = color
	transition_label.add_theme_font_size_override("font_size", 64 if is_boss else 48)
	transition_label.add_theme_color_override("font_outline_color", Color.BLACK)
	transition_label.add_theme_constant_override("outline_size", 6)
	
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Background flash
	var flash = ColorRect.new()
	flash.color = color
	flash.modulate.a = 0.0
	flash.size = viewport_size
	flash.position = Vector2.ZERO
	transition_overlay.add_child(flash)
	
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.3, 0.2)
	flash_tween.tween_property(flash, "modulate:a", 0.0, 0.3).set_delay(0.5)
	flash_tween.tween_callback(flash.queue_free)
	
	# Animate label from center - anchor already set
	transition_label.scale = Vector2(0.3, 0.3)
	
	var label_tween = create_tween()
	label_tween.set_parallel(true)
	label_tween.tween_property(transition_label, "scale", Vector2(1.2, 1.2), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	label_tween.tween_property(transition_label, "modulate:a", 1.0, 0.3)
	
	if is_boss:
		var boss_tween = create_tween()
		boss_tween.tween_property(transition_label, "scale", Vector2(1.5, 1.5), 0.2)
		boss_tween.tween_property(transition_label, "scale", Vector2(1.0, 1.0), 0.2)
		boss_tween.set_loops(3)
	
	await get_tree().create_timer(2.0).timeout
	
	var exit_tween = create_tween()
	exit_tween.set_parallel(true)
	exit_tween.tween_property(transition_label, "scale", Vector2(0.3, 0.3), 0.5).set_ease(Tween.EASE_IN)
	exit_tween.tween_property(transition_label, "modulate:a", 0.0, 0.5)
	
	await get_tree().create_timer(0.6).timeout
	transition_overlay.visible = false
	transition_label.scale = Vector2(1.0, 1.0)
	transition_label.modulate.a = 1.0


func _on_upgrade_chosen(index: int) -> void:
	emit_signal("upgrade_chosen", index)
	hide_upgrade_screen()

func update_bet_amount(amount: int) -> void:
	# Optional: Show bet amount somewhere if you want
	pass
	
func show_boss_intro() :
	boss_overlay.visible = true
	boss_overlay.modulate.a = 0.0
	var tween = create_tween()
	# Fade in red overlay
	tween.tween_property(boss_overlay, "modulate:a", 0.85, 0.6)
	tween.tween_interval(0.8)
	# Flash the text
	tween.tween_callback(func(): _flash_message("⚠️ DOUBLE OR NOTHING", Color.RED))
	tween.tween_interval(1.2)
	# Fade out overlay
	tween.tween_property(boss_overlay, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): boss_overlay.visible = false)
	await tween.finished
	
func show_upgrade_screen(offers: Array) -> void:
	upgrade_screen.visible = true
	upgrade_screen.grab_focus()
	
	# Clear skip hint if exists
	for child in upgrade_screen.get_children():
		if child is Label and child.text == "[ESC] to skip":
			child.queue_free()
	
	# Add skip hint
	var skip_hint = Label.new()
	skip_hint.text = "[ESC] to skip"
	skip_hint.add_theme_font_size_override("font_size", 16)
	skip_hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.7))
	skip_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	skip_hint.add_theme_constant_override("outline_size", 2)
	skip_hint.position = Vector2(
		get_viewport().get_visible_rect().size.x / 2 - 60,
		get_viewport().get_visible_rect().size.y / 2 + 180
	)
	skip_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_screen.add_child(skip_hint)
	
	# Clear old options
	for child in upgrade_options.get_children():
		child.queue_free()
	
	upgrade_options.add_theme_constant_override("separation", 15)
	
	for i in range(offers.size()):
		var offer = offers[i]
		var btn = Button.new()
		
		var icon = _get_upgrade_icon(offer.type)
		# Show the reel number as 1-based for display
		var reel_display = offer.target_reel + 1
		btn.text = "%s %s\n→ Reel %d" % [icon, offer.get_description(), reel_display]
		btn.focus_mode = Control.FOCUS_ALL
		
		btn.add_theme_font_size_override("font_size", 20)
		btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_color_override("font_outline_color", Color.BLACK)
		btn.add_theme_constant_override("outline_size", 2)
		
		var color = _get_upgrade_color(offer.type)
		btn.add_theme_stylebox_override("normal", _create_stylebox(color))
		btn.add_theme_stylebox_override("hover", _create_stylebox(color.lightened(0.2)))
		btn.add_theme_stylebox_override("pressed", _create_stylebox(color.darkened(0.2)))
		
		var idx = i
		btn.pressed.connect(func(): _on_upgrade_chosen(idx))
		upgrade_options.add_child(btn)
		
		var btn_tween = create_tween()
		btn_tween.tween_property(btn, "scale", Vector2(0.5, 0.5), 0.0)
		btn_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2).set_delay(i * 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
func hide_upgrade_screen() -> void:
	# Clear skip hint
	for child in upgrade_screen.get_children():
		if child is Label and child.text == "[ESC] to skip":
			child.queue_free()
	
	var tween = create_tween()
	tween.tween_property(upgrade_screen, "scale", Vector2(0.5, 0.5), 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): 
		upgrade_screen.visible = false
		upgrade_screen.scale = Vector2(1.0, 1.0)
	)
func _unhandled_input(event: InputEvent) -> void:
	# Handle ESC key to cancel upgrade
	if event.is_action_pressed("ui_cancel") and upgrade_screen.visible:
		# Let main handle the skip
		pass
