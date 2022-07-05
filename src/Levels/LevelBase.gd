extends Node

signal level_finished
signal restart_level_request

export var minerals_goal := 50

onready var ObjectsTilemap := $ObjectsTileMap
onready var HUDNode := $LevelUI/HUD
onready var PauseScreen := $PauseScreen/PauseScreen

var level_id := "default"
var _player_folder_name := "PlayerStart"
var _pickups_folder_name := "Pickups"
var _enemies_folder_name := "Enemies"

var _player_tile_name := "player_start"
var _mine_tile_name := "mine"
var _mineral_ground_name := "mineral_boulder"
var _fragment_tile_name := "mineral_fragment"
var _hammer_fish_tile_name := "hammer_fish"
var _seaweed_tile_name := "seaweed"
var _snail_tile_name := "snail"

var _objects_dictionary = {
	_player_tile_name: "res://src/Player/PlayerKinematic.tscn",
	_mine_tile_name: "res://src/Enemies/Mine.tscn",
	_mineral_ground_name: "res://src/Pickups/MineralBodyBase.tscn",
	_fragment_tile_name: "res://src/Pickups/Fragment.tscn",
	_hammer_fish_tile_name: "res://src/Enemies/HammerFish.tscn",
	_seaweed_tile_name: "res://src/Enemies/Seaweed.tscn",
	_snail_tile_name: "res://src/Enemies/Snail.tscn",
}


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
			_snail_tile_name:
				folder_name = _enemies_folder_name

		var node_path = _objects_dictionary.get(type)
		if node_path:
			var scene: PackedScene = load(node_path)
			var instance: Node2D = scene.instance()
			instance.position = pos
			
			if instance.is_in_group("Player"):
				instance.connect("player_ready", self, "_on_unpause_request")

			var is_cell_x_flipped: bool = ObjectsTilemap.is_cell_x_flipped(cell.x, cell.y)
			var is_cell_y_flipped: bool = ObjectsTilemap.is_cell_y_flipped(cell.x, cell.y)
			var is_cell_transposed: bool = ObjectsTilemap.is_cell_transposed(cell.x, cell.y)

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


func unpause() -> void:
	get_tree().paused = false


func pause() -> void:
	get_tree().paused = true


func _show_pause_screen() -> void:
	pause()
	PauseScreen.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if !get_tree().paused:
			_show_pause_screen()


func _ready() -> void:

	get_tree().paused = true
	PauseScreen.connect("back_pressed", self, "_on_pause_back_pressed")
	PauseScreen.connect("restart_pressed", self, "_on_pause_restart_pressed")

	# Object Placer TileMap's tile graphics are only handy in the editor,
	# therefore we must hide it when running the game
	ObjectsTilemap.hide()
	clean_player_tiles()
	place_objects()

	HUDNode.reset_hitpoints()
	HUDNode.set_minerals_goal(minerals_goal)


func _on_pause_back_pressed() -> void:
	get_tree().paused = false
	PauseScreen.visible = false


func _on_pause_restart_pressed() -> void:
	emit_signal("restart_level_request")


func _on_unpause_request() -> void:
	unpause()
