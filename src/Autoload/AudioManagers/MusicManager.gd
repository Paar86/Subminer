extends Node

const BUS := "Music"

var _music_player: AudioStreamPlayer
var _current_music_name := ""

onready var playlist = {
	"victory": preload("res://assets/music/victory.mp3"),
	"complications": preload("res://assets/music/complications.mp3"),
	"dance": preload("res://assets/music/dance_till_you_die.mp3"),
	"day_dreams": preload("res://assets/music/day_dreams.mp3"),
	"ice_temple": preload("res://assets/music/ice_temple.mp3"),
	"npc_theme": preload("res://assets/music/npc_theme.mp3"),
	"red_skies": preload("res://assets/music/red_skies.mp3"),
	"small_town": preload("res://assets/music/a_small_town_on_pluto.mp3"),
	"sunny_afternoon": preload("res://assets/music/sunny_afternoon.mp3"),
	"legends": preload("res://assets/music/legends.mp3"),
	"final_level": preload("res://assets/music/final_level.mp3"),
}


func play_music(music_name: String) -> void:
	if music_name == _current_music_name:
		return

	_music_player.stop()

	if !playlist.has(music_name):
		push_warning("Music file with a name '%s' doesn't exist." % music_name)
		return

	_music_player.stream = playlist[music_name]
	_music_player.stream_paused = false
	_music_player.play()

	_current_music_name = music_name


func stop_music() -> void:
	_current_music_name = ""
	_music_player.stop()


func stop_music_with_fadeout() -> void:
	_current_music_name = ""
	var original_volume = _music_player.volume_db

	var tween := Tween.new()
	tween.interpolate_property(_music_player,
								"volume_db",
								_music_player.volume_db,
								-60.0,
								5.0,
								Tween.TRANS_LINEAR,
								Tween.EASE_OUT)
	add_child(tween)
	tween.start()

	yield(tween, "tween_all_completed")
	_music_player.stream_paused = true
	_music_player.volume_db = original_volume


func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS

	var music_player = AudioStreamPlayer.new()
	music_player.bus = BUS
	_music_player = music_player

	add_child(music_player)
