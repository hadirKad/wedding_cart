import 'package:flutter/material.dart';

/// The wedding details revealed behind the opening doors.
///
/// All text here is placeholder content.
class WeddingCardScreen extends StatelessWidget {
  const WeddingCardScreen({super.key});

  static const _ink = Color(0xFF4A3B2A);
  static const _gold = Color(0xFFB8893B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF6EE),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: DefaultTextStyle(
              textAlign: TextAlign.center,
              style: const TextStyle(color: _ink, fontSize: 16, height: 1.5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TOGETHER WITH THEIR FAMILIES',
                    style: TextStyle(fontSize: 12, letterSpacing: 3),
                  ),
                  const SizedBox(height: 28),
                  const Text('Bride Name', style: _nameStyle),
                  const Text(
                    '&',
                    style: TextStyle(color: _gold, fontSize: 30),
                  ),
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
            ),
          ),
        ),
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
        Container(width: 48, height: 1, color: _gold),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.favorite, size: 12, color: _gold),
        ),
        Container(width: 48, height: 1, color: _gold),
      ],
    );
  }
}
