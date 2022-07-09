extends Node

var _bubble_small_scene := preload("res://src/Common/Bubbles/BubbleSmall.tscn")
var _bubble_medium_scene := preload("res://src/Common/Bubbles/BubbleMedium.tscn")
var _bubble_big_scene := preload("res://src/Common/Bubbles/BubbleBig.tscn")


func generate_bubble_to_position(
		global_position: Vector2,
		parent_node: Node
):
	pass


func generate_bubbles_to_rect(
		global_position: Vector2,
		rect_extents: float,
		parent_node: Node,
		bubbles_count: int
):
	pass
