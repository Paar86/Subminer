extends Node

const TOTAL_CHANNELS := 8
const BUS := "SFX"

var _all_channels := []
var _free_channels := []
var _sounds_queue := []


func play_sound(sound_resource: Resource, volume: float = 0.0) -> void:
	var sound_request = SoundRequest.new(sound_resource, null, volume)
	if not _sounds_queue.has(sound_request):
		_sounds_queue.append(sound_request)


func _ready() -> void:
	# We want to finish all queued sounds even if the game has been paused
	pause_mode = Node.PAUSE_MODE_PROCESS

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
		var sound_request: SoundRequest = _sounds_queue.pop_front()
		stream.stream = sound_request.sound_resource
		stream.volume_db = sound_request.volume
		stream.play()

		sound_request.free()

	for sound in _sounds_queue:
		sound.free()

	_sounds_queue.clear()


func _exit_tree() -> void:
	for sound in _sounds_queue:
		sound.free()


func _on_stream_finished(stream: AudioStreamPlayer) -> void:
	_free_channels.append(stream)
	stream.volume_db = 0.0
