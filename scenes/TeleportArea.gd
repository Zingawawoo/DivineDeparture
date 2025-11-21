extends Area2D
class_name TeleportArea

@export_file("*.tscn") var target_area_path: String = ""
@export var use_last_saved_position: bool = false

# Optional: a custom spawn offset in the destination area
@export var destination_spawn_name: String = "PlayerSpawn"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	if target_area_path == "":
		push_error("TeleportArea has no target_area_path set.")
		return

	# Remember the area we are going to
	GameManager.last_area_path = target_area_path

	if not use_last_saved_position:
		# Reset position so Main will use the PlayerSpawn of destination
		GameManager.last_player_position = Vector2.ZERO

	# Find the Main node (add Main to a group in its _ready)
	var main_node: Main = get_tree().get_first_node_in_group("main") as Main
	if main_node == null:
		push_error("No 'main' node found in scene tree.")
		return

	await HUD.fade_to_black(0.5).finished
	main_node.load_area_external(target_area_path)
	await HUD.fade_from_black(0.5).finished
