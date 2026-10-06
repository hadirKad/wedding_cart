import 'package:flutter/material.dart';

import 'package:wedding_cart/card_config.dart';
import 'package:wedding_cart/opening/arabic_painter.dart';
import 'package:wedding_cart/opening/bow_painter.dart';
import 'package:wedding_cart/opening/envelope_painter.dart';
import 'package:wedding_cart/opening/gatefold_painter.dart';
import 'package:wedding_cart/opening/islamic_painter.dart';
import 'package:wedding_cart/opening/opening_screen.dart';
import 'package:wedding_cart/opening/scroll_painter.dart';

/// Lets the user pick the card style, its colours and the opening animation,
/// then plays the result.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  CardConfig _config = const CardConfig();

  void _update(CardConfig config) => setState(() => _config = config);

  void _start() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            OpeningScreen(config: _config),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Design your card'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(child: _Preview(config: _config)),
          const SizedBox(height: 24),
          _Section(
            title: 'Card style',
            child: Column(
              children: [
                // Two rows of two.
                for (var row = 0; row < CardStyle.values.length; row += 2) ...[
                  if (row > 0) const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final style
                          in CardStyle.values.skip(row).take(2)) ...[
                        if (style.index.isOdd) const SizedBox(width: 12),
                        Expanded(
                          child: _CardStyleOption(
                            style: style,
                            selected: style == _config.style,
                            onTap: () =>
                                _update(_config.copyWith(style: style)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (_config.style != CardStyle.photoBow) ...[
            _Section(
              title: switch (_config.style) {
                CardStyle.envelope => 'Envelope colour',
                CardStyle.scroll => 'Parchment colour',
                CardStyle.arabic => 'Wall colour',
                CardStyle.islamic => 'Background colour',
                _ => 'Paper colour',
              },
              child: Row(
                children: [
                  for (final paper in PaperColor.values)
                    Expanded(
                      child: _Swatch(
                        label: paper.label,
                        semanticLabel: '${paper.label} paper',
                        colors: [
                          paper.palette.paper,
                          Color.lerp(paper.palette.paper, Colors.black, 0.15)!,
                        ],
                        selected: paper == _config.paper,
                        onTap: () => _update(_config.copyWith(paper: paper)),
                      ),
                    ),
                ],
              ),
            ),
            _Section(
              title:
                  '${_accentNoun[0].toUpperCase()}${_accentNoun.substring(1)} colour',
              child: _accentRow(
                selected: _config.accent,
                noun: _accentNoun,
                onSelected: (color) => _update(_config.copyWith(accent: color)),
              ),
            ),
          ] else ...[
            _Section(
              title: 'Background',
              child: Row(
                children: [
                  for (final photo in CoverPhoto.values) ...[
                    if (photo.index > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _PhotoOption(
                        photo: photo,
                        selected: photo == _config.photo,
                        onTap: () => _update(_config.copyWith(photo: photo)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _Section(
              title: 'Bow colour',
              child: _accentRow(
                selected: _config.bowColor,
                noun: 'bow',
                onSelected: (color) =>
                    _update(_config.copyWith(bowColor: color)),
              ),
            ),
            _Section(
              title: 'Bow style',
              child: Row(
                children: [
                  for (final style in BowStyle.values) ...[
                    if (style.index > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _StyleOption(
                        style: style,
                        palette: _config.bowColor.palette,
                        selected: style == _config.bowStyle,
                        onTap: () => _update(_config.copyWith(bowStyle: style)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (_config.style.splits)
            _Section(
              title: 'Opening animation',
              child: SegmentedButton<OpeningStyle>(
                showSelectedIcon: false,
                segments: [
                  for (final style in OpeningStyle.values)
                    ButtonSegment(
                      value: style,
                      icon: Icon(style.icon),
                      label: Text(style.label),
                    ),
                ],
                selected: {_config.opening},
                onSelectionChanged: (selection) =>
                    _update(_config.copyWith(opening: selection.single)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _start,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start'),
        ),
      ),
    );
  }

  /// What the accent colour is used for in the chosen style.
  String get _accentNoun => switch (_config.style) {
    CardStyle.scroll => 'ribbon',
    CardStyle.arabic || CardStyle.islamic => 'ornament',
    _ => 'seal',
  };

  /// One swatch per satin colour, for the bow, seal, ribbon or ornament
  /// ([noun]).
  Widget _accentRow({
    required AccentColor selected,
    required String noun,
    required ValueChanged<AccentColor> onSelected,
  }) {
    return Row(
      children: [
        for (final color in AccentColor.values)
          Expanded(
            child: _Swatch(
              label: color.label,
              semanticLabel: '${color.label} $noun',
              colors: [
                color.palette.light,
                color.palette.base,
                color.palette.dark,
              ],
              selected: color == selected,
              onTap: () => onSelected(color),
            ),
          ),
      ],
    );
  }
}

/// A small, static version of the closed card.
class _Preview extends StatelessWidget {
  const _Preview({required this.config});

  final CardConfig config;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 158,
        height: 280,
        child: switch (config.style) {
          CardStyle.photoBow => _buildPhotoBow(),
          CardStyle.gatefold => ColoredBox(
            // Shows through the gaps between the scallops.
            color: const Color(0xFF1B1712),
            child: CustomPaint(
              painter: GatefoldPainter(
                paper: config.paper.palette,
                wax: config.accent.palette,
              ),
            ),
          ),
          CardStyle.envelope => CustomPaint(
            painter: EnvelopePainter(
              paper: config.paper.palette,
              wax: config.accent.palette,
            ),
          ),
          CardStyle.scroll => CustomPaint(
            painter: ScrollPainter(
              paper: config.paper.palette,
              ribbon: config.accent.palette,
            ),
          ),
          // Opens onto the dark backdrop here, so the arch reads as a doorway.
          CardStyle.arabic => ColoredBox(
            color: const Color(0xFF1B1712),
            child: CustomPaint(
              painter: ArabicPainter(
                paper: config.paper.palette,
                ornament: config.accent.palette,
              ),
            ),
          ),
          CardStyle.islamic => CustomPaint(
            painter: IslamicPainter(
              paper: config.paper.palette,
              ornament: config.accent.palette,
            ),
          ),
        },
      ),
    );
  }

  Widget _buildPhotoBow() {
    final palette = config.bowColor.palette;

    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: SizedBox.expand(
            key: ValueKey(config.photo),
            child: Image(
              image: config.photo.image(width: 600),
              fit: BoxFit.cover,
            ),
          ),
        ),
        CustomPaint(
          painter: RibbonPainter(progress: 0, palette: palette, halfBand: 5),
        ),
        Center(
          child: CustomPaint(
            size: const Size.square(64),
            painter: BowPainter(
              progress: 0,
              palette: palette,
              style: config.bowStyle,
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// A rounded tile with a highlighted border when selected.
class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.selected,
    required this.onTap,
    required this.semanticLabel,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final String semanticLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? scheme.primary : scheme.outlineVariant,
              width: selected ? 3 : 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _CardStyleOption extends StatelessWidget {
  const _CardStyleOption({
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final CardStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SelectableTile(
      selected: selected,
      onTap: onTap,
      semanticLabel: '${style.label} card style',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(
              style.icon,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ExcludeSemantics(
                child: Text(
                  style.label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoOption extends StatelessWidget {
  const _PhotoOption({
    required this.photo,
    required this.selected,
    required this.onTap,
  });

  final CoverPhoto photo;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      onTap: onTap,
      semanticLabel: 'Background ${photo.index + 1}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: AspectRatio(
          aspectRatio: 3 / 4,
          child: Image(image: photo.image(width: 300), fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// A round colour sample with its name underneath.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.label,
    required this.semanticLabel,
    required this.colors,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String semanticLabel;

  /// Shaded diagonally across the swatch, lightest first.
  final List<Color> colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? scheme.primary : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StyleOption extends StatelessWidget {
  const _StyleOption({
    required this.style,
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final BowStyle style;
  final SatinPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SelectableTile(
      selected: selected,
      onTap: onTap,
      semanticLabel: '${style.label} bow style',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            SizedBox(
              height: 84,
              child: Align(
                // Leaves room below for the long cascade tails.
                alignment: const Alignment(0, -0.6),
                child: CustomPaint(
                  size: const Size.square(48),
                  painter: BowPainter(
                    progress: 0,
                    palette: palette,
                    style: style,
                  ),
                ),
              ),
            ),
            ExcludeSemantics(
              child: Text(
                style.label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
