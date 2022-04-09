extends Node

export var level_name := "default_name"
export var minerals_goal := 50

onready var ObjectsTilemap := $ObjectsTileMap

var _player_folder_name := "PlayerStart"
var _pickups_folder_name := "Pickups"
var _enemies_folder_name := "Enemies"

var _player_tile_name := "player_start"
var _mine_tile_name := "mine"
var _mineral_ground_name := "mineral_ground"
var _fragment_tile_name := "mineral_fragment"
var _hammer_fish_tile_name := "hammer_fish"
var _seaweed_tile_name := "seaweed"

var _objects_dictionary = {
	_player_tile_name: "res://src/Player/PlayerKinematic.tscn",
	_mine_tile_name: "res://src/Enemies/Mine.tscn",
	_mineral_ground_name: "res://src/Pickups/MineralBodyHorizontal.tscn",
	_fragment_tile_name: "res://src/Pickups/Fragment.tscn",
	_hammer_fish_tile_name: "res://src/Enemies/HammerFish.tscn",
	_seaweed_tile_name: "res://src/Enemies/Seaweed.tscn",
}


func _ready() -> void:
	# Object Placer TileMap's tile graphics are only handy in the editor,
	# therefore we must hide it when running the game
	ObjectsTilemap.hide()
	clean_player_tiles()
	place_objects()


# There can be only one player tile in the level
func clean_player_tiles() -> void:
	var player_tile = ObjectsTilemap.tile_set.find_tile_by_name(_player_tile_name)
	var player_tiles = ObjectsTilemap.get_used_cells_by_id(player_tile)
	for i in player_tiles.size():
		if i > 0:
			ObjectsTilemap.set_cell(player_tiles[i].x, player_tiles[i].y, -1)


func place_objects() -> void:
	for cell in ObjectsTilemap.get_used_cells():
		var id = ObjectsTilemap.get_cellv(cell)
		var type = ObjectsTilemap.tile_set.tile_get_name(id)
		var region = ObjectsTilemap.tile_set.tile_get_region(id)
		var pos = ObjectsTilemap.map_to_world(cell) + region.size / 2

		var folder_name: String
		match type:
			_player_tile_name:
				folder_name = _player_folder_name
			_mine_tile_name:
				folder_name = _enemies_folder_name
			_mineral_ground_name:
				folder_name = _pickups_folder_name
			_fragment_tile_name:
				folder_name = _pickups_folder_name
			_hammer_fish_tile_name:
				folder_name = _enemies_folder_name
			_seaweed_tile_name:
				folder_name = _enemies_folder_name

		var node_path = _objects_dictionary.get(type)
		if node_path:
			var scene: PackedScene = load(node_path)
			var instance: Node2D = scene.instance()
			instance.position = pos

			var is_cell_x_flipped: bool = ObjectsTilemap.is_cell_x_flipped(cell.x, cell.y)
			var is_cell_y_flipped: bool = ObjectsTilemap.is_cell_y_flipped(cell.x, cell.y)
			var is_cell_transposed: bool = ObjectsTilemap.is_cell_transposed(cell.x, cell.y)

#			if ObjectsTilemap.is_cell_transposed(cell.x, cell.y):
#				if instance.has_method("rotate_left"):
#					instance.rotate_left()
#			if is_cell_x_flipped:
#				if !is_cell_transposed:
#					instance.flip_horizontally()
#				else:
#					instance.flip_vertically()
#			if is_cell_y_flipped:
#				if !is_cell_transposed:
#					instance.flip_vertically()
#				else:
#					instance.flip_horizontally()

			if is_cell_transposed:
				if instance.has_method("transpose"):
					instance.transpose()
			if is_cell_x_flipped:
				if instance.has_method("flip_horizontally"):
					instance.flip_horizontally()
			if is_cell_y_flipped:
				if instance.has_method("flip_vertically"):
					instance.flip_vertically()
			

			var folder = get_node(folder_name)
			folder.add_child(instance)
