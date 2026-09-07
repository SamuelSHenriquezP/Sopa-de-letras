import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MusicTrack {
  final String id;
  final String title;
  final String description;
  final String assetPath;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.description,
    required this.assetPath,
  });
}

class AudioManager {
  static final AudioPlayer _bgmPlayer = AudioPlayer();
  static final AudioPlayer _clickPlayer = AudioPlayer();
  static final AudioPlayer _wordFoundPlayer = AudioPlayer();
  static final AudioPlayer _winPlayer = AudioPlayer();
  static final AudioPlayer _menuSoundPlayer = AudioPlayer();
  static bool _musicOn = true;
  static bool _sfxOn = true;
  static String _currentTrack = '';
  static Timer? _fadeTimer;

  static const List<MusicTrack> tracks = [
    MusicTrack(
      id: 'classic',
      title: 'Sopa de Letras Clásica',
      description: 'Melodía original alegre y relajante',
      assetPath: 'music/Fondo - Sopa letras.mp3',
    ),
    MusicTrack(
      id: 'brainwave',
      title: 'Brainwave Puzzles',
      description: 'Ritmo suave para agilidad mental',
      assetPath: 'music/Brainwave Puzzles.mp3',
    ),
    MusicTrack(
      id: 'focus',
      title: 'Logic & Focus',
      description: 'Ambiente tranquilo para máxima concentración',
      assetPath: 'music/Logic & Focus.mp3',
    ),
  ];

  static int _selectedTrackIndex = 0;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _musicOn = prefs.getBool('music_on') ?? true;
    _sfxOn = prefs.getBool('sfx_on') ?? true;
    _selectedTrackIndex = (prefs.getInt('selected_music_track') ?? 0).clamp(0, tracks.length - 1);

    await _bgmPlayer.setReleaseMode(ReleaseMode.loop);
    await _bgmPlayer.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );

    final sfxContext = AudioContext(
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.playback,
        options: {AVAudioSessionOptions.mixWithOthers},
      ),
      android: AudioContextAndroid(
        isSpeakerphoneOn: false,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    );

    await _clickPlayer.setAudioContext(sfxContext);
    await _wordFoundPlayer.setAudioContext(sfxContext);
    await _winPlayer.setAudioContext(sfxContext);
    await _menuSoundPlayer.setAudioContext(sfxContext);
  }

  static void playLevelSelectSFX() {
    if (_sfxOn) {
      _menuSoundPlayer.play(
        AssetSource('audio/Menu de niveles.wav'),
        volume: 1.0,
      );
    }
  }

  static void playGameMusic({bool forceRestart = false}) async {
    _currentTrack = 'game';
    if (_musicOn) {
      if (!forceRestart && _bgmPlayer.state == PlayerState.playing) {
        return;
      }
      _fadeTimer?.cancel();
      if (_bgmPlayer.state == PlayerState.playing) await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(0);
      final track = tracks[_selectedTrackIndex];
      await _bgmPlayer.play(AssetSource(track.assetPath));
      double vol = 0;
      _fadeTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
        vol += 0.025;
        if (vol >= 0.5) {
          vol = 0.5;
          timer.cancel();
        }
        _bgmPlayer.setVolume(vol);
      });
    }
  }

  static void resumeMusic({bool forceRestart = false}) {
    if (_currentTrack == 'game') {
      playGameMusic(forceRestart: forceRestart);
    }
  }

  static void setMusicTrack(int index) async {
    if (index < 0 || index >= tracks.length) return;
    _selectedTrackIndex = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_music_track', index);
    if (_musicOn) {
      playGameMusic(forceRestart: true);
    }
  }

  static int get selectedTrackIndex => _selectedTrackIndex;
  static MusicTrack get currentTrack => tracks[_selectedTrackIndex];

  static void stopBGM() async {
    _fadeTimer?.cancel();
    _currentTrack = '';
    await _bgmPlayer.stop();
  }

  static void fadeOutMusic() async {
    _fadeTimer?.cancel();
    double currentVol = 1.0;
    _fadeTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) async {
      currentVol -= 0.05;
      if (currentVol <= 0) {
        currentVol = 0;
        timer.cancel();
        await _bgmPlayer.stop();
        _currentTrack = '';
      }
      _bgmPlayer.setVolume(currentVol);
    });
  }

  static void toggleMusic(bool value) async {
    _musicOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('music_on', value);
    if (_musicOn) {
      resumeMusic();
    } else {
      stopBGM();
    }
  }

  static void playClick() {
    if (_sfxOn) {
      _clickPlayer.play(
        AssetSource('audio/inicio rapido - menu - siguiente.wav'),
        volume: 1.0,
      );
    }
  }

  static void playWin() {
    if (_sfxOn) {
      _winPlayer.play(AssetSource('audio/ganar nivel.wav'), volume: 1.0);
    }
  }

  static void playWordFound() {
    if (_sfxOn) {
      _wordFoundPlayer.play(
        AssetSource('audio/Clin cuando encuentra palabra.wav'),
        volume: 1.0,
      );
    }
  }

  static void toggleSFX(bool value) async {
    _sfxOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_on', value);
  }

  static bool get isMusicOn => _musicOn;
  static bool get isSfxOn => _sfxOn;
}
