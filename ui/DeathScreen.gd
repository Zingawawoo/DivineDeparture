extends Control
class_name DeathScreen

@export var main_scene_path: String = "res://scenes/main.tscn"
@export var main_menu_path: String = "res://menus/MainMenu.tscn"

@onready var respawn_button: Button = $CenterContainer/VBoxContainer/RespawnButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	# Wire up buttons
	respawn_button.pressed.connect(_on_respawn_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Make keyboard/gamepad focus start on Respawn
	respawn_button.grab_focus()


func _on_respawn_pressed() -> void:
	# Just go back to the main game scene.
	# Main.gd will read GameManager.last_area_path and last_player_position
	# and spawn you at the last checkpoint.
	get_tree().change_scene_to_file(main_scene_path)


func _on_quit_pressed() -> void:
	# Back to main menu (or quit the game if you prefer).
	get_tree().change_scene_to_file(main_menu_path)
	# If you want to completely exit instead:
	# get_tree().quit()
