import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';

/// Gold foil used for the frame and edges on every paper colour.
final _foil = AccentColor.gold.palette;

/// A closed gatefold invitation filling the canvas.
///
/// Two embossed cardstock panels meet down the middle along scalloped edges,
/// held shut by a wax seal across the seam. As [crack] goes from 0 to 1, a
/// crack runs through the seal along the seam, so the seal splits cleanly
/// when the panels open.
///
/// Sizes scale with the canvas width, so it also works as a small preview.
class GatefoldPainter extends CustomPainter {
  const GatefoldPainter({
    required this.paper,
    required this.wax,
    this.crack = 0,
  });

  final PaperPalette paper;
  final SatinPalette wax;
  final double crack;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 400;
    final c = size.center(Offset.zero);
    final scallop = 9 * unit;
    final foil = Paint()
      ..style = PaintingStyle.stroke
      ..shader = _foilShader(size);

    for (final isLeft in const [true, false]) {
      final edgeX = isLeft ? c.dx - scallop : c.dx + scallop;
      final outerX = isLeft ? 0.0 : size.width;

      final edge = Path()..moveTo(edgeX, 0);
      final bottom = _addScallops(edge, edgeX, scallop, size.height, isLeft);
      final panel = Path()
        ..moveTo(outerX, 0)
        ..lineTo(edgeX, 0)
        ..extendWithPath(edge, Offset.zero)
        ..lineTo(outerX, bottom)
        ..close();

      final bounds = isLeft
          ? Rect.fromLTRB(0, 0, c.dx, size.height)
          : Rect.fromLTRB(c.dx, 0, size.width, size.height);

      canvas.save();
      canvas.clipPath(panel);
      _paintPanel(canvas, bounds, unit, isLeft, foil);
      canvas.restore();

      canvas.drawPath(edge, foil..strokeWidth = 1.4 * unit);
    }

    _paintSeal(canvas, c, 56 * unit, unit);
  }

  /// Adds semicircles running down the panel's inner edge to [path], which
  /// must already be at (x, 0). Returns the y where they end.
  double _addScallops(
    Path path,
    double x,
    double radius,
    double height,
    bool isLeft,
  ) {
    var y = 0.0;
    while (y < height) {
      y += 2 * radius;
      // Bulges toward the centre: right for the left panel, left for the right.
      path.arcToPoint(
        Offset(x, y),
        radius: Radius.circular(radius),
        clockwise: isLeft,
      );
    }
    return y;
  }

  void _paintPanel(
    Canvas canvas,
    Rect bounds,
    double unit,
    bool isLeft,
    Paint foil,
  ) {
    canvas.drawRect(bounds, Paint()..color = paper.paper);

    // Embossed flowers on a staggered grid, set so each panel's pattern is
    // the mirror image of the other's.
    final step = 92 * unit;
    final flowers = Path();
    final sprigs = Path();
    var row = 0;
    for (var y = step * 0.4; y < bounds.bottom + step; y += step * 0.8, row++) {
      final offset = row.isEven ? 0.0 : step / 2;
      for (var d = step * 0.55 + offset; d < bounds.width + step; d += step) {
        final x = isLeft ? bounds.right - d : bounds.left + d;
        _addFlower(flowers, Offset(x, y), 30 * unit, leaves: true);
        _addFlower(
          sprigs,
          Offset(x + (isLeft ? -1 : 1) * step / 2, y + step * 0.4),
          9 * unit,
        );
      }
    }
    _emboss(canvas, flowers, unit);
    _emboss(canvas, sprigs, unit * 0.7);

    // Soft vignette so the panel reads as a sheet of card, not a flat fill.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [paper.embossShadow.withValues(alpha: 0), paper.embossShadow],
        ).createShader(bounds),
    );

    _paintGrain(canvas, bounds, unit);

    // Double foil frame with flourishes in the corners.
    final inset = 18 * unit;
    final innerGap = 26 * unit;
    final frame = Rect.fromLTRB(
      bounds.left + (isLeft ? inset : innerGap),
      bounds.top + inset,
      bounds.right - (isLeft ? innerGap : inset),
      bounds.bottom - inset,
    );
    canvas.drawRect(frame, foil..strokeWidth = 1.6 * unit);
    final inner = frame.deflate(6 * unit);
    canvas.drawRect(inner, foil..strokeWidth = 0.8 * unit);
    for (final corner in [
      (inner.topLeft, 1.0, 1.0),
      (inner.topRight, -1.0, 1.0),
      (inner.bottomLeft, 1.0, -1.0),
      (inner.bottomRight, -1.0, -1.0),
    ]) {
      _paintFlourish(canvas, corner.$1, corner.$2, corner.$3, unit, foil);
    }
  }

  /// Fine paper grain: scattered light and dark specks.
  void _paintGrain(Canvas canvas, Rect bounds, double unit) {
    final random = math.Random(bounds.left.round());
    final light = <Offset>[];
    final dark = <Offset>[];
    final count = (bounds.width * bounds.height / (40 * unit * unit)).round();
    for (var i = 0; i < count; i++) {
      final point = Offset(
        bounds.left + random.nextDouble() * bounds.width,
        bounds.top + random.nextDouble() * bounds.height,
      );
      (i.isEven ? light : dark).add(point);
    }
    canvas.drawPoints(
      ui.PointMode.points,
      light,
      Paint()
        ..strokeWidth = unit
        ..color = paper.embossLight.withValues(
          alpha: paper.embossLight.a * 0.4,
        ),
    );
    canvas.drawPoints(
      ui.PointMode.points,
      dark,
      Paint()
        ..strokeWidth = unit
        ..color = paper.embossShadow.withValues(
          alpha: paper.embossShadow.a * 0.5,
        ),
    );
  }

  /// A curled foil bracket pointing into the frame from [corner].
  void _paintFlourish(
    Canvas canvas,
    Offset corner,
    double dx,
    double dy,
    double unit,
    Paint foil,
  ) {
    Offset at(double x, double y) =>
        corner + Offset(dx * x * unit, dy * y * unit);

    final curl = Path()
      ..moveTo(at(6, 34).dx, at(6, 34).dy)
      ..quadraticBezierTo(at(6, 6).dx, at(6, 6).dy, at(34, 6).dx, at(34, 6).dy)
      ..moveTo(at(14, 24).dx, at(14, 24).dy)
      ..quadraticBezierTo(
        at(14, 14).dx,
        at(14, 14).dy,
        at(24, 14).dx,
        at(24, 14).dy,
      );
    canvas.drawPath(curl, foil..strokeWidth = 1.1 * unit);
    canvas.drawCircle(at(13, 13), 2.2 * unit, Paint()..shader = foil.shader);
  }

  void _paintSeal(Canvas canvas, Offset c, double r, double unit) {
    // Poured wax spreads into an uneven outline.
    final blob = Path();
    const points = 90;
    for (var i = 0; i <= points; i++) {
      final a = i / points * 2 * math.pi;
      final wobble =
          1 +
          0.045 * math.sin(a * 7 + 0.6) +
          0.03 * math.sin(a * 3 + 1.9) +
          0.015 * math.sin(a * 13);
      final p = c + Offset(math.cos(a), math.sin(a)) * r * wobble;
      if (i == 0) {
        blob.moveTo(p.dx, p.dy);
      } else {
        blob.lineTo(p.dx, p.dy);
      }
    }
    blob.close();

    canvas.drawShadow(blob, Colors.black, 5 * unit, false);
    canvas.drawPath(
      blob,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.4),
          radius: 0.9,
          colors: [wax.light, wax.base, wax.dark, wax.deep],
          stops: const [0, 0.35, 0.75, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r * 1.1)),
    );

    // The stamped hollow: shaded at the top left, lit at the bottom right.
    final disc = Rect.fromCircle(center: c, radius: 0.7 * r);
    canvas.drawOval(
      disc,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.2, 0.25),
          colors: [wax.base, wax.dark],
        ).createShader(disc),
    );
    canvas.drawOval(
      disc,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * unit
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [wax.deep, wax.light],
        ).createShader(disc),
    );

    // Raised emblem: a flower inside a ring of beads.
    final emblem = Path();
    _addFlower(emblem, c, 0.85 * r);
    for (var i = 0; i < 24; i++) {
      final a = i / 24 * 2 * math.pi;
      emblem.addOval(
        Rect.fromCircle(
          center: c + Offset(math.cos(a), math.sin(a)) * 0.58 * r,
          radius: 0.028 * r,
        ),
      );
    }
    final lift = 1.1 * unit;
    canvas.drawPath(
      emblem.shift(Offset(-lift, -lift)),
      Paint()..color = wax.gloss,
    );
    canvas.drawPath(
      emblem.shift(Offset(lift, lift)),
      Paint()..color = wax.deep,
    );
    canvas.drawPath(emblem, Paint()..color = wax.base);

    // Glossy wax catches the light along the upper-left rim.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 0.84 * r),
      math.pi * 1.1,
      math.pi * 0.35,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4 * unit
        ..color = Colors.white.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * unit),
    );

    if (crack > 0) _paintCrack(canvas, c, r, unit);
  }

  /// A jagged split down the seam, growing outward from the centre.
  void _paintCrack(Canvas canvas, Offset c, double r, double unit) {
    final reach = r * 1.08 * crack;
    final split = Path()..moveTo(c.dx, c.dy - reach);
    var side = 1.0;
    for (var y = c.dy - reach; y < c.dy + reach; y += 6 * unit) {
      split.lineTo(
        c.dx + side * 2.2 * unit,
        math.min(y + 6 * unit, c.dy + reach),
      );
      side = -side;
    }
    canvas.drawPath(
      split.shift(Offset(unit, 0)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = unit
        ..color = wax.light.withValues(alpha: 0.7),
    );
    canvas.drawPath(
      split,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * unit
        ..strokeJoin = StrokeJoin.miter
        ..color = wax.deep,
    );
  }

  /// Draws [path] as if pressed up out of the paper.
  void _emboss(Canvas canvas, Path path, double unit) {
    final lift = 1.2 * unit;
    canvas.drawPath(
      path.shift(Offset(-lift, -lift)),
      Paint()..color = paper.embossLight,
    );
    canvas.drawPath(
      path.shift(Offset(lift, lift)),
      Paint()..color = paper.embossShadow,
    );
    canvas.drawPath(path, Paint()..color = paper.paper);
  }

  /// A five-petal flower of overall size [size] centred on [p], optionally
  /// with two leaves.
  static void _addFlower(
    Path path,
    Offset p,
    double size, {
    bool leaves = false,
  }) {
    final petal = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(0, -0.3 * size),
          width: 0.28 * size,
          height: 0.44 * size,
        ),
      );
    for (var k = 0; k < 5; k++) {
      path.addPath(
        petal,
        Offset.zero,
        matrix4: (Matrix4.translationValues(
          p.dx,
          p.dy,
          0,
        )..rotateZ(k * 2 * math.pi / 5)).storage,
      );
    }
    path.addOval(Rect.fromCircle(center: p, radius: 0.1 * size));

    if (!leaves) return;
    final leaf = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(0, -0.66 * size),
          width: 0.14 * size,
          height: 0.36 * size,
        ),
      );
    for (final angle in const [0.8, -0.8]) {
      path.addPath(
        leaf,
        Offset.zero,
        matrix4: (Matrix4.translationValues(
          p.dx,
          p.dy,
          0,
        )..rotateZ(math.pi + angle)).storage,
      );
    }
  }

  /// Bands of light and dark repeating across the canvas, like foil
  /// catching the light.
  static Shader _foilShader(Size size) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_foil.light, _foil.base, _foil.dark, _foil.base, _foil.gloss],
      tileMode: TileMode.mirror,
    ).createShader(Rect.fromLTWH(0, 0, size.width * 0.5, size.height * 0.25));
  }

  @override
  bool shouldRepaint(GatefoldPainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.wax != wax ||
      oldDelegate.crack != crack;
}
