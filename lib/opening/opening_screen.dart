import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/bow_painter.dart';
import 'package:wedding_cart/opening/door_half.dart';
import 'package:wedding_cart/opening/gatefold_painter.dart';
import 'package:wedding_cart/wedding_card_screen.dart';

/// The wedding card, closed in the chosen [CardConfig.style]: a photo tied
/// with a bow, or a gatefold held by a wax seal.
///
/// Tapping unties the bow or cracks the seal, opens the cover in the chosen
/// [CardConfig.opening] style and reveals the [WeddingCardScreen] behind it.
class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key, required this.config});

  final CardConfig config;

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

  /// Decoded at a fixed width so the large source photos don't make the
  /// opening stutter.
  late final ImageProvider _photo = widget.config.photo.image(width: 1440);

  /// Once the card is fully open the cover is removed from the tree.
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
    if (widget.config.style == CardStyle.photoBow) {
      precacheImage(_photo, context);
    }
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

  void _replay() {
    setState(() => _opened = false);
    _open.reset();
    _breathe.repeat(reverse: true);
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
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Back to design',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const Spacer(),
                    IconButton.filledTonal(
                      tooltip: 'Replay',
                      icon: const Icon(Icons.replay),
                      onPressed: _replay,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCover(Size size) {
    final config = widget.config;
    final untie = _untie.value;
    final breathe = Curves.easeInOut.transform(_breathe.value);
    final palette = config.bowColor.palette;
    final gatefold = config.style == CardStyle.gatefold;

    return Stack(
      fit: StackFit.expand,
      children: [
        ..._buildOpening(size, _buildFace(untie)),
        if (gatefold && untie < 1)
          _buildHint(
            untie,
            breathe,
            color: config.paper.palette.ink,
            shadow: false,
          ),
        if (!gatefold && untie < 1) ...[
          CustomPaint(
            painter: RibbonPainter(progress: untie, palette: palette),
          ),
          Center(
            child: Transform.scale(
              scale: 1 + 0.04 * breathe,
              child: CustomPaint(
                size: const Size.square(170),
                painter: BowPainter(
                  progress: untie,
                  palette: palette,
                  style: config.bowStyle,
                  sheen: breathe,
                ),
              ),
            ),
          ),
          _buildHint(untie, breathe, color: Colors.white, shadow: true),
        ],
      ],
    );
  }

  Widget _buildHint(
    double untie,
    double breathe, {
    required Color color,
    required bool shadow,
  }) {
    return Align(
      alignment: const Alignment(0, 0.4),
      child: Opacity(
        opacity: (1 - untie * 3).clamp(0.0, 1.0) * (0.6 + 0.4 * breathe),
        child: Text(
          'TAP TO OPEN',
          style: TextStyle(
            color: color,
            fontSize: 14,
            letterSpacing: 4,
            fontWeight: FontWeight.w500,
            shadows: shadow
                ? const [Shadow(blurRadius: 8, color: Colors.black54)]
                : null,
          ),
        ),
      ),
    );
  }

  /// The full-screen front of the closed card, before it is split open.
  Widget _buildFace(double untie) {
    final config = widget.config;
    return switch (config.style) {
      CardStyle.photoBow => Image(
        image: _photo,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      ),
      // Kept in its own layer so the doors can move it without repainting.
      CardStyle.gatefold => RepaintBoundary(
        child: CustomPaint(
          painter: GatefoldPainter(
            paper: config.paper.palette,
            wax: config.sealColor.palette,
            crack: untie,
          ),
        ),
      ),
    };
  }

  List<Widget> _buildOpening(Size size, Widget face) {
    final style = widget.config.opening;
    final progress = _doors.value;

    if (style == OpeningStyle.zoom) {
      return [
        Opacity(
          opacity: 1 - progress,
          child: Transform.scale(scale: 1 + 0.6 * progress, child: face),
        ),
      ];
    }

    return [
      for (final isLeft in const [true, false])
        DoorHalf(
          cover: face,
          screenSize: size,
          isLeft: isLeft,
          progress: progress,
          style: style,
        ),
    ];
  }
}
