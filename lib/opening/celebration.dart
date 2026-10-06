import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/paper_art.dart';

enum _Shape { petal, confetti, star }

/// Petals, gold confetti or eight-point stars drifting down over the opened
/// card, chosen to suit its [CardConfig.style]. Plays once and doesn't take
/// touches.
class Celebration extends StatefulWidget {
  const Celebration({super.key, required this.config});

  final CardConfig config;

  @override
  State<Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fall = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..forward();

  late final List<_Piece> _pieces = _scatter(widget.config);

  @override
  void dispose() {
    _fall.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _CelebrationPainter(_pieces, _fall),
        ),
      ),
    );
  }

  static List<_Piece> _scatter(CardConfig config) {
    final gold = AccentColor.gold.palette;
    final (shapes, palette) = switch (config.style) {
      CardStyle.photoBow => ([_Shape.petal], config.bowColor.palette),
      CardStyle.gatefold || CardStyle.envelope => (
        [_Shape.petal, _Shape.confetti],
        config.accent.palette,
      ),
      CardStyle.scroll => ([_Shape.petal], config.accent.palette),
      CardStyle.arabic => (
        [_Shape.confetti, _Shape.star],
        config.accent.palette,
      ),
      CardStyle.islamic => ([_Shape.star], config.accent.palette),
    };
    final colors = [
      palette.light,
      palette.base,
      palette.gloss,
      gold.base,
      gold.light,
    ];

    final random = math.Random(7);
    return [
      for (var i = 0; i < 70; i++)
        _Piece(
          shape: shapes[random.nextInt(shapes.length)],
          color: colors[random.nextInt(colors.length)],
          x: random.nextDouble(),
          delay: random.nextDouble() * 0.35,
          speed: 0.8 + random.nextDouble() * 0.5,
          size: 5 + random.nextDouble() * 6,
          sway: 0.5 + random.nextDouble(),
          swayRate: 1 + random.nextDouble() * 2,
          spin: (random.nextDouble() - 0.5) * 4,
          flutter: 2 + random.nextDouble() * 4,
          phase: random.nextDouble() * 2 * math.pi,
        ),
    ];
  }
}

class _Piece {
  const _Piece({
    required this.shape,
    required this.color,
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.sway,
    required this.swayRate,
    required this.spin,
    required this.flutter,
    required this.phase,
  });

  final _Shape shape;
  final Color color;

  /// Starting position across the width, 0 to 1.
  final double x;

  /// When it starts falling, as a fraction of the whole animation.
  final double delay;
  final double speed;
  final double size;
  final double sway;
  final double swayRate;

  /// Turns per fall.
  final double spin;

  /// How often it tumbles edge-on per fall.
  final double flutter;
  final double phase;
}

class _CelebrationPainter extends CustomPainter {
  _CelebrationPainter(this.pieces, this.fall) : super(repaint: fall);

  final List<_Piece> pieces;
  final Animation<double> fall;

  @override
  void paint(Canvas canvas, Size size) {
    final t = fall.value;
    for (final piece in pieces) {
      // Each piece crosses the screen in about two thirds of the animation.
      final p = (t - piece.delay) * piece.speed / 0.65;
      if (p <= 0 || p >= 1) continue;

      final y = -0.05 * size.height + p * 1.15 * size.height;
      final x =
          piece.x * size.width +
          math.sin(p * piece.swayRate * 2 * math.pi + piece.phase) *
              piece.sway *
              size.width *
              0.04;
      final opacity = math.min(1.0, (1 - p) * 6) * 0.9;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(piece.spin * p * 2 * math.pi + piece.phase);
      // Tumbling: squash one way as it turns edge-on.
      canvas.scale(
        1,
        0.25 + 0.75 * math.cos(p * piece.flutter * math.pi + piece.phase).abs(),
      );
      final paint = Paint()..color = piece.color.withValues(alpha: opacity);
      final s = piece.size;
      switch (piece.shape) {
        case _Shape.petal:
          canvas.drawPath(
            Path()
              ..moveTo(0, -s)
              ..quadraticBezierTo(s * 0.9, -s * 0.2, 0, s)
              ..quadraticBezierTo(-s * 0.9, -s * 0.2, 0, -s),
            paint,
          );
        case _Shape.confetti:
          canvas.drawRect(
            Rect.fromCenter(
              center: Offset.zero,
              width: s * 0.6,
              height: s * 1.2,
            ),
            paint,
          );
        case _Shape.star:
          canvas.drawPath(starPath(Offset.zero, s * 0.8), paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_CelebrationPainter oldDelegate) =>
      oldDelegate.pieces != pieces;
}
