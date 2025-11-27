import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ==========================================
// 1. BASE DE DATOS EXTENDIDA (DATA)
// ==========================================
// Necesitamos muchas palabras para soportar niveles altos y mezclas.
const Map<String, List<String>> wordThemes = {
  "COCINA": ["OLLA", "SAL", "AZUCAR", "MESA", "PAN", "SOPA", "CAFE", "FRUTA", "AGUA", "CHEF", "HORNO", "CUCHILLO", "PLATO", "TENEDOR", "VASO", "SERVILLETAS", "BATIDORA", "HARINA", "HUEVO", "LECHE"],
  "ANIMALES": ["GATO", "PERRO", "LORO", "LEON", "TIGRE", "OSO", "PEZ", "VACA", "PATO", "LOBO", "ELEFANTE", "JIRAFA", "ZEBRA", "MONO", "AGUILA", "DELFIN", "BALLENA", "TIBURON", "CABALLO", "OVEJA"],
  "VALORES": ["AMOR", "PAZ", "FE", "VIDA", "ALMA", "LUZ", "HONOR", "VERDAD", "GOZO", "UNION", "AMISTAD", "RESHETO", "BONDAD", "CALMA", "VALOR", "JUSTICIA", "LIBERTAD", "ESPERANZA", "GRACIA", "LEALTAD"],
  "CASA": ["SALA", "BAÑO", "CAMA", "SOFA", "PISO", "TECHO", "LLAVE", "FOCO", "RELOJ", "JARDIN", "PUERTA", "VENTANA", "SOTANO", "COCINA", "COMEDOR", "ESPEJO", "CUADRO", "ALFOMBRA", "SILLA", "LAMPARA"],
  "NATURALEZA": ["RIO", "MAR", "SOL", "LUNA", "FLOR", "ARBOL", "MONTE", "LLUVIA", "NUBE", "VIENTO", "NIEVE", "RAYO", "TRUENO", "BOSQUE", "SELVA", "DESIERTO", "PLAYA", "ARENA", "PIEDRA", "TIERRA"],
  "COLORES": ["ROJO", "AZUL", "GRIS", "ROSA", "VERDE", "NEGRO", "BLANCO", "LILA", "CIAN", "ORO", "PLATA", "VIOLETA", "NARANJA", "BEIGE", "MARRON", "TURQUESA", "INDIGO", "CORAL", "MAGENTA", "AMARILLO"],
  "FAMILIA": ["MAMA", "PAPA", "HIJO", "NIETO", "TIA", "TIO", "PRIMA", "ABUELO", "HERMANO", "NUERA", "SUEGRA", "SUEGRO", "CUÑADO", "PADRINO", "MADRINA", "BEBE", "ESPOSO", "MUJER", "SOBRINO", "PRIMO"],
  "ROPA": ["CAMISA", "PANTALON", "FALDA", "VESTIDO", "ZAPATO", "GORRO", "BUFANDA", "GUANTE", "ABRIGO", "MEDIA", "BOTAS", "CINTURON", "CORBATA", "SACO", "BLUSA", "PIJAMA", "SANDALIA", "LENTES", "RELOJ", "ANILLO"],
  "CIUDAD": ["CALLE", "AUTO", "BUS", "METRO", "PARQUE", "TIENDA", "CINE", "HOTEL", "BANCO", "PLAZA", "MUSEO", "ESCUELA", "MERCADO", "PUENTE", "TORRE", "BARRIO", "SEMAFORO", "ACERA", "TRAFICO", "GENTE"],
  "CUERPO": ["MANO", "PIE", "OJOS", "BOCA", "NARIZ", "PELO", "DEDO", "UÑA", "BRAZO", "PIERNA", "RODILLA", "CODO", "CUELLO", "ESPALDA", "PECHO", "CORAZON", "MENTE", "PIEL", "DIENTE", "LENGUA"],
};

void main() {
  runApp(const SopaSeniorApp());
}

class SopaSeniorApp extends StatelessWidget {
  const SopaSeniorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sopa Senior Pro',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),
        primaryColor: const Color(0xFF6D4C41),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6D4C41),
          primary: const Color(0xFF6D4C41),
          secondary: const Color(0xFFFFA726),
          surface: const Color(0xFFFFF8E1),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto', 
      ),
      home: const HomeScreen(),
    );
  }
}

// ==========================================
// 2. LÓGICA DE DIFICULTAD (EL CEREBRO)
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

  // Fórmula Maestra de Dificultad
  factory LevelConfig.fromLevel(int level) {
    // 1. Grid Size (Crece muy lento para mantener legibilidad)
    // Nivel 1: 8x8 -> Nivel 50: 10x9 -> Nivel 100+: Max 12x11 (Tope para seniors)
    int c = (8 + (level / 25)).floor().clamp(8, 11); 
    int r = (8 + (level / 20)).floor().clamp(8, 13);
    
    // 2. Cantidad de palabras (Crece linealmente)
    // Nivel 1: 5 palabras -> Nivel 150: 20 palabras (Max)
    int count = (5 + (level / 10)).floor().clamp(5, 20);

    // 3. Complejidad de direcciones
    bool diags = level > 5;
    bool reverse = level > 25; // Introduce palabras al revés en nivel 25

    // 4. Mezcla de temáticas (Chaos Mode)
    int mixes = 1;
    if (level >= 100) mixes = 2;
    if (level >= 200) mixes = 3;

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
// 3. PANTALLA DE INICIO
// ==========================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentLevel = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.orange.shade50, Colors.white],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'icon',
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: const Offset(0,5))],
                    ),
                    child: Icon(Icons.psychology_alt, size: 90, color: Colors.brown.shade700),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  "SOPA DE LETRAS",
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.brown.shade900, letterSpacing: 1.5),
                ),
                Text(
                  "Edición Senior",
                  style: TextStyle(fontSize: 20, color: Colors.brown.shade400, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 60),
                
                // Botón Jugar
                Transform.scale(
                  scale: 1.1,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => GameScreen(level: currentLevel)),
                      ).then((val) {
                        if (val != null && val is int) setState(() => currentLevel = val);
                      });
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      backgroundColor: const Color(0xFF6D4C41),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 8,
                    ),
                    icon: const Icon(Icons.play_circle_fill, size: 30),
                    label: const Text("JUGAR AHORA", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.brown.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.brown.shade200),
                  ),
                  child: Text(
                    "Nivel alcanzado: $currentLevel",
                    style: TextStyle(fontSize: 18, color: Colors.brown.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
                // Botón trampa para probar niveles altos (Solo para desarrollo)
                TextButton(
                  onPressed: () => setState(() => currentLevel += 10), 
                  child: const Text("Saltar +10 Niveles (Dev)", style: TextStyle(fontSize: 10, color: Colors.grey)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. PANTALLA DE JUEGO (GAME ENGINE)
// ==========================================

class GameScreen extends StatefulWidget {
  final int level;
  const GameScreen({super.key, required this.level});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late int currentLevel;
  late LevelConfig config;
  
  String levelTitle = "";
  List<String> activeWords = [];
  List<String> grid = [];
  List<String> foundWords = [];
  
  List<WordLine> persistentLines = [];
  WordLine? currentLine;
  int? startIndex, tempEndIndex;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.level;
    _initializeLevel();
  }

  void _initializeLevel() {
    setState(() {
      config = LevelConfig.fromLevel(currentLevel); // Calculamos dificultad
      
      // 1. Selección y Mezcla de Temáticas
      final random = Random();
      List<String> availableKeys = wordThemes.keys.toList();
      availableKeys.shuffle();
      
      // Tomamos N temáticas según dificultad
      List<String> selectedThemes = availableKeys.take(config.themesToMix).toList();
      
      // Generamos el título
      if (selectedThemes.length == 1) {
        levelTitle = selectedThemes.first;
      } else {
        levelTitle = "MIX: ${selectedThemes.join(' + ')}";
      }

      // 2. Construcción de pool de palabras
      Set<String> wordPool = {};
      for (var theme in selectedThemes) {
        wordPool.addAll(wordThemes[theme]!);
      }
      
      // Seleccionamos las palabras finales
      List<String> allWords = wordPool.toList()..shuffle();
      activeWords = allWords.take(config.wordCount).toList();

      // Limpieza
      foundWords.clear();
      persistentLines.clear();
      currentLine = null;
      startIndex = null;
      
      // 3. Generación del Tablero (Con reintentos inteligentes)
      _generateGrid();
    });
  }

  void _generateGrid() {
    grid = List.filled(config.rows * config.cols, '');
    final random = Random();
    
    // Ordenar palabras por longitud (fundamental para encajar 20 palabras)
    activeWords.sort((a, b) => b.length.compareTo(a.length));

    for (String word in activeWords) {
      bool placed = false;
      int attempts = 0;
      // Más intentos cuanto más alto el nivel
      int maxAttempts = 100 + (currentLevel * 2); 

      while (!placed && attempts < maxAttempts) {
        // Direcciones permitidas
        // 0:Horiz, 1:Vert, 2:Diag, 3:Diag-Up
        int maxDir = config.allowDiagonals ? 4 : 2;
        int dir = random.nextInt(maxDir);
        
        String finalWord = word;
        // Invertir palabra si el nivel lo permite
        if (config.allowReverse && random.nextBool()) {
          finalWord = word.split('').reversed.join('');
        }

        int row = random.nextInt(config.rows);
        int col = random.nextInt(config.cols);
        List<int> indices = _getIndices(row, col, finalWord.length, dir);

        if (indices.isNotEmpty && _canPlace(indices, finalWord)) {
          for (int i = 0; i < finalWord.length; i++) {
            grid[indices[i]] = finalWord[i];
          }
          placed = true;
        }
        attempts++;
      }
      
      // Si falla poner una palabra, reiniciamos todo el nivel (backtracking simple)
      if (!placed) {
        // Safety: Si falla muchas veces, podría reducir palabras, 
        // pero por ahora reintentamos recursivamente.
        _generateGrid(); 
        return;
      }
    }

    // Relleno
    const letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    for (int i = 0; i < grid.length; i++) {
      if (grid[i] == '') grid[i] = letters[random.nextInt(letters.length)];
    }
  }

  List<int> _getIndices(int row, int col, int len, int dir) {
    List<List<int>> deltas = [[0,1], [1,0], [1,1], [-1,1]];
    int dr = deltas[dir][0], dc = deltas[dir][1];
    List<int> idx = [];
    for(int i=0; i<len; i++){
      int r = row + dr*i, c = col + dc*i;
      if(r<0||r>=config.rows||c<0||c>=config.cols) return [];
      idx.add(r*config.cols+c);
    }
    return idx;
  }

  bool _canPlace(List<int> idx, String w) {
    for(int i=0; i<idx.length; i++){
      if(grid[idx[i]]!='' && grid[idx[i]]!=w[i]) return false;
    }
    return true;
  }

  // --- UI DIALOGS ---

  void _handleLevelComplete() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8E1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.emoji_events_rounded, size: 70, color: Colors.orange),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("¡Nivel Completado!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text("Has superado el nivel $currentLevel", style: const TextStyle(fontSize: 16)),
            if (currentLevel == 99) 
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text("¡Atención! A partir del próximo nivel se mezclarán temáticas.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(ctx); Navigator.pop(context, currentLevel + 1); }, // Guardar progreso
            child: const Text("Salir", style: TextStyle(color: Colors.brown)),
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
            child: const Text("Siguiente"),
          )
        ],
      ),
    );
  }

  // --- GESTOS Y PINTURA (Igual que antes pero usando config.cols) ---
  
  int _idx(Offset p, Size s) {
    double cw = s.width/config.cols, ch = s.height/config.rows;
    int c = (p.dx/cw).floor().clamp(0,config.cols-1), r = (p.dy/ch).floor().clamp(0,config.rows-1);
    return r*config.cols+c;
  }
  
  Offset _center(int i, Size s) {
    double cw = s.width/config.cols, ch = s.height/config.rows;
    int r = i ~/ config.cols, c = i % config.cols;
    return Offset((c*cw)+(cw/2), (r*ch)+(ch/2));
  }

  void _panStart(DragStartDetails d, Size s) {
    int i = _idx(d.localPosition, s);
    startIndex = i; tempEndIndex = i;
    HapticFeedback.lightImpact();
  }

  void _panUpdate(DragUpdateDetails d, Size s) {
    if(startIndex==null) return;
    int curr = _idx(d.localPosition, s);
    if(curr != tempEndIndex) {
      int r1 = startIndex! ~/ config.cols, c1 = startIndex! % config.cols;
      int r2 = curr ~/ config.cols, c2 = curr % config.cols;
      int dr = r2-r1, dc = c2-c1;
      if(dr==0 || dc==0 || dr.abs()==dc.abs()) {
        setState(() {
          tempEndIndex = curr;
          currentLine = WordLine(_center(startIndex!, s), _center(curr, s), Colors.orange.withOpacity(0.5));
        });
      }
    }
  }

  void _panEnd(DragEndDetails d, Size s) {
    if(startIndex!=null && tempEndIndex!=null) {
      String w = _getWord(startIndex!, tempEndIndex!);
      String rw = w.split('').reversed.join('');
      String? match;
      if(activeWords.contains(w) && !foundWords.contains(w)) match = w;
      else if(activeWords.contains(rw) && !foundWords.contains(rw)) match = rw;

      if(match != null) {
        HapticFeedback.heavyImpact();
        setState(() {
          foundWords.add(match!);
          persistentLines.add(WordLine(_center(startIndex!, s), _center(tempEndIndex!, s), Colors.green.withOpacity(0.4)));
        });
        if(foundWords.length == activeWords.length) _handleLevelComplete();
      }
    }
    setState(() { startIndex=null; tempEndIndex=null; currentLine=null; });
  }

  String _getWord(int s, int e) {
    int r1 = s~/config.cols, c1 = s%config.cols, r2 = e~/config.cols, c2 = e%config.cols;
    int dr = (r2-r1).sign, dc = (c2-c1).sign;
    int steps = max((r2-r1).abs(), (c2-c1).abs());
    StringBuffer sb = StringBuffer();
    for(int i=0; i<=steps; i++) sb.write(grid[(r1+dr*i)*config.cols + (c1+dc*i)]);
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text("NIVEL $currentLevel", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
            Text(levelTitle, style: TextStyle(fontSize: 12, color: Colors.brown.shade400, overflow: TextOverflow.ellipsis)),
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
          // Indicador de progreso 10/20
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                "${foundWords.length}/${activeWords.length}", 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade700)
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. LISTA DE PALABRAS (Ahora con Scroll porque pueden ser 20)
            Container(
              height: 110, // Un poco más alto para alojar muchas palabras
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3))]
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8, runSpacing: 8,
                  children: activeWords.map((word) {
                    bool found = foundWords.contains(word);
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: found ? 0.3 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: found ? Colors.green.withOpacity(0.1) : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: found ? Colors.green.withOpacity(0.3) : Colors.orange.shade200),
                        ),
                        child: Text(
                          word, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 13, 
                            color: found ? Colors.green : Colors.brown.shade800,
                            decoration: found ? TextDecoration.lineThrough : null
                          )
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            // 2. TABLERO
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: LayoutBuilder(
                  builder: (ctx, constr) {
                    Size s = Size(constr.maxWidth, constr.maxHeight);
                    double cellSize = min(s.width / config.cols, s.height / config.rows);
                    double boardWidth = cellSize * config.cols;
                    double boardHeight = cellSize * config.rows;
                    
                    return Center(
                      child: SizedBox(
                        width: boardWidth,
                        height: boardHeight,
                        child: GestureDetector(
                          onPanStart: (d) => _panStart(d, Size(boardWidth, boardHeight)),
                          onPanUpdate: (d) => _panUpdate(d, Size(boardWidth, boardHeight)),
                          onPanEnd: (d) => _panEnd(d, Size(boardWidth, boardHeight)),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]
                                ),
                              ),
                              CustomPaint(
                                size: Size(boardWidth, boardHeight),
                                painter: LinePainter(persistentLines, currentLine, config.cols, config.rows),
                              ),
                              GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: config.rows * config.cols,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: config.cols,
                                  childAspectRatio: 1.0,
                                ),
                                itemBuilder: (c, i) => Center(
                                  child: Text(
                                    grid[i], 
                                    style: TextStyle(
                                      fontSize: cellSize * 0.5,
                                      fontWeight: FontWeight.bold, 
                                      color: Colors.brown.shade900
                                    )
                                  )
                                ),
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
    );
  }
}

class WordLine {
  final Offset s, e; final Color c;
  WordLine(this.s, this.e, this.c);
}

class LinePainter extends CustomPainter {
  final List<WordLine> lines; final WordLine? cur; final int c, r;
  LinePainter(this.lines, this.cur, this.c, this.r);
  @override
  void paint(Canvas cv, Size sz) {
    final p = Paint()..style=PaintingStyle.stroke..strokeCap=StrokeCap.round..strokeWidth=(sz.width/c)*0.6;
    for(var l in lines) { p.color=l.c; cv.drawLine(l.s, l.e, p); }
    if(cur!=null) { p.color=cur!.c; cv.drawLine(cur!.s, cur!.e, p); }
  }
  @override
  bool shouldRepaint(covariant LinePainter old) => true;
}