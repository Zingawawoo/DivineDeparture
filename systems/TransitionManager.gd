extends Node

@export var default_duration: float = 0.6

# Helper: fade to black using HUD
func _fade_to_black(duration: float) -> Tween:
	var d: float = duration
	if d <= 0.0:
		d = default_duration

	var tween: Tween = HUD.fade_to_black(d)
	return tween

# Helper: fade from black using HUD
func _fade_from_black(duration: float) -> Tween:
	var d: float = duration
	if d <= 0.0:
		d = default_duration

	var tween: Tween = HUD.fade_from_black(d)
	return tween

# Top-level scenes: change by PackedScene with fade
func change_scene_to_packed_with_fade(scene: PackedScene, duration: float = -1.0) -> void:
	var d: float = duration
	if d <= 0.0:
		d = default_duration

	var t1: Tween = _fade_to_black(d)
	await t1.finished

	get_tree().change_scene_to_packed(scene)

	var t2: Tween = _fade_from_black(d)
	await t2.finished

# Top-level scenes: change by path with fade
func change_scene_to_file_with_fade(path: String, duration: float = -1.0) -> void:
	var d: float = duration
	if d <= 0.0:
		d = default_duration

	var t1: Tween = _fade_to_black(d)
	await t1.finished

	get_tree().change_scene_to_file(path)

	var t2: Tween = _fade_from_black(d)
	await t2.finished
