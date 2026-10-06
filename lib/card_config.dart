import 'package:flutter/material.dart';

/// What the closed card looks like.
enum CardStyle {
  /// A photo tied with a satin ribbon and bow.
  photoBow('Photo & bow', Icons.photo_outlined),

  /// Two embossed cardstock panels closed with a wax seal.
  gatefold('Gatefold', Icons.local_florist_outlined);

  const CardStyle(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The photos the card can open from.
enum CoverPhoto {
  place01('assets/images/place01.jpg'),
  place02('assets/images/place02.jpg'),
  place03('assets/images/place03.jpg');

  const CoverPhoto(this.asset);

  final String asset;

  /// Decoded at [width] pixels so the multi-megabyte source photos stay
  /// quick to draw.
  ImageProvider image({required int width}) =>
      ResizeImage(AssetImage(asset), width: width);
}

/// The five tones a satin ribbon is shaded with, darkest to brightest.
class SatinPalette {
  const SatinPalette({
    required this.deep,
    required this.dark,
    required this.base,
    required this.light,
    required this.gloss,
  });

  final Color deep;
  final Color dark;
  final Color base;
  final Color light;
  final Color gloss;
}

/// Satin and wax colours, shared by the bow and the wax seal.
enum AccentColor {
  gold(
    'Gold',
    SatinPalette(
      deep: Color(0xFF6E4E1E),
      dark: Color(0xFF9C7430),
      base: Color(0xFFD4A955),
      light: Color(0xFFF3DFA8),
      gloss: Color(0xFFFFF6DC),
    ),
  ),
  ivory(
    'Ivory',
    SatinPalette(
      deep: Color(0xFF8A7F6A),
      dark: Color(0xFFB9AE96),
      base: Color(0xFFE6DCC6),
      light: Color(0xFFF8F2E4),
      gloss: Color(0xFFFFFFFF),
    ),
  ),
  blush(
    'Blush',
    SatinPalette(
      deep: Color(0xFF8E4B55),
      dark: Color(0xFFC07A83),
      base: Color(0xFFE3A9AF),
      light: Color(0xFFF6D5D8),
      gloss: Color(0xFFFFF0F2),
    ),
  ),
  silver(
    'Silver',
    SatinPalette(
      deep: Color(0xFF55595F),
      dark: Color(0xFF8A9097),
      base: Color(0xFFC2C7CC),
      light: Color(0xFFE8EBEE),
      gloss: Color(0xFFFFFFFF),
    ),
  ),
  burgundy(
    'Burgundy',
    SatinPalette(
      deep: Color(0xFF3E0E18),
      dark: Color(0xFF6B1A2A),
      base: Color(0xFF962B40),
      light: Color(0xFFC9566B),
      gloss: Color(0xFFF2B5C0),
    ),
  );

  const AccentColor(this.label, this.palette);

  final String label;
  final SatinPalette palette;
}

/// Colours for a gatefold card's cardstock.
class PaperPalette {
  const PaperPalette({
    required this.paper,
    required this.embossLight,
    required this.embossShadow,
    required this.ink,
  });

  final Color paper;

  /// The lit upper-left edge of raised (embossed) shapes.
  final Color embossLight;

  /// The shaded lower-right edge of raised shapes.
  final Color embossShadow;

  /// Text drawn on the paper, chosen to stay readable on it.
  final Color ink;
}

enum PaperColor {
  burgundy(
    'Burgundy',
    PaperPalette(
      paper: Color(0xFF6E1726),
      embossLight: Color(0x2EFFFFFF),
      embossShadow: Color(0x73000000),
      ink: Color(0xFFF3DFA8),
    ),
  ),
  ivory(
    'Ivory',
    PaperPalette(
      paper: Color(0xFFF7F1E5),
      embossLight: Color(0xE6FFFFFF),
      embossShadow: Color(0x24402A10),
      ink: Color(0xFF9C7430),
    ),
  ),
  champagne(
    'Champagne',
    PaperPalette(
      paper: Color(0xFFE9D8BC),
      embossLight: Color(0xA6FFFFFF),
      embossShadow: Color(0x335A3A10),
      ink: Color(0xFF7A5A26),
    ),
  );

  const PaperColor(this.label, this.palette);

  final String label;
  final PaperPalette palette;
}

enum BowStyle {
  /// Two loops and two short tails.
  classic('Classic'),

  /// A second, larger pair of loops behind the first.
  layered('Double'),

  /// Classic loops with long, flowing tails.
  cascade('Cascade');

  const BowStyle(this.label);

  final String label;
}

enum OpeningStyle {
  /// The cover splits and swings open like double doors.
  doors('Doors', Icons.door_front_door_outlined),

  /// The cover splits and both halves slide off the sides.
  slide('Slide', Icons.swap_horiz),

  /// The cover grows and fades, as if walking through it.
  zoom('Zoom', Icons.zoom_out_map);

  const OpeningStyle(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// Everything the user chose on the setup screen.
class CardConfig {
  const CardConfig({
    this.style = CardStyle.photoBow,
    this.photo = CoverPhoto.place01,
    this.bowColor = AccentColor.gold,
    this.bowStyle = BowStyle.classic,
    this.paper = PaperColor.burgundy,
    this.sealColor = AccentColor.gold,
    this.opening = OpeningStyle.doors,
  });

  final CardStyle style;

  // Used by [CardStyle.photoBow].
  final CoverPhoto photo;
  final AccentColor bowColor;
  final BowStyle bowStyle;

  // Used by [CardStyle.gatefold].
  final PaperColor paper;
  final AccentColor sealColor;

  final OpeningStyle opening;

  CardConfig copyWith({
    CardStyle? style,
    CoverPhoto? photo,
    AccentColor? bowColor,
    BowStyle? bowStyle,
    PaperColor? paper,
    AccentColor? sealColor,
    OpeningStyle? opening,
  }) {
    return CardConfig(
      style: style ?? this.style,
      photo: photo ?? this.photo,
      bowColor: bowColor ?? this.bowColor,
      bowStyle: bowStyle ?? this.bowStyle,
      paper: paper ?? this.paper,
      sealColor: sealColor ?? this.sealColor,
      opening: opening ?? this.opening,
    );
  }
}
