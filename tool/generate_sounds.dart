// Synthesizes the opening's sound effects and music into assets/sounds/.
//
// Everything is generated from scratch, so there are no licences to track.
// Run from the project root:
//
//   dart run tool/generate_sounds.dart
//
// To use real recordings instead, drop WAV files with the same names into
// assets/sounds/.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _rate = 22050;
final _random = math.Random(11);

void main() {
  Directory('assets/sounds').createSync(recursive: true);
  _write('crack', _crack());
  _write('swish', _swish());
  _write('creak', _creak());
  _write('rustle', _rustle());
  _write('chime', _chime());
  _write('music', _music());
}

/// Wax snapping: two sharp, muffled bursts.
Float64List _crack() {
  final out = Float64List((_rate * 0.35).round());
  for (final (start, gain) in [(0.0, 1.0), (0.06, 0.5), (0.11, 0.25)]) {
    var low = 0.0;
    final from = (start * _rate).round();
    for (var i = from; i < out.length; i++) {
      final t = (i - from) / _rate;
      low += 0.5 * (_noise() - low);
      out[i] += low * gain * math.exp(-t / 0.015);
    }
  }
  return _normalise(out, 0.8);
}

/// Satin sliding: filtered noise that swells and brightens.
Float64List _swish() {
  final out = Float64List((_rate * 0.7).round());
  var low = 0.0;
  for (var i = 0; i < out.length; i++) {
    final p = i / out.length;
    low += (0.05 + 0.25 * p) * (_noise() - low);
    out[i] = low * math.pow(math.sin(math.pi * p), 2);
  }
  return _normalise(out, 0.35);
}

/// Wooden doors: stick-slip pulses, each ringing like a small resonator.
Float64List _creak() {
  final out = Float64List((_rate * 1.4).round());
  var t = 0.0;
  while (t < 1.35) {
    final p = t / 1.4;
    final pulse = (t * _rate).round();
    final pitch = 520 + 160 * math.sin(p * 5);
    for (var j = 0; j < _rate * 0.006 && pulse + j < out.length; j++) {
      final s = j / _rate;
      out[pulse + j] +=
          math.sin(2 * math.pi * pitch * s) *
          math.exp(-s / 0.0015) *
          math.sin(math.pi * p);
    }
    // Pulses come faster in the middle of the swing.
    t += 1 / (35 + 45 * math.sin(math.pi * p) + _random.nextDouble() * 8);
  }
  return _normalise(out, 0.4);
}

/// Paper: soft hiss with random crackles.
Float64List _rustle() {
  final out = Float64List((_rate * 0.9).round());
  var low = 0.0;
  for (var i = 0; i < out.length; i++) {
    final p = i / out.length;
    low += 0.3 * (_noise() - low);
    final crackle = _random.nextDouble() < 0.004 ? _noise() * 4 : 0.0;
    out[i] = (low * 0.4 + crackle) * math.sin(math.pi * p);
  }
  return _normalise(out, 0.3);
}

/// A rising four-note bell arpeggio.
Float64List _chime() {
  final out = Float64List((_rate * 2.4).round());
  const notes = [1046.5, 1318.5, 1568.0, 2093.0];
  for (var n = 0; n < notes.length; n++) {
    _bell(out, (n * 0.12 * _rate).round(), notes[n], 0.25, 0.7);
  }
  return _normalise(out, 0.45);
}

/// A gentle music-box loop: C – Am – F – G, arpeggiated, twice through with
/// the melody varied the second time. The tail of the last notes wraps
/// round to the start, so it loops without a seam.
Float64List _music() {
  const eighth = 0.3;
  final out = Float64List((_rate * eighth * 64).round());
  const chords = [
    [261.63, 329.63, 392.00], // C
    [220.00, 261.63, 329.63], // Am
    [174.61, 220.00, 261.63], // F
    [196.00, 246.94, 293.66], // G
  ];
  const pattern = [0, 1, 2, 3, 2, 1, 2, 3];
  const melodies = [
    [783.99, 880.00, 698.46, 783.99],
    [1046.50, 880.00, 880.00, 987.77],
  ];
  for (var pass = 0; pass < 2; pass++) {
    for (var c = 0; c < chords.length; c++) {
      final chord = chords[c];
      final bar = (pass * 4 + c) * 8;
      for (var e = 0; e < 8; e++) {
        final step = pattern[e];
        final freq = step == 3 ? chord[0] * 2 : chord[step];
        final at = ((bar + e) * eighth * _rate).round();
        _bell(out, at, freq * 2, 0.16, 0.6, wrap: true);
      }
      final first = (bar * eighth * _rate).round();
      _bell(out, first, melodies[pass][c] * 2, 0.22, 1.1, wrap: true);
      // An answering note halfway through the bar, a tone higher in the
      // first and third bars.
      _bell(
        out,
        ((bar + 4) * eighth * _rate).round(),
        melodies[pass][c] * 2 * (c.isEven ? 1.122 : 1),
        0.14,
        0.9,
        wrap: true,
      );
      _sine(out, first, chord[0] / 2, 0.12, 1.4, wrap: true);
    }
  }
  return _normalise(out, 0.5);
}

/// A music-box or bell tone: a fundamental, a soft octave and a faint
/// inharmonic shimmer, all fading away.
void _bell(
  Float64List out,
  int start,
  double freq,
  double gain,
  double decay, {
  bool wrap = false,
}) {
  final length = (_rate * decay * 5).round();
  for (var j = 0; j < length; j++) {
    final t = j / _rate;
    final i = start + j;
    if (!wrap && i >= out.length) break;
    final v =
        (math.sin(2 * math.pi * freq * t) +
            0.3 * math.sin(2 * math.pi * freq * 2 * t) +
            0.08 * math.sin(2 * math.pi * freq * 4.2 * t) * math.exp(-t / 0.08)) *
        gain *
        math.exp(-t / decay) *
        math.min(1, t * 400);
    out[i % out.length] += v;
  }
}

void _sine(
  Float64List out,
  int start,
  double freq,
  double gain,
  double decay, {
  bool wrap = false,
}) {
  final length = (_rate * decay * 5).round();
  for (var j = 0; j < length; j++) {
    final t = j / _rate;
    final i = start + j;
    if (!wrap && i >= out.length) break;
    out[i % out.length] +=
        math.sin(2 * math.pi * freq * t) *
        gain *
        math.exp(-t / decay) *
        math.min(1, t * 200);
  }
}

double _noise() => _random.nextDouble() * 2 - 1;

Float64List _normalise(Float64List samples, double peak) {
  final loudest = samples.fold<double>(0, (m, s) => math.max(m, s.abs()));
  if (loudest == 0) return samples;
  for (var i = 0; i < samples.length; i++) {
    samples[i] *= peak / loudest;
  }
  return samples;
}

/// Writes [samples] as 16-bit mono PCM.
void _write(String name, Float64List samples) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _rate, Endian.little);
  data.setUint32(28, _rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final s = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, s, Endian.little);
  }
  final file = File('assets/sounds/$name.wav')
    ..writeAsBytesSync(data.buffer.asUint8List());
  stdout.writeln('${file.path}  ${(file.lengthSync() / 1024).round()} KB');
}
