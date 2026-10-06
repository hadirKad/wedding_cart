import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';

/// One half of the closed card's cover, opening away from the centre.
///
/// With [OpeningStyle.doors] it swings on its outer edge like a door; with
/// [OpeningStyle.slide] it slides straight off its side of the screen.
class DoorHalf extends StatelessWidget {
  const DoorHalf({
    super.key,
    required this.cover,
    required this.screenSize,
    required this.isLeft,
    required this.progress,
    this.style = OpeningStyle.doors,
  }) : assert(style != OpeningStyle.zoom);

  /// The whole, full-screen cover; only this door's half of it is shown.
  final Widget cover;
  final Size screenSize;
  final bool isLeft;

  /// 0 is closed, 1 is fully open.
  final double progress;
  final OpeningStyle style;

  @override
  Widget build(BuildContext context) {
    final hinge = isLeft ? Alignment.centerLeft : Alignment.centerRight;
    final outward = isLeft ? -1.0 : 1.0;
    final swings = style == OpeningStyle.doors;

    final transform = swings
        // Opposite signs swing both doors away from the viewer, into the scene.
        ? (Matrix4.identity()
            ..setEntry(3, 2, 0.0012)
            ..rotateY(outward * progress * math.pi / 2))
        : Matrix4.translationValues(
            outward * progress * screenSize.width / 2,
            0,
            0,
          );

    return Align(
      alignment: hinge,
      child: Transform(
        alignment: hinge,
        transform: transform,
        child: ClipRect(
          // Lay out the full-screen cover, then keep only this door's half,
          // so the two halves line up exactly when closed.
          child: Align(
            alignment: hinge,
            widthFactor: 0.5,
            child: SizedBox.fromSize(
              size: screenSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  cover,
                  // Darkens as the door turns away from the light.
                  if (swings)
                    ColoredBox(
                      color: Colors.black.withValues(alpha: 0.55 * progress),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
