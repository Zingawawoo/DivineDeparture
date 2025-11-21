extends Node
class_name Main

@onready var current_area: Node = $CurrentArea
@onready var camera: Camera2D = $Camera2D

@export var first_area_path: String = "res://levels/Intro_House.tscn"
@export var player_scene: PackedScene = preload("res://player/Player.tscn")

var player: Player = null


func _ready() -> void:
	# So TeleportArea can find this node
	add_to_group("main")
	
	GameManager.set_combat_enabled(false)  # overworld = no combat
	
	var area_path: String = first_area_path
	if GameManager.last_area_path != "":
		area_path = GameManager.last_area_path

	_load_area(area_path)
	
	player = get_tree().get_first_node_in_group("player")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("set_player_reference"):
			enemy.set_player_reference(player)

func _load_area(path: String) -> void:
	_clear_current_area()

	var area_scene: PackedScene = load(path)
	if area_scene == null:
		push_error("Failed to load area: " + path)
		return

	var area_instance: Node = area_scene.instantiate()
	current_area.add_child(area_instance)

	_spawn_or_reuse_player(area_instance)
	GameManager.last_area_path = path


func _clear_current_area() -> void:
	for child: Node in current_area.get_children():
		child.queue_free()


func _spawn_or_reuse_player(area_root: Node) -> void:
	# 1) Find the World node inside the loaded area
	var world: Node2D = area_root.get_node_or_null("World") as Node2D
	if world == null:
		push_error("Area has no 'World' node – cannot Y-sort player.")
		return

	# 2) Create player once, then reuse it between areas
	if player == null:
		var p: Node = player_scene.instantiate()
		if p is Player:
			player = p
		else:
			push_error("Player scene does not provide a Player class.")
			return
		world.add_child(player)  # first time
	else:
		# Reparent existing player into the new world's hierarchy
		if player.get_parent() != world:
			var old_global_pos: Vector2 = player.global_position
			player.get_parent().remove_child(player)
			world.add_child(player)
			player.global_position = old_global_pos

	# 3) Find spawn point inside this area (search recursively)
	var spawn: Node2D = _find_spawn(area_root)

	if spawn != null:
		if GameManager.last_player_position != Vector2.ZERO:
			player.global_position = GameManager.last_player_position
		else:
			player.global_position = spawn.global_position
	else:
		if GameManager.last_player_position != Vector2.ZERO:
			player.global_position = GameManager.last_player_position
		else:
			player.global_position = Vector2.ZERO

		player.reset_health()

	# 4) Initial camera placement
	camera.make_current()
	camera.global_position = player.global_position


func _process(delta: float) -> void:
	if player == null:
		return

	var difference: Vector2 = player.global_position - camera.global_position
	var distance: float = difference.length()
	var follow_speed: float = 5.0
	var radius: float = 50.0

	if distance <= 0.0:
		return

	if distance > radius:
		var direction: Vector2 = difference.normalized()
		var move: float = (distance - radius) * follow_speed * delta
		camera.global_position = camera.global_position + direction * move


func _find_spawn(area_root: Node) -> Node2D:
	# Looks anywhere in the area for a node named "PlayerSpawn"
	var found: Node = area_root.find_child("PlayerSpawn", true, false)
	if found is Node2D:
		return found
	return null


func load_area_external(path: String) -> void:
	# Called from TeleportArea and other systems
	_load_area(path)
