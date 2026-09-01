import 'dart:math';
import 'package:flutter/material.dart';

/// Reusable breathing/pulsing widget for buttons and icons
class PulsingWidget extends StatefulWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final Duration duration;

  const PulsingWidget({
    super.key,
    required this.child,
    this.minScale = 0.96,
    this.maxScale = 1.04,
    this.duration = const Duration(milliseconds: 1200),
  });

  @override
  State<PulsingWidget> createState() => _PulsingWidgetState();
}

class _PulsingWidgetState extends State<PulsingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.child,
    );
  }
}

/// Floating encouragement popup when finding a word
class FloatingWordPopup extends StatefulWidget {
  final String message;
  final VoidCallback onComplete;

  const FloatingWordPopup({
    super.key,
    required this.message,
    required this.onComplete,
  });

  @override
  State<FloatingWordPopup> createState() => _FloatingWordPopupState();
}

class _FloatingWordPopupState extends State<FloatingWordPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scale = Tween<double>(begin: 0.3, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.elasticOut),
      ),
    );

    _opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 1.0, curve: Curves.easeIn),
      ),
    );

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: const Offset(0, -0.6),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offset,
      child: FadeTransition(
        opacity: _opacity,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Colors.yellow, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.star_rounded, color: Colors.yellow, size: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Confetti burst animation for win dialogs or celebrations
class ConfettiWidgetOverlay extends StatefulWidget {
  const ConfettiWidgetOverlay({super.key});

  @override
  State<ConfettiWidgetOverlay> createState() => _ConfettiWidgetOverlayState();
}

class _ConfettiWidgetOverlayState extends State<ConfettiWidgetOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    for (int i = 0; i < 40; i++) {
      _particles.add(_Particle(_rand));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _ConfettiPainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late Color color;
  late double size;
  late double rotation;

  _Particle(Random rand) {
    x = rand.nextDouble();
    y = rand.nextDouble() * 0.3; // Starts at top area
    vx = (rand.nextDouble() - 0.5) * 0.4;
    vy = rand.nextDouble() * 0.5 + 0.3;
    size = rand.nextDouble() * 8 + 6;
    rotation = rand.nextDouble() * pi * 2;
    final colors = [
      Colors.redAccent,
      Colors.amber,
      Colors.greenAccent,
      Colors.lightBlueAccent,
      Colors.purpleAccent,
      Colors.orangeAccent,
    ];
    color = colors[rand.nextInt(colors.length)];
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      double px = (p.x + p.vx * progress) * size.width;
      double py = ((p.y + p.vy * progress) % 1.0) * size.height;

      final paint = Paint()
        ..color = p.color.withValues(alpha: 1.0 - (py / size.height) * 0.5)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + progress * pi * 4);
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: p.size,
          height: p.size * 0.6,
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
