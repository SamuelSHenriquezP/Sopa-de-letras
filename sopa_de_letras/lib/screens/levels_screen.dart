import 'package:flutter/material.dart';

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
