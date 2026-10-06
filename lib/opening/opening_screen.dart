import 'package:flutter/material.dart';

import 'package:wedding_cart/opening/bow_painter.dart';
import 'package:wedding_cart/opening/door_half.dart';
import 'package:wedding_cart/wedding_card_screen.dart';

/// Decoded at a fixed width so the 3465px source photo doesn't make the
/// doors stutter.
const _cover = ResizeImage(
  AssetImage('assets/images/place01.jpg'),
  width: 1440,
);

/// The wedding card, closed behind a photo tied with a bow.
///
/// Tapping unties the bow, swings the photo open like double doors and
/// reveals the [WeddingCardScreen] behind it.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

class _OpeningScreenState extends State<OpeningScreen>
    with TickerProviderStateMixin {
  late final AnimationController _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3000),
  );

  /// Gentle idle pulse on the bow while waiting for a tap.
  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _untie = CurvedAnimation(
    parent: _open,
    curve: const Interval(0.0, 0.3, curve: Curves.easeInCubic),
  );
  late final Animation<double> _doors = CurvedAnimation(
    parent: _open,
    curve: const Interval(0.25, 0.75, curve: Curves.easeInOutCubic),
  );
  late final Animation<double> _reveal = CurvedAnimation(
    parent: _open,
    curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
  );

  /// Once the doors are fully open the cover is removed from the tree.
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _open.addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _opened = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(_cover, context);
  }

  @override
  void dispose() {
    _open.dispose();
    _breathe.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_open.isDismissed) return;
    _breathe.stop();
    _open.forward();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Material(
      color: const Color(0xFF1B1712),
      child: Stack(
        fit: StackFit.expand,
        children: [
          FadeTransition(
            opacity: _reveal,
            child: ScaleTransition(
              scale: Tween(begin: 1.08, end: 1.0).animate(_reveal),
              child: const WeddingCardScreen(),
            ),
          ),
          if (!_opened)
            Semantics(
              button: true,
              label: 'Open the invitation',
              child: GestureDetector(
                onTap: _handleTap,
                child: AnimatedBuilder(
                  animation: Listenable.merge([_open, _breathe]),
                  builder: (context, _) => _buildCover(size),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCover(Size size) {
    final untie = _untie.value;
    final breathe = Curves.easeInOut.transform(_breathe.value);

    return Stack(
      fit: StackFit.expand,
      children: [
        DoorHalf(
          image: _cover,
          screenSize: size,
          isLeft: true,
          progress: _doors.value,
        ),
        DoorHalf(
          image: _cover,
          screenSize: size,
          isLeft: false,
          progress: _doors.value,
        ),
        if (untie < 1) ...[
          CustomPaint(painter: RibbonPainter(progress: untie)),
          Center(
            child: Transform.scale(
              scale: 1 + 0.04 * breathe,
              child: CustomPaint(
                size: const Size.square(170),
                painter: BowPainter(progress: untie, sheen: breathe),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.4),
            child: Opacity(
              opacity: (1 - untie * 3).clamp(0.0, 1.0) * (0.6 + 0.4 * breathe),
              child: const Text(
                'TAP TO OPEN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
