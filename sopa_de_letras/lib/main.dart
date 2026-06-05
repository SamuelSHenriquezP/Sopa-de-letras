import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:audioplayers/audioplayers.dart';

import 'data/dictionary.dart';
// ==========================================
// 1. GESTORES (AUDIO, IAP, ADS)
// ==========================================

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

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _musicOn = prefs.getBool('music_on') ?? true;
    _sfxOn = prefs.getBool('sfx_on') ?? true;

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
    if (_sfxOn)
      _menuSoundPlayer.play(
        AssetSource('audio/Menu de niveles.wav'),
        volume: 1.0,
      );
  }

  static void playGameMusic() async {
    _currentTrack = 'game';
    if (_musicOn) {
      _fadeTimer?.cancel();
      if (_bgmPlayer.state == PlayerState.playing) await _bgmPlayer.stop();
      await _bgmPlayer.setVolume(0);
      await _bgmPlayer.play(AssetSource('audio/Fondo - Sopa letras.wav'));
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

  static void resumeMusic() {
    if (_currentTrack == 'game') playGameMusic();
  }

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
    if (_sfxOn)
      _clickPlayer.play(
        AssetSource('audio/inicio rapido - menu - siguiente.wav'),
        volume: 1.0,
      );
  }

  static void playWin() {
    if (_sfxOn)
      _winPlayer.play(AssetSource('audio/ganar nivel.wav'), volume: 1.0);
  }

  static void playWordFound() {
    if (_sfxOn)
      _wordFoundPlayer.play(
        AssetSource('audio/Clin cuando encuentra palabra.wav'),
        volume: 1.0,
      );
  }

  static void toggleSFX(bool value) async {
    _sfxOn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sfx_on', value);
  }

  static bool get isMusicOn => _musicOn;
  static bool get isSfxOn => _sfxOn;
}

class IAPManager {
  static final InAppPurchase _iap = InAppPurchase.instance;
  static bool available = true;
  static List<ProductDetails> products = [];
  static const String _productId = 'remove_ads';
  static Future<void> initialize() async {
    available = await _iap.isAvailable();
    if (available) {
      const Set<String> ids = {_productId};
      final ProductDetailsResponse response = await _iap.queryProductDetails(
        ids,
      );
      products = response.productDetails;
    }
  }

  static void buyRemoveAds() {
    if (products.isNotEmpty) {
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: products.first,
      );
      _iap.buyNonConsumable(purchaseParam: purchaseParam);
    }
  }
}

class AdManager {
  // NOTA: REEMPLAZA ESTOS IDs CON LOS TUYOS REALES ANTES DE SUBIR A LA TIENDA
  static final String _bannerId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';
  static final String _interstitialId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';
  static final String _rewardedId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialReady = false;
  bool _isRewardedReady = false;
  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
        },
        onAdFailedToLoad: (err) {
          _isInterstitialReady = false;
        },
      ),
    );
  }

  void showInterstitial(bool isPro, Function onAdClosed) {
    if (isPro) {
      onAdClosed();
      return;
    }
    if (_isInterstitialReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadInterstitial();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadInterstitial();
          onAdClosed();
        },
      );
      _interstitialAd!.show();
      _isInterstitialReady = false;
    } else {
      onAdClosed();
      loadInterstitial();
    }
  }

  void loadRewarded() {
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedReady = true;
        },
        onAdFailedToLoad: (err) {
          _isRewardedReady = false;
        },
      ),
    );
  }

  void showRewarded(Function onUserEarnedReward) {
    if (_isRewardedReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          loadRewarded();
        },
      );
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward();
        },
      );
      _isRewardedReady = false;
    } else {
      loadRewarded();
    }
  }

  static BannerAd createBanner() {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }
}

// ==========================================
// 2. DATA (TEMAS + DICCIONARIO + MOTIVACIÓN)
// ==========================================


class AppTheme {
  final String name;
  final Color background;
  final Color primary;
  final Color surface;
  final Color text;
  final Color accent;
  final Brightness brightness;
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
  AppTheme(
    name: "Clásico",
    background: const Color(0xFFFDFBF7),
    primary: const Color(0xFF6D4C41),
    surface: const Color(0xFFFFF8E1),
    text: const Color(0xFF4E342E),
    accent: const Color(0xFFFFA726),
    brightness: Brightness.light,
  ),
  AppTheme(
    name: "Noche",
    background: const Color(0xFF121212),
    primary: const Color(0xFF90CAF9),
    surface: const Color(0xFF1E1E1E),
    text: const Color(0xFFEEEEEE),
    accent: const Color(0xFF64B5F6),
    brightness: Brightness.dark,
  ),
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

// ==========================================
// 3. MAIN & STATE
// ==========================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await AudioManager.init();
  runApp(const SopaSeniorApp());
}

class SopaSeniorApp extends StatefulWidget {
  const SopaSeniorApp({super.key});
  static _SopaSeniorAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_SopaSeniorAppState>();
  @override
  State<SopaSeniorApp> createState() => _SopaSeniorAppState();
}

class _SopaSeniorAppState extends State<SopaSeniorApp>
    with WidgetsBindingObserver {
  int _themeIndex = 0;
  bool _vibrationEnabled = true;
  bool _isPro = false;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _initIAP();
    AudioManager.resumeMusic();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AudioManager.stopBGM();
    } else if (state == AppLifecycleState.resumed) {
      if (AudioManager.isMusicOn) AudioManager.resumeMusic();
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeIndex = prefs.getInt('theme_index') ?? 0;
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
      _isPro = prefs.getBool('is_pro') ?? false;
    });
  }

  void _initIAP() async {
    await IAPManager.initialize();
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () => _subscription.cancel(),
      onError: (error) {},
    );
  }

  void _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.purchased ||
          purchaseDetails.status == PurchaseStatus.restored) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_pro', true);
        setState(() {
          _isPro = true;
        });
        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }

  void changeTheme(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_index', index);
    setState(() => _themeIndex = index);
  }

  void toggleVibration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('vibration', value);
    setState(() => _vibrationEnabled = value);
  }

  void vibrate({bool heavy = false}) {
    if (_vibrationEnabled) {
      if (heavy)
        HapticFeedback.heavyImpact();
      else
        HapticFeedback.lightImpact();
    }
  }

  void setProMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    setState(() => _isPro = value);
  }

  bool get isPro => _isPro;

  @override
  Widget build(BuildContext context) {
    final currentTheme = myThemes[_themeIndex];
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sopa Senior Pro',
      theme: ThemeData(
        brightness: currentTheme.brightness,
        scaffoldBackgroundColor: currentTheme.background,
        primaryColor: currentTheme.primary,
        cardColor: currentTheme.surface,
        dividerColor: currentTheme.primary.withValues(alpha: 0.2),
        colorScheme: ColorScheme.fromSeed(
          seedColor: currentTheme.primary,
          primary: currentTheme.primary,
          surface: currentTheme.surface,
          secondary: currentTheme.accent,
          onSurface: currentTheme.text,
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
// 4. HOME SCREEN
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

  Future<void> _refreshData() async {
    await Future.delayed(
      const Duration(milliseconds: 100),
    ); // Delay para asegurar guardado
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        availableHints = prefs.getInt('hints') ?? 5;
        maxUnlockedLevel = prefs.getInt('max_level') ?? 1;
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

  @override
  Widget build(BuildContext context) {
    if (isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPro = SopaSeniorApp.of(context)?.isPro ?? false;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.settings, size: 30, color: colors.primary),
            onPressed: () {
              AudioManager.playClick();
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Edición Senior",
                    style: TextStyle(
                      fontSize: 20,
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.2),
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
                        vertical: 15,
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
                      size: 24,
                      color: colors.primary,
                    ),
                    label: Text(
                      "NIVELES",
                      style: TextStyle(
                        fontSize: 16,
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
                        vertical: 15,
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
                      size: 24,
                      color: colors.primary,
                    ),
                    label: Text(
                      "DICCIONARIO",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
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
// 5. DICTIONARY SCREEN
// ==========================================
class DictionaryScreen extends StatelessWidget {
  final int maxUnlocked;
  const DictionaryScreen({super.key, required this.maxUnlocked});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Diccionario Colombiano",
          style: TextStyle(color: colors.onSurface),
        ),
        centerTitle: true,
        leading: BackButton(color: colors.onSurface),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: colombianDictionary.length,
        itemBuilder: (context, index) {
          bool isUnlocked =
              index < (maxUnlocked - 1); // Se desbloquea 1 por nivel
          final entry = colombianDictionary[index];
          return Card(
            elevation: isUnlocked ? 2 : 0,
            color: isUnlocked ? colors.surface : Colors.grey.withValues(alpha: 0.1),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? colors.secondary.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUnlocked ? Icons.lock_open_rounded : Icons.lock,
                  color: isUnlocked ? colors.secondary : Colors.grey,
                ),
              ),
              title: Text(
                isUnlocked ? entry['word']! : "Nivel ${index + 1}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isUnlocked ? colors.primary : Colors.grey,
                ),
              ),
              subtitle: isUnlocked
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        entry['meaning']!,
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    )
                  : const Text(
                      "Completa el nivel para desbloquear.",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 6. SETTINGS SCREEN
// ==========================================
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = SopaSeniorApp.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isPro = appState?.isPro ?? false;
    final sectionStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
      color: colors.onSurface.withValues(alpha: 0.6),
    );
    final bodyStyle = TextStyle(fontSize: 16, color: colors.onSurface);

    return Scaffold(
      appBar: AppBar(
        title: Text("Ajustes", style: TextStyle(color: colors.onSurface)),
        centerTitle: true,
        leading: BackButton(color: colors.onSurface),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!isPro) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.deepOrange.shade600],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: const Icon(Icons.star, color: Colors.white, size: 40),
                title: const Text(
                  "QUITAR ANUNCIOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: const Text(
                  "Juega sin interrupciones por \$1.99",
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
                onTap: () {
                  if (IAPManager.available) {
                    IAPManager.buyRemoveAds();
                  }
                },
              ),
            ),
            const SizedBox(height: 25),
          ],
          Text("APARIENCIA", style: sectionStyle),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Text("Elige un tema visual", style: bodyStyle),
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
                                      : Colors.grey.withValues(alpha: 0.5),
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
          Text("JUEGO", style: sectionStyle),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text("Música", style: bodyStyle),
                  secondary: Icon(Icons.music_note, color: colors.primary),
                  value: AudioManager.isMusicOn,
                  activeThumbColor: colors.primary,
                  onChanged: (val) {
                    AudioManager.toggleMusic(val);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text("Sonidos", style: bodyStyle),
                  secondary: Icon(Icons.volume_up, color: colors.primary),
                  value: AudioManager.isSfxOn,
                  activeThumbColor: colors.primary,
                  onChanged: (val) {
                    AudioManager.toggleSFX(val);
                    setState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text("Vibración", style: bodyStyle),
                  subtitle: Text(
                    "Vibrar al encontrar",
                    style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
                  ),
                  secondary: Icon(Icons.vibration, color: colors.primary),
                  value: SopaSeniorApp.of(context)?._vibrationEnabled ?? true,
                  activeThumbColor: colors.primary,
                  onChanged: (val) {
                    appState?.toggleVibration(val);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Text("DATOS", style: sectionStyle),
          Card(
            color: Colors.red.withValues(alpha: 0.1),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
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
                "Borra todo.",
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
              ),
              onTap: () {
                _showResetDialog(context, colors.onSurface);
              },
            ),
          ),
          const SizedBox(height: 30),
          if (!isPro)
            Center(
              child: TextButton(
                onPressed: () => appState?.setProMode(true),
                child: const Text(
                  "DEV: Simular Compra Exitosa",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          if (isPro)
            Center(
              child: TextButton(
                onPressed: () => appState?.setProMode(false),
                child: const Text(
                  "DEV: Cancelar Premium",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 20),
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
          "Perderás todo tu avance.",
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
// 7. LEVELS SCREEN
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
                    ? colors.surface.withValues(alpha: 0.5)
                    : (isCurrent
                          ? colors.secondary.withValues(alpha: 0.2)
                          : colors.surface),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isLocked
                      ? Colors.grey.withValues(alpha: 0.3)
                      : (isCurrent
                            ? colors.secondary
                            : colors.primary.withValues(alpha: 0.3)),
                  width: isCurrent ? 3 : 1,
                ),
                boxShadow: isLocked
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Center(
                child: isLocked
                    ? Icon(Icons.lock, color: Colors.grey.withValues(alpha: 0.5))
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
// 8. LEVEL CONFIG
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
// 9. GAME SCREEN
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
  String? lastHintedWord;
  late AdManager _adManager;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  bool isPro = false;

  @override
  void initState() {
    super.initState();
    currentLevel = widget.level;
    _adManager = AdManager();
    _checkProStatusAndLoadAds();
    _loadHints();
    _initializeLevel();
  }

  void _checkProStatusAndLoadAds() {
    final proStatus = SopaSeniorApp.of(context)?.isPro ?? false;
    setState(() {
      isPro = proStatus;
    });
    AudioManager.playGameMusic();
    if (!isPro) {
      _bannerAd = AdManager.createBanner();
      _bannerAd?.load().then((_) {
        if (mounted)
          setState(() {
            _isBannerLoaded = true;
          });
      });
      _adManager.loadInterstitial();
    }
    _adManager.loadRewarded();
  }

  @override
  void dispose() {
    hintTimer?.cancel();
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
    int savedMax = prefs.getInt('max_level') ?? 1;
    int nextLevel = currentLevel + 1;
    if (nextLevel > savedMax) {
      await prefs.setInt('max_level', nextLevel);
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
      Set<String> rawWordPool = {};
      for (var theme in selectedThemes)
        if (wordThemes.containsKey(theme))
          rawWordPool.addAll(wordThemes[theme]!);

      int maxDimension = max(config.rows, config.cols);
      List<String> validWords = rawWordPool
          .where((w) => w.length <= maxDimension)
          .toList();
      if (validWords.isEmpty)
        validWords = ["SOL", "LUZ", "MAR", "DIA", "PAN", "ORO", "RIO", "FLOR"];
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
            for (int i = 0; i < finalWord.length; i++)
              grid[indices[i]] = finalWord[i];
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
        if (totalRetries % 10 == 0 && activeWords.isNotEmpty)
          activeWords.removeAt(0);
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

  void _handleLevelComplete() {
    hintTimer?.cancel();
    AudioManager.fadeOutMusic();
    final colors = Theme.of(context).colorScheme;
    AudioManager.playWin();
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
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Icon(
          Icons.emoji_events_rounded,
          size: 70,
          color: colors.secondary,
        ),
        content: SingleChildScrollView(
          child: Column(
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
                motivation,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (unlockedWord != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.menu_book,
                            size: 20,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "DICCIONARIO DESBLOQUEADO",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        unlockedWord,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        unlockedMeaning!,
                        style: TextStyle(fontSize: 14, color: colors.onSurface),
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
                    color: Colors.grey,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: Text("Menú", style: TextStyle(color: colors.primary)),
          ),
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
      if (activeWords.contains(w) && !foundWords.contains(w))
        match = w;
      else if (activeWords.contains(rw) && !foundWords.contains(rw))
        match = rw;
      if (match != null) {
        SopaSeniorApp.of(context)?.vibrate(heavy: true);
        AudioManager.playWordFound();
        setState(() {
          foundWords.add(match!);
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
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Row(
            children: [
              Text(
                "Nivel $currentLevel",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  levelTitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          centerTitle: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
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
              if (currentLevel == 1 && foundWords.isEmpty)
                Positioned(
                  top: 150,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 60,
                            color: colors.secondary.withValues(alpha: 0.8),
                          ),
                          Text(
                            "Arrastra para seleccionar",
                            style: TextStyle(
                              color: colors.secondary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              shadows: [
                                Shadow(blurRadius: 2, color: colors.surface),
                              ],
                            ),
                          ),
                        ],
                      ),
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

