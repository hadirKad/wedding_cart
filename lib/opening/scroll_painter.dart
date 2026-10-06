import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/bow_painter.dart';
import 'package:wedding_cart/opening/paper_art.dart';

/// A parchment scroll rolled up on two rollers and tied with a satin bow.
///
/// [progress] runs the whole opening from 0 (tied) to 1 (fully open):
///
/// * 0.00–0.25  the bow unties and the ribbon slips off
/// * 0.24–0.70  the rollers part, unrolling the parchment from the middle
/// * 0.68–0.95  the scroll comes forward to fill the canvas
///
/// Sizes scale with the canvas width, so it also works as a small preview.
class ScrollPainter extends CustomPainter {
  const ScrollPainter({
    required this.paper,
    required this.ribbon,
    this.progress = 0,
  });

  final PaperPalette paper;
  final SatinPalette ribbon;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final untie = phase(t, 0, 0.25, Curves.easeInCubic);
    final unroll = phase(t, 0.24, 0.70, Curves.easeInOutCubic);
    final grow = phase(t, 0.68, 0.95, Curves.easeInOutCubic);

    final unit = size.width / 400;
    final foil = foilPaint(size);
    paintBackdrop(canvas, size);

    final c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(1 + 0.35 * grow);
    canvas.translate(-c.dx, -c.dy);

    final width = size.width * 0.8;
    final radius = 13 * unit;
    final sheet = Rect.fromLTRB(
      c.dx - width / 2,
      size.height * 0.09,
      c.dx + width / 2,
      size.height * 0.91,
    );
    final topY = lerpDouble(c.dy - radius, sheet.top, unroll)!;
    final bottomY = lerpDouble(c.dy + radius, sheet.bottom, unroll)!;

    if (bottomY - topY > 2 * radius) {
      // The whole sheet is laid out at full size; only the unrolled part
      // between the rollers shows.
      final visible = Rect.fromLTRB(sheet.left, topY, sheet.right, bottomY);
      canvas.save();
      canvas.clipRect(visible);
      paintInvitationFace(canvas, sheet, paper, unit, foil);
      // Shade where the paper curls into each roller.
      for (final (edge, begin) in [
        (
          Rect.fromLTRB(sheet.left, topY, sheet.right, topY + 36 * unit),
          Alignment.topCenter,
        ),
        (
          Rect.fromLTRB(sheet.left, bottomY - 36 * unit, sheet.right, bottomY),
          Alignment.bottomCenter,
        ),
      ]) {
        canvas.drawRect(
          edge,
          Paint()
            ..shader = LinearGradient(
              begin: begin,
              end: -begin,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.black.withValues(alpha: 0),
              ],
            ).createShader(edge),
        );
      }
      canvas.restore();
    }

    _paintRoller(canvas, Offset(c.dx, topY), width, radius, unit);
    _paintRoller(canvas, Offset(c.dx, bottomY), width, radius, unit);

    if (untie < 1) _paintTie(canvas, c, radius, unit, untie);
    canvas.restore();
  }

  /// Parchment rolled around a rod with gold finials at each end.
  void _paintRoller(
    Canvas canvas,
    Offset centre,
    double width,
    double radius,
    double unit,
  ) {
    // Rod and finials stick out past the rolled paper.
    final knob = radius * 0.8;
    for (final side in const [-1.0, 1.0]) {
      final end = centre.dx + side * (width / 2 + 4 * unit);
      final rod = Rect.fromLTRB(
        side < 0 ? end - 12 * unit : end,
        centre.dy - radius * 0.3,
        side < 0 ? end : end + 12 * unit,
        centre.dy + radius * 0.3,
      );
      final ball = Offset(end + side * (12 * unit + knob * 0.8), centre.dy);
      final gold = AccentColor.gold.palette;
      canvas.drawRect(
        rod,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gold.dark, gold.light, gold.dark],
          ).createShader(rod),
      );
      canvas.drawCircle(
        ball,
        knob,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.4),
            colors: [gold.gloss, gold.base, gold.deep],
          ).createShader(Rect.fromCircle(center: ball, radius: knob)),
      );
    }

    final roll = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: centre,
        width: width + 8 * unit,
        height: 2 * radius,
      ),
      Radius.elliptical(radius * 0.45, radius),
    );
    canvas.drawRRect(
      roll.shift(Offset(0, 3 * unit)),
      Paint()
        ..color = Colors.black38
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * unit),
    );
    // Rounded like a cylinder: dark at the top and bottom, lit just above
    // the middle.
    canvas.drawRRect(
      roll,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(paper.paper, Colors.black, 0.35)!,
            Color.lerp(paper.paper, Colors.white, 0.35)!,
            paper.paper,
            Color.lerp(paper.paper, Colors.black, 0.45)!,
          ],
          stops: const [0, 0.3, 0.55, 1],
        ).createShader(roll.outerRect),
    );

    // The spiral of rolled paper visible at each end.
    for (final side in const [-1.0, 1.0]) {
      final endCentre = Offset(
        centre.dx + side * (roll.width / 2 - radius * 0.45),
        centre.dy,
      );
      for (final scale in const [0.75, 0.45]) {
        canvas.drawOval(
          Rect.fromCenter(
            center: endCentre,
            width: radius * 0.9 * scale,
            height: 2 * radius * scale,
          ),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = unit
            ..color = paper.embossShadow,
        );
      }
    }
  }

  /// A satin band around both rollers, finished with a bow. As [untie] goes
  /// from 0 to 1, the bow collapses and the band slips off.
  void _paintTie(
    Canvas canvas,
    Offset c,
    double radius,
    double unit,
    double untie,
  ) {
    final band = Rect.fromCenter(
      center: c,
      width: 16 * unit,
      height: 5 * radius * (1 - untie),
    );
    if (!band.isEmpty) {
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            colors: [
              ribbon.deep,
              ribbon.base,
              ribbon.light,
              ribbon.gloss,
              ribbon.light,
              ribbon.base,
              ribbon.deep,
            ],
            stops: const [0, 0.15, 0.32, 0.42, 0.55, 0.8, 1],
          ).createShader(band)
          ..color = Colors.black.withValues(alpha: 1 - untie),
      );
    }

    final bowSize = 100 * unit;
    canvas.save();
    canvas.translate(c.dx - bowSize / 2, c.dy - bowSize / 2);
    BowPainter(
      progress: untie,
      palette: ribbon,
    ).paint(canvas, Size.square(bowSize));
    canvas.restore();
  }

  @override
  bool shouldRepaint(ScrollPainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.ribbon != ribbon ||
      oldDelegate.progress != progress;
}
