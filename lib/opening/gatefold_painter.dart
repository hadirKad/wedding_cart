import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/paper_art.dart';

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
    final foil = foilPaint(size);

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
      // Mirrored so the pattern is symmetrical about the seam.
      paintPaper(canvas, bounds, paper, unit, mirror: isLeft);
      final inset = 18 * unit;
      final innerGap = 26 * unit;
      paintFoilFrame(
        canvas,
        Rect.fromLTRB(
          bounds.left + (isLeft ? inset : innerGap),
          bounds.top + inset,
          bounds.right - (isLeft ? innerGap : inset),
          bounds.bottom - inset,
        ),
        unit,
        foil,
      );
      canvas.restore();

      canvas.drawPath(edge, foil..strokeWidth = 1.4 * unit);
    }

    paintWaxSeal(canvas, c, 56 * unit, unit, wax, crack: crack);
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

  @override
  bool shouldRepaint(GatefoldPainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.wax != wax ||
      oldDelegate.crack != crack;
}
