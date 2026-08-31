class LevelConfig {
  final int rows;
  final int cols;
  final int wordCount;
  final bool allowDiagonals;
  final bool allowReverse;
  final int themesToMix;
  final String difficultyLabel;

  LevelConfig({
    required this.rows,
    required this.cols,
    required this.wordCount,
    required this.allowDiagonals,
    required this.allowReverse,
    required this.themesToMix,
    required this.difficultyLabel,
  });

  factory LevelConfig.fromLevel(int level, [int difficulty = 0]) {
    int eff = level;
    if (difficulty == 1) eff += 20;
    if (difficulty == 2) eff += 50;

    int c = (8 + (eff / 12)).floor().clamp(8, 12);
    int r = (8 + (eff / 10)).floor().clamp(8, 13);
    int count = (5 + (eff / 5)).floor().clamp(5, 18);
    bool diags = eff >= 4;
    bool reverse = eff >= 12;
    int mixes = eff >= 25 ? 3 : (eff >= 15 ? 2 : 1);

    String label = "Principiante";
    if (eff >= 25) {
      label = "Experto";
    } else if (eff >= 15) {
      label = "Avanzado";
    } else if (eff >= 6) {
      label = "Intermedio";
    }

    return LevelConfig(
      rows: r,
      cols: c,
      wordCount: count,
      allowDiagonals: diags,
      allowReverse: reverse,
      themesToMix: mixes,
      difficultyLabel: label,
    );
  }

  factory LevelConfig.dailyChallenge(DateTime date) {
    int daySeed = date.day;
    int r = 10 + (daySeed % 3);
    int c = 10 + ((daySeed + 1) % 3);
    int count = 8 + (daySeed % 5);
    return LevelConfig(
      rows: r,
      cols: c,
      wordCount: count,
      allowDiagonals: true,
      allowReverse: daySeed % 2 == 0,
      themesToMix: 2,
      difficultyLabel: "Reto Diario",
    );
  }
}
