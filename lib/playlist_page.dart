import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'player_page.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({Key? key}) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _audioPlayer = AudioPlayer();
  SongModel? _currentSong;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();

    // Listen for playback state changes
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  Future<void> _requestPermission() async {
    bool permissionStatus = await _audioQuery.permissionsStatus();
    if (!permissionStatus) {
      await _audioQuery.permissionsRequest();
    }
    setState(() {});
  }

  Future<void> _playSong(SongModel song) async {
    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      await _audioPlayer.play();
      setState(() {
        _currentSong = song;
        _isPlaying = true;
      });
    } catch (e) {
      print("Error playing song: $e");
    }
  }

  void _pauseOrResume() {
    if (_isPlaying) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _navigateToPlayerPage() {
    if (_currentSong != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => PlayerPage(
            audioPlayer: _audioPlayer, // Shared AudioPlayer instance
            songUri: _currentSong!.uri!,
            title: _currentSong!.title,
            artist: _currentSong!.artist ?? "Unknown Artist",
            songId: _currentSong!.id,
          ),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text(
          'Music Player',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<SongModel>>(
              future: _audioQuery.querySongs(
                sortType: SongSortType.TITLE,
                orderType: OrderType.ASC_OR_SMALLER,
                uriType: UriType.EXTERNAL,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text("No songs found!",
                          style: TextStyle(color: Colors.white)));
                }

                List<SongModel> songs = snapshot.data!;

                return ListView.separated(
                  separatorBuilder: (context, index) => const Divider(
                      color: Colors.white30,
                      height: 0,
                      thickness: 1,
                      indent: 85),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];

                    return ListTile(
                      title: Text(song.title,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(song.artist ?? "Unknown Artist",
                          style: const TextStyle(color: Colors.white70)),
                      leading: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        artworkBorder: BorderRadius.circular(10),
                        nullArtworkWidget: const Icon(Icons.music_note,
                            size: 50, color: Colors.white),
                      ),
                      onTap: () {
                        _playSong(song);
                        _navigateToPlayerPage();
                      },
                    );
                  },
                );
              },
            ),
          ),

          // 'Now Playing' Widget - Clickable & Animates to Player Page
          if (_currentSong != null)
            GestureDetector(
              onTap: _navigateToPlayerPage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.black.withOpacity(0.9),
                child: Row(
                  children: [
                    QueryArtworkWidget(
                      id: _currentSong!.id,
                      type: ArtworkType.AUDIO,
                      artworkBorder: BorderRadius.circular(10),
                      artworkHeight: 50,
                      artworkWidth: 50,
                      nullArtworkWidget: const Icon(Icons.music_note,
                          size: 50, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentSong!.title,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _currentSong!.artist ?? "Unknown Artist",
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                          _isPlaying ? Icons.pause_circle : Icons.play_circle),
                      color: Colors.white,
                      iconSize: 40,
                      onPressed: _pauseOrResume,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
