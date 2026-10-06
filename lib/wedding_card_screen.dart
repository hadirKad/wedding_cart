import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/arabic_painter.dart';
import 'package:wedding_cart/opening/bow_painter.dart';
import 'package:wedding_cart/opening/islamic_painter.dart';
import 'package:wedding_cart/opening/paper_art.dart';

/// The wedding details revealed when the card opens, dressed to match the
/// outside: the same paper, trim and ornament as the chosen [CardStyle].
///
/// All text here is placeholder content.
class WeddingCardScreen extends StatelessWidget {
  const WeddingCardScreen({super.key, required this.config});

  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    final look = _Look.of(config);
    final details = _Details(look: look, initials: config.initials);

    return Scaffold(
      backgroundColor: look.paper.paper,
      // Sized from the card itself, so its frames line up wherever it is shown.
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _BackgroundPainter(config, look)),
              if (config.style == CardStyle.photoBow)
                SingleChildScrollView(
                  child: Column(
                    children: [
                      _PhotoHeader(
                        config: config,
                        paper: look.paper.paper,
                        height: size.height * 0.36,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 40, 32, 48),
                        child: details,
                      ),
                    ],
                  ),
                )
              else
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: _padding(size),
                      child: details,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Keeps the details inside each style's frame.
  EdgeInsets _padding(Size size) {
    final unit = size.width / 400;
    return switch (config.style) {
      // Inside the arch, below its point.
      CardStyle.arabic => EdgeInsets.fromLTRB(
        size.width * 0.18,
        size.height * 0.2,
        size.width * 0.18,
        size.height * 0.1,
      ),
      // On the plain panel below the Basmala.
      CardStyle.islamic => EdgeInsets.fromLTRB(
        60 * unit,
        150 * unit,
        60 * unit,
        64 * unit,
      ),
      _ => const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
    };
  }
}

/// The colours the inside of the card is drawn in.
class _Look {
  const _Look({
    required this.paper,
    required this.trim,
    required this.ink,
    required this.accent,
    required this.stars,
  });

  factory _Look.of(CardConfig config) {
    final style = config.style;
    final paper = switch (style) {
      CardStyle.photoBow => _cream,
      // The same ivory card that slides out of the envelope.
      CardStyle.envelope => PaperColor.ivory.palette,
      _ => config.paper.palette,
    };
    final trim = switch (style) {
      CardStyle.photoBow => config.bowColor.palette,
      CardStyle.gatefold || CardStyle.envelope => AccentColor.gold.palette,
      _ => config.accent.palette,
    };
    final light = paper.paper.computeLuminance() > 0.4;
    return _Look(
      paper: paper,
      trim: trim,
      ink: light
          ? Color.lerp(paper.ink, Colors.black, 0.45)!
          : Color.lerp(paper.ink, Colors.white, 0.25)!,
      accent: light ? trim.dark : trim.light,
      stars: style == CardStyle.arabic || style == CardStyle.islamic,
    );
  }

  static const _cream = PaperPalette(
    paper: Color(0xFFFBF6EE),
    embossLight: Color(0xFFFFFFFF),
    embossShadow: Color(0x1A4A3B2A),
    ink: Color(0xFF4A3B2A),
  );

  final PaperPalette paper;

  /// Metal or satin used for frames and ornament.
  final SatinPalette trim;

  /// Body text.
  final Color ink;

  /// Names, dividers and the monogram.
  final Color accent;

  /// Whether dividers use an eight-point star rather than a heart.
  final bool stars;
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter(this.config, this.look);

  final CardConfig config;
  final _Look look;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 400;
    final area = Offset.zero & size;
    final paper = look.paper;
    final foil = foilPaint(size);
    final metal = metalPaint(look.trim, area);
    canvas.clipRect(area);

    switch (config.style) {
      case CardStyle.photoBow:
        canvas.drawRect(area, Paint()..color = paper.paper);

      case CardStyle.gatefold:
        paintPaper(canvas, area, paper, unit);
        paintFoilFrame(canvas, area.deflate(18 * unit), unit, foil);

      case CardStyle.envelope:
        paintCardFace(canvas, area, paper, unit, foil);

      case CardStyle.scroll:
        paintCardFace(canvas, area, paper, unit, foil);
        // Shade where the parchment curls toward its rollers.
        for (final (edge, begin) in [
          (Rect.fromLTRB(0, 0, size.width, 40 * unit), Alignment.topCenter),
          (
            Rect.fromLTRB(0, size.height - 40 * unit, size.width, size.height),
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
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0),
                ],
              ).createShader(edge),
          );
        }

      case CardStyle.arabic:
        paintPaper(canvas, area, paper, unit);
        final line = Paint()
          ..style = PaintingStyle.stroke
          ..shader = metal.shader;
        canvas.drawPath(moorishArch(size, 0), line..strokeWidth = 2 * unit);
        canvas.drawPath(
          moorishArch(size, 10 * unit),
          line..strokeWidth = 0.8 * unit,
        );
        final apex = moorishArch(size, 10 * unit).getBounds().top;
        canvas.drawPath(
          starPath(Offset(size.width / 2, apex - 22 * unit), 10 * unit),
          metal,
        );

      case CardStyle.islamic:
        canvas.drawRect(area, Paint()..color = paper.paper);
        canvas.drawRect(
          area,
          Paint()
            ..shader = RadialGradient(
              radius: 0.9,
              colors: [
                paper.embossShadow.withValues(alpha: 0),
                paper.embossShadow,
              ],
            ).createShader(area),
        );
        final ink = islamicInk(paper, look.trim);
        paintStarGeometry(canvas, size, unit, ink);
        paintStarBorder(canvas, size, unit, paper, metal);
        // A plain panel so the details read clearly over the pattern.
        final panel = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            44 * unit,
            136 * unit,
            size.width - 44 * unit,
            size.height - 48 * unit,
          ),
          Radius.circular(10 * unit),
        );
        canvas.drawRRect(panel, Paint()..color = paper.paper);
        canvas.drawRRect(
          panel,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4 * unit
            ..shader = metal.shader,
        );
        paintCartouche(
          canvas,
          Offset(size.width / 2, 92 * unit),
          basmala,
          21,
          unit,
          paper,
          ink,
          metal,
        );
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) =>
      oldDelegate.config != config;
}

/// The cover photo fading into the card, with the bow where they meet.
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({
    required this.config,
    required this.paper,
    required this.height,
  });

  final CardConfig config;
  final Color paper;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          Image(image: config.photo.image(width: 1440), fit: BoxFit.cover),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [paper.withValues(alpha: 0), paper],
                stops: const [0.55, 1],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomPaint(
              size: const Size.square(84),
              painter: BowPainter(
                progress: 0,
                palette: config.bowColor.palette,
                style: config.bowStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.look, required this.initials});

  final _Look look;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      textAlign: TextAlign.center,
      style: TextStyle(color: look.ink, fontSize: 16, height: 1.5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (initials.isNotEmpty) ...[
            _Monogram(initials: initials, color: look.accent),
            const SizedBox(height: 24),
          ],
          const Text(
            'TOGETHER WITH THEIR FAMILIES',
            style: TextStyle(fontSize: 12, letterSpacing: 3),
          ),
          const SizedBox(height: 28),
          const Text('Bride Name', style: _nameStyle),
          Text('&', style: TextStyle(color: look.accent, fontSize: 30)),
          const Text('Groom Name', style: _nameStyle),
          const SizedBox(height: 24),
          const Text(
            'request the pleasure of your company\n'
            'at the celebration of their marriage',
          ),
          const SizedBox(height: 32),
          _divider(),
          const SizedBox(height: 32),
          const Text(
            'SATURDAY',
            style: TextStyle(fontSize: 13, letterSpacing: 3),
          ),
          const Text(
            '12 June 2027',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
          ),
          const Text('at 5:00 PM'),
          const SizedBox(height: 32),
          _divider(),
          const SizedBox(height: 32),
          const Text(
            'Venue Name',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Text('Street address, City'),
        ],
      ),
    );
  }

  static const _nameStyle = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w300,
    fontStyle: FontStyle.italic,
    height: 1.2,
  );

  Widget _divider() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 48, height: 1, color: look.accent),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: look.stars
              ? CustomPaint(
                  size: const Size.square(14),
                  painter: _StarPainter(look.accent),
                )
              : Icon(Icons.favorite, size: 12, color: look.accent),
        ),
        Container(width: 48, height: 1, color: look.accent),
      ],
    );
  }
}

/// The couple's initials in a double ring.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.initials, required this.color});

  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 0.8),
        ),
        padding: const EdgeInsets.all(12),
        child: FittedBox(
          child: Text(
            initials,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      starPath(size.center(Offset.zero), size.shortestSide / 2),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}
