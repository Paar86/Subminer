extends Node

var _bubble_small_scene := preload("res://src/Common/Bubbles/BubbleSmall.tscn")
var _bubble_medium_scene := preload("res://src/Common/Bubbles/BubbleMedium.tscn")
var _bubble_big_scene := preload("res://src/Common/Bubbles/BubbleBig.tscn")

var _bubbles_weights := {
	_bubble_small_scene: 80.0,
	_bubble_medium_scene: 20.0,
	_bubble_big_scene: 0.0
}

var _cumulative_weight = 0.0
var _rnd_generator := RandomNumberGenerator.new()


func generate_bubble_to_position(
		global_position: Vector2,
		parent_node: Node
):
	var bubble := _pick_random_bubble()
	bubble.global_position = global_position
	parent_node.call_deferred("add_child", bubble)


func generate_bubbles_to_rect(
		global_position: Vector2,
		rect_extents_x: float,
		rect_extents_y: float,
		parent_node: Node,
		bubbles_count: int
):
	var rect_origin = Vector2(global_position.x - rect_extents_x,
							global_position.y - rect_extents_y)

	var rect_end = Vector2(global_position.x + rect_extents_x,
							global_position.y + rect_extents_y)

	for i in range(bubbles_count):
		var random_x = _rnd_generator.randf_range(rect_origin.x, rect_end.x)
		var random_y = _rnd_generator.randf_range(rect_origin.y, rect_end.y)
		generate_bubble_to_position(Vector2(random_x, random_y),parent_node)


func generate_bubbles_with_delay(
	emittor_object: Node2D,
	parent_node: Node,
	bubbles_count: int,
	delay: float
):
	for i in bubbles_count:
		if !emittor_object || !parent_node:
			return

		generate_bubble_to_position(emittor_object.global_position, parent_node)
		yield(get_tree().create_timer(delay), "timeout")


func _ready() -> void:
	_rnd_generator.randomize()

	for bubble_key in _bubbles_weights:
		_cumulative_weight += _bubbles_weights[bubble_key]


func generate_bubbles_in_rect_with_delay(
	emittor_object: Node2D,
	rect_extents_x: float,
	rect_extents_y: float,
	parent_node: Node,
	bubbles_count: int,
	delay: float
):
	for i in bubbles_count:
		if !is_instance_valid(emittor_object) || !is_instance_valid(parent_node):
			return

		generate_bubbles_to_rect(
			emittor_object.global_position,
			rect_extents_x,
			rect_extents_y,
			parent_node,
			1
		)
		yield(get_tree().create_timer(delay), "timeout")

func _pick_random_bubble() -> Node2D:
	var local_cumul = _cumulative_weight
	var random_value: float = _rnd_generator.randf() * _cumulative_weight

	if _bubbles_weights.size() > 1:
		for bubble_key in _bubbles_weights:
			local_cumul -= _bubbles_weights[bubble_key]
			if random_value >= local_cumul:
				return bubble_key.instance()

	return _bubbles_weights.values()[0].instance()
