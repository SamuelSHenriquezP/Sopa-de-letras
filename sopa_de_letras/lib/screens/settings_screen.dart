import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../models/app_theme.dart';
import '../services/audio_manager.dart';
import '../services/iap_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    // Si los productos aún no han cargado, los cargamos ahora
    if (IAPManager.products.isEmpty) {
      _loadingProducts = true;
      IAPManager.initialize().then((_) {
        if (mounted) setState(() => _loadingProducts = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = SopaSeniorApp.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bool isPro = appState?.isPro ?? false;
    final String productPrice = IAPManager.products.isNotEmpty
        ? IAPManager.products.first.price
        : "";
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
                                boxShadow: const [
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
                  value: appState?.vibrationEnabled ?? true,
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
          const SizedBox(height: 25),
          Text("PRO", style: sectionStyle),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              leading: Icon(Icons.block, color: colors.primary),
              title: Text(
                isPro ? "Anuncios desactivados" : "Quitar anuncios",
                style: bodyStyle.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isPro
                    ? "Gracias por apoyar el juego."
                    : _loadingProducts
                        ? "Cargando precio..."
                        : productPrice.isNotEmpty
                            ? "Elimina los anuncios por $productPrice."
                            : "La compra no está disponible actualmente.",
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
              ),
              trailing: isPro
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : _loadingProducts
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton(
                          onPressed: IAPManager.products.isNotEmpty
                              ? () {
                                  IAPManager.buyRemoveAds();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Procesando compra..."),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            productPrice.isNotEmpty
                                ? productPrice
                                : "Quitar anuncios",
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 30),
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
              if (!context.mounted) return;
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
