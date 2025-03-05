import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class PlayerPage extends StatefulWidget {
  final String songUri;
  final String title;
  final String artist;
  final int songId;

  const PlayerPage({
    Key? key,
    required this.songUri,
    required this.title,
    required this.artist,
    required this.songId,
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool isPlaying = true;
  Color backgroundColor = Colors.black;
  Color secondaryColor = Colors.black;

  @override
  void initState() {
    super.initState();
    _setupPlayer();
    _extractAlbumArtColors();
  }

  Future<void> _setupPlayer() async {
    try {
      await _audioPlayer
          .setAudioSource(AudioSource.uri(Uri.parse(widget.songUri)));

      _audioPlayer.durationStream.listen((d) {
        if (d != null) {
          setState(() {
            _duration = d;
          });
        }
      });

      _audioPlayer.positionStream.listen((p) {
        setState(() {
          _position = p;
        });
      });

      _audioPlayer.playerStateStream.listen((state) {
        setState(() {
          isPlaying = state.playing;
        });
      });

      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading song: $e");
    }
  }

  Future<void> _extractAlbumArtColors() async {
    try {
      final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
        QueryArtworkWidget(id: widget.songId, type: ArtworkType.AUDIO)
                .artworkImage ??
            const AssetImage('assets/default_album.png'),
      );

      if (mounted) {
        setState(() {
          backgroundColor = palette.dominantColor?.color ?? Colors.black;
          secondaryColor = palette.lightVibrantColor?.color ??
              backgroundColor.withOpacity(0.7);
        });
      }
    } catch (e) {
      debugPrint("Error extracting colors: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () {
            _audioPlayer.stop();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 30, color: Colors.white),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circular Album Art with Progress Bar
          Stack(
            alignment: Alignment.center,
            children: [
              SleekCircularSlider(
                appearance: CircularSliderAppearance(
                  customWidths:
                      CustomSliderWidths(progressBarWidth: 8, trackWidth: 8),
                  size: 250,
                  startAngle: 180,
                  angleRange: 360,
                  customColors: CustomSliderColors(
                    progressBarColor: Colors.white,
                    trackColor: Colors.white.withOpacity(0.3),
                    dotColor: Colors.transparent,
                  ),
                ),
                min: 0,
                max: _duration.inSeconds.toDouble(),
                initialValue: _position.inSeconds.toDouble(),
                onChange: (double value) {
                  _audioPlayer.seek(Duration(seconds: value.toInt()));
                },
              ),
              QueryArtworkWidget(
                id: widget.songId,
                type: ArtworkType.AUDIO,
                artworkHeight: 200,
                artworkWidth: 200,
                artworkBorder: BorderRadius.circular(100),
                nullArtworkWidget: const Icon(Icons.music_note,
                    size: 150, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Song title and artist
          Text(widget.title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 5),
          Text(widget.artist,
              style: const TextStyle(fontSize: 20, color: Colors.white70)),
          const SizedBox(height: 20),

          // Time indicators
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
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

          const SizedBox(height: 20),

          // Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _audioPlayer.seekToPrevious(),
                icon: const Icon(Icons.skip_previous_rounded,
                    size: 50, color: Colors.white),
              ),
              GestureDetector(
                onTap: () async {
                  isPlaying
                      ? await _audioPlayer.pause()
                      : await _audioPlayer.play();
                },
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 50, color: backgroundColor),
                ),
              ),
              IconButton(
                onPressed: () => _audioPlayer.seekToNext(),
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

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
