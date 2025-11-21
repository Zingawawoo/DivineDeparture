extends Control

# ==========================
#  Exports
# ==========================
@export var main_scene: PackedScene

# ==========================
#  Node refs
# ==========================
@onready var title_layer_1: TextureRect = $TitleContainer/TitleLayer1
@onready var title_layer_2: TextureRect = $TitleContainer/TitleLayer2
@onready var title_layer_3: TextureRect = $TitleContainer/TitleLayer3

@onready var button_container: VBoxContainer = $ButtonContainer
@onready var new_game_button: Button = $ButtonContainer/NewGameButton
@onready var continue_button: Button = $ButtonContainer/ContinueButton
@onready var quit_button: Button = $ButtonContainer/QuitButton

@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_player: AudioStreamPlayer = $SfxPlayer

@onready var fade_rect: ColorRect = $FadeRect

# ==========================
#  Config
# ==========================
const TITLE_FADE_TIME: float = 0.5
const TITLE_DELAY: float = 0.2
const BUTTON_FADE_TIME: float = 0.5
const MUSIC_DELAY_AFTER_LAST_TITLE: float = 0.3


func _ready() -> void:
	_init_visual_state()

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	var has_save_data: bool = GameManager.has_save()
	continue_button.disabled = not has_save_data


	if has_save_data:
		continue_button.disabled = false
	else:
		continue_button.disabled = true

	_play_intro_sequence()


# --------------------------
#  Initial state
# --------------------------
func _init_visual_state() -> void:
	_set_alpha(title_layer_1, 0.0)
	_set_alpha(title_layer_2, 0.0)
	_set_alpha(title_layer_3, 0.0)

	_set_alpha(button_container, 0.0)

	# Start fully black
	_set_alpha(fade_rect, 1.0)


func _set_alpha(node: CanvasItem, alpha: float) -> void:
	var color: Color = node.modulate
	color.a = alpha
	node.modulate = color


# --------------------------
#  Audio helpers
# --------------------------
func _play_sfx() -> void:
	if sfx_player.stream != null:
		sfx_player.stop()
		sfx_player.play()


func _start_music() -> void:
	if music_player.stream != null:
		music_player.play()


# --------------------------
#  Intro sequence
# --------------------------
func _play_intro_sequence() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# 1) Fade from black
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)
	tween.tween_interval(0.2)

	# 2) Title 1 + SFX
	tween.tween_callback(func():
		_play_sfx()
		_rumble(0.6, 0.9, 0.20))
	tween.tween_property(title_layer_1, "modulate:a", 1.0, TITLE_FADE_TIME)
	tween.tween_interval(TITLE_DELAY)
	

	# 3) Title 2 + SFX
	tween.tween_callback(func():
		_play_sfx()
		_rumble(0.6, 0.9, 0.20))
	tween.tween_property(title_layer_2, "modulate:a", 1.0, TITLE_FADE_TIME)
	tween.tween_interval(TITLE_DELAY)

	# 4) Title 3 + SFX
	tween.tween_callback(func():
		_play_sfx()
		_rumble(0.6, 0.9, 0.20))
	tween.tween_property(title_layer_3, "modulate:a", 1.0, TITLE_FADE_TIME)

	# 5) Small pause then music
	tween.tween_interval(MUSIC_DELAY_AFTER_LAST_TITLE)
	tween.tween_callback(_start_music)

	# 6) Fade in buttons
	tween.tween_property(button_container, "modulate:a", 1.0, BUTTON_FADE_TIME)
	tween.tween_callback(func() -> void:
		new_game_button.grab_focus()
	)


# --------------------------
#  Buttons
# --------------------------
func _on_new_game_pressed() -> void:
	_rumble(0.6, 0.9, 0.20)
	if main_scene == null:
		push_error("Main scene not set on MainMenu.")
		return

	GameManager.reset_to_new_game()
	# Optional: immediately write a save file for New Game
	GameManager.save()

	await TransitionManager.change_scene_to_packed_with_fade(main_scene)


func _on_continue_pressed() -> void:
	_rumble(0.6, 0.9, 0.20)
	if main_scene == null:
		push_error("Main scene not set on MainMenu.")
		return

	# Try to load the save file. If it fails, do nothing.
	if not GameManager.load():
		print("No valid save file to continue from.")
		return

	await TransitionManager.change_scene_to_packed_with_fade(main_scene)


func _on_quit_pressed() -> void:
	_rumble(0.6, 0.9, 0.20)
	get_tree().quit()


func _rumble(weak: float, strong: float, duration: float) -> void:
	# weak / strong in range [0.0, 1.0]
	# duration in seconds
	var pads: Array = Input.get_connected_joypads()
	if pads.is_empty():
		return

	var device_id: int = int(pads[0])
	Input.start_joy_vibration(device_id, weak, strong, duration)
