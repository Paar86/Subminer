extends AnimatedSprite

var push_vector := Vector2.UP

onready var HitEffect := $HitEffect
onready var HitEffectTimer := $HitEffectTimer
onready var _shock_sfx_path := "res://assets/sfx/shock.wav"

var _damage := 2
var _push_strength := 60.0


func flip_horizontally() -> void:
#	We must take into a condsideration local transform (when x axis is in fact y)
	if rotation:
		scale.y *= -1.0
		return

	scale.x *= -1.0


func flip_vertically() -> void:
	if rotation:
		scale.x *= -1.0
		return

	scale.y *= -1.0


func transpose() -> void:
	var transform_x: Vector2 = transform.x
	transform.x = transform.y
	transform.y = transform_x


func _ready() -> void:
	HitEffect.hide()


func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		area.owner.propagate_effects({Enums.Effects.DAMAGE: _damage})
		AudioStreamManager.play_sound(_shock_sfx_path)
		HitEffectTimer.start()
		HitEffect.show()
		HitEffect.playing = true


func _on_HitEffectTimer_timeout() -> void:
	HitEffect.hide()
	HitEffect.playing = false
