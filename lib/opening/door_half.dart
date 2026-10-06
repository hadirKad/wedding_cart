import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One half of the cover photo, swinging open on its outer edge like a door.
class DoorHalf extends StatelessWidget {
  const DoorHalf({
    super.key,
    required this.image,
    required this.screenSize,
    required this.isLeft,
    required this.progress,
  });

  final ImageProvider image;
  final Size screenSize;
  final bool isLeft;

  /// 0 is closed, 1 is fully open (edge-on to the viewer).
  final double progress;

  @override
  Widget build(BuildContext context) {
    final hinge = isLeft ? Alignment.centerLeft : Alignment.centerRight;
    // Opposite signs swing both doors away from the viewer, into the scene.
    final angle = (isLeft ? -1 : 1) * progress * math.pi / 2;

    return Align(
      alignment: hinge,
      child: Transform(
        alignment: hinge,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(angle),
        child: ClipRect(
          // Lay out the full-screen photo, then keep only this door's half,
          // so the two halves line up exactly when closed.
          child: Align(
            alignment: hinge,
            widthFactor: 0.5,
            child: SizedBox.fromSize(
              size: screenSize,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: image, fit: BoxFit.cover, gaplessPlayback: true),
                  // Darkens as the door turns away from the light.
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
