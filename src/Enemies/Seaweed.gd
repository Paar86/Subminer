extends Sprite

var push_vector := Vector2.UP

var _damage := 2
var _push_strength := 60.0


func _on_Hitbox_area_entered(area: Area2D) -> void:
	if area.owner is GameActor:
		area.owner.propagate_effects({Enums.Effects.DAMAGE: _damage})
