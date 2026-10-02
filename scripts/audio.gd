extends Node
var music_clock = 0.0
var music_step = 0
var cache: Dictionary = {}
const MELODY = [261.63, 329.63, 392.0, 329.63, 293.66, 349.23, 440.0, 349.23]

func _process(delta: float) -> void:
	music_clock += delta
	if music_clock > 1.8:
		music_clock = 0
		var volume = float(Economy.data.settings.music)
		if volume > 0.001: tone(MELODY[music_step % MELODY.size()], 0.65, volume * 0.12)
		music_step += 1

func tone(hz: float, duration: float, volume: float) -> void:
	if volume < 0.001: return
	var key = "%s_%s" % [hz, duration]
	var stream: AudioStreamWAV
	if cache.has(key): stream = cache[key]
	else:
		stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var samples = int(duration * 22050)
		var bytes = PackedByteArray()
		bytes.resize(samples * 2)
		for i in samples:
			var t = float(i) / 22050.0
			var envelope = minf(t * 70, 1.0) * pow(1.0 - float(i) / samples, 2)
			var value = (sin(TAU * hz * t) + 0.18 * sin(TAU * hz * 2 * t)) * envelope
			bytes.encode_s16(i * 2, int(value * 17000))
		stream.data = bytes
		cache[key] = stream
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = linear_to_db(volume)
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func cue(kind: String) -> void:
	var volume = float(Economy.data.settings.sfx) * 0.45
	match kind:
		"cast": tone(320, 0.16, volume)
		"bite":
			tone(640, 0.12, volume)
			get_tree().create_timer(0.12).timeout.connect(func(): tone(880, 0.18, volume))
		"catch", "upgrade":
			tone(523, 0.2, volume)
			get_tree().create_timer(0.1).timeout.connect(func(): tone(659, 0.25, volume))
			get_tree().create_timer(0.2).timeout.connect(func(): tone(784, 0.3, volume))
		"merge_pull": tone(250,0.16,volume*0.60)
		"merge":
			tone(523,0.14,volume)
			tone(1046,0.24,volume*0.65)
			get_tree().create_timer(0.08).timeout.connect(func(): tone(784,0.24,volume))
			get_tree().create_timer(0.16).timeout.connect(func(): tone(1318,0.28,volume*0.75))
		"transfer": tone(480,0.045,volume*0.22)
		"sale": tone(880,0.06,volume*0.40)
		"coin": tone(988, 0.12, volume)
		"slice": tone(760,0.024,volume*0.23); tone(165,0.035,volume*0.17)
		"cut": tone(150, 0.09, volume * 0.6)
		"spin": tone(120, 0.3, volume * 0.35)
		"batch":
			tone(659, 0.15, volume * 0.6)
			get_tree().create_timer(0.1).timeout.connect(func(): tone(880, 0.2, volume * 0.6))
		"fail": tone(160, 0.2, volume)
		"click": tone(420, 0.06, volume * 0.3)
