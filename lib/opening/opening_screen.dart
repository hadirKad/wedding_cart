import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/arabic_painter.dart';
import 'package:wedding_cart/opening/bow_painter.dart';
import 'package:wedding_cart/opening/card_audio.dart';
import 'package:wedding_cart/opening/celebration.dart';
import 'package:wedding_cart/opening/door_half.dart';
import 'package:wedding_cart/opening/envelope_painter.dart';
import 'package:wedding_cart/opening/gatefold_painter.dart';
import 'package:wedding_cart/opening/islamic_painter.dart';
import 'package:wedding_cart/opening/scroll_painter.dart';
import 'package:wedding_cart/wedding_card_screen.dart';

/// The wedding card, closed in the chosen [CardConfig.style].
///
/// Tapping opens it and reveals the [WeddingCardScreen]. Covers that split
/// down the middle (photo and bow, gatefold) open in the chosen
/// [CardConfig.opening] style; the others have their own opening.
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
    duration: Duration(milliseconds: widget.config.style.splits ? 3000 : 3800),
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

  /// Fades the card in: early for covers it shows through as they open,
  /// late for the envelope and scroll, which bring their own card forward
  /// first.
  late final Animation<double> _reveal = CurvedAnimation(
    parent: _open,
    curve: widget.config.style.revealsThrough
        ? const Interval(0.3, 0.9, curve: Curves.easeOutCubic)
        : const Interval(0.78, 1.0, curve: Curves.easeOut),
  );

  /// Decoded at a fixed width so the large source photos don't make the
  /// opening stutter.
  late final ImageProvider _photo = widget.config.photo.image(width: 1440);

  /// Once the card is fully open the cover is removed from the tree.
  bool _opened = false;

  /// Silences the music and sound effects.
  bool _muted = false;

  final _audio = CardAudio.instance;

  /// Sounds, each with a buzz, at points through the opening (0 to 1).
  late final List<(double, Sfx)> _cues = _cuesFor(widget.config);
  var _nextCue = 0;

  @override
  void initState() {
    super.initState();
    _open
      ..addListener(_playCues)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _opened = true);
        }
      });
    _audio.preload();
    if (widget.config.music) _audio.startMusic();
  }

  static List<(double, Sfx)> _cuesFor(CardConfig config) {
    final split = switch (config.opening) {
      OpeningStyle.doors => Sfx.creak,
      OpeningStyle.slide => Sfx.rustle,
      OpeningStyle.zoom => Sfx.swish,
    };
    return switch (config.style) {
      CardStyle.photoBow => [(0, Sfx.swish), (0.25, split), (0.9, Sfx.chime)],
      CardStyle.gatefold => [(0, Sfx.crack), (0.25, split), (0.9, Sfx.chime)],
      CardStyle.envelope => [
        (0, Sfx.crack),
        (0.18, Sfx.rustle),
        (0.42, Sfx.rustle),
        (0.95, Sfx.chime),
      ],
      CardStyle.scroll => [
        (0, Sfx.swish),
        (0.24, Sfx.rustle),
        (0.95, Sfx.chime),
      ],
      CardStyle.arabic => [(0.1, Sfx.creak), (0.9, Sfx.chime)],
      CardStyle.islamic => [(0.15, Sfx.swish), (0.85, Sfx.chime)],
    };
  }

  void _playCues() {
    while (_nextCue < _cues.length && _open.value >= _cues[_nextCue].$1) {
      final (_, effect) = _cues[_nextCue++];
      HapticFeedback.lightImpact();
      if (!_muted) _audio.play(effect);
    }
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
    _audio.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_open.isDismissed) return;
    HapticFeedback.mediumImpact();
    _breathe.stop();
    _open.forward();
  }

  void _replay() {
    setState(() => _opened = false);
    _nextCue = 0;
    _open.reset();
    _breathe.repeat(reverse: true);
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    if (_muted) {
      _audio.pauseMusic();
    } else if (widget.config.music) {
      _audio.startMusic();
    }
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
              child: WeddingCardScreen(config: widget.config),
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
            Celebration(config: widget.config),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_opened)
                    IconButton.filledTonal(
                      tooltip: 'Back to design',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  const Spacer(),
                  IconButton.filledTonal(
                    tooltip: _muted ? 'Unmute' : 'Mute',
                    icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                    onPressed: _toggleMute,
                  ),
                  if (_opened) ...[
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Replay',
                      icon: const Icon(Icons.replay),
                      onPressed: _replay,
                    ),
                  ],
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

    if (!config.style.splits) return _buildStationery(breathe);

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

  /// The styles that play their whole opening in one painter.
  Widget _buildStationery(double breathe) {
    final config = widget.config;
    final t = _open.value;
    final paper = config.paper.palette;
    final accent = config.accent.palette;
    final (painter, hintAt) = switch (config.style) {
      CardStyle.envelope => (
        EnvelopePainter(
          paper: paper,
          wax: accent,
          initials: config.initials,
          progress: t,
        ),
        const Alignment(0, 0.62),
      ),
      CardStyle.scroll => (
        ScrollPainter(paper: paper, ribbon: accent, progress: t),
        const Alignment(0, 0.3),
      ),
      CardStyle.arabic => (
        ArabicPainter(
          paper: paper,
          ornament: accent,
          progress: t,
          shimmer: breathe,
        ),
        const Alignment(0, 0.66),
      ),
      CardStyle.islamic => (
        IslamicPainter(
          paper: paper,
          ornament: accent,
          initials: config.initials,
          progress: t,
          shimmer: breathe,
        ),
        const Alignment(0, 0.3),
      ),
      _ => throw StateError('${config.style} splits; use _buildOpening'),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: painter),
        _buildHint(
          t * 3,
          breathe,
          color: Colors.white,
          shadow: true,
          alignment: hintAt,
        ),
      ],
    );
  }

  Widget _buildHint(
    double untie,
    double breathe, {
    required Color color,
    required bool shadow,
    Alignment alignment = const Alignment(0, 0.4),
  }) {
    return Align(
      alignment: alignment,
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
            wax: config.accent.palette,
            initials: config.initials,
            crack: untie,
          ),
        ),
      ),
      _ => throw StateError("${config.style} doesn't split"),
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
