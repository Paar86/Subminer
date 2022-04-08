extends Node

const TOTAL_CHANNELS := 8
const BUS := "master"

var _all_channels := []
var _free_channels := []
var _sounds_queue := []


func play_sound(sound_file: String):
	if not _sounds_queue.has(sound_file):
		_sounds_queue.append(sound_file)


func _ready() -> void:
	for i in TOTAL_CHANNELS:
		var stream_player := AudioStreamPlayer.new()
		stream_player.bus = BUS
		stream_player.autoplay = true
		add_child(stream_player)
		_all_channels.append(stream_player)
		_free_channels.append(stream_player)
		stream_player.connect("finished", self, "_on_stream_finished", [stream_player])


func _process(delta: float) -> void:
	var sounds_to_play: int = min(_free_channels.size(), _sounds_queue.size())

	for i in sounds_to_play:
		var stream: AudioStreamPlayer = _free_channels.pop_front()
		stream.stream = load(_sounds_queue.pop_front())
		stream.play()
		
	_sounds_queue.clear()


func _on_stream_finished(stream: AudioStreamPlayer) -> void:
	_free_channels.append(stream)
