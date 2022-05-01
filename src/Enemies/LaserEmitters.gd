tool
extends Node2D

# How long will the beam be active when fired
export var beam_longetivity := 2.0
# Delay after which the beam begins to be active
export var beam_delay := 0.0
# How long the beam has to be inactive before activating again
export var beam_interval := 3.0

onready var LaserLine := $LaserLine
onready var LaserRayCast := $LaserRayCast
onready var EmitterA := $EmitterA
onready var EmitterB := $EmitterB
onready var EmitterPointA := $EmitterA/EmitterPoint
onready var EmitterPointB := $EmitterB/EmitterPoint

# Timers
onready var IntervalTimer := $IntervalTimer
onready var DelayTimer := $DelayTimer
onready var PrepareTimer := $PrepareTimer
onready var ShootTimer := $ShootTimer


func _ready() -> void:
	if Engine.editor_hint:
		return
	
	set_physics_process(false)
	
	LaserRayCast.position = EmitterA.position
	LaserRayCast.cast_to = EmitterB.position - LaserRayCast.position
	
	LaserLine.points[0] = $EmitterA.position + EmitterPointA.position
	LaserLine.points[1] = $EmitterB.position + EmitterPointB.position
	
	IntervalTimer.wait_time = beam_interval
	ShootTimer.wait_time = beam_longetivity
	
	LaserLine.hide()
	
	if beam_delay > 0.0:
		DelayTimer.wait_time = beam_delay
		DelayTimer.start()
	else:
		set_physics_process(true)
		IntervalTimer.start()


func _process(delta: float) -> void:
	if Engine.editor_hint:
		var emitter_a_point = get_node("EmitterA/EmitterPoint")
		var emitter_b_point = get_node("EmitterB/EmitterPoint")
		get_node("LaserLine").points[0] = get_node("EmitterA").position + emitter_a_point.position
		get_node("LaserLine").points[1] = get_node("EmitterB").position + emitter_b_point.position


func _physics_process(delta: float) -> void:
	if Engine.editor_hint:
		return
		
	if LaserRayCast.is_colliding():
		var collider = LaserRayCast.get_collider()
		if collider.owner is GameActor:
			collider.owner.propagate_effects({Enums.Effects.DAMAGE: 2})


func _on_DelayTimer_timeout() -> void:
	set_physics_process(true)
	IntervalTimer.start()


func _on_IntervalTimer_timeout() -> void:
	# Telegraph a beam effect
	PrepareTimer.start()


func _on_PrepareTimer_timeout() -> void:
	# Hide telegraphing effect and activate the beam itself
	LaserRayCast.set_deferred("enabled", true)
	LaserLine.show()
	ShootTimer.start()


func _on_ShootTimer_timeout() -> void:
	# Disable the beam and hide all effects
	# Begin another interval
	LaserRayCast.set_deferred("enabled", false)
	LaserLine.hide()
	IntervalTimer.start()
