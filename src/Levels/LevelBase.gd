tool
extends Node

signal level_finished
signal restart_level_request

export var minerals_goal := 50

onready var ObjectsTilemap := $ObjectsTileMap
onready var WorldTilemap := $WallsTileMap

onready var HUDNode := $LevelUI/HUD
onready var PauseScreen := $PauseScreen/PauseScreen
onready var GreatJobLabel: Label = $LevelUI/GreatJobLabel
onready var RestartNotification := $LevelUI/RestartNotification
onready var DebugControl := $Debug/DebugControl
onready var PlayerEndLevelCanvas := $PlayerEndLevelLayer
onready var UIAnimationPlayer := $LevelUI/UIAnimationPlayer

onready var _available_minerals_count := get_minerals_count()

var _restart_level_by_any_key := false
var _player_node_reference: GameActor = null

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

# Debug function
func get_minerals_count() -> int:
	var object_tile_map = get_node("ObjectsTileMap")
	var fragment_tile_id = object_tile_map.tile_set.find_tile_by_name(_fragment_tile_name)
	var mineral_lump_id = object_tile_map.tile_set.find_tile_by_name(_mineral_ground_name)

	var mineral_fragments_tiles = object_tile_map.get_used_cells_by_id(fragment_tile_id)
	var mineral_lump_tiles = object_tile_map.get_used_cells_by_id(mineral_lump_id)

	return mineral_fragments_tiles.size() + (mineral_lump_tiles.size() * 6)


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
				instance.connect("player_ready", self, "_on_player_ready")
				instance.connect("player_died", self, "_on_player_death")
				_player_node_reference = instance

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
	if _restart_level_by_any_key:
		emit_signal("restart_level_request")

	if event.is_action_pressed("pause"):
		if !get_tree().paused:
			_show_pause_screen()


func _ready() -> void:
	if Engine.editor_hint:
		_update_debug_window()
		return

	DebugControl.hide()
	RestartNotification.text = TextManager.get_string_by_key("restart_notification")
	GreatJobLabel.text = TextManager.get_string_by_key("great_job")

	PlayerStats.reset()
	PlayerStats.minerals_goal = minerals_goal
	PlayerStats.connect("minerals_goal_achieved", self, "_on_minerals_goal_achieved")

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


# Process used only for debug purposes
func _process(delta: float) -> void:
	if !Engine.editor_hint:
		return

	_update_debug_window()


# Debug
func _update_debug_window() -> void:
	var minerals_count := get_minerals_count()
	get_node("Debug/DebugControl/VBoxContainer/HBoxContainer/GoalCount").text = str(minerals_goal)
	get_node("Debug/DebugControl/VBoxContainer/HBoxContainer2/CurrentCount").text = str(minerals_count)

	if minerals_count < minerals_goal:
		get_node("Debug/DebugControl/VBoxContainer/HBoxContainer2/CurrentCount").modulate = Color.red
	else:
		get_node("Debug/DebugControl/VBoxContainer/HBoxContainer2/CurrentCount").modulate = Color.white


func _on_pause_back_pressed() -> void:
	get_tree().paused = false
	PauseScreen.visible = false


func _on_pause_restart_pressed() -> void:
	emit_signal("restart_level_request")


func _on_player_ready(camera: Camera2D) -> void:
	var world_rect = WorldTilemap.get_used_rect()

	var cell_size = WorldTilemap.cell_size.x
	var pixel_rect = Rect2(
		world_rect.position.x * cell_size,
		world_rect.position.y * cell_size,
		world_rect.size.x * cell_size,
		world_rect.size.y * cell_size
	)
	camera.limit_left = pixel_rect.position.x
	camera.limit_top = pixel_rect.position.y
	camera.limit_right = pixel_rect.position.x + pixel_rect.size.x
	camera.limit_bottom = pixel_rect.position.y + pixel_rect.size.y

	unpause()


func _on_player_death() -> void:
	# Delay for notification to show
	$LevelUI/RestartNotificationTimer.start()


func _on_RestartNoticitaionTimer_timeout() -> void:
	RestartNotification.visible = true
	_restart_level_by_any_key = true


func _on_minerals_goal_achieved() -> void:
	get_tree().paused = true
	Physics2DServer.set_active(true)
	UIAnimationPlayer.play("SHOW_GREAT_JOB")
	HUDNode.hide()


func _on_UIAnimationPlayer_animation_finished(anim_name: String) -> void:
	match anim_name:
		"SHOW_GREAT_JOB":
			_player_node_reference.connect("player_teleported_away", self, "_on_player_teleported_away")
			_player_node_reference.start_teleport_away_animation()


func _on_player_teleported_away() -> void:
	emit_signal("level_finished")
