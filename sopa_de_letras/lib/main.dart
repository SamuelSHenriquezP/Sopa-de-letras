import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'models/app_theme.dart';
import 'services/audio_manager.dart';
import 'services/iap_manager.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await AudioManager.init();
  runApp(const SopaSeniorApp());
}

class SopaSeniorApp extends StatefulWidget {
  const SopaSeniorApp({super.key});
  static SopaSeniorAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<SopaSeniorAppState>();
  @override
  State<SopaSeniorApp> createState() => SopaSeniorAppState();
}

class SopaSeniorAppState extends State<SopaSeniorApp>
    with WidgetsBindingObserver {
  int _themeIndex = 0;
  int _difficulty = 0;
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
      _themeIndex = (prefs.getInt('theme_index') ?? 0).clamp(0, myThemes.length - 1);
      _vibrationEnabled = prefs.getBool('vibration') ?? true;
      _isPro = prefs.getBool('is_pro') ?? false;
      _difficulty = prefs.getInt('difficulty') ?? 0;
    });
  }

  void _initIAP() {
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () => _subscription.cancel(),
      onError: (error) {},
    );
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    await IAPManager.initialize();
    if (mounted) setState(() {});
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
      if (heavy) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }
    }
  }

  void setProMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', value);
    setState(() => _isPro = value);
  }

  bool get isPro => _isPro;
  int get themeIndex => _themeIndex;
  int get difficulty => _difficulty;
  bool get vibrationEnabled => _vibrationEnabled;
  
  void setDifficulty(int diff) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('difficulty', diff);
    setState(() => _difficulty = diff);
  }

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
