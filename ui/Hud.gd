extends CanvasLayer

@onready var hearts_container: HBoxContainer = $Hearts/HeartsContainer
@onready var heart_template: AnimatedSprite2D = $Hearts/HeartTemplate

@onready var currency_label: Label = $Currency/AmountLabel
@onready var currency_icon: Node = $Currency/CurrencyIcon

@onready var prompt_label: Label = $PromptLabel
@onready var fade_rect: ColorRect = $FadeRect

@export var default_max_hearts: int = 3
@export var heart_frames: SpriteFrames

var current_max_hearts: int = 0

func _ready() -> void:
	if heart_frames != null:
		heart_template.sprite_frames = heart_frames

	heart_template.visible = false
	current_max_hearts = 0
	set_hearts(default_max_hearts, default_max_hearts)

	currency_label.text = "0"
	prompt_label.visible = false

	# Fade overlay setup
	var c: Color = fade_rect.color
	c.a = 1.0
	fade_rect.color = c
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Make sure fade covers everything, including DialogueBox
	fade_rect.z_index = 100
	if has_node("DialogueBox"):
		var dlg := get_node("DialogueBox") as Control
		dlg.z_index = 0

# ---------------------------------------------------------
# HEARTS
# ---------------------------------------------------------
func _ensure_heart_count(max_hearts: int) -> void:
	if max_hearts == current_max_hearts:
		return

	for child in hearts_container.get_children():
		if child != heart_template:
			child.queue_free()

	for i in max_hearts:
		var heart := heart_template.duplicate() as AnimatedSprite2D
		heart.visible = true
		hearts_container.add_child(heart)

	current_max_hearts = max_hearts


func _get_hearts_array() -> Array[AnimatedSprite2D]:
	var result: Array[AnimatedSprite2D] = []
	for child in hearts_container.get_children():
		if child is AnimatedSprite2D and child != heart_template:
			result.append(child)
	return result


func set_hearts(current_hearts: int, max_hearts: int) -> void:
	if max_hearts < 0:
		max_hearts = 0
	if current_hearts < 0:
		current_hearts = 0
	if current_hearts > max_hearts:
		current_hearts = max_hearts

	_ensure_heart_count(max_hearts)

	var hearts := _get_hearts_array()
	for i in hearts.size():
		var heart := hearts[i]
		if heart.sprite_frames == null:
			continue

		if i < current_hearts:
			if heart.sprite_frames.has_animation("full"):
				heart.play("full")
		else:
			if heart.sprite_frames.has_animation("empty"):
				heart.play("empty")

func update_hearts(current_hearts: int, max_hearts: int) -> void:
	set_hearts(current_hearts, max_hearts)

# ---------------------------------------------------------
# CURRENCY
# ---------------------------------------------------------
func set_currency(amount: int) -> void:
	currency_label.text = str(amount)

# ---------------------------------------------------------
# PROMPTS
# ---------------------------------------------------------
func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = true

func hide_prompt() -> void:
	prompt_label.visible = false

# ---------------------------------------------------------
# FADES
# ---------------------------------------------------------
func fade_to_black(duration: float = 0.5) -> Tween:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	return tween

func fade_from_black(duration: float = 0.5) -> Tween:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	return tween
