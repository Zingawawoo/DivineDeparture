extends CharacterBody2D
class_name EnemyBase

@export var max_hp: int = 3
@export var move_speed: float = 90.0
@export var chase_radius: float = 100.0
@export var stop_radius: float = 29.0
@export var attack_range: float = 29.0

@export var knockback_decay: float = 2200.0
@export var flash_duration: float = 0.1
@export var telegraph_duration: float = 0.3

@export var attack_damage: int = 1
@export var attack_knockback: float = 160.0
@export var attack_cooldown: float = 1.4

var _hp: int = 0
var _knockback_velocity: Vector2 = Vector2.ZERO
var _is_hurt: bool = false
var _player: Node2D = null
var _facing: Vector2 = Vector2.DOWN


var _attack_cooldown_left: float = 0.0
var _is_attacking: bool = false

@onready var Anim: AnimatedSprite2D = $Anim
@onready var hurt_timer: Timer = $HurtTimer
@onready var telegraph_timer: Timer = $TelegraphTimer

func _ready() -> void:
	_hp = max_hp
	
	if Anim != null:
		Anim.animation_finished.connect(_on_anim_finished)
	
	_find_player()
	add_to_group("battle_enemy")

func _physics_process(delta: float) -> void:
	if _hp <= 0:
		return
	
	_find_player()

	# Attack cooldown timer
	if _attack_cooldown_left > 0.0:
		_attack_cooldown_left -= delta
		if _attack_cooldown_left < 0.0:
			_attack_cooldown_left = 0.0

	# Decay knockback
	if _knockback_velocity.length() > 0.0:
		_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)

	var move_vec: Vector2 = Vector2.ZERO

	if _player != null and not _is_hurt:
		var to_player: Vector2 = _player.global_position - global_position
		var dist: float = to_player.length()

		if dist > stop_radius and dist < chase_radius:
			var direction: Vector2 = to_player.normalized()
			move_vec = direction * move_speed
		else:
			move_vec = Vector2.ZERO

		if dist <= attack_range and _attack_cooldown_left <= 0.0 and not _is_attacking:
			var dir_to_player: Vector2 = Vector2.ZERO
			dir_to_player = to_player.normalized()
			_do_attack(dir_to_player)



	var combined: Vector2 = move_vec + _knockback_velocity
	velocity = combined

	_update_facing()

	# Only drive idle/walk if NOT attacking (so we don't overwrite attack anim)
	if not _is_hurt and not _is_attacking:
		if move_vec.length() > 0.1:
			_play_anim("walk")
		else:
			_play_anim("idle")

	move_and_slide()

func _do_attack(direction: Vector2) -> void:
	if _player == null:
		return

	_is_attacking = true
	_attack_cooldown_left = attack_cooldown

	var dir: Vector2 = direction
	if dir == Vector2.ZERO and _player != null:
		dir = (_player.global_position - global_position).normalized()

	var hit: Dictionary = {
		"damage": attack_damage,
		"knockback": attack_knockback,
		"direction": dir,
		"source": self
	}
	_play_anim("attack")
	telegraph_timer.start(telegraph_duration)
	await telegraph_timer.timeout
	if _player.has_method("apply_hit"):
		_player.call("apply_hit", hit)

	

func apply_hit(hit: Dictionary) -> void:
	var dmg_value: Variant = hit.get("damage", 1)
	var damage: int = int(dmg_value)

	var kb_value: Variant = hit.get("knockback", 100)
	var knockback: float = float(kb_value)

	var dir_value: Variant = hit.get("direction", Vector2.ZERO)
	var dir: Vector2 = Vector2.ZERO
	if dir_value is Vector2:
		dir = dir_value as Vector2

	_hp = _hp - damage
	if _hp < 0:
		_hp = 0

	if dir != Vector2.ZERO:
		_knockback_velocity = dir.normalized() * knockback

	_start_flash()

	_is_hurt = true
	hurt_timer.start(flash_duration)
	await hurt_timer.timeout
	_is_hurt = false
	
	if _hp <= 0:
		_die()


func _update_facing() -> void:
	var dir: Vector2 = velocity

	# If we're not moving, face the player instead (if there is one)
	if dir == Vector2.ZERO and _player != null:
		dir = _player.global_position - global_position

	if dir != Vector2.ZERO:
		_facing = dir.normalized()

func _get_facing_suffix() -> String:
	var dir: Vector2 = _facing
	var abs_x: float = absf(dir.x)
	var abs_y: float = absf(dir.y)

	if abs_x > abs_y:
		if dir.x > 0.0:
			return "right"
		else:
			return "left"
	else:
		if dir.y > 0.0:
			return "down"
		else:
			return "up"

func _play_anim(base_name: String) -> void:
	var suffix: String = _get_facing_suffix()
	var anim_name: String = base_name + "_" + suffix
	if Anim.animation != anim_name:
		Anim.play(anim_name)

func _start_flash() -> void:
	var original: Color = Anim.modulate
	Anim.modulate = Color(1.8, 1.8, 1.8)
	var t: SceneTreeTimer = get_tree().create_timer(flash_duration)
	await t.timeout
	Anim.modulate = original

func _die() -> void:
	queue_free()

func _find_player() -> void:
	var players: Array = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var node: Node = players[0]
		if node is Node2D:
			_player = node as Node2D

func set_player_reference(p: Node2D) -> void:
	_player = p

func _on_anim_finished() -> void:
	if Anim == null:
		return

	if Anim.animation.begins_with("attack"):
		_is_attacking = false
		_play_anim("idle")
