extends Node

const TOTAL_CHANNELS := 16
const BUS := "SFX"

var _free_channels := []
var _active_channels := []
var _sounds_queue := []


func play_sound(sound_resource: Resource, sound_owner: Node2D, volume = 0.0) -> void:
	var sound_request = SoundRequest.new(sound_resource, sound_owner, volume)
	if not _sounds_queue.has(sound_request):
		_sounds_queue.append(sound_request)


func _ready() -> void:
	# We want to finish all queued sounds even if the game has been paused
	pause_mode = Node.PAUSE_MODE_PROCESS

	for i in TOTAL_CHANNELS:
		var stream_player := AudioStreamPlayer2D.new()
		stream_player.bus = BUS
		stream_player.autoplay = false
		stream_player.max_distance = 320.0

		var stream_channel := AudioStreamLocal.new(stream_player)
		stream_channel.stream_player.connect("finished", self, "_on_stream_finished", [stream_channel])
		_free_channels.append(stream_channel)

		add_child(stream_player)


func _process(delta: float) -> void:
	var sound_requests: int = min(_free_channels.size(), _sounds_queue.size())

	for i in sound_requests:
		var stream_channel: AudioStreamLocal = _free_channels.pop_front()
		var sound_request = _sounds_queue.pop_front() as SoundRequest

		stream_channel.stream_player.stream = sound_request.sound_resource
		stream_channel.stream_player.volume_db = sound_request.volume
		stream_channel.stream_player.global_position = sound_request.initial_global_position
		stream_channel.stream_owner = sound_request.sound_owner
		stream_channel.stream_player.play()
		sound_request.free()

		_active_channels.append(stream_channel)

	# Destroy all unprocessed sound requests to avoid memory leaks
	for sound_request in _sounds_queue:
		sound_request.free()

	_sounds_queue.clear()
	_update_active_channels_position()


# Destroy all objects not in the scene tree to prevent memory leaks
func _exit_tree() -> void:
	for active_channel in _active_channels:
		active_channel.free()

	for free_channel in _free_channels:
		free_channel.free()


func _update_active_channels_position() -> void:
	for active_channel in _active_channels:
		var stream_owner = active_channel.stream_owner
		if is_instance_valid(stream_owner):
			active_channel.stream_player.global_position = stream_owner.global_position


func _on_stream_finished(stream_channel: AudioStreamLocal) -> void:
	if _active_channels.has(stream_channel):
		_active_channels.erase(stream_channel)

	_free_channels.append(stream_channel)
	stream_channel.reset()
