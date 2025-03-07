import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';

class PlayerPage extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final String songUri;
  final String title;
  final String artist;
  final int songId;

  const PlayerPage({
    Key? key,
    required this.audioPlayer,
    required this.songUri,
    required this.title,
    required this.artist,
    required this.songId,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool isPlaying = false;
  Color _dominantColor = Colors.black;
  PaletteGenerator? _palette;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
    _extractAlbumArtColors();
  }

  Future<void> _setupPlayer() async {
    try {
      widget.audioPlayer.durationStream.listen((d) {
        if (d != null) {
          setState(() => _duration = d);
        }
      });

      widget.audioPlayer.positionStream.listen((p) {
        setState(() => _position = p);
      });

      widget.audioPlayer.playerStateStream.listen((state) {
        setState(() => isPlaying = state.playing);
      });
    } catch (e) {
      print("Error loading song: $e");
    }
  }

  Future<void> _extractAlbumArtColors() async {
    try {
      Uint8List? imageBytes =
          await _audioQuery.queryArtwork(widget.songId, ArtworkType.AUDIO);
      if (imageBytes != null) {
        final imageProvider = MemoryImage(imageBytes);
        _palette = await PaletteGenerator.fromImageProvider(imageProvider);

        setState(() {
          _dominantColor = _palette?.dominantColor?.color ?? Colors.black;
        });
      }
    } catch (e) {
      print("Error extracting album art colors: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dominantColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 30, color: Colors.white),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 5),
          Text(widget.artist,
              style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 280,
                width: 280,
                child: CircularProgressIndicator(
                  value: _position.inSeconds /
                      (_duration.inSeconds == 0 ? 1 : _duration.inSeconds),
                  strokeWidth: 6,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                  backgroundColor: Colors.white30,
                ),
              ),
              FutureBuilder<Uint8List?>(
                future:
                    _audioQuery.queryArtwork(widget.songId, ArtworkType.AUDIO),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(140),
                      child: Image.memory(snapshot.data!,
                          height: 240, width: 240, fit: BoxFit.cover),
                    );
                  } else {
                    return const Icon(Icons.music_note,
                        size: 150, color: Colors.white);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Slider(
                  activeColor: Colors.orangeAccent,
                  inactiveColor: Colors.white30,
                  min: 0,
                  max: _duration.inSeconds.toDouble(),
                  value: _position.inSeconds
                      .toDouble()
                      .clamp(0, _duration.inSeconds.toDouble()),
                  onChanged: (value) {
                    widget.audioPlayer.seek(Duration(seconds: value.toInt()));
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_position),
                          style: const TextStyle(color: Colors.white70)),
                      Text(_formatDuration(_duration - _position),
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await widget.audioPlayer.seekToPrevious();
                },
                icon: const Icon(Icons.skip_previous_rounded,
                    size: 50, color: Colors.white),
              ),
              IconButton(
                onPressed: () async {
                  if (isPlaying) {
                    await widget.audioPlayer.pause();
                  } else {
                    await widget.audioPlayer.play();
                  }
                },
                icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle,
                    size: 70, color: Colors.white),
              ),
              IconButton(
                onPressed: () async {
                  await widget.audioPlayer.seekToNext();
                },
                icon: const Icon(Icons.skip_next_rounded,
                    size: 50, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
