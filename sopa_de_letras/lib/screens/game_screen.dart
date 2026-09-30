import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../main.dart';
import '../data/dictionary.dart';
import '../models/level_config.dart';
import '../models/word_line.dart';
import '../services/ad_manager.dart';
import '../services/audio_manager.dart';
import '../widgets/line_painter.dart';
import '../widgets/fun_effects.dart';

class GameScreen extends StatefulWidget {
  final int level;
  final bool isDailyChallenge;

  const GameScreen({
    super.key,
    required this.level,
    this.isDailyChallenge = false,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int currentLevel;
  late LevelConfig config;
  String levelTitle = "";
  List<String> activeWords = [];
  List<String> grid = [];
  List<String> foundWords = [];
  Map<String, int> wordStartIndices = {};
  List<WordLine> persistentLines = [];
  WordLine? currentLine;
  int? startIndex, tempEndIndex;
  late Random levelRandom;
  int hints = 0;
  int? hintedIndex;
  Timer? hintTimer;
  String? lastHintedWord;
  late AdManager _adManager;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool isPro = false;
  bool _hasShown5MinInactivityPrompt = false;
  Timer? _gameTimer;
  int _secondsElapsed = 0;
  String? _currentFloatingMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    currentLevel = widget.level;
    _adManager = AdManager();
    _loadHints();
    _initializeLevel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProStatusAndLoadAds();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _saveHintsSafe();
      AudioManager.stopBGM();
    } else if (state == AppLifecycleState.resumed) {
      AudioManager.playGameMusic();
    }
  }

  Future<void> _saveHintsSafe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('hints', hints);
    } catch (_) {}
  }

  void _checkProStatusAndLoadAds() {
    final proStatus = SopaSeniorApp.of(context)?.isPro ?? false;
    setState(() {
      isPro = proStatus;
    });
    AudioManager.playGameMusic();
    if (!isPro) {
      _bannerAd = AdManager.createBanner(onLoaded: () {
        if (mounted) setState(() => _isBannerLoaded = true);
      });
      _adManager.loadInterstitial();
    }
    _adManager.loadRewarded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _saveHintsSafe();
    hintTimer?.cancel();
    _gameTimer?.cancel();
    AudioManager.stopBGM();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadHints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hints = prefs.getInt('hints') ?? 5;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (!widget.isDailyChallenge) {
      int savedMax = prefs.getInt('max_level') ?? 1;
      int nextLevel = currentLevel + 1;
      if (nextLevel > savedMax) {
        await prefs.setInt('max_level', nextLevel);
      }
    }
  }

  Future<void> _useHint() async {
    if (hints > 0) {
      if (lastHintedWord != null && !foundWords.contains(lastHintedWord)) {
        _flashHint();
        return;
      }
      List<String> missingWords = activeWords
          .where((w) => !foundWords.contains(w))
          .toList();
      if (missingWords.isNotEmpty) {
        String targetWord = missingWords[Random().nextInt(missingWords.length)];
        int? startIdx = wordStartIndices[targetWord];
        if (startIdx != null) {
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            hints--;
            hintedIndex = startIdx;
            lastHintedWord = targetWord;
          });
          await prefs.setInt('hints', hints);
          if (!mounted) return;
          SopaSeniorApp.of(context)?.vibrate();
          _flashHint();
        }
      }
    } else {
      _showRewardDialog();
    }
  }

  void _showRewardDialog() {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Icon(Icons.video_library, size: 50, color: colors.primary),
        content: Text(
          "¿Te quedaste sin pistas?\nMira un video corto para ganar 3 pistas extra.",
          style: TextStyle(color: colors.onSurface),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text("Ver Video"),
            style: FilledButton.styleFrom(backgroundColor: colors.secondary),
            onPressed: () {
              Navigator.pop(ctx);
              _adManager.showRewarded(() async {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  hints += 3;
                });
                await prefs.setInt('hints', hints);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("¡+3 Pistas conseguidas!")),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  void _show5MinHintDialog() {
    if (!mounted) return;
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lightbulb_rounded,
                size: 40,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "¿Necesitas ayuda?",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          "Llevas 5 minutos en este nivel.\n¿Quieres ver un video corto para obtener 3 pistas extra?",
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurface.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "No, gracias",
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text(
                    "Ver Anuncio",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _adManager.showRewarded(() async {
                      final prefs = await SharedPreferences.getInstance();
                      setState(() {
                        hints += 3;
                      });
                      await prefs.setInt('hints', hints);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("¡+3 Pistas conseguidas!")),
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _flashHint() {
    hintTimer?.cancel();
    int? targetIndex = hintedIndex;
    hintTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) return;
      setState(() {
        hintedIndex = (hintedIndex == null) ? targetIndex : null;
      });
      if (timer.tick >= 6) {
        timer.cancel();
        if (mounted) setState(() => hintedIndex = targetIndex);
      }
    });
  }

  void _initializeLevel() {
    hintTimer?.cancel();
    _gameTimer?.cancel();

    final int diff = SopaSeniorApp.of(context)?.difficulty ?? 0;
    _secondsElapsed = 0;
    _hasShown5MinInactivityPrompt = false;

    final newTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _secondsElapsed++);
        if (_secondsElapsed >= 300 && !_hasShown5MinInactivityPrompt) {
          _hasShown5MinInactivityPrompt = true;
          if (foundWords.length < activeWords.length) {
            _show5MinHintDialog();
          }
        }
      }
    });

    setState(() {
      _gameTimer = newTimer;

      if (widget.isDailyChallenge) {
        final now = DateTime.now();
        int seed = now.year * 10000 + now.month * 100 + now.day;
        levelRandom = Random(seed);
        config = LevelConfig.dailyChallenge(now);
        levelTitle = "Reto ${now.day}/${now.month}";
      } else {
        levelRandom = Random(currentLevel + diff * 1000);
        config = LevelConfig.fromLevel(currentLevel, diff);
      }

      List<String> availableKeys = wordThemes.keys.toList()
        ..shuffle(levelRandom);
      List<String> selectedThemes = availableKeys
          .take(config.themesToMix)
          .toList();

      if (!widget.isDailyChallenge) {
        levelTitle = selectedThemes.length == 1
            ? selectedThemes.first
            : "MIX: ${selectedThemes.join(' + ')}";
      }

      Set<String> rawWordPool = {};
      for (var theme in selectedThemes) {
        if (wordThemes.containsKey(theme)) {
          rawWordPool.addAll(wordThemes[theme]!);
        }
      }

      int maxDimension = max(config.rows, config.cols);
      List<String> validWords = rawWordPool
          .where((w) => w.length <= maxDimension)
          .toList();
      if (validWords.isEmpty) {
        validWords = ["SOL", "LUZ", "MAR", "DIA", "PAN", "ORO", "RIO", "FLOR"];
      }
      activeWords = (validWords..shuffle(levelRandom))
          .take(config.wordCount)
          .toList();

      foundWords.clear();
      persistentLines.clear();
      wordStartIndices.clear();
      currentLine = null;
      startIndex = null;
      hintedIndex = null;
      lastHintedWord = null;
      _generateGridSafely();
    });
  }

  void _generateGridSafely() {
    bool success = false;
    int totalRetries = 0;
    while (!success && totalRetries < 50) {
      grid = List.filled(config.rows * config.cols, '');
      activeWords.sort((a, b) => b.length.compareTo(a.length));
      bool currentAttemptFailed = false;
      Map<String, int> tempIndices = {};
      for (String word in activeWords) {
        bool placed = false;
        int wordAttempts = 0;
        int maxWordAttempts = 50;
        while (!placed && wordAttempts < maxWordAttempts) {
          int maxDir = config.allowDiagonals ? 4 : 2;
          int dir = levelRandom.nextInt(maxDir);
          String finalWord = (config.allowReverse && levelRandom.nextBool())
              ? word.split('').reversed.join('')
              : word;
          int row = levelRandom.nextInt(config.rows);
          int col = levelRandom.nextInt(config.cols);
          List<int> indices = _getIndices(row, col, finalWord.length, dir);
          if (indices.isNotEmpty && _canPlace(indices, finalWord)) {
            for (int i = 0; i < finalWord.length; i++) {
              grid[indices[i]] = finalWord[i];
            }
            tempIndices[word] = indices[0];
            placed = true;
          }
          wordAttempts++;
        }
        if (!placed) {
          currentAttemptFailed = true;
          break;
        }
      }
      if (!currentAttemptFailed) {
        success = true;
        wordStartIndices = tempIndices;
      } else {
        totalRetries++;
        if (totalRetries % 10 == 0 && activeWords.isNotEmpty) {
          activeWords.removeAt(0);
        }
      }
    }
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (int i = 0; i < grid.length; i++) {
      if (grid[i] == '') grid[i] = letters[levelRandom.nextInt(letters.length)];
    }
    if (activeWords.isEmpty) activeWords = ["ERROR", "REINTENTA"];
  }

  List<int> _getIndices(int row, int col, int len, int dir) {
    List<List<int>> deltas = [
      [0, 1],
      [1, 0],
      [1, 1],
      [-1, 1],
    ];
    int dr = deltas[dir][0], dc = deltas[dir][1];
    List<int> idx = [];
    for (int i = 0; i < len; i++) {
      int r = row + dr * i, c = col + dc * i;
      if (r < 0 || r >= config.rows || c < 0 || c >= config.cols) return [];
      idx.add(r * config.cols + c);
    }
    return idx;
  }

  bool _canPlace(List<int> idx, String w) {
    for (int i = 0; i < idx.length; i++) {
      if (grid[idx[i]] != '' && grid[idx[i]] != w[i]) return false;
    }
    return true;
  }

  Future<void> _saveDailyChallengeCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    String todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    String? lastDate = prefs.getString('daily_last_completed_date');
    int currentStreak = prefs.getInt('daily_streak_count') ?? 0;

    if (lastDate != todayStr) {
      final yesterday = now.subtract(const Duration(days: 1));
      String yesterdayStr = "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
      if (lastDate == yesterdayStr) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      await prefs.setString('daily_last_completed_date', todayStr);
      await prefs.setInt('daily_streak_count', currentStreak);
      // Recompensa +3 Pistas
      int currentHints = prefs.getInt('hints') ?? 5;
      await prefs.setInt('hints', currentHints + 3);
    }
  }

  void _handleLevelComplete() async {
    hintTimer?.cancel();
    _gameTimer?.cancel();
    AudioManager.fadeOutMusic();
    final colors = Theme.of(context).colorScheme;
    AudioManager.playWin();

    if (widget.isDailyChallenge) {
      await _saveDailyChallengeCompletion();
      final prefs = await SharedPreferences.getInstance();
      int streak = prefs.getInt('daily_streak_count') ?? 1;

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Stack(
          alignment: Alignment.center,
          children: [
            const ConfettiWidgetOverlay(),
            AlertDialog(
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              title: Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 36,
                    color: colors.primary,
                  ),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "¡Reto Diario Completado!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "⏱ Tiempo: ${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.local_fire_department_rounded,
                              size: 18,
                              color: colors.secondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Racha: $streak días seguidos",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colors.secondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              size: 18,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "¡+3 Pistas otorgadas!",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: colors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                Center(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _adManager.showInterstitial(isPro, () {
                        Navigator.pop(context);
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Volver al Menú",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      return;
    }

    _saveProgress();
    String motivation =
        motivationalMessages[Random().nextInt(motivationalMessages.length)];
    int unlockedIndex = currentLevel - 1;
    String? unlockedWord;
    String? unlockedMeaning;
    if (unlockedIndex < colombianDictionary.length) {
      unlockedWord = colombianDictionary[unlockedIndex]['word'];
      unlockedMeaning = colombianDictionary[unlockedIndex]['meaning'];
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Stack(
        alignment: Alignment.center,
        children: [
          const ConfettiWidgetOverlay(),
          AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            title: Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  size: 36,
                  color: colors.primary,
                ),
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "¡Nivel Completado!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "⏱ Tiempo: ${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    motivation,
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  if (unlockedWord != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 16,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "DICCIONARIO DESBLOQUEADO",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            unlockedWord,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            unlockedMeaning!,
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Text(
                      "Has desbloqueado todo el diccionario.",
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 13,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Menú",
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _adManager.showInterstitial(isPro, () {
                        setState(() {
                          currentLevel++;
                          _initializeLevel();
                        });
                        AudioManager.playGameMusic();
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Siguiente Nivel",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _idx(Offset p, Size s) {
    double cw = s.width / config.cols, ch = s.height / config.rows;
    int c = (p.dx / cw).floor().clamp(0, config.cols - 1),
        r = (p.dy / ch).floor().clamp(0, config.rows - 1);
    return r * config.cols + c;
  }

  Offset _center(int i, Size s) {
    double cw = s.width / config.cols, ch = s.height / config.rows;
    int r = i ~/ config.cols, c = i % config.cols;
    return Offset((c * cw) + (cw / 2), (r * ch) + (ch / 2));
  }

  void _panStart(DragStartDetails d, Size s) {
    int i = _idx(d.localPosition, s);
    startIndex = i;
    tempEndIndex = i;
    SopaSeniorApp.of(context)?.vibrate();
    AudioManager.playClick();
  }

  void _panUpdate(DragUpdateDetails d, Size s) {
    if (startIndex == null) return;
    int curr = _idx(d.localPosition, s);
    if (curr != tempEndIndex) {
      int r1 = startIndex! ~/ config.cols, c1 = startIndex! % config.cols;
      int r2 = curr ~/ config.cols, c2 = curr % config.cols;
      int dr = r2 - r1, dc = c2 - c1;
      if (dr == 0 || dc == 0 || dr.abs() == dc.abs()) {
        setState(() {
          tempEndIndex = curr;
          currentLine = WordLine(
            _center(startIndex!, s),
            _center(curr, s),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
          );
        });
      }
    }
  }

  void _panEnd(DragEndDetails d, Size s) {
    if (startIndex != null && tempEndIndex != null) {
      String w = _getWord(startIndex!, tempEndIndex!);
      String rw = w.split('').reversed.join('');
      String? match;
      if (activeWords.contains(w) && !foundWords.contains(w)) {
        match = w;
      } else if (activeWords.contains(rw) && !foundWords.contains(rw)) {
        match = rw;
      }
      if (match != null) {
        SopaSeniorApp.of(context)?.vibrate(heavy: true);
        AudioManager.playWordFound();
        final funPhrases = [
          "¡Eso, parce! 🔥",
          "¡Muy teso! 💪",
          "¡De una! ✨",
          "¡Excelente! 😎",
          "¡Qué vista! 👁️",
          "¡A lo bien! 🇨🇴",
          "¡Buena esa! ⚡",
          "¡La romdiste! 🚀",
        ];
        String phrase = funPhrases[Random().nextInt(funPhrases.length)];

        setState(() {
          foundWords.add(match!);
          _currentFloatingMessage = phrase;
          persistentLines.add(
            WordLine(
              _center(startIndex!, s),
              _center(tempEndIndex!, s),
              Colors.green.withValues(alpha: 0.4),
            ),
          );
          if (lastHintedWord != null && match == lastHintedWord) {
            hintedIndex = null;
            lastHintedWord = null;
            hintTimer?.cancel();
          }
        });
        if (foundWords.length == activeWords.length) _handleLevelComplete();
      }
    }
    setState(() {
      startIndex = null;
      tempEndIndex = null;
      currentLine = null;
    });
  }

  String _getWord(int s, int e) {
    int r1 = s ~/ config.cols,
        c1 = s % config.cols,
        r2 = e ~/ config.cols,
        c2 = e % config.cols;
    int dr = (r2 - r1).sign, dc = (c2 - c1).sign;
    int steps = max((r2 - r1).abs(), (c2 - c1).abs());
    StringBuffer sb = StringBuffer();
    for (int i = 0; i <= steps; i++) {
      sb.write(grid[(r1 + dr * i) * config.cols + (c1 + dc * i)]);
    }
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.isDailyChallenge ? "Reto" : "Niv. $currentLevel",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.isDailyChallenge
                        ? Colors.deepOrange.withValues(alpha: 0.15)
                        : colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    levelTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isDailyChallenge ? Colors.deepOrange : colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, size: 15, color: colors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    "${(_secondsElapsed ~/ 60).toString().padLeft(2, '0')}:${(_secondsElapsed % 60).toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 15, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    "${foundWords.length}/${activeWords.length}",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.only(
            bottom: (!isPro && _isBannerLoaded) ? 60 : 20,
          ),
          child: FloatingActionButton.extended(
            onPressed: _useHint,
            backgroundColor: hints > 0 ? colors.secondary : Colors.grey,
            icon: Icon(
              hints > 0 ? Icons.lightbulb : Icons.video_library,
              color: hints > 0 ? colors.onSecondary : Colors.white,
            ),
            label: Text(
              hints > 0 ? "PISTA ($hints)" : "GRATIS (+3)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hints > 0 ? colors.onSecondary : Colors.white,
              ),
            ),
          ),
        ),
        bottomNavigationBar: (!isPro && _isBannerLoaded)
            ? SizedBox(
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : const SizedBox(height: 50),

        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.05),
                      border: Border(
                        bottom: BorderSide(
                          color: colors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            "BUSCA ESTAS PALABRAS:",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: activeWords.length,
                            itemBuilder: (context, index) {
                              String word = activeWords[index];
                              bool found = foundWords.contains(word);
                              return AnimatedOpacity(
                                duration: const Duration(milliseconds: 500),
                                opacity: found ? 0.5 : 1.0,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: found
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : colors.surface,
                                    borderRadius: BorderRadius.circular(25),
                                    border: Border.all(
                                      color: found
                                          ? Colors.green
                                          : colors.primary.withValues(alpha: 0.3),
                                      width: found ? 1 : 2,
                                    ),
                                    boxShadow: found
                                        ? []
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (found)
                                        const Padding(
                                          padding: EdgeInsets.only(right: 5),
                                          child: Icon(
                                            Icons.check_circle,
                                            size: 16,
                                            color: Colors.green,
                                          ),
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 5,
                                          ),
                                          child: Icon(
                                            Icons.search,
                                            size: 16,
                                            color: colors.primary.withValues(alpha: 
                                              0.5,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        word,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: found
                                              ? Colors.green
                                              : colors.onSurface,
                                          decoration: found
                                              ? TextDecoration.lineThrough
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 12.0, bottom: 90.0),
                      child: LayoutBuilder(
                        builder: (ctx, constr) {
                          Size s = Size(constr.maxWidth, constr.maxHeight);
                          double cellSize = min(
                            s.width / config.cols,
                            s.height / config.rows,
                          );
                          double boardWidth = cellSize * config.cols;
                          double boardHeight = cellSize * config.rows;
                          return Center(
                            child: SizedBox(
                              width: boardWidth,
                              height: boardHeight,
                              child: GestureDetector(
                                onPanStart: (d) =>
                                    _panStart(d, Size(boardWidth, boardHeight)),
                                onPanUpdate: (d) => _panUpdate(
                                  d,
                                  Size(boardWidth, boardHeight),
                                ),
                                onPanEnd: (d) =>
                                    _panEnd(d, Size(boardWidth, boardHeight)),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: colors.surface,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                    CustomPaint(
                                      size: Size(boardWidth, boardHeight),
                                      painter: LinePainter(
                                        persistentLines,
                                        currentLine,
                                        config.cols,
                                        config.rows,
                                      ),
                                    ),
                                    GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: config.rows * config.cols,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: config.cols,
                                            childAspectRatio: 1.0,
                                          ),
                                      itemBuilder: (c, i) {
                                        bool isHinted = (i == hintedIndex);
                                        return AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isHinted
                                                ? colors.secondary.withValues(alpha: 
                                                    0.5,
                                                  )
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              grid[i],
                                              style: TextStyle(
                                                fontSize: cellSize * 0.55,
                                                fontWeight: FontWeight.bold,
                                                color: colors.onSurface,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              if (_currentFloatingMessage != null)
                Center(
                  child: FloatingWordPopup(
                    message: _currentFloatingMessage!,
                    onComplete: () {
                      if (mounted) {
                        setState(() => _currentFloatingMessage = null);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
