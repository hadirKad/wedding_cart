import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/paper_art.dart';

/// A lined envelope, sealed with wax, holding the invitation card.
///
/// [progress] runs the whole opening from 0 (sealed) to 1 (card filling the
/// canvas):
///
/// * 0.00–0.15  the seal cracks
/// * 0.12–0.24  the broken seal falls away
/// * 0.18–0.42  the flap lifts open
/// * 0.40–0.66  the card slides up out of the envelope
/// * 0.64–0.95  the card grows to fill the canvas as the envelope drops away
///
/// Sizes scale with the canvas width, so it also works as a small preview.
class EnvelopePainter extends CustomPainter {
  const EnvelopePainter({
    required this.paper,
    required this.wax,
    this.initials = '',
    this.progress = 0,
  });

  final PaperPalette paper;
  final SatinPalette wax;

  /// Stamped into the wax seal; a flower when empty.
  final String initials;
  final double progress;

  /// The card inside is always ivory, whatever colour the envelope is.
  static final _card = PaperColor.ivory.palette;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress;
    final crack = phase(t, 0, 0.15);
    final sealGone = phase(t, 0.12, 0.24, Curves.easeIn);
    final flap = phase(t, 0.18, 0.42, Curves.easeInOutCubic);
    final rise = phase(t, 0.40, 0.66, Curves.easeOutCubic);
    final grow = phase(t, 0.64, 0.95, Curves.easeInOutCubic);

    final unit = size.width / 400;
    final foil = foilPaint(size);
    paintBackdrop(canvas, size);

    final envWidth = size.width * 0.86;
    final envHeight = envWidth * 0.68;
    final env = Rect.fromCenter(
      center: Offset(
        size.width / 2,
        size.height * 0.6 + grow * size.height * 0.7,
      ),
      width: envWidth,
      height: envHeight,
    );

    final cardRest = Rect.fromLTWH(
      env.left + 10 * unit,
      env.top + 8 * unit,
      envWidth - 20 * unit,
      envHeight - 14 * unit,
    );
    // Slides all the way clear of the pocket before it starts to grow.
    final cardOut = cardRest.shift(Offset(0, -rise * (envHeight - 2 * unit)));
    final card = Rect.lerp(cardOut, Offset.zero & size, grow)!;

    canvas.saveLayer(
      null,
      Paint()..color = Colors.black.withValues(alpha: 1 - grow),
    );
    canvas.drawShadow(Path()..addRect(env), Colors.black, 10 * unit, false);
    _paintLiner(canvas, env, unit, foil);
    // Once past upright, the open flap sits behind the card.
    if (flap > 0.5) _paintFlap(canvas, env, flap, unit, foil);
    if (grow == 0) _paintCard(canvas, card, cardRest, unit, foil);
    _paintPocket(canvas, env, unit, foil);
    if (flap <= 0.5) _paintFlap(canvas, env, flap, unit, foil);

    if (sealGone < 1) {
      final seal = Offset(env.center.dx, env.top + envHeight * 0.55);
      canvas.saveLayer(
        null,
        Paint()..color = Colors.black.withValues(alpha: 1 - sealGone),
      );
      canvas.translate(seal.dx, seal.dy + sealGone * 30 * unit);
      canvas.scale(1 - 0.3 * sealGone);
      canvas.translate(-seal.dx, -seal.dy);
      paintWaxSeal(
        canvas,
        seal,
        32 * unit,
        unit,
        wax,
        crack: crack,
        initials: initials,
      );
      canvas.restore();
    }
    canvas.restore();

    if (grow > 0) _paintCard(canvas, card, cardRest, unit, foil);
  }

  /// The patterned lining seen inside the envelope and under the flap.
  void _paintLiner(Canvas canvas, Rect rect, double unit, Paint foil) {
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [wax.dark, wax.deep],
        ).createShader(rect),
    );
    final step = 26 * unit;
    final flowers = Path();
    var row = 0;
    for (var y = rect.top; y < rect.bottom + step; y += step * 0.8, row++) {
      final offset = row.isEven ? 0.0 : step / 2;
      for (var x = rect.left + offset; x < rect.right + step; x += step) {
        addFlower(flowers, Offset(x, y), 10 * unit);
      }
    }
    canvas.save();
    canvas.clipRect(rect);
    canvas.drawPath(
      flowers,
      Paint()
        ..shader = foil.shader
        ..color = Colors.black.withValues(alpha: 0.55),
    );
    canvas.restore();
  }

  /// The top flap, hinged along the envelope's top edge. Closed at 0, lying
  /// open above the envelope at 1.
  void _paintFlap(
    Canvas canvas,
    Rect env,
    double flap,
    double unit,
    Paint foil,
  ) {
    final hinge = env.topCenter;
    final tip = Offset(env.center.dx, env.top + env.height * 0.58);
    final flapPath = Path()
      ..moveTo(env.left, env.top)
      ..lineTo(env.right, env.top)
      ..lineTo(tip.dx, tip.dy)
      ..close();

    canvas.save();
    canvas.translate(hinge.dx, hinge.dy);
    canvas.transform(
      (Matrix4.identity()
            ..setEntry(3, 2, 0.0015 / unit)
            ..rotateX(flap * math.pi))
          .storage,
    );
    canvas.translate(-hinge.dx, -hinge.dy);

    if (flap <= 0.5) {
      // The outside of the flap, trimmed in foil.
      canvas.drawShadow(flapPath, Colors.black, 4 * unit, false);
      canvas.save();
      canvas.clipPath(flapPath);
      paintPaper(canvas, env, paper, unit);
      canvas.restore();
      canvas.drawPath(
        Path()
          ..moveTo(env.left, env.top)
          ..lineTo(tip.dx, tip.dy)
          ..lineTo(env.right, env.top),
        foil..strokeWidth = 1.4 * unit,
      );
    } else {
      // Past upright we see the flap's lined inside.
      canvas.save();
      canvas.clipPath(flapPath);
      _paintLiner(canvas, flapPath.getBounds(), unit, foil);
      canvas.restore();
    }
    canvas.restore();
  }

  /// The front of the envelope: everything below the V-shaped opening.
  void _paintPocket(Canvas canvas, Rect env, double unit, Paint foil) {
    final v = Offset(env.center.dx, env.top + env.height * 0.52);
    final pocket = Path()
      ..moveTo(env.left, env.top)
      ..lineTo(v.dx, v.dy)
      ..lineTo(env.right, env.top)
      ..lineTo(env.right, env.bottom)
      ..lineTo(env.left, env.bottom)
      ..close();

    canvas.save();
    canvas.clipPath(pocket);
    paintPaper(canvas, env, paper, unit);

    // Creases where the bottom flap is folded over the side flaps.
    final fold = Offset(env.center.dx, env.top + env.height * 0.64);
    final creases = Path()
      ..moveTo(env.left, env.bottom)
      ..lineTo(fold.dx, fold.dy)
      ..lineTo(env.right, env.bottom);
    canvas.drawPath(
      creases.shift(Offset(0, unit)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * unit
        ..color = paper.embossLight,
    );
    canvas.drawPath(
      creases,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * unit
        ..color = paper.embossShadow,
    );
    canvas.restore();

    canvas.drawPath(
      Path()
        ..moveTo(env.left, env.top)
        ..lineTo(v.dx, v.dy)
        ..lineTo(env.right, env.top),
      foil..strokeWidth = 1.2 * unit,
    );
  }

  void _paintCard(
    Canvas canvas,
    Rect card,
    Rect cardRest,
    double unit,
    Paint foil,
  ) {
    canvas.drawShadow(Path()..addRect(card), Colors.black, 6 * unit, false);
    // Text and trim grow with the card's width as it fills the canvas.
    final faceUnit = unit * card.width / cardRest.width;
    paintInvitationFace(canvas, card, _card, faceUnit, foil);
  }

  @override
  bool shouldRepaint(EnvelopePainter oldDelegate) =>
      oldDelegate.paper != paper ||
      oldDelegate.wax != wax ||
      oldDelegate.initials != initials ||
      oldDelegate.progress != progress;
}
