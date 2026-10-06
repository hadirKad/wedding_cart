import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/paper_art.dart';

/// A panel of eight-point star geometry with a decorated border, the
/// Basmala above and a Qur'anic verse on marriage below, and a star rosette
/// in the centre.
///
/// [progress] runs the whole opening from 0 (closed) to 1 (gone):
///
/// * 0.00–0.20  the rosette turns an eighth of a turn
/// * 0.12–0.30  the rosette fades away
/// * 0.15–0.80  an eight-point star window opens from the centre, slowly
///   turning, until it clears the panel
///
/// Inside the window is transparent, so whatever is behind the painter shows
/// through. [shimmer] (0 to 1) moves the light across the rosette while
/// waiting. Sizes scale with the canvas width, so it also works as a small
/// preview.
class IslamicPainter extends CustomPainter {
  const IslamicPainter({
    required this.paper,
    required this.ornament,
    this.progress = 0,
    this.shimmer = 0.5,
  });

  final PaperPalette paper;
  final SatinPalette ornament;
  final double progress;
  final double shimmer;

  /// Surah An-Naba 78:8: "And We created you in pairs."
  static const _verse = 'وخلقناكم أزواجا';
  static const _basmala = 'بسم الله الرحمن الرحيم';

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final turn = phase(t, 0, 0.2, Curves.easeInOut);
    final fade = phase(t, 0.12, 0.3, Curves.easeIn);
    final open = phase(t, 0.15, 0.8, Curves.easeInCubic);

    final unit = size.width / 400;
    final c = size.center(Offset.zero);
    final area = Offset.zero & size;
    final metal = _metal(area);
    // Light ornament on dark paper, dark ornament on light paper.
    final onLight = paper.paper.computeLuminance() > 0.4;
    final ink = onLight ? ornament.dark : ornament.light;

    canvas.saveLayer(null, Paint());
    canvas.drawRect(area, Paint()..color = paper.paper);
    canvas.drawRect(
      area,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [paper.embossShadow.withValues(alpha: 0), paper.embossShadow],
        ).createShader(area),
    );
    _paintGeometry(canvas, size, unit, ink);
    _paintBorder(canvas, size, unit, metal);
    _paintCartouche(
      canvas,
      Offset(c.dx, 92 * unit),
      _basmala,
      21,
      unit,
      ink,
      metal,
    );
    _paintCartouche(
      canvas,
      Offset(c.dx, size.height - 92 * unit),
      _verse,
      18,
      unit,
      ink,
      metal,
    );

    final rotation = turn * math.pi / 4 + open * 0.6;
    final window = starPath(
      c,
      open * size.longestSide * 0.95,
      rotation: rotation,
    );
    if (open > 0) {
      canvas.drawPath(window, Paint()..blendMode = BlendMode.clear);
    }
    canvas.restore();

    if (open > 0) {
      // A gilded rim around the window's edge.
      canvas.drawPath(
        window,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * unit
          ..shader = metal.shader,
      );
    }

    if (fade < 1) {
      canvas.saveLayer(
        null,
        Paint()..color = Colors.black.withValues(alpha: 1 - fade),
      );
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rotation);
      canvas.scale(1 + 0.3 * fade);
      canvas.translate(-c.dx, -c.dy);
      _paintRosette(canvas, c, 72 * unit, unit);
      canvas.restore();
    }
  }

  Paint _metal(Rect area) => Paint()
    ..shader =
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ornament.light,
            ornament.base,
            ornament.dark,
            ornament.base,
            ornament.gloss,
          ],
          tileMode: TileMode.mirror,
        ).createShader(
          Rect.fromLTWH(
            area.left,
            area.top,
            area.width * 0.5,
            area.height * 0.25,
          ),
        );

  /// Large stars on a square grid with small stars between them.
  void _paintGeometry(Canvas canvas, Size size, double unit, Color ink) {
    final step = 64 * unit;
    final stars = Path();
    final c = size.center(Offset.zero);
    // Centred on the middle so the pattern is symmetrical.
    final startX = c.dx - (c.dx / step).ceil() * step;
    final startY = c.dy - (c.dy / step).ceil() * step;
    for (var y = startY; y < size.height + step; y += step) {
      for (var x = startX; x < size.width + step; x += step) {
        stars.addPath(starPath(Offset(x, y), step * 0.42), Offset.zero);
        stars.addPath(
          starPath(Offset(x + step / 2, y + step / 2), step * 0.16),
          Offset.zero,
        );
      }
    }
    canvas.drawPath(
      stars,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1 * unit
        ..color = ink.withValues(alpha: 0.4),
    );
  }

  /// A plain band inside two gilded rules, studded with small stars.
  void _paintBorder(Canvas canvas, Size size, double unit, Paint metal) {
    final outer = (Offset.zero & size).deflate(14 * unit);
    final inner = outer.deflate(16 * unit);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(outer)
        ..addRect(inner),
      Paint()..color = paper.paper,
    );
    final rule = Paint()
      ..style = PaintingStyle.stroke
      ..shader = metal.shader;
    canvas.drawRect(outer, rule..strokeWidth = 1.6 * unit);
    canvas.drawRect(inner, rule..strokeWidth = 1.6 * unit);

    final band = outer.deflate(8 * unit);
    final studs = Path();
    final gap = 20 * unit;
    for (var x = band.left + gap; x < band.right - gap / 2; x += gap) {
      studs.addPath(starPath(Offset(x, band.top), 3.4 * unit), Offset.zero);
      studs.addPath(starPath(Offset(x, band.bottom), 3.4 * unit), Offset.zero);
    }
    for (var y = band.top + gap; y < band.bottom - gap / 2; y += gap) {
      studs.addPath(starPath(Offset(band.left, y), 3.4 * unit), Offset.zero);
      studs.addPath(starPath(Offset(band.right, y), 3.4 * unit), Offset.zero);
    }
    for (final corner in [
      band.topLeft,
      band.topRight,
      band.bottomLeft,
      band.bottomRight,
    ]) {
      studs.addPath(starPath(corner, 8 * unit), Offset.zero);
    }
    canvas.drawPath(studs, metal);
  }

  /// Arabic text on a plain panel with pointed ends and a gilded edge.
  void _paintCartouche(
    Canvas canvas,
    Offset centre,
    String text,
    double fontSize,
    double unit,
    Color ink,
    Paint metal,
  ) {
    final words = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      text: TextSpan(
        text: text,
        style: TextStyle(color: ink, fontSize: fontSize * unit, height: 1.2),
      ),
    )..layout(maxWidth: 260 * unit);

    final half = Size(
      words.width / 2 + 34 * unit,
      words.height / 2 + 12 * unit,
    );
    final panel = Path()
      ..moveTo(centre.dx - half.width - 14 * unit, centre.dy)
      ..lineTo(centre.dx - half.width, centre.dy - half.height)
      ..lineTo(centre.dx + half.width, centre.dy - half.height)
      ..lineTo(centre.dx + half.width + 14 * unit, centre.dy)
      ..lineTo(centre.dx + half.width, centre.dy + half.height)
      ..lineTo(centre.dx - half.width, centre.dy + half.height)
      ..close();
    canvas.drawPath(panel, Paint()..color = paper.paper);
    canvas.drawPath(
      panel,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * unit
        ..shader = metal.shader,
    );
    for (final side in const [-1.0, 1.0]) {
      canvas.drawPath(
        starPath(
          Offset(centre.dx + side * (half.width - 12 * unit), centre.dy),
          5 * unit,
        ),
        metal,
      );
    }
    words.paint(canvas, centre - Offset(words.width / 2, words.height / 2));
  }

  /// Layered stars in gilded relief around a small flower.
  void _paintRosette(Canvas canvas, Offset c, double r, double unit) {
    final light = Alignment(-0.6 + 0.5 * shimmer, -0.6 + 0.3 * shimmer);
    Paint relief(double radius) => Paint()
      ..shader = RadialGradient(
        center: light,
        radius: 1.1,
        colors: [ornament.gloss, ornament.light, ornament.base, ornament.dark],
        stops: const [0, 0.25, 0.6, 1],
      ).createShader(Rect.fromCircle(center: c, radius: radius));
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = unit
      ..color = ornament.deep;

    final outer = starPath(c, r);
    canvas.drawShadow(outer, Colors.black, 6 * unit, false);
    canvas.drawPath(outer, relief(r));
    canvas.drawPath(outer, edge);

    final rotated = starPath(c, r * 0.82, rotation: math.pi / 8);
    canvas.drawPath(rotated, Paint()..color = paper.paper);
    canvas.drawPath(rotated, edge);

    canvas.drawCircle(c, r * 0.56, relief(r * 0.56));
    canvas.drawCircle(c, r * 0.56, edge);
    final ring = Path();
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * 2 * math.pi;
      ring.addOval(
        Rect.fromCircle(
          center: c + Offset(math.cos(a), math.sin(a)) * r * 0.47,
          radius: r * 0.035,
        ),
      );
    }
    canvas.drawPath(ring, Paint()..color = ornament.deep);

    final flower = Path();
    addFlower(flower, c, r * 0.62);
    canvas.drawPath(flower, Paint()..color = paper.paper);
    canvas.drawPath(flower, edge);
    canvas.drawPath(starPath(c, r * 0.12), relief(r * 0.12));
  }

  @override
  bool shouldRepaint(IslamicPainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.ornament != ornament ||
      oldDelegate.progress != progress ||
      oldDelegate.shimmer != shimmer;
}
