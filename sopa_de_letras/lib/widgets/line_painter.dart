import 'package:flutter/material.dart';
import '../models/word_line.dart';

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
