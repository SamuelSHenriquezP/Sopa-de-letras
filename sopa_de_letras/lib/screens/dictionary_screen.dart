import 'package:flutter/material.dart';
import '../data/dictionary.dart';

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
