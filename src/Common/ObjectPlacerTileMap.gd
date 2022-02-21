"""
Class for spawning game objects using a TileMap.
"""
extends TileMap

var _player_folder_name := "PlayerStart"
var _pickups_folder_name := "Pickups"
var _enemies_folder_name := "Enemies"

var _player_tile_name := "player_start"
var _mine_tile_name := "mine"
var _fragment_tile_name := "mineral_fragment"
var _hammer_fish_tile_name := "hammer_fish"

var _objects_dictionary = {
	_player_tile_name: "res://src/Player/PlayerKinematic.tscn",
	_mine_tile_name: "res://src/Enemies/Mine.tscn",
	_fragment_tile_name: "res://src/Pickups/Fragment.tscn",
	_hammer_fish_tile_name: "res://src/Enemies/HammerFish.tscn",
}


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PARENTED:
			var parent = get_parent()
			parent.connect("ready", self, "_on_parent_ready")


func _ready() -> void:
	# This TileMap's tile graphics are only handy in the editor,
	# therefore we must hide it when running the game
	hide()


func place_objects() -> void:
	for cell in get_used_cells():
		var id = get_cellv(cell)
		var type = tile_set.tile_get_name(id)
		var region = tile_set.tile_get_region(id)
		var pos = map_to_world(cell) + region.size / 2

		var folder_name: String
		match type:
			_player_tile_name:
				folder_name = _player_folder_name
			_mine_tile_name:
				folder_name = _enemies_folder_name
			_fragment_tile_name:
				folder_name = _pickups_folder_name
			_hammer_fish_tile_name:
				folder_name = _enemies_folder_name

		var node_path = _objects_dictionary.get(type)
		if node_path:
			var scene: PackedScene = load(node_path)
			var instance: Node2D = scene.instance()
			instance.position = pos

			var parent = get_parent()
			var folder = parent.get_node(folder_name)
			folder.add_child(instance)


func prepare_folder_nodes() -> void:
	var parent_node: Node = get_parent()
	if !parent_node:
		print("ERROR: Parent object doesn't exist!")
		return

	var playerFolder := parent_node.has_node(_player_folder_name)
	if !playerFolder:
		create_folder_node(_player_folder_name, parent_node)

	var pickupsFolder := parent_node.has_node(_pickups_folder_name)
	if !pickupsFolder:
		create_folder_node(_pickups_folder_name, parent_node)

	var enemiesFolder := parent_node.has_node(_enemies_folder_name)
	if !enemiesFolder:
		create_folder_node(_enemies_folder_name, parent_node)


func create_folder_node(folder_name: String, parent_node: Node) -> void:
	var folder := Node.new()
	folder.name = folder_name
	parent_node.add_child(folder)


func _on_parent_ready() -> void:
	prepare_folder_nodes()
	place_objects()
