import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/paper_art.dart';

/// Carved palace doors in a pointed Moorish arch, set in an embossed wall
/// between two hanging lanterns.
///
/// [progress] runs the whole opening from 0 (closed) to 1 (gone):
///
/// * 0.00–0.15  light seeps through the seam between the doors
/// * 0.12–0.55  the doors swing inward, away from the viewer
/// * 0.50–0.95  the view moves through the arch and the wall falls away
///
/// Inside the arch is left transparent, so whatever is behind the painter
/// shows through as the doors open. [shimmer] (0 to 1) makes the lanterns
/// flicker while waiting. Sizes scale with the canvas width, so it also works
/// as a small preview.
class ArabicPainter extends CustomPainter {
  const ArabicPainter({
    required this.paper,
    required this.ornament,
    this.progress = 0,
    this.shimmer = 0.5,
  });

  final PaperPalette paper;
  final SatinPalette ornament;
  final double progress;
  final double shimmer;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final seep = phase(t, 0, 0.15);
    final swing = phase(t, 0.12, 0.55, Curves.easeInOutCubic);
    final through = phase(t, 0.5, 0.95, Curves.easeInCubic);

    final unit = size.width / 400;
    final opening = moorishArch(size, 0);
    final bounds = opening.getBounds();

    final focus = Offset(size.width / 2, size.height * 0.55);
    canvas.save();
    canvas.translate(focus.dx, focus.dy);
    canvas.scale(1 + 4 * through);
    canvas.translate(-focus.dx, -focus.dy);
    canvas.saveLayer(
      null,
      Paint()..color = Colors.black.withValues(alpha: 1 - through),
    );

    // Warm light from inside, strongest as the doors first part.
    final light = seep * (1 - swing * 0.6);
    if (light > 0) {
      canvas.save();
      canvas.clipPath(opening);
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = RadialGradient(
            colors: [
              ornament.gloss.withValues(alpha: 0.7 * light),
              ornament.light.withValues(alpha: 0),
            ],
          ).createShader(bounds),
      );
      canvas.restore();
    }

    for (final isLeft in const [true, false]) {
      _paintDoor(canvas, size, opening, isLeft, swing, unit);
    }
    if (seep > 0 && swing < 1) {
      canvas.drawLine(
        Offset(bounds.center.dx, bounds.top + bounds.height * 0.25),
        Offset(bounds.center.dx, bounds.bottom),
        Paint()
          ..strokeWidth = 3 * unit
          ..color = ornament.gloss.withValues(alpha: seep * (1 - swing))
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * unit),
      );
    }

    // The wall goes on top, so it also trims the doors to the arch.
    canvas.saveLayer(null, Paint());
    paintPaper(canvas, Offset.zero & size, paper, unit);
    canvas.drawPath(opening, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    _paintFrame(canvas, size, unit);
    final wallMiddle = (bounds.left - 22 * unit) / 2;
    for (final x in [wallMiddle, size.width - wallMiddle]) {
      _paintLantern(canvas, Offset(x, size.height * 0.22), unit);
    }

    canvas.restore();
    canvas.restore();
  }

  /// The gilded band around the arch, its threshold and a star keystone.
  void _paintFrame(Canvas canvas, Size size, double unit) {
    final area = Offset.zero & size;
    final metal = metalPaint(ornament, area);
    final band = Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(moorishArch(size, 22 * unit), Offset.zero)
      ..addPath(moorishArch(size, 0), Offset.zero);
    canvas.drawShadow(band, Colors.black, 4 * unit, false);
    canvas.drawPath(band, metal);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = ornament.deep;
    canvas.drawPath(moorishArch(size, 0), line..strokeWidth = 1.4 * unit);
    canvas.drawPath(
      moorishArch(size, 11 * unit),
      line..strokeWidth = 0.8 * unit,
    );
    canvas.drawPath(
      moorishArch(size, 30 * unit),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * unit
        ..shader = metal.shader,
    );

    final bounds = moorishArch(size, 0).getBounds();
    final threshold = Rect.fromLTRB(
      bounds.left - 30 * unit,
      bounds.bottom,
      bounds.right + 30 * unit,
      bounds.bottom + 12 * unit,
    );
    canvas.drawRect(threshold, metal);
    canvas.drawRect(threshold, line..strokeWidth = unit);

    final keystone = starPath(
      Offset(size.width / 2, bounds.top - 48 * unit),
      12 * unit,
    );
    canvas.drawShadow(keystone, Colors.black, 2 * unit, false);
    canvas.drawPath(keystone, metal);
  }

  void _paintDoor(
    Canvas canvas,
    Size size,
    Path opening,
    bool isLeft,
    double swing,
    double unit,
  ) {
    final b = opening.getBounds();
    final hingeX = isLeft ? b.left : b.right;
    final half = isLeft
        ? Rect.fromLTRB(b.left, b.top, b.center.dx, b.bottom)
        : Rect.fromLTRB(b.center.dx, b.top, b.right, b.bottom);
    final metal = metalPaint(ornament, b);

    canvas.save();
    canvas.translate(hingeX, 0);
    canvas.transform(
      (Matrix4.identity()
            ..setEntry(3, 2, 0.0012 / unit)
            ..rotateY((isLeft ? -1 : 1) * swing * math.pi / 2))
          .storage,
    );
    canvas.translate(-hingeX, 0);
    canvas.clipPath(opening);
    canvas.clipRect(half);

    // Carved wood, a shade darker than the wall: toward black on dark walls,
    // toward the ornament's warm tone on light ones so it doesn't turn grey.
    final wood = paper.paper.computeLuminance() > 0.4
        ? Color.lerp(paper.paper, ornament.dark, 0.45)!
        : Color.lerp(paper.paper, Colors.black, 0.35)!;
    canvas.drawRect(
      half,
      Paint()
        ..shader = LinearGradient(
          colors: [wood, Color.lerp(wood, Colors.white, 0.1)!, wood],
        ).createShader(half),
    );

    // Mashrabiya: a lattice of gold diamonds in an inset arched panel, above
    // a solid lower panel.
    final panelBottom = b.bottom - 120 * unit;
    canvas.save();
    canvas.clipPath(moorishArch(size, -16 * unit));
    canvas.clipRect(
      Rect.fromLTRB(
        half.left + (isLeft ? 0 : 10 * unit),
        b.top,
        half.right - (isLeft ? 10 * unit : 0),
        panelBottom,
      ),
    );
    final step = 16 * unit;
    final lattice = Path();
    final beads = Path();
    for (var d = -b.height; d < b.width + b.height; d += step) {
      lattice
        ..moveTo(b.left + d, b.top)
        ..lineTo(b.left + d - b.height, b.bottom)
        ..moveTo(b.left + d - b.height, b.top)
        ..lineTo(b.left + d, b.bottom);
    }
    for (var y = b.top; y < panelBottom; y += step / 2) {
      final shift = ((y - b.top) / (step / 2)).round().isEven ? 0.0 : step / 2;
      for (var x = b.left + shift; x < b.right; x += step) {
        beads.addOval(Rect.fromCircle(center: Offset(x, y), radius: 2 * unit));
      }
    }
    canvas.drawPath(
      lattice,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * unit
        ..shader = metal.shader,
    );
    canvas.drawPath(beads, metal);
    canvas.restore();

    final lower = Rect.fromLTRB(
      half.left + (isLeft ? 16 : 10) * unit,
      panelBottom + 14 * unit,
      half.right - (isLeft ? 10 : 16) * unit,
      b.bottom - 18 * unit,
    );
    canvas.drawRect(
      lower,
      Paint()..color = Color.lerp(wood, Colors.black, 0.2)!,
    );
    canvas.drawRect(
      lower,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * unit
        ..shader = metal.shader,
    );
    canvas.drawPath(starPath(lower.center, 10 * unit), metal);

    // Studs down the outer edge and a ring knocker by the seam.
    final edgeX = isLeft ? half.left + 7 * unit : half.right - 7 * unit;
    final studs = Path();
    for (
      var y = b.top + b.height * 0.3;
      y < b.bottom - 10 * unit;
      y += 22 * unit
    ) {
      studs.addOval(
        Rect.fromCircle(center: Offset(edgeX, y), radius: 2.4 * unit),
      );
    }
    canvas.drawPath(studs, metal);
    final knocker = Offset(
      isLeft ? half.right - 22 * unit : half.left + 22 * unit,
      b.top + b.height * 0.6,
    );
    canvas.drawCircle(knocker, 4 * unit, metal);
    canvas.drawCircle(
      knocker + Offset(0, 9 * unit),
      9 * unit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * unit
        ..shader = metal.shader,
    );

    // The seam edge, and shade as the door turns away from the light.
    final seamX = isLeft ? half.right : half.left;
    canvas.drawLine(
      Offset(seamX, b.top),
      Offset(seamX, b.bottom),
      Paint()
        ..strokeWidth = 2 * unit
        ..color = ornament.deep,
    );
    canvas.drawRect(
      half,
      Paint()..color = Colors.black.withValues(alpha: 0.5 * swing),
    );
    canvas.restore();
  }

  /// A fanous: a domed lantern on a chain, glowing from inside.
  void _paintLantern(Canvas canvas, Offset top, double unit) {
    Offset at(double x, double y) => top + Offset(x * unit, y * unit);
    final glow = 0.75 + 0.25 * shimmer;
    final warm = Color.lerp(ornament.gloss, const Color(0xFFFFD27A), 0.6)!;

    canvas.drawLine(
      Offset(top.dx, 0),
      top,
      Paint()
        ..strokeWidth = 1.2 * unit
        ..color = ornament.dark,
    );
    final halo = Rect.fromCircle(center: at(0, 34), radius: 46 * unit);
    canvas.drawOval(
      halo,
      Paint()
        ..shader = RadialGradient(
          colors: [
            warm.withValues(alpha: 0.35 * glow),
            warm.withValues(alpha: 0),
          ],
        ).createShader(halo),
    );

    final body = Path()
      ..moveTo(at(-11, 14).dx, at(-11, 14).dy)
      ..lineTo(at(11, 14).dx, at(11, 14).dy)
      ..lineTo(at(14, 32).dx, at(14, 32).dy)
      ..lineTo(at(9, 52).dx, at(9, 52).dy)
      ..lineTo(at(-9, 52).dx, at(-9, 52).dy)
      ..lineTo(at(-14, 32).dx, at(-14, 32).dy)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(warm, Colors.white, 0.5 * glow)!,
            warm,
            ornament.dark,
          ],
          stops: const [0, 0.6, 1],
        ).createShader(body.getBounds()),
    );
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * unit
      ..color = ornament.deep;
    canvas.drawPath(body, frame);
    canvas.drawPath(
      Path()
        ..moveTo(at(0, 14).dx, at(0, 14).dy)
        ..lineTo(at(0, 52).dx, at(0, 52).dy)
        ..moveTo(at(-14, 32).dx, at(-14, 32).dy)
        ..lineTo(at(14, 32).dx, at(14, 32).dy),
      frame..strokeWidth = 0.8 * unit,
    );

    final metal = metalPaint(
      ornament,
      Rect.fromCircle(center: top, radius: 60 * unit),
    );
    final dome = Path()
      ..moveTo(at(-13, 15).dx, at(-13, 15).dy)
      ..quadraticBezierTo(
        at(0, -6).dx,
        at(0, -6).dy,
        at(13, 15).dx,
        at(13, 15).dy,
      )
      ..close();
    canvas.drawPath(dome, metal);
    canvas.drawRect(Rect.fromPoints(at(-8, 52), at(8, 58)), metal);
    canvas.drawPath(
      Path()
        ..moveTo(at(-5, 58).dx, at(-5, 58).dy)
        ..lineTo(at(0, 68).dx, at(0, 68).dy)
        ..lineTo(at(5, 58).dx, at(5, 58).dy)
        ..close(),
      metal,
    );
  }

  @override
  bool shouldRepaint(ArabicPainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.ornament != ornament ||
      oldDelegate.progress != progress ||
      oldDelegate.shimmer != shimmer;
}

/// A pointed (Moorish) arch with straight sides down to a threshold, sized
/// for a canvas of [size] and grown outward by [grow].
Path moorishArch(Size size, double grow) {
  final cx = size.width / 2;
  final half = size.width * 0.36 + grow;
  final bottom = size.height * 0.93;
  final spring = size.height * 0.38;
  final apex = size.height * 0.13 - grow * 1.2;
  final rise = spring - apex;
  return Path()
    ..moveTo(cx - half, bottom)
    ..lineTo(cx - half, spring)
    ..cubicTo(
      cx - half,
      spring - rise * 0.55,
      cx - half * 0.35,
      apex + rise * 0.2,
      cx,
      apex,
    )
    ..cubicTo(
      cx + half * 0.35,
      apex + rise * 0.2,
      cx + half,
      spring - rise * 0.55,
      cx + half,
      spring,
    )
    ..lineTo(cx + half, bottom)
    ..close();
}
