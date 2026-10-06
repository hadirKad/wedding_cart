import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';

/// Two satin bands crossing at the centre of the screen.
///
/// As [progress] goes from 0 to 1, each band pulls back toward the screen edges.
class RibbonPainter extends CustomPainter {
  const RibbonPainter({
    required this.progress,
    required this.palette,
    this.halfBand = 13,
  });

  final double progress;
  final SatinPalette palette;

  /// Half the thickness of each band, in logical pixels.
  final double halfBand;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final keep = 1 - progress;

    final horizontal = [
      Rect.fromLTRB(0, c.dy - halfBand, c.dx * keep, c.dy + halfBand),
      Rect.fromLTRB(
        size.width - (size.width - c.dx) * keep,
        c.dy - halfBand,
        size.width,
        c.dy + halfBand,
      ),
    ];
    final vertical = [
      Rect.fromLTRB(c.dx - halfBand, 0, c.dx + halfBand, c.dy * keep),
      Rect.fromLTRB(
        c.dx - halfBand,
        size.height - (size.height - c.dy) * keep,
        c.dx + halfBand,
        size.height,
      ),
    ];

    for (final rect in horizontal) {
      _paintBand(canvas, rect, Axis.horizontal);
    }
    // The vertical band sits on top, covering the seam between the doors.
    for (final rect in vertical) {
      _paintBand(canvas, rect, Axis.vertical);
    }
  }

  void _paintBand(Canvas canvas, Rect rect, Axis axis) {
    if (rect.isEmpty) return;

    final horizontal = axis == Axis.horizontal;
    // A soft, off-centre sheen with darker selvage edges, like flat satin.
    final satin = Paint()
      ..shader = LinearGradient(
        begin: horizontal ? Alignment.topCenter : Alignment.centerLeft,
        end: horizontal ? Alignment.bottomCenter : Alignment.centerRight,
        colors: [
          palette.deep,
          palette.base,
          palette.light,
          palette.gloss,
          palette.light,
          palette.base,
          palette.dark,
          palette.deep,
        ],
        stops: const [0, 0.12, 0.3, 0.38, 0.48, 0.7, 0.9, 1],
      ).createShader(rect);

    canvas.drawRect(
      rect.shift(Offset(0, halfBand * 0.15)),
      Paint()
        ..color = Colors.black26
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, halfBand * 0.23),
    );
    canvas.drawRect(rect, satin);
  }

  @override
  bool shouldRepaint(RibbonPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.palette != palette ||
      oldDelegate.halfBand != halfBand;
}

/// A satin bow centred in its canvas.
///
/// As [progress] goes from 0 to 1, the loops and knot collapse into the
/// centre and the tails drop away, all fading out. [sheen] (0 to 1) shifts
/// the highlights slightly so the fabric seems to catch moving light.
class BowPainter extends CustomPainter {
  const BowPainter({
    required this.progress,
    required this.palette,
    this.style = BowStyle.classic,
    this.sheen = 0.5,
  });

  final double progress;
  final SatinPalette palette;
  final BowStyle style;
  final double sheen;

  @override
  void paint(Canvas canvas, Size size) {
    final fade = (1 - progress).clamp(0.0, 1.0);
    if (fade == 0) return;

    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Draw everything opaque into one layer, then fade the whole bow at once.
    canvas.saveLayer(
      null,
      Paint()..color = Colors.black.withValues(alpha: fade),
    );

    // Tails sit behind the loops and fall as the bow unties.
    final tailLength = style == BowStyle.cascade ? 1.7 : 1.0;
    canvas.save();
    canvas.translate(0, progress * r * 1.6);
    for (final side in const [-1.0, 1.0]) {
      _paintTail(canvas, c, r, side, tailLength);
    }
    canvas.restore();

    // Loops and knot collapse into the centre.
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1 - progress);
    canvas.translate(-c.dx, -c.dy);
    if (style == BowStyle.layered) {
      // A larger pair raised behind, a smaller pair drooping in front.
      for (final side in const [-1.0, 1.0]) {
        _paintLoop(canvas, c, r, side, tilt: -0.32, scale: 1.05);
      }
      for (final side in const [-1.0, 1.0]) {
        _paintLoop(canvas, c, r, side, tilt: 0.12, scale: 0.78);
      }
    } else {
      for (final side in const [-1.0, 1.0]) {
        _paintLoop(canvas, c, r, side);
      }
    }
    _paintKnot(canvas, c, r);
    canvas.restore();

    canvas.restore();
  }

  /// [tilt] rotates the loop about the knot: negative lifts it, positive
  /// lets it droop.
  void _paintLoop(
    Canvas canvas,
    Offset c,
    double r,
    double side, {
    double tilt = 0,
    double scale = 1,
  }) {
    Offset at(double x, double y) => Offset(c.dx + side * x * r, c.dy + y * r);
    final shift = (sheen - 0.5) * 0.06;

    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(side * tilt);
    canvas.scale(scale);
    canvas.translate(-c.dx, -c.dy);

    final loop = Path()
      ..moveToPoint(at(0, 0))
      ..cubicToPoints(at(0.55, -0.95), at(1.15, -0.35), at(0.95, 0.15))
      ..cubicToPoints(at(0.8, 0.45), at(0.35, 0.25), at(0, 0))
      ..close();
    final bounds = loop.getBounds();

    canvas.drawShadow(loop, Colors.black54, 4, false);
    canvas.save();
    canvas.clipPath(loop);

    // Rounded body, lit from the upper outside of the loop.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: Alignment(side * 0.25, -0.45),
          radius: 0.95,
          colors: [palette.light, palette.base, palette.dark, palette.deep],
          stops: const [0, 0.4, 0.75, 1],
        ).createShader(bounds),
    );

    // The inside of the loop: the back of the ribbon, in shadow.
    final opening = Path()
      ..moveToPoint(at(0.42, -0.08))
      ..cubicToPoints(at(0.55, -0.36), at(0.86, -0.26), at(0.84, 0.02))
      ..cubicToPoints(at(0.8, 0.16), at(0.56, 0.08), at(0.42, -0.08))
      ..close();
    canvas.drawPath(
      opening,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.deep, palette.dark],
        ).createShader(opening.getBounds()),
    );
    // Where the fabric rolls over at the bottom of the opening.
    _gloss(
      canvas,
      Path()
        ..moveToPoint(at(0.84, 0.02))
        ..cubicToPoints(at(0.8, 0.16), at(0.56, 0.08), at(0.42, -0.08)),
      r,
      width: 0.05,
    );

    // The long satin highlight across the top of the loop.
    _gloss(
      canvas,
      Path()
        ..moveToPoint(at(0.18, -0.12 + shift))
        ..quadTo(at(0.42, -0.48 + shift), at(0.82, -0.32 + shift)),
      r,
    );

    // Fabric gathered and pinched into the knot.
    _crease(
      canvas,
      Path()
        ..moveToPoint(at(0.14, -0.08))
        ..quadTo(at(0.3, -0.2), at(0.5, -0.22)),
      r,
    );
    _crease(
      canvas,
      Path()
        ..moveToPoint(at(0.14, 0.06))
        ..quadTo(at(0.3, 0.14), at(0.52, 0.14)),
      r,
    );
    final pinch = Rect.fromCircle(center: c, radius: 0.5 * r);
    canvas.drawRect(
      pinch,
      Paint()
        ..shader = RadialGradient(
          colors: [
            palette.deep.withValues(alpha: 0.7),
            palette.deep.withValues(alpha: 0),
          ],
        ).createShader(pinch),
    );

    canvas.restore();
    canvas.drawPath(loop, _edge);
    canvas.restore();
  }

  void _paintTail(
    Canvas canvas,
    Offset c,
    double r,
    double side,
    double length,
  ) {
    Offset at(double x, double y) =>
        Offset(c.dx + side * x * r, c.dy + y * length * r);

    final tail = Path()
      ..moveToPoint(at(0.06, 0))
      ..quadTo(at(0.28, 0.5), at(0.56, 0.95))
      // Swallowtail notch at the end of the ribbon.
      ..lineToPoint(at(0.4, 0.8))
      ..lineToPoint(at(0.22, 1.02))
      ..quadTo(at(0.1, 0.5), at(-0.08, 0))
      ..close();
    final bounds = tail.getBounds();

    canvas.drawShadow(tail, Colors.black54, 3, false);
    canvas.save();
    canvas.clipPath(tail);

    // Bands of light and dark along the length read as a gentle twist.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.deep,
            palette.base,
            palette.light,
            palette.base,
            palette.dark,
            palette.base,
            palette.light,
          ],
          stops: const [0, 0.15, 0.32, 0.5, 0.64, 0.82, 1],
        ).createShader(bounds),
    );
    _gloss(
      canvas,
      Path()
        ..moveToPoint(at(0.1, 0.14))
        ..quadTo(at(0.22, 0.5), at(0.42, 0.86)),
      r,
      width: 0.08,
    );

    canvas.restore();
    canvas.drawPath(tail, _edge);
  }

  void _paintKnot(Canvas canvas, Offset c, double r) {
    final rect = Rect.fromCenter(center: c, width: 0.36 * r, height: 0.4 * r);
    final knot = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(0.1 * r)));
    final glossAt = 0.4 + (sheen - 0.5) * 0.12;

    canvas.drawShadow(knot, Colors.black54, 3, false);
    canvas.save();
    canvas.clipPath(knot);

    // Wrapped around the bow, so it's rounded top to bottom.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.deep,
            palette.base,
            palette.light,
            palette.base,
            palette.dark,
          ],
          stops: [0, glossAt - 0.2, glossAt, glossAt + 0.3, 1],
        ).createShader(rect),
    );
    // Gathers where the knot squeezes the fabric.
    for (final x in const [-0.08, 0.08]) {
      _crease(
        canvas,
        Path()
          ..moveTo(c.dx + x * r, rect.top)
          ..quadraticBezierTo(
            c.dx + x * 1.6 * r,
            c.dy,
            c.dx + x * r,
            rect.bottom,
          ),
        r,
      );
    }

    canvas.restore();
    canvas.drawPath(knot, _edge);
  }

  /// A satin highlight: a soft glow with a bright, narrow core.
  void _gloss(Canvas canvas, Path path, double r, {double width = 0.16}) {
    final strength = 0.75 + 0.25 * sheen;
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * r
        ..color = palette.gloss.withValues(alpha: 0.55 * strength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.4 * r),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width * 0.22 * r
        ..color = Colors.white.withValues(alpha: 0.85 * strength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.08 * r),
    );
  }

  /// A soft fold line in the fabric.
  void _crease(Canvas canvas, Path path, double r) {
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 0.04 * r
        ..color = palette.deep.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 0.025 * r),
    );
  }

  Paint get _edge => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8
    ..color = palette.deep.withValues(alpha: 0.5);

  @override
  bool shouldRepaint(BowPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.sheen != sheen ||
      oldDelegate.palette != palette ||
      oldDelegate.style != style;
}

extension on Path {
  void moveToPoint(Offset p) => moveTo(p.dx, p.dy);
  void lineToPoint(Offset p) => lineTo(p.dx, p.dy);
  void quadTo(Offset control, Offset end) =>
      quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
  void cubicToPoints(Offset c1, Offset c2, Offset end) =>
      cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
}
