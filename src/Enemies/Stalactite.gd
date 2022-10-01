extends KinematicBody2D

onready var SpriteNode := $Sprite
onready var PlayerDetectorLeft := $PlayerDetectorLeft
onready var PlayerDetectorRight := $PlayerDetectorRight
onready var ShakeFrequency := $ShakeFrequency
onready var ShakeDuration := $ShakeDuration
onready var ShakeTween := $ShakeTween
onready var Hitbox := $HitBox
onready var VisibilityEnablerNode := $VisibilityEnabler2D


enum States { IDLE, SHAKING, FALLING, ON_GROUND }
var _state: int = States.IDLE

var _shake_sfx_path := "res://assets/sfx/stalactiteShake3.wav"
var _fall_sfx_path := "res://assets/sfx/stalactiteFall.wav"
var _stuck_sfx_path := "res://assets/sfx/stalactiteStuck.wav"

# How much will the sprite move from center position when shaking, in pixels
var _shake_offset := 3.0
# Number of "shakes" per second
var _shake_frequency := 30.0

var _acceleration := 100.0
var _max_speed := 150.0
var _velocity := Vector2.ZERO

var _damage := 5


func _ready() -> void:
	ShakeFrequency.wait_time = 1 / _shake_frequency


func _physics_process(delta: float) -> void:
	match(_state):
		States.IDLE:
			idle_state(delta)
			return
		States.FALLING:
			falling_state(delta)


# Just checks for player
func idle_state(delta: float) -> void:
	if !PlayerDetectorLeft.is_colliding() and !PlayerDetectorRight.is_colliding():
		return

	var left_collider = PlayerDetectorLeft.get_collider()
	var right_collider = PlayerDetectorRight.get_collider()

	var player_collider = null
	if left_collider is GameActor:
		player_collider = left_collider
	if right_collider is GameActor:
		player_collider = right_collider

	if player_collider:
		start_shaking()


func falling_state(delta: float) -> void:
	_velocity += Vector2(0.0, _acceleration * delta)
	_velocity.y = clamp(_velocity.y, 0.0, _max_speed)
	_velocity = move_and_slide(_velocity, Vector2.UP)

	if is_on_floor():
		AudioStreamManager2D.play_sound(_stuck_sfx_path, self)
		_state = States.ON_GROUND
		Hitbox.set_deferred("monitoring", false)
		VisibilityEnablerNode.set_enabler(VisibilityEnabler2D.ENABLER_PARENT_PHYSICS_PROCESS, true)


func start_shaking() -> void:
	AudioStreamManager2D.play_sound(_shake_sfx_path, self)
	_state = States.SHAKING
	_new_shake()

	ShakeFrequency.start()
	ShakeDuration.start()


func _new_shake(is_final: bool = false):
	var new_sprite_position = Vector2.ZERO
	if !is_final:
		# Setting the targer for tween interpolation
		if !SpriteNode.position.x:
			new_sprite_position = Vector2(_shake_offset, 0.0)
		else:
			new_sprite_position = Vector2(_shake_offset * sign(SpriteNode.position.x) * -1.0, 0.0)

	ShakeTween.interpolate_property(
		SpriteNode,
		"position",
		SpriteNode.position,
		new_sprite_position,
		ShakeFrequency.wait_time,
		Tween.TRANS_SINE,
		Tween.EASE_IN_OUT
	)

	ShakeTween.start()


func _on_ShakeFrequency_timeout() -> void:
	_new_shake()


func _on_ShakeDuration_timeout() -> void:
	AudioStreamManager2D.play_sound(_fall_sfx_path, self)
	
	ShakeFrequency.stop()
	_new_shake(true)
	_state = States.FALLING
	
	VisibilityEnablerNode.set_enabler(VisibilityEnabler2D.ENABLER_PARENT_PHYSICS_PROCESS, false)
	Hitbox.set_deferred("monitoring", true)


func _on_HitBox_area_entered(area: Area2D) -> void:
	var collision_body = area.owner as GameActor
	collision_body.propagate_effects({
				Enums.Effects.DAMAGE: _damage
				})
