import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// The opening's sound effects, in assets/sounds/ (see
/// tool/generate_sounds.dart).
enum Sfx {
  crack('crack.wav', 0.9),
  swish('swish.wav', 0.8),
  creak('creak.wav', 0.7),
  rustle('rustle.wav', 0.8),
  chime('chime.wav', 0.6);

  const Sfx(this.file, this.volume);

  final String file;
  final double volume;
}

/// Plays the opening's sound effects and background music.
///
/// The app uses [instance]; tests swap in [SilentCardAudio], since there is
/// no audio plugin under `flutter test`.
abstract class CardAudio {
  static CardAudio instance = AudioplayersCardAudio();

  /// Loads the effects so the first one plays without a delay.
  Future<void> preload();

  Future<void> play(Sfx effect);

  /// Starts the music loop, or resumes it if paused.
  Future<void> startMusic();

  Future<void> pauseMusic();

  /// Stops the music and releases every player.
  Future<void> dispose();
}

/// Plays nothing.
class SilentCardAudio implements CardAudio {
  const SilentCardAudio();

  @override
  Future<void> preload() async {}

  @override
  Future<void> play(Sfx effect) async {}

  @override
  Future<void> startMusic() async {}

  @override
  Future<void> pauseMusic() async {}

  @override
  Future<void> dispose() async {}
}

/// [CardAudio] on the audioplayers plugin. A sound that fails to play is
/// skipped rather than interrupting the opening.
class AudioplayersCardAudio implements CardAudio {
  final _effects = <Sfx, AudioPlayer>{};
  AudioPlayer? _music;

  @override
  Future<void> preload() => _guard(() async {
    for (final effect in Sfx.values) {
      final player = _effects[effect] ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(effect.volume);
      await player.setSource(AssetSource('sounds/${effect.file}'));
    }
  });

  @override
  Future<void> play(Sfx effect) => _guard(() async {
    final player = _effects[effect];
    if (player == null) {
      await (_effects[effect] = AudioPlayer()).play(
        AssetSource('sounds/${effect.file}'),
        volume: effect.volume,
      );
      return;
    }
    await player.seek(Duration.zero);
    await player.resume();
  });

  @override
  Future<void> startMusic() => _guard(() async {
    final music = _music;
    if (music != null) return music.resume();
    final player = _music = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.play(AssetSource('sounds/music.wav'), volume: 0.4);
  });

  @override
  Future<void> pauseMusic() => _guard(() async => _music?.pause());

  @override
  Future<void> dispose() => _guard(() async {
    final players = [..._effects.values, ?_music];
    _effects.clear();
    _music = null;
    for (final player in players) {
      await player.dispose();
    }
  });

  static Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Card audio unavailable: $error');
    }
  }
}
