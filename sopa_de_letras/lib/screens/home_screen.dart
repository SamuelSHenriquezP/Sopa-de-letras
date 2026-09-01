import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/level_config.dart';
import '../services/audio_manager.dart';
import 'dictionary_screen.dart';
import 'game_screen.dart';
import 'levels_screen.dart';
import 'settings_screen.dart';
import '../widgets/fun_effects.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int maxUnlockedLevel = 1;
  int availableHints = 5;
  bool isLoading = true;

  int dailyStreak = 0;
  bool isDailyCompletedToday = false;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    String todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterday = now.subtract(const Duration(days: 1));
    String yesterdayStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
    String? lastCompletedDate = prefs.getString('daily_last_completed_date');
    int savedStreak = prefs.getInt('daily_streak_count') ?? 0;
    if (lastCompletedDate != todayStr && lastCompletedDate != yesterdayStr) {
      savedStreak = 0;
    }

    setState(() {
      maxUnlockedLevel = prefs.getInt('max_level') ?? 1;
      availableHints = prefs.getInt('hints') ?? 5;
      dailyStreak = savedStreak;
      isDailyCompletedToday = (lastCompletedDate == todayStr);
      isLoading = false;
    });
  }

  Future<void> _refreshData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    String todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    final yesterday = now.subtract(const Duration(days: 1));
    String yesterdayStr =
        "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";
    String? lastCompletedDate = prefs.getString('daily_last_completed_date');
    int savedStreak = prefs.getInt('daily_streak_count') ?? 0;
    if (lastCompletedDate != todayStr && lastCompletedDate != yesterdayStr) {
      savedStreak = 0;
    }

    if (mounted) {
      setState(() {
        availableHints = prefs.getInt('hints') ?? 5;
        maxUnlockedLevel = prefs.getInt('max_level') ?? 1;
        dailyStreak = savedStreak;
        isDailyCompletedToday = (lastCompletedDate == todayStr);
      });
    }
  }

  void _launchGame(int level) {
    AudioManager.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(level: level)),
    ).then((_) {
      _refreshData();
    });
  }

  void _launchDailyChallenge() {
    AudioManager.playClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const GameScreen(level: 0, isDailyChallenge: true),
      ),
    ).then((_) {
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPro = SopaSeniorApp.of(context)?.isPro ?? false;
    final difficulty = SopaSeniorApp.of(context)?.difficulty ?? 0;

    final LevelConfig currentConfig = LevelConfig.fromLevel(
      maxUnlockedLevel,
      difficulty,
    );

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 30, color: colors.primary),
            onPressed: () {
              AudioManager.playClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              ).then((_) => _refreshData());
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'icon',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.psychology_alt,
                      size: 80,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "SOPA DE LETRAS",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: colors.onSurface,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Edición Senior Pro",
                      style: TextStyle(
                        fontSize: 18,
                        color: colors.primary.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (isPro)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          "PRO",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 15),

                // BADGE DE HILERA: PISTAS Y DIFICULTAD PROGRESIVA
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.secondary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb, size: 18, color: colors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            "$availableHints Pistas",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.primary),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bar_chart_rounded, size: 18, color: colors.primary),
                          const SizedBox(width: 6),
                          Text(
                            currentConfig.difficultyLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // CARD DEL RETO DIARIO
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isDailyCompletedToday
                            ? Colors.green.withValues(alpha: 0.5)
                            : Colors.deepOrange.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDailyCompletedToday
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.deepOrange.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDailyCompletedToday
                                      ? Icons.check_circle_rounded
                                      : Icons.local_fire_department_rounded,
                                  color: isDailyCompletedToday
                                      ? Colors.green
                                      : Colors.deepOrange,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "RETO DIARIO",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: colors.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isDailyCompletedToday
                                          ? "¡Completado por hoy!"
                                          : "Resuelve la sopa de hoy y gana +3 pistas",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (dailyStreak > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.deepOrange.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.local_fire_department,
                                        size: 16,
                                        color: Colors.deepOrange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "$dailyStreak",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: isDailyCompletedToday
                                  ? null
                                  : _launchDailyChallenge,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                disabledBackgroundColor: Colors.grey.shade300,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                isDailyCompletedToday
                                    ? Icons.task_alt
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                isDailyCompletedToday
                                    ? "RETO COMPLETADO"
                                    : "JUGAR RETO DIARIO",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // SELECTOR DE DIFICULTAD
                ToggleButtons(
                  borderRadius: BorderRadius.circular(20),
                  fillColor: colors.primary.withValues(alpha: 0.2),
                  selectedColor: colors.primary,
                  color: colors.onSurface.withValues(alpha: 0.6),
                  constraints: const BoxConstraints(minHeight: 38, minWidth: 78),
                  isSelected: [
                    difficulty == 0,
                    difficulty == 1,
                    difficulty == 2,
                  ],
                  onPressed: (int index) {
                    AudioManager.playClick();
                    SopaSeniorApp.of(context)?.setDifficulty(index);
                    setState(() {});
                  },
                  children: const [
                    Text("Desde Cero", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    Text("Medio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    Text("Difícil", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 16),

                // BOTÓN DE NIVELES PRINCIPAL
                PulsingWidget(
                  minScale: 0.98,
                  maxScale: 1.06,
                  duration: const Duration(milliseconds: 1100),
                  child: FilledButton.icon(
                    onPressed: () => _launchGame(maxUnlockedLevel),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 36,
                        vertical: 16,
                      ),
                      backgroundColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 6,
                    ),
                    icon: const Icon(
                      Icons.play_circle_fill,
                      size: 28,
                      color: Colors.white,
                    ),
                    label: Text(
                      "JUGAR NIVEL $maxUnlockedLevel",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // BOTONES DE NAVEGACIÓN
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        AudioManager.playLevelSelectSFX();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                LevelsScreen(maxUnlocked: maxUnlockedLevel),
                          ),
                        ).then((val) {
                          if (val is int) _launchGame(val);
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        side: BorderSide(
                          color: colors.primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(
                        Icons.grid_view_rounded,
                        size: 22,
                        color: colors.primary,
                      ),
                      label: Text(
                        "NIVELES",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    OutlinedButton.icon(
                      onPressed: () {
                        AudioManager.playClick();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                DictionaryScreen(maxUnlocked: maxUnlockedLevel),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        side: BorderSide(
                          color: colors.primary.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(
                        Icons.menu_book,
                        size: 22,
                        color: colors.primary,
                      ),
                      label: Text(
                        "DICCIONARIO",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
