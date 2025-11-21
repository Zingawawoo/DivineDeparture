extends Area2D
class_name Checkpoint

@export var checkpoint_id: String = ""
@export var auto_save: bool = true

var _activated: bool = false


func _ready() -> void:
	# Make sure this Area2D detects the player.
	# In the editor, also ensure:
	#   - monitoring = true
	#   - collision shape exists
	body_entered.connect(_on_body_entered)
	add_to_group("checkpoint")


func _on_body_entered(body: Node2D) -> void:
	# Only react to the player.
	if not body.is_in_group("player"):
		return

	# Avoid doing work twice if the player stands in the same checkpoint.
	if _activated:
		return

	_activate_checkpoint()


func _activate_checkpoint() -> void:
	_activated = true

	# Remember which checkpoint this is (for debug / UI if you want).
	GameManager.current_checkpoint_id = checkpoint_id

	# Store where to respawn: this scene and this position.
	GameManager.last_player_position = global_position

	# The current area path is already stored by Main.gd when it loads the area
	# via GameManager.last_area_path = path
	# so we do not need to touch it here.

	if auto_save:
		var ok: bool = GameManager.save()
		if ok:
			print("Checkpoint activated and saved: ", checkpoint_id, " at ", global_position)
		else:
			print("Failed to save at checkpoint: ", checkpoint_id)
