import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';

// Drawing helpers shared by the stationery-style covers (gatefold, envelope
// and scroll). Sizes are given in multiples of `unit`, which painters set to
// canvas width / 400 so the same art scales down for previews.

/// Gold foil used for frames and trims on every paper colour.
final _foil = AccentColor.gold.palette;

/// A stroke paint in gold foil: bands of light and dark repeating across
/// [area], like foil catching the light.
Paint foilPaint(Size area) {
  return Paint()
    ..style = PaintingStyle.stroke
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [_foil.light, _foil.base, _foil.dark, _foil.base, _foil.gloss],
      tileMode: TileMode.mirror,
    ).createShader(Rect.fromLTWH(0, 0, area.width * 0.5, area.height * 0.25));
}

/// The dark, softly lit surface the card rests on.
void paintBackdrop(Canvas canvas, Size size) {
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const RadialGradient(
        radius: 0.8,
        colors: [Color(0xFF3A302A), Color(0xFF15110E)],
      ).createShader(rect),
  );
}

/// Textured cardstock filling [bounds]: embossed flowers, a soft vignette
/// and fine grain.
///
/// The flower grid is measured from the left edge, or from the right edge
/// when [mirror] is set, so two panels side by side can mirror each other.
void paintPaper(
  Canvas canvas,
  Rect bounds,
  PaperPalette paper,
  double unit, {
  bool mirror = false,
}) {
  canvas.drawRect(bounds, Paint()..color = paper.paper);

  final step = 92 * unit;
  final flowers = Path();
  final sprigs = Path();
  var row = 0;
  for (
    var y = bounds.top + step * 0.4;
    y < bounds.bottom + step;
    y += step * 0.8, row++
  ) {
    final offset = row.isEven ? 0.0 : step / 2;
    for (var d = step * 0.55 + offset; d < bounds.width + step; d += step) {
      final x = mirror ? bounds.right - d : bounds.left + d;
      addFlower(flowers, Offset(x, y), 30 * unit, leaves: true);
      addFlower(
        sprigs,
        Offset(x + (mirror ? -1 : 1) * step / 2, y + step * 0.4),
        9 * unit,
      );
    }
  }
  _emboss(canvas, flowers, paper, unit);
  _emboss(canvas, sprigs, paper, unit * 0.7);

  // Soft vignette so it reads as a sheet of card, not a flat fill.
  canvas.drawRect(
    bounds,
    Paint()
      ..shader = RadialGradient(
        radius: 0.9,
        colors: [paper.embossShadow.withValues(alpha: 0), paper.embossShadow],
      ).createShader(bounds),
  );

  paintGrain(canvas, bounds, paper, unit);
}

/// Fine paper grain: scattered light and dark specks.
void paintGrain(Canvas canvas, Rect bounds, PaperPalette paper, double unit) {
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
      ..color = paper.embossLight.withValues(alpha: paper.embossLight.a * 0.4),
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

/// A double foil frame along [frame] with curled flourishes in the corners.
void paintFoilFrame(Canvas canvas, Rect frame, double unit, Paint foil) {
  canvas.drawRect(frame, foil..strokeWidth = 1.6 * unit);
  final inner = frame.deflate(6 * unit);
  canvas.drawRect(inner, foil..strokeWidth = 0.8 * unit);
  for (final (corner, dx, dy) in [
    (inner.topLeft, 1.0, 1.0),
    (inner.topRight, -1.0, 1.0),
    (inner.bottomLeft, 1.0, -1.0),
    (inner.bottomRight, -1.0, -1.0),
  ]) {
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
}

/// The invitation card itself: plain cardstock, a foil frame and a short
/// greeting, laid out to fill [rect].
void paintInvitationFace(
  Canvas canvas,
  Rect rect,
  PaperPalette paper,
  double unit,
  Paint foil,
) {
  canvas.drawRect(rect, Paint()..color = paper.paper);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = RadialGradient(
        radius: 0.9,
        colors: [paper.embossShadow.withValues(alpha: 0), paper.embossShadow],
      ).createShader(rect),
  );
  paintGrain(canvas, rect, paper, unit);
  paintFoilFrame(canvas, rect.deflate(14 * unit), unit, foil);

  final greeting = TextPainter(
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    text: TextSpan(
      style: TextStyle(color: paper.ink),
      children: [
        TextSpan(
          text: "You're invited\n",
          style: TextStyle(
            fontSize: 26 * unit,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w300,
            height: 1.6,
          ),
        ),
        TextSpan(
          text: 'TO CELEBRATE OUR WEDDING',
          style: TextStyle(fontSize: 9 * unit, letterSpacing: 3 * unit),
        ),
      ],
    ),
  )..layout(maxWidth: rect.width - 60 * unit);
  final textTop = rect.center.dy - greeting.height / 2;
  greeting.paint(canvas, Offset(rect.center.dx - greeting.width / 2, textTop));

  final flower = Path();
  addFlower(flower, Offset(rect.center.dx, textTop - 22 * unit), 22 * unit);
  canvas.drawPath(flower, Paint()..shader = foil.shader);
}

/// A poured wax seal of radius [r] centred on [c].
///
/// As [crack] goes from 0 to 1, a jagged split runs down through it
/// vertically, growing outward from the centre.
void paintWaxSeal(
  Canvas canvas,
  Offset c,
  double r,
  double unit,
  SatinPalette wax, {
  double crack = 0,
}) {
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
      ..strokeWidth = 3 * r / 56
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [wax.deep, wax.light],
      ).createShader(disc),
  );

  // Raised emblem: a flower inside a ring of beads.
  final emblem = Path();
  addFlower(emblem, c, 0.85 * r);
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
  canvas.drawPath(emblem.shift(Offset(lift, lift)), Paint()..color = wax.deep);
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
      ..strokeWidth = 4 * r / 56
      ..color = Colors.white.withValues(alpha: 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * unit),
  );

  if (crack <= 0) return;
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

/// Adds a five-petal flower of overall size [size] centred on [p] to
/// [path], optionally with two leaves.
void addFlower(Path path, Offset p, double size, {bool leaves = false}) {
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

/// Draws [path] as if pressed up out of the paper.
void _emboss(Canvas canvas, Path path, PaperPalette paper, double unit) {
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

/// Maps [t] onto the slice of an animation between [begin] and [end],
/// clamped to 0–1 and passed through [curve].
double phase(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.linear,
]) {
  return curve.transform(((t - begin) / (end - begin)).clamp(0.0, 1.0));
}
