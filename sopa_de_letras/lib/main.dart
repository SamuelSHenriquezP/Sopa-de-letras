import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ==========================================
// 1. BASE DE DATOS (DATA)
// ==========================================
const Map<String, List<String>> wordThemes = {
  "COCINA": [
    "OLLA",
    "SAL",
    "AZUCAR",
    "MESA",
    "PAN",
    "SOPA",
    "CAFE",
    "FRUTA",
    "AGUA",
    "CHEF",
    "HORNO",
    "CUCHILLO",
    "PLATO",
    "TENEDOR",
    "VASO",
    "SERVILLETAS",
    "BATIDORA",
    "HARINA",
    "HUEVO",
    "LECHE",
  ],
  "ANIMALES": [
    "GATO",
    "PERRO",
    "LORO",
    "LEON",
    "TIGRE",
    "OSO",
    "PEZ",
    "VACA",
    "PATO",
    "LOBO",
    "ELEFANTE",
    "JIRAFA",
    "ZEBRA",
    "MONO",
    "AGUILA",
    "DELFIN",
    "BALLENA",
    "TIBURON",
    "CABALLO",
    "OVEJA",
  ],
  "VALORES": [
    "AMOR",
    "PAZ",
    "FE",
    "VIDA",
    "ALMA",
    "LUZ",
    "HONOR",
    "VERDAD",
    "GOZO",
    "UNION",
    "AMISTAD",
    "RESPETO",
    "BONDAD",
    "CALMA",
    "VALOR",
    "JUSTICIA",
    "LIBERTAD",
    "ESPERANZA",
    "GRACIA",
    "LEALTAD",
  ],
  "CASA": [
    "SALA",
    "BAÑO",
    "CAMA",
    "SOFA",
    "PISO",
    "TECHO",
    "LLAVE",
    "FOCO",
    "RELOJ",
    "JARDIN",
    "PUERTA",
    "VENTANA",
    "SOTANO",
    "COCINA",
    "COMEDOR",
    "ESPEJO",
    "CUADRO",
    "ALFOMBRA",
    "SILLA",
    "LAMPARA",
  ],
  "NATURALEZA": [
    "RIO",
    "MAR",
    "SOL",
    "LUNA",
    "FLOR",
    "ARBOL",
    "MONTE",
    "LLUVIA",
    "NUBE",
    "VIENTO",
    "NIEVE",
    "RAYO",
    "TRUENO",
    "BOSQUE",
    "SELVA",
    "DESIERTO",
    "PLAYA",
    "ARENA",
    "PIEDRA",
    "TIERRA",
  ],
  "COLORES": [
    "ROJO",
    "AZUL",
    "GRIS",
    "ROSA",
    "VERDE",
    "NEGRO",
    "BLANCO",
    "LILA",
    "CIAN",
    "ORO",
    "PLATA",
    "VIOLETA",
    "NARANJA",
    "BEIGE",
    "MARRON",
    "TURQUESA",
    "INDIGO",
    "CORAL",
    "MAGENTA",
    "AMARILLO",
  ],
  "FAMILIA": [
    "MAMA",
    "PAPA",
    "HIJO",
    "NIETO",
    "TIA",
    "TIO",
    "PRIMA",
    "ABUELO",
    "HERMANO",
    "NUERA",
    "SUEGRA",
    "SUEGRO",
    "CUÑADO",
    "PADRINO",
    "MADRINA",
    "BEBE",
    "ESPOSO",
    "MUJER",
    "SOBRINO",
    "PRIMO",
  ],
  "ROPA": [
    "CAMISA",
    "PANTALON",
    "FALDA",
    "VESTIDO",
    "ZAPATO",
    "GORRO",
    "BUFANDA",
    "GUANTE",
    "ABRIGO",
    "MEDIA",
    "BOTAS",
    "CINTURON",
    "CORBATA",
    "SACO",
    "BLUSA",
    "PIJAMA",
    "SANDALIA",
    "LENTES",
    "RELOJ",
    "ANILLO",
  ],
  "CIUDAD": [
    "CALLE",
    "AUTO",
    "BUS",
    "METRO",
    "PARQUE",
    "TIENDA",
    "CINE",
    "HOTEL",
    "BANCO",
    "PLAZA",
    "MUSEO",
    "ESCUELA",
    "MERCADO",
    "PUENTE",
    "TORRE",
    "BARRIO",
    "SEMAFORO",
    "ACERA",
    "TRAFICO",
    "GENTE",
  ],
  "CUERPO": [
    "MANO",
    "PIE",
    "OJOS",
    "BOCA",
    "NARIZ",
    "PELO",
    "DEDO",
    "UÑA",
    "BRAZO",
    "PIERNA",
    "RODILLA",
    "CODO",
    "CUELLO",
    "ESPALDA",
    "PECHO",
    "CORAZON",
    "MENTE",
    "PIEL",
    "DIENTE",
    "LENGUA",
  ],
};

// ==========================================
// 2. DEFINICIÓN DE TEMAS VISUALES
// ==========================================
class AppTheme {
  final String name;
  final Color background;
  final Color primary;
  final Color surface;
  final Color text;
  final Color accent;
  final Brightness brightness; // Para iconos de batería/hora

  AppTheme({
    required this.name,
    required this.background,
    required this.primary,
    required this.surface,
    required this.text,
    required this.accent,
    required this.brightness,
  });
}

final List<AppTheme> myThemes = [
  // 0: CLÁSICO
  AppTheme(
    name: "Clásico",
    background: const Color(0xFFFDFBF7),
    primary: const Color(0xFF6D4C41),
    surface: const Color(0xFFFFF8E1),
    text: const Color(0xFF4E342E),
    accent: const Color(0xFFFFA726),
    brightness: Brightness.light,
  ),
  // 1: NOCHE (Corregido para alto contraste oscuro)
  AppTheme(
    name: "Noche",
    background: const Color(0xFF121212),
    primary: const Color(0xFF90CAF9),
    surface: const Color(0xFF1E1E1E),
    text: const Color(0xFFEEEEEE),
    accent: const Color(0xFF64B5F6),
    brightness: Brightness.dark,
  ),
  // 2: LAVANDA
  AppTheme(
    name: "Lavanda",
    background: const Color(0xFFF3E5F5),
    primary: const Color(0xFF6A1B9A),
    surface: const Color(0xFFFFFFFF),
    text: const Color(0xFF4A148C),
    accent: const Color(0xFFAB47BC),
    brightness: Brightness.light,
  ),
];

void main() {
  runApp(const SopaSeniorApp());
}

// ==========================================
// 3. WIDGET RAÍZ
// ==========================================

class SopaSeniorApp extends StatefulWidget {
  const SopaSeniorApp({super.key});
  static _SopaSeniorAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_SopaSeniorAppState>();

  @override
  State<SopaSeniorApp> createState() => _SopaSeniorAppState();
}

class _SopaSeniorAppState extends State<SopaSeniorApp> {
  int _themeIndex = 0;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeIndex = prefs.getInt('theme_index') ?? 0;
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
    });
  }

  void changeTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', index);
    setState(() {
      _themeIndex = index;
    });
  }

  void toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', value);
    setState(() {
      _vibrationEnabled = value;
    });
  }

  void vibrate({bool heavy = false}) {
    if (_vibrationEnabled) {
      if (heavy)
        HapticFeedback.heavyImpact();
      else
        HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = myThemes[_themeIndex];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sopa Senior Pro',
      theme: ThemeData(
        brightness: currentTheme.brightness, // Importante para Modo Oscuro
        scaffoldBackgroundColor: currentTheme.background,
        primaryColor: currentTheme.primary,
        cardColor: currentTheme.surface,
        dividerColor: currentTheme.primary.withOpacity(0.2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: currentTheme.primary,
          primary: currentTheme.primary,
          surface: currentTheme.surface,
          secondary: currentTheme.accent,
          onSurface: currentTheme
              .text, // Esto define el color del texto sobre el fondo
          background: currentTheme.background,
          brightness: currentTheme.brightness,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: currentTheme.primary),
          titleTextStyle: TextStyle(
            color: currentTheme.primary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          systemOverlayStyle: currentTheme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// 4. PANTALLA DE INICIO
// ==========================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int maxUnlockedLevel = 1;
  int availableHints = 5;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      maxUnlockedLevel = prefs.getInt('max_level') ?? 1;
      availableHints = prefs.getInt('hints') ?? 5;
      isLoading = false;
    });
  }

  Future<void> _updateProgress(int newLevel) async {
    if (newLevel > maxUnlockedLevel) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('max_level', newLevel);
      setState(() {
        maxUnlockedLevel = newLevel;
      });
    }
  }

  Future<void> _refreshData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      availableHints = prefs.getInt('hints') ?? 5;
      maxUnlockedLevel = prefs.getInt('max_level') ?? 1;
    });
  }

  void _launchGame(int level) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => GameScreen(level: level)),
    ).then((result) {
      _refreshData();
      if (result != null && result is int) {
        _updateProgress(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 30, color: colors.primary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) => _refreshData());
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Center(
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology_alt,
                    size: 90,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Text(
                "SOPA DE LETRAS",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "Edición Senior",
                style: TextStyle(
                  fontSize: 20,
                  color: colors.primary.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.secondary),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb, color: colors.secondary),
                    const SizedBox(width: 8),
                    Text(
                      "$availableHints Pistas",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Transform.scale(
                scale: 1.1,
                child: FilledButton.icon(
                  onPressed: () => _launchGame(maxUnlockedLevel),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 18,
                    ),
                    backgroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 8,
                  ),
                  icon: const Icon(
                    Icons.play_circle_fill,
                    size: 30,
                    color: Colors.white,
                  ),
                  label: Text(
                    "JUGAR NIVEL $maxUnlockedLevel",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () {
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
                    horizontal: 30,
                    vertical: 15,
                  ),
                  side: BorderSide(
                    color: colors.primary.withOpacity(0.5),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                icon: Icon(
                  Icons.grid_view_rounded,
                  size: 24,
                  color: colors.primary,
                ),
                label: Text(
                  "ELEGIR NIVEL",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 5. PANTALLA DE AJUSTES (CORREGIDA PARA MODO OSCURO)
// ==========================================

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = SopaSeniorApp.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Estilos de texto explícitos para asegurar visibilidad en Dark Mode
    final sectionTitleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: colors.onSurface.withOpacity(0.6),
    );
    final bodyTextStyle = TextStyle(fontSize: 16, color: colors.onSurface);

    return Scaffold(
      appBar: AppBar(
        title: Text("Ajustes", style: TextStyle(color: colors.onSurface)),
        centerTitle: true,
        leading: BackButton(color: colors.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text("APARIENCIA", style: sectionTitleStyle),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Text("Elige un tema visual", style: bodyTextStyle),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(myThemes.length, (index) {
                      final itemTheme = myThemes[index];
                      bool isSelected =
                          theme.scaffoldBackgroundColor == itemTheme.background;

                      return GestureDetector(
                        onTap: () {
                          appState?.changeTheme(index);
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: itemTheme.background,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? itemTheme.primary
                                      : Colors.grey.withOpacity(0.5),
                                  width: isSelected ? 4 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Aa",
                                  style: TextStyle(
                                    color: itemTheme.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              itemTheme.name,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text("JUEGO", style: sectionTitleStyle),
          ),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                StatefulBuilder(
                  builder: (context, setState) {
                    return FutureBuilder<bool>(
                      future: SharedPreferences.getInstance().then(
                        (p) => p.getBool('vibration') ?? true,
                      ),
                      builder: (context, snapshot) {
                        bool vib = snapshot.data ?? true;
                        return SwitchListTile(
                          title: Text("Vibración", style: bodyTextStyle),
                          subtitle: Text(
                            "Vibrar al encontrar palabras",
                            style: TextStyle(
                              color: colors.onSurface.withOpacity(0.7),
                            ),
                          ),
                          secondary: Icon(
                            Icons.vibration,
                            color: colors.primary,
                          ),
                          value: vib,
                          activeColor: colors.primary,
                          onChanged: (val) {
                            appState?.toggleVibration(val);
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text("DATOS", style: sectionTitleStyle),
          ),
          Card(
            color: Colors.red.withOpacity(0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.red.withOpacity(0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text(
                "Reiniciar Progreso",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "Borra niveles y pistas. No se puede deshacer.",
                style: TextStyle(color: colors.onSurface.withOpacity(0.7)),
              ),
              onTap: () {
                _showResetDialog(context, colors.onSurface);
              },
            ),
          ),

          const SizedBox(height: 30),
          Center(
            child: Text(
              "Versión 1.0.2",
              style: TextStyle(color: colors.onSurface.withOpacity(0.4)),
            ),
          ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, Color textColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("¿Estás seguro?", style: TextStyle(color: textColor)),
        content: Text(
          "Perderás todo tu avance y volverás al Nivel 1.",
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('max_level');
              await prefs.remove('hints');
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Progreso reiniciado.")),
              );
            },
            child: const Text(
              "Sí, borrar todo",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 6. SELECTOR DE NIVELES
// ==========================================

class LevelsScreen extends StatelessWidget {
  final int maxUnlocked;
  const LevelsScreen({super.key, required this.maxUnlocked});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Seleccionar Nivel",
          style: TextStyle(color: colors.onSurface),
        ),
        centerTitle: true,
        leading: BackButton(color: colors.onSurface),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: maxUnlocked + 20,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
        ),
        itemBuilder: (context, index) {
          int level = index + 1;
          bool isLocked = level > maxUnlocked;
          bool isCurrent = level == maxUnlocked;

          return InkWell(
            onTap: isLocked ? null : () => Navigator.pop(context, level),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              decoration: BoxDecoration(
                color: isLocked
                    ? colors.surface.withOpacity(0.5)
                    : (isCurrent
                          ? colors.secondary.withOpacity(0.2)
                          : colors.surface),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isLocked
                      ? Colors.grey.withOpacity(0.3)
                      : (isCurrent
                            ? colors.secondary
                            : colors.primary.withOpacity(0.3)),
                  width: isCurrent ? 3 : 1,
                ),
                boxShadow: isLocked
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: isLocked
                    ? Icon(Icons.lock, color: Colors.grey.withOpacity(0.5))
                    : Text(
                        "$level",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isCurrent
                              ? colors.secondary
                              : colors.onSurface,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 7. CONFIGURACIÓN DEL JUEGO
// ==========================================

class LevelConfig {
  final int rows;
  final int cols;
  final int wordCount;
  final bool allowDiagonals;
  final bool allowReverse;
  final int themesToMix;

  LevelConfig({
    required this.rows,
    required this.cols,
    required this.wordCount,
    required this.allowDiagonals,
    required this.allowReverse,
    required this.themesToMix,
  });

  factory LevelConfig.fromLevel(int level) {
    int c = (8 + (level / 25)).floor().clamp(8, 11);
    int r = (8 + (level / 20)).floor().clamp(8, 13);
    int count = (5 + (level / 10)).floor().clamp(5, 20);
    bool diags = level > 5;
    bool reverse = level > 25;
    int mixes = level >= 200 ? 3 : (level >= 100 ? 2 : 1);
    return LevelConfig(
      rows: r,
      cols: c,
      wordCount: count,
      allowDiagonals: diags,
      allowReverse: reverse,
      themesToMix: mixes,
    );
  }
}

// ==========================================
// 8. PANTALLA DE JUEGO (PISTAS MEJORADAS)
// ==========================================

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
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
  String? lastHintedWord; // Para evitar repetir la misma palabra seguida

  @override
  void initState() {
    super.initState();
    currentLevel = widget.level;
    _loadHints();
    _initializeLevel();
  }

  @override
  void dispose() {
    hintTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHints() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hints = prefs.getInt('hints') ?? 5;
    });
  }

  // --- NUEVA LÓGICA DE PISTAS ALEATORIAS ---
  Future<void> _useHint() async {
    if (hints > 0) {
      // 1. Obtener todas las palabras que faltan
      List<String> missingWords = activeWords
          .where((w) => !foundWords.contains(w))
          .toList();

      if (missingWords.isNotEmpty) {
        String targetWord;

        // 2. Si hay más de una palabra, intentamos evitar la última que sugerimos
        if (missingWords.length > 1 &&
            lastHintedWord != null &&
            missingWords.contains(lastHintedWord)) {
          List<String> candidates = missingWords
              .where((w) => w != lastHintedWord)
              .toList();
          targetWord = candidates[Random().nextInt(candidates.length)];
        } else {
          // Si solo queda una o no hay historial, elegimos al azar de las que quedan
          targetWord = missingWords[Random().nextInt(missingWords.length)];
        }

        // 3. Ejecutar la pista
        int? startIdx = wordStartIndices[targetWord];
        if (startIdx != null) {
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            hints--;
            hintedIndex = startIdx;
            lastHintedWord = targetWord; // Guardamos para la próxima
          });
          await prefs.setInt('hints', hints);

          SopaSeniorApp.of(context)?.vibrate();
          hintTimer?.cancel();
          hintTimer = Timer.periodic(const Duration(milliseconds: 500), (
            timer,
          ) {
            if (mounted)
              setState(() {
                if (hintedIndex == null)
                  hintedIndex = startIdx;
                else
                  hintedIndex = null;
              });
            if (timer.tick >= 6) {
              timer.cancel();
              setState(() => hintedIndex = startIdx);
            }
          });
        }
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("¡Sin pistas!")));
    }
  }

  void _initializeLevel() {
    setState(() {
      levelRandom = Random(currentLevel);
      config = LevelConfig.fromLevel(currentLevel);
      List<String> availableKeys = wordThemes.keys.toList()
        ..shuffle(levelRandom);
      List<String> selectedThemes = availableKeys
          .take(config.themesToMix)
          .toList();
      levelTitle = selectedThemes.length == 1
          ? selectedThemes.first
          : "MIX: ${selectedThemes.join(' + ')}";
      Set<String> wordPool = {};
      for (var theme in selectedThemes) wordPool.addAll(wordThemes[theme]!);
      activeWords = (wordPool.toList()..shuffle(levelRandom))
          .take(config.wordCount)
          .toList();
      foundWords.clear();
      persistentLines.clear();
      wordStartIndices.clear();
      currentLine = null;
      startIndex = null;
      hintedIndex = null;
      lastHintedWord = null;
      _generateGrid();
    });
  }

  void _generateGrid() {
    grid = List.filled(config.rows * config.cols, '');
    activeWords.sort((a, b) => b.length.compareTo(a.length));
    for (String word in activeWords) {
      bool placed = false;
      int attempts = 0;
      int maxAttempts = 100 + (currentLevel * 2);
      while (!placed && attempts < maxAttempts) {
        int maxDir = config.allowDiagonals ? 4 : 2;
        int dir = levelRandom.nextInt(maxDir);
        String finalWord = (config.allowReverse && levelRandom.nextBool())
            ? word.split('').reversed.join('')
            : word;
        int row = levelRandom.nextInt(config.rows);
        int col = levelRandom.nextInt(config.cols);
        List<int> indices = _getIndices(row, col, finalWord.length, dir);
        if (indices.isNotEmpty && _canPlace(indices, finalWord)) {
          for (int i = 0; i < finalWord.length; i++)
            grid[indices[i]] = finalWord[i];
          wordStartIndices[word] = indices[0];
          placed = true;
        }
        attempts++;
      }
      if (!placed) {
        _generateGrid();
        return;
      }
    }
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (int i = 0; i < grid.length; i++) {
      if (grid[i] == '') grid[i] = letters[levelRandom.nextInt(letters.length)];
    }
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

  void _handleLevelComplete() {
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Icon(
          Icons.emoji_events_rounded,
          size: 70,
          color: colors.secondary,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "¡Nivel Completado!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Has superado el nivel $currentLevel",
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, currentLevel + 1);
            },
            child: Text("Menú", style: TextStyle(color: colors.primary)),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                currentLevel++;
                _initializeLevel();
              });
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              "Siguiente",
              style: TextStyle(color: Colors.white),
            ),
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
            Theme.of(context).colorScheme.secondary.withOpacity(0.5),
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
      if (activeWords.contains(w) && !foundWords.contains(w))
        match = w;
      else if (activeWords.contains(rw) && !foundWords.contains(rw))
        match = rw;

      if (match != null) {
        SopaSeniorApp.of(context)?.vibrate(heavy: true);
        setState(() {
          foundWords.add(match!);
          persistentLines.add(
            WordLine(
              _center(startIndex!, s),
              _center(tempEndIndex!, s),
              Colors.green.withOpacity(0.4),
            ),
          );
          if (hintedIndex != null && wordStartIndices[match] == hintedIndex) {
            hintedIndex = null;
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
    for (int i = 0; i <= steps; i++)
      sb.write(grid[(r1 + dr * i) * config.cols + (c1 + dc * i)]);
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, currentLevel);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              Text(
                "NIVEL $currentLevel",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: colors.onSurface,
                ),
              ),
              Text(
                levelTitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withOpacity(0.6),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context, currentLevel),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  "${foundWords.length}/${activeWords.length}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: FloatingActionButton.extended(
            onPressed: _useHint,
            backgroundColor: hints > 0 ? colors.secondary : Colors.grey,
            icon: Icon(
              Icons.lightbulb,
              color: hints > 0 ? colors.onSecondary : Colors.white,
            ),
            label: Text(
              hints > 0 ? "PISTA ($hints)" : "SIN PISTAS",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: hints > 0 ? colors.onSecondary : Colors.white,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: activeWords.map((word) {
                      bool found = foundWords.contains(word);
                      return AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: found ? 0.3 : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: found
                                ? Colors.green.withOpacity(0.1)
                                : colors.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: found
                                  ? Colors.green.withOpacity(0.3)
                                  : colors.primary.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: found ? Colors.green : colors.onSurface,
                              decoration: found
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
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
                            onPanUpdate: (d) =>
                                _panUpdate(d, Size(boardWidth, boardHeight)),
                            onPanEnd: (d) =>
                                _panEnd(d, Size(boardWidth, boardHeight)),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
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
                                  physics: const NeverScrollableScrollPhysics(),
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
                                            ? colors.secondary.withOpacity(0.5)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Center(
                                        child: Text(
                                          grid[i],
                                          style: TextStyle(
                                            fontSize: cellSize * 0.5,
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
        ),
      ),
    );
  }
}

class WordLine {
  final Offset s, e;
  final Color c;
  WordLine(this.s, this.e, this.c);
}

class LinePainter extends CustomPainter {
  final List<WordLine> lines;
  final WordLine? cur;
  final int c, r;
  LinePainter(this.lines, this.cur, this.c, this.r);
  @override
  void paint(Canvas cv, Size sz) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (sz.width / c) * 0.6;
    for (var l in lines) {
      p.color = l.c;
      cv.drawLine(l.s, l.e, p);
    }
    if (cur != null) {
      p.color = cur!.c;
      cv.drawLine(cur!.s, cur!.e, p);
    }
  }

  @override
  bool shouldRepaint(covariant LinePainter old) => true;
}
