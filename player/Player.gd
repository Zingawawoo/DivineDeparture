extends CharacterBody2D
class_name Player

const MOVE_THRESHOLD := 20.0

@onready var attack_pivot: Node2D = $AttackPivot
@onready var attack_area: Area2D = $AttackPivot/AttackArea
@onready var attack_shape: CollisionShape2D = $AttackPivot/AttackArea/CollisionShape2D
@onready var Anim: AnimatedSprite2D = $Anim

# =========================================================
#  Dialogue / input lock
# =========================================================
var input_enabled: bool = true

func reset_health() -> void:
	hp = max_hp
	_hurt_invuln_left = 0.0
	GameManager.player_hp = hp
	if HUD != null:
		_sync_health_to_hud()
		
		
func set_input_enabled(enabled: bool) -> void:
	input_enabled = enabled

	if not enabled:
		# Stop motion
		_input_dir = Vector2.ZERO
		_velocity = Vector2.ZERO
		velocity = Vector2.ZERO

		# Cancel attack state completely
		_is_attacking = false
		_attack_state = AttackState.IDLE
		_attack_timer = 0.0
		_attack_cooldown_left = 0.0
		_set_attack_active(false)

		# Cancel dash state
		_state = MoveState.NORMAL
		_dash_time_left = 0.0
		_dash_cooldown_left = 0.0
		is_invulnerable = false

		# Cancel block / parry
		_is_blocking = false
		_is_parrying = false
		_parry_timer = 0.0
		_parry_cooldown_left = 0.0

		# Force idle anim from current facing
		_play_anim("idle")


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

func _start_hurt_flash() -> void:
	if Anim == null:
		return

	# Increment id so older flashes know they're outdated
	_hurt_flash_id += 1
	var my_id: int = _hurt_flash_id

	# Make him bright
	Anim.modulate = Color(1.4, 1.4, 1.4)  # slightly toned down from 1.8 if you want

	var t: SceneTreeTimer = get_tree().create_timer(hurt_flash_duration)
	await t.timeout

	# Only the *latest* flash is allowed to restore the color
	if my_id == _hurt_flash_id:
		Anim.modulate = _base_modulate


# -------------------------------
# Tuning — Movement & Dash
# -------------------------------
@export var walk_speed: float = 50.0        
@export var acceleration: float = 3000.0
@export var friction: float = 3000.0

@export var dash_speed_multiplier: float = 3.0   # ≈ 3x walk speed
@export var dash_duration: float = 0.15          
@export var dash_cooldown: float = 0.50    


# -------------------------------
# Sword Attack (3-phase swing)
# -------------------------------
@export var attack_windup: float = 0.06      # time before the hitbox becomes active
@export var attack_active: float = 0.08      # time the hitbox is active
@export var attack_recover: float = 0.06     # end-lag after the strike
@export var attack_cooldown: float = 0.20    # minimal delay before next attack
@export var attack_damage: int = 1           # base damage; used later when we add enemies
@export var attack_knockback: float = 140.0  # push strength; used later
@export var hurt_invuln_time: float = 0.4        # time you are invulnerable after being hit
@export var hurt_knockback: float = 130.0        # how hard the player gets pushed back on hit
@export var parry_knockback: float = 260.0       # how hard enemies get pushed back on a perfect parry
@export var max_hp: int = 5
@export var hurt_flash_duration: float = 0.1

enum AttackState { IDLE, WINDUP, ACTIVE, RECOVER }

var _attack_state: int = AttackState.IDLE
var _attack_timer: float = 0.0
var _attack_cooldown_left: float = 0.0
var _is_attacking: bool = false

var _base_modulate: Color = Color(1, 1, 1, 1)
var _hurt_flash_id: int = 0


# -------------------------------
# Block / Parry
# -------------------------------
@export var block_damage_reduction: float = 0.8   # 80% damage reduction during hold
@export var parry_window: float = 0.12            # seconds at block start for perfect parry
@export var parry_cooldown: float = 0.6           # time before you can parry again

var _is_blocking: bool = false
var _is_parrying: bool = false
var _parry_timer: float = 0.0
var _parry_cooldown_left: float = 0.0


@onready var sfx_attack: AudioStreamPlayer2D = $SFX_Attack
@onready var sfx_dash: AudioStreamPlayer2D = $SFX_Dash
@onready var sfx_block: AudioStreamPlayer2D = $SFX_Block
@onready var sfx_parry: AudioStreamPlayer2D = $SFX_Parry
@onready var sfx_hurt: AudioStreamPlayer2D = $SFX_Hurt
@onready var sfx_walk: AudioStreamPlayer2D = $SFX_Walk

# -------------------------------
# Internal State
# -------------------------------
enum MoveState { NORMAL, DASHING }

var _state: int = MoveState.NORMAL
var _input_dir: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _facing: Vector2 = Vector2.DOWN

# Dash bookkeeping
var _dash_time_left: float = 0.0
var _dash_cooldown_left: float = 0.0
var _dash_dir: Vector2 = Vector2.ZERO

# Combat-related flags (will be used later by hit logic)
var is_invulnerable: bool = false    # set true during dash window; consumed by damage code later
var _hurt_invuln_left: float = 0.0   # post-hit invulnerability timer
var hp: int = 0                      # current player health


func _ready() -> void:
	# Register as the player so other systems (Dialogues, enemies) can find us
	add_to_group("player")
	set_physics_process(true)

	# Sync from GameManager
	max_hp = GameManager.player_max_hp
	hp = GameManager.player_hp
	
	_sync_health_to_hud()
	
	_base_modulate = Anim.modulate
	var player = get_tree().get_first_node_in_group("player")
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("set_player_reference"):
			enemy.set_player_reference(player)

	# Update HUD with current values
	if HUD != null:
		HUD.update_hearts(hp, max_hp)
		HUD.set_currency(GameManager.currency)
		
		
func _physics_process(delta: float) -> void:
	if not input_enabled:
		# Hard-lock movement AND animation every frame while disabled
		_input_dir = Vector2.ZERO
		_velocity = Vector2.ZERO
		velocity = Vector2.ZERO

		_play_anim("idle")  # keep forcing idle in case something else tried to play

		move_and_slide()
		global_position = global_position.round()
		return
		
	_update_timers(delta)
	_read_move_input()
	_handle_dash_input()
	_handle_block_input(delta)
	_handle_attack_input()
	_update_attack_state(delta)
	
	
	if _state == MoveState.DASHING:
		_update_dashing_physics(delta)
		_play_anim("dash")
	else:
		_update_walking_physics(delta)
	if _is_blocking:
		_play_anim("block")
	elif _is_attacking:
		# Attack anim handled by _start_attack()
		pass
	else:
		if _input_dir == Vector2.ZERO:
			_play_anim("idle")
		else:
			_play_anim("walk")
			if not sfx_walk.playing:	
				_play_sfx(sfx_walk)
		
	_update_facing()
	
	if _attack_state == AttackState.WINDUP or _attack_state == AttackState.ACTIVE:
		_velocity = Vector2.ZERO

	velocity = _velocity	
	move_and_slide()
	global_position = global_position.round()
	_update_camera_hint()
	
# ---------------------------------
# Timers & Input
# ---------------------------------
func _update_timers(delta: float) -> void:
	if _dash_cooldown_left > 0.0:
		_dash_cooldown_left = _dash_cooldown_left - delta
		if _dash_cooldown_left < 0.0:
			_dash_cooldown_left = 0.0

	if _state == MoveState.DASHING:
		_dash_time_left = _dash_time_left - delta
		if _dash_time_left <= 0.0:
			_end_dash()
	
	if _hurt_invuln_left > 0.0:
		_hurt_invuln_left = _hurt_invuln_left - delta
	if _hurt_invuln_left < 0.0:
		_hurt_invuln_left = 0.0
		
func _read_move_input() -> void:

	if _is_blocking:
		_input_dir = Vector2.ZERO
		return
	
	var x: float = 0.0
	var y: float = 0.0

	if Input.is_action_pressed("move_left"):
		x = x - 1.0
	if Input.is_action_pressed("move_right"):
		x = x + 1.0
	if Input.is_action_pressed("move_up"):
		y = y - 1.0
	if Input.is_action_pressed("move_down"):
		y = y + 1.0
		
	var v: Vector2 = Vector2(x, y)
	if v.length() > 0.0:
		_input_dir = v.normalized()
	else:
		_input_dir = Vector2.ZERO


func _handle_dash_input() -> void:
	# If combat is disabled, ignore dash
	if not GameManager.combat_enabled:
		return
	# Only start a dash if:
	# - player pressed the dash action this frame
	# - cooldown is ready
	# - not already dashing
	if Input.is_action_just_pressed("dash"):
		if _dash_cooldown_left <= 0.0:
			if _state != MoveState.DASHING:
				_start_dash()

func _handle_block_input(delta: float) -> void:
	# If combat is disabled, ignore block / parry
	if not GameManager.combat_enabled:
		_is_blocking = false
		_is_parrying = false
		return
	# Cooldown timer prevents parry spam
	if _parry_cooldown_left > 0.0:
		_parry_cooldown_left = _parry_cooldown_left - delta
		if _parry_cooldown_left < 0.0:
			_parry_cooldown_left = 0.0

	# If already dashing, ignore block input
	if _state == MoveState.DASHING:
		return

	# Handle starting block
	if Input.is_action_just_pressed("block"):
		_start_block()

	# Handle ending block
	if Input.is_action_just_released("block"):
		_end_block()

	# If currently parrying, count down the parry window timer
	if _is_parrying:
		_parry_timer = _parry_timer - delta
		if _parry_timer <= 0.0:
			# End parry window, continue normal block if still held
			_is_parrying = false

func _update_walking_physics(delta: float) -> void:
	var target_velocity: Vector2 = _input_dir * walk_speed
	
	var changing_direction : bool = false
	if _input_dir.dot(_velocity) < 0.0:
		changing_direction = true
		
	if _input_dir != Vector2.ZERO:
		# Accelerate toward target
		_velocity = _velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# Apply friction when no input
		_velocity = _velocity.move_toward(Vector2.ZERO, friction * delta)
		
	# Extra help when reversing direction
	if changing_direction:
		_velocity = _velocity.move_toward(target_velocity, (acceleration + friction) * delta)


func _start_dash() -> void:
	if not input_enabled:
		return
	GameEvents.emit_signal("player_dash")
	# Choose dash direction:
	# - Prefer current input direction if any
	# - Otherwise use last facing direction (so you can dash from standstill)
	var dir: Vector2 = _input_dir
	if dir == Vector2.ZERO:
		dir = _facing
	if dir == Vector2.ZERO:
		# If we somehow still have zero (e.g., at very start), default upward to avoid NaNs
		dir = Vector2.UP
	_dash_dir = dir.normalized()

	_state = MoveState.DASHING
	_dash_time_left = dash_duration
	_dash_cooldown_left = dash_cooldown
	is_invulnerable = true

	# Immediate burst velocity set; physics step will keep it for dash_duration
	var dash_speed: float = walk_speed * dash_speed_multiplier
	_velocity = _dash_dir * dash_speed

	_play_sfx(sfx_dash)
	_rumble(0.2, 0.5, 0.12)

func _update_dashing_physics(_delta: float) -> void:
	# During dash, keep moving strongly in the locked dash direction
	var dash_speed: float = walk_speed * dash_speed_multiplier
	_velocity = _dash_dir * dash_speed

	
func _end_dash() -> void:
	_state = MoveState.NORMAL
	is_invulnerable = false
	
	GameEvents.emit_signal("player_dash_finished")
	
	
# ---------------------------------
# Block / Parry Actions
# ---------------------------------
func _start_block() -> void:
	if not input_enabled:
		return
		
	if not GameManager.combat_enabled:
		return
		
	GameEvents.emit_signal("player_block")
	if _is_blocking:
		return
	_is_blocking = true

	# Check if parry is available
	if _parry_cooldown_left <= 0.0:
		_is_parrying = true
		_parry_timer = parry_window
		_parry_cooldown_left = parry_cooldown

	# Visual / audio feedback hooks (we'll add these later)
	_play_sfx(sfx_block)

func _end_block() -> void:
	if not _is_blocking:
		return
	
	if _is_parrying:
		GameEvents.emit_signal("player_parry_finished")
	else:
		GameEvents.emit_signal("player_block_finished")
		
	_is_blocking = false
	_is_parrying = false

	

# ---------------------------------
# Attack Input
# ---------------------------------
func _handle_attack_input() -> void:

	# Disable attacking entirely if combat is off
	if not GameManager.combat_enabled:
		return
		
	# Do not start if already attacking, dashing, or blocking
	if _is_attacking:
		return
	if _state == MoveState.DASHING:
		return
	if _is_blocking:
		return
	if _attack_cooldown_left > 0.0:
		return

	if Input.is_action_just_pressed("attack"):
		_start_attack()

# ---------------------------------
# Attack State Machine
# ---------------------------------
func _start_attack() -> void:
	if not input_enabled:
		return
		
	GameEvents.emit_signal("player_attack")
	_is_attacking = true
	_attack_state = AttackState.WINDUP
	_attack_timer = attack_windup
	_attack_cooldown_left = attack_cooldown

	_update_attack_orientation()
	_set_attack_active(false)
	# Hook: play "swing_start" SFX or raise weapon animation later
	_play_anim("attack")
	_play_sfx(sfx_attack)

func _update_attack_state(delta: float) -> void:
	# handle cooldown tick
	if _attack_cooldown_left > 0.0:
		_attack_cooldown_left = _attack_cooldown_left - delta
		if _attack_cooldown_left < 0.0:
			_attack_cooldown_left = 0.0

	if not _is_attacking:
		return

	_attack_timer = _attack_timer - delta
	if _attack_timer > 0.0:
		return

	# Advance phase
	if _attack_state == AttackState.WINDUP:
		_attack_state = AttackState.ACTIVE
		_attack_timer = attack_active
		_update_attack_orientation()
		_set_attack_active(true)
		# Hook: play "slash" SFX, enable flash/trail later
		return

	if _attack_state == AttackState.ACTIVE:
		_attack_state = AttackState.RECOVER
		_attack_timer = attack_recover
		_set_attack_active(false)
		return

	if _attack_state == AttackState.RECOVER:
		_attack_state = AttackState.IDLE
		_is_attacking = false
		_set_attack_active(false)
		GameEvents.emit_signal("player_attack_finished")
		return

func _set_attack_active(active: bool) -> void:
	# Toggle Area2D monitoring for hit detection
	attack_area.monitoring = active
	attack_area.monitorable = active
	
# ---------------------------------
# Facing & Camera hint
# ---------------------------------
func _update_facing() -> void:
	if _input_dir != Vector2.ZERO:
		_facing = _input_dir
		

func _update_attack_orientation() -> void:
	# Decide cardinal facing from _facing vector (no ternaries)
	var dir: Vector2 = _facing
	var rot_deg: float = 0.0
	var pivot_offset: Vector2 = Vector2.ZERO

	var abs_x: float = absf(dir.x)
	var abs_y: float = absf(dir.y)

	if abs_x > abs_y:
		if dir.x > 0.0:
			# facing right
			rot_deg = 0.0
			pivot_offset = Vector2(0.0, 0.0)
		else:
			# facing left
			rot_deg = 180.0
			pivot_offset = Vector2(0.0, 0.0)
	else:
		if dir.y > 0.0:
			# facing down
			rot_deg = 90.0
			pivot_offset = Vector2(0.0, 0.0)
		else:
			# facing up
			rot_deg = -90.0
			pivot_offset = Vector2(0.0, 0.0)

	# Position the pivot slightly forward so the rectangle sits in front of the player
	var forward: Vector2 = dir.normalized()
	if forward == Vector2.ZERO:
		forward = Vector2.DOWN
	var forward_offset: Vector2 = forward * 14.0

	attack_pivot.global_position = global_position + forward_offset + pivot_offset
	attack_pivot.rotation_degrees = rot_deg


func _update_camera_hint() -> void:
	# No-op for now; placeholder if you later want to inform camera about look-ahead.
	pass


func _on_attack_area_body_entered(body: Node2D) -> void:
	
	if _attack_state != AttackState.ACTIVE:
		return
	
	if not body.has_method("apply_hit"):
		return
	
	var dir: Vector2 = _facing
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	dir = dir.normalized()
	
	var dmg: int = attack_damage
	var kb : float = attack_knockback
	
	var hit: Dictionary = {
		"damage": dmg,
		"knockback": kb,
		"direction": dir,
		"source": self
	}
	
	body.call("apply_hit", hit)
	_rumble(0.3, 0.6, 0.10)
	
func apply_hit(hit: Dictionary) -> void:
	# 1) Skip if currently invulnerable (dash or recent damage)
	if is_invulnerable or _hurt_invuln_left > 0.0:
		return

	# 2) Extract hit data safely
	var dmg_value: Variant = hit.get("damage", 1)
	var damage: int = int(dmg_value)

	var kb_value: Variant = hit.get("knockback", hurt_knockback)
	var knockback: float = float(kb_value)

	var dir_value: Variant = hit.get("direction", Vector2.ZERO)
	var dir: Vector2 = Vector2.ZERO
	if dir_value is Vector2:
		dir = dir_value as Vector2

	var source: Node = null
	if hit.has("source") and hit["source"] is Node:
		source = hit["source"] as Node

	# 3) Handle block / parry
	if _is_blocking:
		if _is_parrying:
			# --- PERFECT PARRY ---
			# Push the enemy back instead of taking damage
			_play_sfx(sfx_parry)
			_rumble(0.9, 0.9, 0.12)
			if source != null and source.has_method("apply_hit"):
				var reflect_dir: Vector2 = Vector2.ZERO

				if dir != Vector2.ZERO:
					# Incoming dir is usually enemy -> player; reverse it to push enemy away
					reflect_dir = -dir.normalized()
				elif source is Node2D:
					# Fallback: compute from positions
					reflect_dir = ((source as Node2D).global_position - global_position).normalized()

				var parry_hit: Dictionary = {
					"damage": attack_damage * 2,                            
					"knockback": parry_knockback,
					"direction": reflect_dir,
					"source": self
				}
				source.call("apply_hit", parry_hit)

			# Consume parry window (block can continue if held)
			_is_parrying = false

			# Successful parry: no damage to the player
			return
		else:
			# --- NORMAL BLOCK ---
			# Reduce damage & knockback while blocking
			var reduced: float = float(damage) * (1.0 - block_damage_reduction)
			if reduced < 0.0:
				reduced = 0.0
			damage = int(round(reduced))
			knockback *= (1.0 - block_damage_reduction)  # heavily reduce knockback on block

	# 4) If after block/parry we still have no damage and no knockback, early-out
	if damage <= 0 and knockback <= 0.0:
		return

	# 5) Apply damage
	if damage > 0:
		hp -= damage
		if hp < 0:
			hp = 0
		_hurt_invuln_left = hurt_invuln_time
		_start_hurt_flash()
		_play_sfx(sfx_hurt)
		_rumble(0.6, 0.9, 0.20)

	# 6) Apply knockback to player
	if dir != Vector2.ZERO and knockback > 0.0:
		_velocity += dir.normalized() * knockback
		_state = MoveState.NORMAL  # cancel dash / weird states if we were in them
		
	# 7) Sync with GameManager and HUD
	GameManager.player_hp = hp

	if HUD != null:
		HUD.update_hearts(hp, max_hp)
	if damage > 0:
		hp = hp - damage
		if hp < 0:
			hp = 0
		_hurt_invuln_left = hurt_invuln_time

		if hp <= 0:
			_on_death()
			return
	
func _on_death() -> void:
	# Stop all input and physics
	input_enabled = false
	set_physics_process(false)

	collision_layer = 0
	collision_mask = 0
	Anim.play("death")  # if you make one later
	
	reset_health()

	# Fade out, then change to the DeathScreen scene
	DialogueManager.fade_then(0.5, func() -> void:
		get_tree().change_scene_to_file("res://ui/DeathScreen.tscn")
	)


func _play_sfx(player: AudioStreamPlayer2D) -> void:
	if player == null:
		return
	if player.stream == null:
		return

	# Stop if already playing so rapid presses do not layer too loud
	if player.playing:
		player.stop()

	player.play()

func _rumble(weak: float, strong: float, duration: float) -> void:
	# weak / strong in range [0.0, 1.0]
	# duration in seconds
	var pads: Array = Input.get_connected_joypads()
	if pads.is_empty():
		return

	var device_id: int = int(pads[0])
	Input.start_joy_vibration(device_id, weak, strong, duration)


func _stop_rumble() -> void:
	var pads: Array = Input.get_connected_joypads()
	if pads.is_empty():
		return
	var device_id: int = int(pads[0])
	Input.stop_joy_vibration(device_id)


func _sync_health_to_hud() -> void:
	GameManager.player_hp = hp
	GameManager.player_max_hp = max_hp

	if HUD != null:
		HUD.update_hearts(hp, max_hp)
