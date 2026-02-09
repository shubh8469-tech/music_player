import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ios_audio_player_service.dart';

class EqualizerPrefKeys {
  static const bassBoost = 'eq_bass_boost';
  static const virtualizer = 'eq_virtualizer';
  static const reverb = 'eq_reverb';
}

/// Unified equalizer service that works on both Android and iOS
/// Uses just_audio for Android and native AVAudioEngine for iOS
class UnifiedEqualizerService {
  static final UnifiedEqualizerService _instance = UnifiedEqualizerService._internal();

  factory UnifiedEqualizerService() => _instance;

  late final SharedPreferences _prefs;

  void attachPrefs(SharedPreferences prefs) {
    _prefs = prefs;
  }

  // Android-specific
  AndroidEqualizer? _androidEqualizer;
  AndroidLoudnessEnhancer? _loudnessEnhancer;

  // iOS-specific
  IOSAudioPlayer? _iosPlayer;

  // Common state
  bool _isInitialized = false;
  bool _isEnabled = false;
  List<double> _bandLevels = [];
  List<double> _centerFrequencies = [];
  double _minDecibels = -15.0;
  double _maxDecibels = 15.0;
  String _currentPreset = 'Custom';
  double _bassBoost = 0.0;
  double _virtualizer = 0.0;
  String _reverbType = 'None';

  // Store original EQ values before applying effects
  List<double> _originalBandLevels = [];

  // Presets
  final Map<String, List<double>> _presets = {
    'Custom': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Normal': [0.3, 0.0, 0.0, 0.0, 0.3],
    'Rock': [0.5, 0.3, -0.1, 0.3, 0.5],
    'Dance': [0.6, 0.0, 0.2, 0.4, 0.1],
    'Pop': [-0.1, 0.2, 0.5, 0.1, -0.2],
    'Hip Hop': [0.5, 0.3, 0.0, 0.1, 0.3],
    'Acoustic': [0.5, 0.3, 0.2, 0.4, 0.4],
    'Heavy Metal': [0.4, 0.1, 0.9, 0.3, 0.0],
    'Folk': [0.3, 0.2, 0.0, 0.2, 0.1],
    'Head Phones': [0.6, 0.5, 0.0, 0.3, 0.0],
    'Loud': [0.5, 0.0, 0.1, 0.4, 0.3],
    'Piano': [0.3, 0.2, 0.2, 0.4, 0.4],
    'Bass Boost': [0.6, 0.4, 0.1, 0.0, 0.0],
    'Electronic': [0.5, 0.0, 0.0, 0.0, 0.5],
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Classical': [0.5, 0.3, -0.2, 0.4, 0.4],
    'Straightness': [0.1, 0.0, 0.0, 0.1, 0.1],
    'Jazz': [0.4, 0.2, -0.2, 0.2, 0.5],
    'Treble Boost': [0.0, 0.0, 0.1, 0.4, 0.6],
    'Vocal Boost': [-0.3, -0.2, 0.3, 0.2, -0.1],
    'Latin': [0.3, 0.0, -0.1, 0.0, 0.3],
    'Deep': [0.5, 0.4, 0.3, 0.0, -0.4],
    'Lounge': [-0.3, 0.0, 0.3, -0.1, 0.1],
    'R&B': [0.5, 0.3, -0.3, 0.2, 0.4],
  };

  final StreamController<void> _equalizerChangedController = StreamController<void>.broadcast();

  Stream<void> get equalizerChanged => _equalizerChangedController.stream;

  UnifiedEqualizerService._internal();

  bool get isInitialized => _isInitialized;

  bool get isEnabled => _isEnabled;

  bool get isAndroid => Platform.isAndroid;

  bool get isIOS => Platform.isIOS;

  List<double> get bandLevels => List.unmodifiable(_bandLevels);

  List<double> get centerFrequencies => List.unmodifiable(_centerFrequencies);

  double get minDecibels => _minDecibels;

  double get maxDecibels => _maxDecibels;

  String get currentPreset => _currentPreset;

  List<String> get presetNames => _presets.keys.toList();

  double get bassBoost => _bassBoost;

  double get virtualizer => _virtualizer;

  String get reverbType => _reverbType;

  AndroidEqualizer? get androidEqualizer => _androidEqualizer;

  /// Initialize equalizer for current platform
  Future<void> initialize(dynamic player) async {
    log('🎵 EQUALIZER INITIALIZATION STARTED');
    log('═══════════════════════════════════════════════════');
    _initializeDummyEqualizer();
    if (Platform.isAndroid) {
      await _initializeAndroid(player as AudioPlayer);
    } else if (Platform.isIOS) {
      await _initializeIOS(player);
    } else {
      _initializeDummyEqualizer();
    }
    _isInitialized = true;
    await restoreSavedEffects();
    log('═══════════════════════════════════════════════════');
    log('✅ EQUALIZER INITIALIZED');
    log('   - Frequencies: $_centerFrequencies');
    log('   - Band levels: $_bandLevels');
    log('   - Selected preset: $_currentPreset');
    log('   - Is Enabled: $_isEnabled');
    log('═══════════════════════════════════════════════════');
  }

  Future<void> restoreSavedEffects() async {
    if (!_isInitialized) return;

    final savedBass = _prefs.getDouble(EqualizerPrefKeys.bassBoost) ?? 0.0;
    final savedVirtualizer = _prefs.getDouble(EqualizerPrefKeys.virtualizer) ?? 0.0;
    final savedReverb = _prefs.getString(EqualizerPrefKeys.reverb) ?? 'None';

    log('♻️ Restoring EQ effects');
    log('   Bass: $savedBass');
    log('   Virtualizer: $savedVirtualizer');
    log('   Reverb: $savedReverb');

    if (savedBass > 0) {
      await setBassBoost(savedBass);
    }

    if (savedVirtualizer > 0) {
      await setVirtualizer(savedVirtualizer);
    }

    if (savedReverb != 'None') {
      await setReverb(savedReverb);
    }
  }


  /// Initialize Android equalizer
  Future<void> _initializeAndroid(AudioPlayer player) async {
    try {
      log('🤖 Initializing Android Equalizer...');

      // Check if player is playing or has loaded audio
      log('🎧 Audio Player State:');
      log('   - Is Playing: ${player.playing}');
      log('   - Duration: ${player.duration}');
      log('   - Position: ${player.position}');

      // Get audio session ID
      final sessionId = await player.androidAudioSessionId;
      log('📱 Android Audio Session ID: $sessionId');

      if (sessionId == null) {
        log('❌ Audio session ID is NULL!');
        log('   Audio player may not be initialized');
        log('   Using dummy equalizer for UI');
        _initializeDummyEqualizer();
        return;
      }

      if (sessionId == 0) {
        log('❌ Audio session ID is 0 (invalid)!');
        _initializeDummyEqualizer();
        return;
      }

      log('✅ Valid audio session ID obtained: $sessionId');

      // NOW check if we have the equalizer instance
      if (_androidEqualizer == null) {
        log('❌ AndroidEqualizer instance is NULL!');
        log('   This means createAndroidPlayerWithEqualizer() was not called');
        log('   Using dummy equalizer for UI');
        _initializeDummyEqualizer();
        return;
      }

      // Small delay to ensure audio session is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Get equalizer parameters
      log('📊 Getting equalizer parameters...');
      final params = await _androidEqualizer!.parameters;

      log('📈 Equalizer Info:');
      log('   - Number of bands: ${params.bands.length}');
      log('   - Min gain: ${params.minDecibels} dB');
      log('   - Max gain: ${params.maxDecibels} dB');

      if (params.bands.isNotEmpty) {
        _minDecibels = params.minDecibels;
        _maxDecibels = params.maxDecibels;
        _centerFrequencies = params.bands.map((band) => band.centerFrequency).toList();
        _bandLevels = List.filled(params.bands.length, 0.0);
        _originalBandLevels = List.from(_bandLevels);

        log('🎚️ Band frequencies: $_centerFrequencies Hz');

        // Apply default preset (Custom with flat EQ)
        _currentPreset = 'Custom';
        _presets['Custom'] = List.from(_bandLevels);

        _isInitialized = true;
        log('✅ Android Equalizer initialized successfully');
        log('   Default preset: $_currentPreset');
      } else {
        log('⚠️  Equalizer has NO bands - using UI defaults');
        _initializeDummyEqualizer();
      }
    } catch (e, stackTrace) {
      log('❌ Error initializing Android equalizer: $e');
      log('Stack trace: $stackTrace');
      _initializeDummyEqualizer();
    }
  }

  /*
  Future<void> _initializeAndroid(AudioPlayer player) async {
    try {
      log('🤖 Initializing Android Equalizer...');

      // Check if player is playing or has loaded audio
      log('🎧 Audio Player State:');
      log('   - Is Playing: ${player.playing}');
      log('   - Duration: ${player.duration}');
      log('   - Position: ${player.position}');

      // Get audio session ID
      if (player.androidAudioSessionId != null) {
        log('📱 Android Audio Session ID: ${player.androidAudioSessionId}');
      }

      // Wait for player to be ready if needed
      if (player.duration == null) {
        log('⏳ Waiting for player to load audio...');
        await player.durationStream.firstWhere((d) => d != null);
        log('✅ Audio loaded, duration: ${player.duration}');
      }

      // Small delay to ensure audio session is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Get equalizer parameters
      if (_androidEqualizer != null) {
        log('📊 Getting equalizer parameters...');
        final params = await _androidEqualizer!.parameters;

        log('📈 Equalizer Info:');
        log('   - Number of bands: ${params.bands.length}');
        log('   - Min gain: ${params.minDecibels} dB');
        log('   - Max gain: ${params.maxDecibels} dB');

        if (params.bands.isNotEmpty) {
          _minDecibels = params.minDecibels;
          _maxDecibels = params.maxDecibels;
          _centerFrequencies = params.bands.map((band) => band.centerFrequency).toList();
          _bandLevels = List.filled(params.bands.length, 0.0);

          log('🎚️ Band frequencies: $_centerFrequencies Hz');

          // Apply default preset
          await applyPreset('Normal');

          _isInitialized = true;
          log('✅ Android Equalizer initialized successfully');
        } else {
          log('⚠️  Equalizer has NO bands - using UI defaults');
          log('   This means equalizer may NOT be synced with audio!');
          _initializeDummyEqualizer();
        }
      } else {
        log('❌ Android Equalizer object is null!');
        _initializeDummyEqualizer();
      }

    } catch (e, stackTrace) {
      log('❌ Error initializing Android equalizer: $e');
      log('Stack trace: $stackTrace');
      _initializeDummyEqualizer();
    }
  }
*/

  /// Initialize iOS equalizer
  Future<void> _initializeIOS(dynamic player) async {
    try {
      log('🍎 Initializing iOS Equalizer...');

      if (player is IOSAudioPlayer) {
        _iosPlayer = player;
      } else {
        log('❌ iOS player is not IOSAudioPlayer type');
        _initializeDummyEqualizer();
        return;
      }

      // Get frequencies from iOS player
      final frequencies = await _iosPlayer!.getEqualizerFrequencies();
      if (frequencies != null && frequencies.isNotEmpty) {
        _centerFrequencies = frequencies;
        _bandLevels = List.filled(_centerFrequencies.length, 0.0);
        _originalBandLevels = List.from(_bandLevels);
        _minDecibels = -15.0;
        _maxDecibels = 15.0;

        await applyPreset('Custom');

        _isInitialized = true;
        log('✅ iOS Equalizer initialized with ${_bandLevels.length} bands');
      } else {
        log('⚠️  Could not get iOS equalizer frequencies');
        _initializeDummyEqualizer();
      }
    } catch (e) {
      log('❌ Error initializing iOS equalizer: $e');
      _initializeDummyEqualizer();
    }
  }

  /// Initialize dummy equalizer for unsupported platforms or when initialization fails
  void _initializeDummyEqualizer() {
    log('⚠️  Using dummy equalizer (5 bands, UI only)');
    _centerFrequencies = [60.0, 230.0, 910.0, 3600.0, 14000.0];
    _bandLevels = List.filled(5, 0.0);
    _originalBandLevels = List.from(_bandLevels);
    _minDecibels = -15.0;
    _maxDecibels = 15.0;
    _currentPreset = 'Custom'; //  Set Custom as default
    _presets['Custom'] = List.from(_bandLevels);
    _isInitialized = true; //  Mark as initialized for UI
  }

  /// Create AudioPlayer with equalizer (Android only)
  AudioPlayer createAndroidPlayerWithEqualizer() {
    if (!Platform.isAndroid) {
      log('⚠️  Not on Android - creating regular AudioPlayer');
      return AudioPlayer();
    }

    log('🤖 Creating Android AudioPlayer with Equalizer...');

    _androidEqualizer = AndroidEqualizer();
    _loudnessEnhancer = AndroidLoudnessEnhancer();

    final player = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [_androidEqualizer!, _loudnessEnhancer!]));

    log('✅ Android AudioPlayer created with equalizer pipeline');

    return player;
  }

  /// Create iOS audio player
  Future<IOSAudioPlayer> createIOSPlayer() async {
    log('🍎 Creating iOS AudioPlayer...');

    final player = IOSAudioPlayer();
    await player.initialize();
    _iosPlayer = player;

    log('✅ iOS AudioPlayer created and initialized');

    return player;
  }

  /// Toggle equalizer on/off
  Future<void> toggleEnabled() async {
    await setEnabled(!_isEnabled);
  }

  /// Set equalizer enabled state
  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;

    log('🔧 ${enabled ? "Enabling" : "Disabling"} equalizer...');

    _isEnabled = enabled;

    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        await _androidEqualizer!.setEnabled(enabled);
        log('✅ Equalizer enabled: $enabled');
      } catch (e) {
        log('❌ Error setting Android equalizer enabled: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      final result = await _iosPlayer!.setEqualizerEnabled(enabled);
      log('✅ iOS Equalizer enabled: $result');
    }

    _equalizerChangedController.add(null);
  }

  /// Set band gain
  Future<void> setBandLevel(int bandIndex, double gain) async {
    if (bandIndex < 0 || bandIndex >= _bandLevels.length) {
      log('⚠️  Invalid band index: $bandIndex (valid: 0-${_bandLevels.length - 1})');
      return;
    }

    final clampedGain = gain.clamp(_minDecibels, _maxDecibels);
    _bandLevels[bandIndex] = clampedGain;
    _originalBandLevels[bandIndex] = clampedGain;

    log('🎚️ Setting band $bandIndex (${_centerFrequencies[bandIndex].toStringAsFixed(0)}Hz) to ${clampedGain.toStringAsFixed(1)} dB');

    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        final params = await _androidEqualizer!.parameters;
        if (bandIndex < params.bands.length) {
          // await params.bands[bandIndex].setGain(clampedGain);
          // FIXED: For manual band adjustment, gain is in -1.5 to 1.5 range from UI
          // Scale to dB range for Android
          final gainDb = clampedGain * 10.0;
          await params.bands[bandIndex].setGain(gainDb);

          // Store actual dB value
          _bandLevels[bandIndex] = params.bands[bandIndex].gain;
          _originalBandLevels[bandIndex] = params.bands[bandIndex].gain;
          log('✅ Android band level set to ${params.bands[bandIndex].gain} dB');
        } else {
          log('⚠️  Band index out of range for Android equalizer');
        }
      } catch (e) {
        log('❌ Error setting Android band level: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      await _iosPlayer!.setEqualizerBandLevel(bandIndex, clampedGain);
      _bandLevels[bandIndex] = clampedGain;
      _originalBandLevels[bandIndex] = clampedGain;
      log('✅ iOS band level set');
    }

    _currentPreset = 'Custom';
    _presets['Custom'] = List.from(_bandLevels);

    // NOTE: Do NOT reapply all effects on every band change.
    // That was causing audible glitches when moving sliders because
    // bass boost / virtualizer / reverb were repeatedly re-written.
    // Effects are still re-applied when their own controls change.
    _equalizerChangedController.add(null);
  }

  /// Apply preset
  Future<void> applyPreset(String presetName) async {
    if (!_presets.containsKey(presetName)) {
      log('⚠️  Unknown preset: $presetName');
      return;
    }

    log('🎵 Applying preset: $presetName');

    _currentPreset = presetName;
    final presetLevels = _presets[presetName]!;

    if (presetLevels.length != _bandLevels.length) {
      _bandLevels = _adjustPresetToBands(presetLevels);
    } else {
      _bandLevels = List.from(presetLevels);
    }
    _originalBandLevels = List.from(_bandLevels);
    // Apply to platform-specific equalizer
    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        final params = await _androidEqualizer!.parameters;
        for (int i = 0; i < _bandLevels.length && i < params.bands.length; i++) {
          final gainDb = _bandLevels[i] * 10.0;
          await params.bands[i].setGain(gainDb);
          log('   Band $i: ${gainDb.toStringAsFixed(1)} dB');
        }
        // Update _bandLevels to actual dB values for consistency
        for (int i = 0; i < params.bands.length; i++) {
          _bandLevels[i] = params.bands[i].gain;
          _originalBandLevels[i] = params.bands[i].gain;
        }

        log('✅ Android preset applied');
      } catch (e) {
        log('❌ Error applying Android preset: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      for (int i = 0; i < _bandLevels.length; i++) {
        await _iosPlayer!.setEqualizerBandLevel(i, _bandLevels[i]);
      }
      log('✅ iOS preset applied');
    }
    // Reapply effects after preset change
    await _reapplyAllEffects();
    _equalizerChangedController.add(null);
  }

  /// Adjust preset levels to match actual number of bands
  List<double> _adjustPresetToBands(List<double> preset) {
    final result = <double>[];
    final ratio = preset.length / _centerFrequencies.length;

    for (int i = 0; i < _centerFrequencies.length; i++) {
      final index = (i * ratio).floor().clamp(0, preset.length - 1);
      result.add(preset[index]);
    }

    return result;
  }

  Future<void> setBassBoost(double strength) async {
    final clampedStrength = strength.clamp(0.0, 1.0);
    _bassBoost = clampedStrength;

    log('🔊 Setting bass boost: ${(clampedStrength * 100).toStringAsFixed(0)}%');
    _prefs.setDouble(EqualizerPrefKeys.bassBoost, _bassBoost);

    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        final params = await _androidEqualizer!.parameters;
        if (params.bands.isNotEmpty) {
          // Use ONLY EQ bands with higher boost values
          // This gives natural bass enhancement without compression
          final bassGain = _originalBandLevels[0] + (clampedStrength * 12.0);

          await params.bands[0].setGain(bassGain);
          _bandLevels[0] = bassGain;

          if (params.bands.length > 1) {
            final secondBandGain = _originalBandLevels[1] + (clampedStrength * 7.0);
            await params.bands[1].setGain(secondBandGain);
            _bandLevels[1] = secondBandGain;
          }

          log('✅ Android bass boost applied: Band 0 = ${bassGain.toStringAsFixed(1)} dB');
        }

        // DISABLE loudness enhancer completely - it's causing the aggressive sound
        if (_loudnessEnhancer != null) {
          await _loudnessEnhancer!.setEnabled(false);
          log('🔇 Loudness enhancer: DISABLED (EQ only)');
        }
      } catch (e) {
        log('❌ Error setting Android bass boost: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      await _iosPlayer!.setBassBoost(clampedStrength);

      if (_bandLevels.isNotEmpty) {
        final bassGain = _originalBandLevels[0] + (clampedStrength * 0.6);
        await _iosPlayer!.setEqualizerBandLevel(0, bassGain);
        _bandLevels[0] = bassGain;
      }

      if (_bandLevels.length > 1) {
        final secondGain = _originalBandLevels[1] + (clampedStrength * 0.4);
        await _iosPlayer!.setEqualizerBandLevel(1, secondGain);
        _bandLevels[1] = secondGain;
      }
      log('✅ iOS bass boost set');
    }

    _equalizerChangedController.add(null);
  }


  /* Future<void> setBassBoost(double strength) async {
    // final clampedStrength = strength.clamp(0.0, 0.6);
    final clampedStrength = strength.clamp(0.0, 1.0);
    _bassBoost = clampedStrength;

    log('🔊 Setting bass boost: ${(clampedStrength * 100).toStringAsFixed(0)}%');

    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        final params = await _androidEqualizer!.parameters;
        if (params.bands.isNotEmpty) {
          // Boost first 2 bands (bass frequencies: 60Hz, 230Hz)
          // final bassGain = clampedStrength * 25.0; // 0-15 dB range
          // final bassGain = _originalBandLevels[0] * 10.0 + (clampedStrength * 6.0);
          final bassGain = _originalBandLevels[0] + (clampedStrength * 6.0);

          await params.bands[0].setGain(bassGain);
          _bandLevels[0] = bassGain;

          if (params.bands.length > 1) {
            // final secondBandGain = bassGain * 0.7;
            final secondBandGain = _originalBandLevels[1] + (clampedStrength * 4.0);
            await params.bands[1].setGain(secondBandGain);
            _bandLevels[1] = secondBandGain;
          }

          log('✅ Android bass boost applied: Band 0 = ${bassGain.toStringAsFixed(1)} dB');
        }

        // Also use loudness enhancer
        if (_loudnessEnhancer != null) {
          // await _loudnessEnhancer!.setTargetGain(clampedStrength * 1000);
          await _loudnessEnhancer!.setTargetGain(clampedStrength * 200);
          await _loudnessEnhancer!.setEnabled(clampedStrength > 0);
        }
      } catch (e) {
        log('❌ Error setting Android bass boost: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      await _iosPlayer!.setBassBoost(clampedStrength);
      // Apply bass boost to EQ bands
      if (_bandLevels.isNotEmpty) {
        final bassGain = _originalBandLevels[0] + (clampedStrength * 0.6);
        await _iosPlayer!.setEqualizerBandLevel(0, bassGain);
        _bandLevels[0] = bassGain;
      }

      if (_bandLevels.length > 1) {
        final secondGain = _originalBandLevels[1] + (clampedStrength * 0.4);
        await _iosPlayer!.setEqualizerBandLevel(1, secondGain);
        _bandLevels[1] = secondGain;
      }
      log('✅ iOS bass boost set');
    }

    _equalizerChangedController.add(null);
  }*/

  Future<void> setVirtualizer(double strength) async {
    final clampedStrength = strength.clamp(0.0, 1.0);
    _virtualizer = clampedStrength;
    _prefs.setDouble(EqualizerPrefKeys.virtualizer, _virtualizer);

    log('🎧 Setting virtualizer: ${(clampedStrength * 100).toStringAsFixed(0)}%');

    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        final params = await _androidEqualizer!.parameters;
        // Boost mid-range frequencies (910Hz, 3600Hz)
        if (params.bands.length >= 4) {
          // final midGain = clampedStrength * 5.0;
          final midGain = _originalBandLevels[2]+ (clampedStrength * 3.0);
          final highMidGain = _originalBandLevels[3] + (clampedStrength * 2.0);

          await params.bands[2].setGain(midGain);
          await params.bands[3].setGain(highMidGain);
          // await params.bands[3].setGain(midGain * 0.8);
          _bandLevels[2] = midGain;
          // _bandLevels[3] = (midGain * 0.8) / 10.0;
          _bandLevels[3] =  midGain;
          log('✅ Android virtualizer applied');
        }
      } catch (e) {
        log('❌ Error setting Android virtualizer: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      // iOS implementation
      if (_bandLevels.length >= 4) {
        // final gain = clampedStrength * 5.0;
        final midGain = _originalBandLevels[2] + (clampedStrength * 0.3);
        final highMidGain = _originalBandLevels[3] + (clampedStrength * 0.2);

        await _iosPlayer!.setEqualizerBandLevel(2, midGain);
        // await _iosPlayer!.setEqualizerBandLevel(3, gain * 0.8);
        await _iosPlayer!.setEqualizerBandLevel(3, highMidGain);
        _bandLevels[2] = midGain;
        _bandLevels[3] = highMidGain;
        // _bandLevels[2] = gain / 10.0;
        // _bandLevels[3] = (gain * 0.8) / 10.0;
        log('✅ iOS virtualizer applied');
      }
    }

    _equalizerChangedController.add(null);
  }

  /// Set bass boost (0.0 to 1.0)
  /* Future<void> setBassBoost(double strength) async {
    _bassBoost = strength.clamp(0.0, 1.0);

    log('🔊 Setting bass boost: ${(_bassBoost * 100).toStringAsFixed(0)}%');

    if (Platform.isAndroid && _loudnessEnhancer != null) {
      try {
        await _loudnessEnhancer!.setTargetGain(_bassBoost * 1000);
        await _loudnessEnhancer!.setEnabled(_bassBoost > 0);
        log('✅ Android bass boost set');
      } catch (e) {
        log('❌ Error setting Android bass boost: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      await _iosPlayer!.setBassBoost(_bassBoost);
      log('✅ iOS bass boost set');
    }

    _equalizerChangedController.add(null);
  }*/

  /* /// Set virtualizer (0.0 to 1.0)
  Future<void> setVirtualizer(double strength) async {
    _virtualizer = strength.clamp(0.0, 1.0);
    log('🎧 Setting virtualizer: ${(_virtualizer * 100).toStringAsFixed(0)}%');
    // Note: just_audio doesn't have built-in virtualizer for either platform
    // This is a placeholder for UI state
    _equalizerChangedController.add(null);
  }*/

  Future<void> setReverb(String reverbType) async {
    if (!_isInitialized) {
      log('⚠️ Equalizer not initialized');
      return;
    }

    log('🎵 Setting reverb to: $reverbType');

    try {
      // First restore original EQ values before applying new reverb
      await _restoreOriginalEQ();

      _reverbType = reverbType;

      if (Platform.isAndroid && _androidEqualizer != null) {
        await _setAndroidReverb(reverbType);
      } else if (Platform.isIOS && _iosPlayer != null) {
        await _setIOSReverb(reverbType);
      }
      _prefs.setString(EqualizerPrefKeys.reverb, _reverbType);

      _equalizerChangedController.add(null);
      log('✅ Reverb applied: $reverbType');
    } catch (e) {
      log('❌ Error setting reverb: $e');
    }
  }

  /// Restore original EQ values before applying reverb
  Future<void> _restoreOriginalEQ() async {
    if (Platform.isAndroid && _androidEqualizer != null) {
      final params = await _androidEqualizer!.parameters;
      for (int i = 0; i < _originalBandLevels.length && i < params.bands.length; i++) {
        await params.bands[i].setGain(_originalBandLevels[i]);
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      for (int i = 0; i < _originalBandLevels.length; i++) {
        await _iosPlayer!.setEqualizerBandLevel(i, _originalBandLevels[i]);
      }
    }

    _bandLevels = List.from(_originalBandLevels);
  }

  /// Apply Android reverb using EQ bands
  /// FIXED: Android reverb with subtle, professional settings
  Future<void> _setAndroidReverb(String reverbType) async {
    final params = await _androidEqualizer!.parameters;

    switch (reverbType) {
      case 'None':
      // Keep original EQ
        break;

      case 'Small Room':
        if (params.bands.length >= 4) {
          // Subtle mid-high boost
          await params.bands[2].setGain((_originalBandLevels[2]) + 1.5);
          await params.bands[3].setGain((_originalBandLevels[3]) + 2.0);
        }
        break;

      case 'Medium Room':
        if (params.bands.length >= 4) {
          await params.bands[2].setGain((_originalBandLevels[2]) + 2.0);
          await params.bands[3].setGain((_originalBandLevels[3]) + 2.5);
        }
        break;

      case 'Large Room':
      case 'Medium Hall':
        if (params.bands.length >= 4) {
          // Balanced room sound
          await params.bands[1].setGain((_originalBandLevels[1]) + 1.0);
          await params.bands[2].setGain((_originalBandLevels[2]) + 2.5);
          await params.bands[3].setGain((_originalBandLevels[3]) + 3.0);
        }
        break;

      case 'Large Hall':
        if (params.bands.length >= 5) {
          // Wide, spacious sound
          await params.bands[1].setGain((_originalBandLevels[1]) + 1.5);
          await params.bands[2].setGain((_originalBandLevels[2]) + 3.0);
          await params.bands[3].setGain((_originalBandLevels[3]) + 3.5);
          await params.bands[4].setGain((_originalBandLevels[4]) + 2.5);
        }
        break;

      case 'Plate':
        if (params.bands.length >= 5) {
          // Bright, shimmery reverb
          await params.bands[3].setGain((_originalBandLevels[3]) + 3.0);
          await params.bands[4].setGain((_originalBandLevels[4]) + 3.5);
        }
        break;
    }

    // Update band levels for UI
    for (int i = 0; i < params.bands.length; i++) {
      _bandLevels[i] = params.bands[i].gain / 10.0;
    }
  }
 /* Future<void> _setAndroidReverb(String reverbType) async {
    final params = await _androidEqualizer!.parameters;

    // Reset to current preset first if not Custom
    if (_currentPreset != 'Custom') {
      await applyPreset(_currentPreset);
    }

    switch (reverbType) {
      case 'None':
        // Keep current EQ settings
        break;
      case 'Small Room':
        if (params.bands.length >= 4) {
          await params.bands[2].setGain((_bandLevels[2] * 10.0) + 2.0);
          await params.bands[3].setGain((_bandLevels[3] * 10.0) + 3.0);
        }
        break;
      case 'Medium Room':
        if (params.bands.length >= 4) {
          await params.bands[2].setGain((_bandLevels[2] * 10.0) + 3.0);
          await params.bands[3].setGain((_bandLevels[3] * 10.0) + 4.0);
        }
        break;
      case 'Large Room':
      case 'Medium Hall':
        if (params.bands.length >= 4) {
          await params.bands[1].setGain((_bandLevels[1] * 10.0) + 2.0);
          await params.bands[2].setGain((_bandLevels[2] * 10.0) + 4.0);
          await params.bands[3].setGain((_bandLevels[3] * 10.0) + 5.0);
        }
        break;
      case 'Large Hall':
        if (params.bands.length >= 5) {
          await params.bands[1].setGain((_bandLevels[1] * 10.0) + 3.0);
          await params.bands[2].setGain((_bandLevels[2] * 10.0) + 5.0);
          await params.bands[3].setGain((_bandLevels[3] * 10.0) + 6.0);
          await params.bands[4].setGain((_bandLevels[4] * 10.0) + 4.0);
        }
        break;
      case 'Plate':
        if (params.bands.length >= 5) {
          await params.bands[3].setGain((_bandLevels[3] * 10.0) + 5.0);
          await params.bands[4].setGain((_bandLevels[4] * 10.0) + 6.0);
        }
        break;
    }
  }*/

  /// Apply iOS reverb using EQ
  ///
  Future<void> _setIOSReverb(String reverbType) async {
    switch (reverbType) {
      case 'None':
        break;

      case 'Small Room':
        if (_bandLevels.length >= 4) {
          await _iosPlayer!.setEqualizerBandLevel(2, _originalBandLevels[2] + 0.15);
          await _iosPlayer!.setEqualizerBandLevel(3, _originalBandLevels[3] + 0.20);
          _bandLevels[2] = _originalBandLevels[2] + 0.15;
          _bandLevels[3] = _originalBandLevels[3] + 0.20;
        }
        break;

      case 'Medium Room':
        if (_bandLevels.length >= 4) {
          await _iosPlayer!.setEqualizerBandLevel(2, _originalBandLevels[2] + 0.20);
          await _iosPlayer!.setEqualizerBandLevel(3, _originalBandLevels[3] + 0.25);
          _bandLevels[2] = _originalBandLevels[2] + 0.20;
          _bandLevels[3] = _originalBandLevels[3] + 0.25;
        }
        break;

      case 'Large Room':
      case 'Medium Hall':
        if (_bandLevels.length >= 4) {
          await _iosPlayer!.setEqualizerBandLevel(1, _originalBandLevels[1] + 0.10);
          await _iosPlayer!.setEqualizerBandLevel(2, _originalBandLevels[2] + 0.25);
          await _iosPlayer!.setEqualizerBandLevel(3, _originalBandLevels[3] + 0.30);
          _bandLevels[1] = _originalBandLevels[1] + 0.10;
          _bandLevels[2] = _originalBandLevels[2] + 0.25;
          _bandLevels[3] = _originalBandLevels[3] + 0.30;
        }
        break;

      case 'Large Hall':
        if (_bandLevels.length >= 5) {
          await _iosPlayer!.setEqualizerBandLevel(1, _originalBandLevels[1] + 0.15);
          await _iosPlayer!.setEqualizerBandLevel(2, _originalBandLevels[2] + 0.30);
          await _iosPlayer!.setEqualizerBandLevel(3, _originalBandLevels[3] + 0.35);
          await _iosPlayer!.setEqualizerBandLevel(4, _originalBandLevels[4] + 0.25);
          _bandLevels[1] = _originalBandLevels[1] + 0.15;
          _bandLevels[2] = _originalBandLevels[2] + 0.30;
          _bandLevels[3] = _originalBandLevels[3] + 0.35;
          _bandLevels[4] = _originalBandLevels[4] + 0.25;
        }
        break;

      case 'Plate':
        if (_bandLevels.length >= 5) {
          await _iosPlayer!.setEqualizerBandLevel(3, _originalBandLevels[3] + 0.30);
          await _iosPlayer!.setEqualizerBandLevel(4, _originalBandLevels[4] + 0.35);
          _bandLevels[3] = _originalBandLevels[3] + 0.30;
          _bandLevels[4] = _originalBandLevels[4] + 0.35;
        }
        break;
    }
  }
  /*Future<void> _setIOSReverb(String reverbType) async {
    // Reset to current preset first
    if (_currentPreset != 'Custom') {
      await applyPreset(_currentPreset);
    }

    switch (reverbType) {
      case 'None':
        break;
      case 'Small Room':
        if (_bandLevels.length >= 4) {
          await _iosPlayer!.setEqualizerBandLevel(2, (_bandLevels[2] * 10.0) + 2.0);
          await _iosPlayer!.setEqualizerBandLevel(3, (_bandLevels[3] * 10.0) + 3.0);
        }
        break;
      case 'Medium Room':
        if (_bandLevels.length >= 4) {
          await _iosPlayer!.setEqualizerBandLevel(2, (_bandLevels[2] * 10.0) + 3.0);
          await _iosPlayer!.setEqualizerBandLevel(3, (_bandLevels[3] * 10.0) + 4.0);
        }
        break;
      case 'Large Room':
      case 'Medium Hall':
        if (_bandLevels.length >= 4) {
          await _iosPlayer!.setEqualizerBandLevel(1, (_bandLevels[1] * 10.0) + 2.0);
          await _iosPlayer!.setEqualizerBandLevel(2, (_bandLevels[2] * 10.0) + 4.0);
          await _iosPlayer!.setEqualizerBandLevel(3, (_bandLevels[3] * 10.0) + 5.0);
        }
        break;
      case 'Large Hall':
        if (_bandLevels.length >= 5) {
          await _iosPlayer!.setEqualizerBandLevel(1, (_bandLevels[1] * 10.0) + 3.0);
          await _iosPlayer!.setEqualizerBandLevel(2, (_bandLevels[2] * 10.0) + 5.0);
          await _iosPlayer!.setEqualizerBandLevel(3, (_bandLevels[3] * 10.0) + 6.0);
          await _iosPlayer!.setEqualizerBandLevel(4, (_bandLevels[4] * 10.0) + 4.0);
        }
        break;
      case 'Plate':
        if (_bandLevels.length >= 5) {
          await _iosPlayer!.setEqualizerBandLevel(3, (_bandLevels[3] * 10.0) + 5.0);
          await _iosPlayer!.setEqualizerBandLevel(4, (_bandLevels[4] * 10.0) + 6.0);
        }
        break;
    }
  }*/

  /// Reapply all effects after EQ changes
  Future<void> _reapplyAllEffects() async {
    // Reapply bass boost if active
    if (_bassBoost > 0) {
      final tempBassBoost = _bassBoost;
      _bassBoost = 0;
      await setBassBoost(tempBassBoost);
    }

    // Reapply virtualizer if active
    if (_virtualizer > 0) {
      final tempVirtualizer = _virtualizer;
      _virtualizer = 0;
      await setVirtualizer(tempVirtualizer);
    }

    // Reapply reverb if active
    if (_reverbType != 'None') {
      final tempReverb = _reverbType;
      _reverbType = 'None';
      await setReverb(tempReverb);
    }
  }


  /// Reset equalizer to flat
  Future<void> reset() async {
    log('🔄 Resetting equalizer to flat');
    await applyPreset('Flat');
    await setBassBoost(0.0);
    await setVirtualizer(0.0);
    await setReverb('None');


    await _prefs.remove(EqualizerPrefKeys.bassBoost);
    await _prefs.remove(EqualizerPrefKeys.virtualizer);
    await _prefs.remove(EqualizerPrefKeys.reverb);
  }

  void dispose() {
    _equalizerChangedController.close();
    _iosPlayer?.dispose();
  }
}

/*
class UnifiedEqualizerService {
  static final UnifiedEqualizerService _instance = UnifiedEqualizerService._internal();
  factory UnifiedEqualizerService() => _instance;

  // Android-specific
  AndroidEqualizer? _androidEqualizer;
  AndroidLoudnessEnhancer? _loudnessEnhancer;

  // iOS-specific
  IOSAudioPlayer? _iosPlayer;

  // Common state
  bool _isEnabled = false;
  List<double> _bandLevels = [];
  List<double> _centerFrequencies = [];
  double _minDecibels = -15.0;
  double _maxDecibels = 15.0;
  String _currentPreset = 'Custom';
  double _bassBoost = 0.0;
  double _virtualizer = 0.0;

  // Presets
  final Map<String, List<double>> _presets = {
    'Normal': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Rock': [5.0, 3.0, -2.0, 0.0, 4.0],
    'Classical': [4.0, 3.0, -2.0, 2.0, 3.0],
    'Hip Hop': [6.0, 4.0, 0.0, 2.0, 3.0],
    'Jazz': [4.0, 2.0, -2.0, 2.0, 5.0],
    'Electronic': [4.0, 3.0, 1.0, 0.0, 4.0],
    'Flat': [0.0, 0.0, 0.0, 0.0, 0.0],
    'Pop': [2.0, 4.0, 5.0, 4.0, 2.0],
    'Custom': [0.0, 0.0, 0.0, 0.0, 0.0],
  };

  final StreamController<void> _equalizerChangedController = StreamController<void>.broadcast();
  Stream<void> get equalizerChanged => _equalizerChangedController.stream;

  UnifiedEqualizerService._internal();

  bool get isEnabled => _isEnabled;
  bool get isAndroid => Platform.isAndroid;
  bool get isIOS => Platform.isIOS;
  List<double> get bandLevels => List.unmodifiable(_bandLevels);
  List<double> get centerFrequencies => List.unmodifiable(_centerFrequencies);
  double get minDecibels => _minDecibels;
  double get maxDecibels => _maxDecibels;
  String get currentPreset => _currentPreset;
  List<String> get presetNames => _presets.keys.toList();
  double get bassBoost => _bassBoost;
  double get virtualizer => _virtualizer;

  /// Initialize equalizer for current platform
  Future<void> initialize(dynamic player) async {
    try{
      print('═══════════════════════════════════════════════════');
      print('🔧 UnifiedEqualizerService.init() STARTED');
      print('═══════════════════════════════════════════════════');

      if (Platform.isAndroid) {
        await _initializeAndroid(player as AudioPlayer);
      } else if (Platform.isIOS) {
        await _initializeIOS(player);
      } else {
        _initializeDummyEqualizer();
      }
      print('✅ UnifiedEqualizerService.init() COMPLETE');
      print('   - Band Levels Count: ${_bandLevels.length}');
      print('   - Center Frequencies: $_centerFrequencies');
      print('   - Is Enabled: $_isEnabled');
      print('═══════════════════════════════════════════════════\n');
    }catch(e){
      print('❌ ERROR in UnifiedEqualizerService.init(): $e');
      print('═══════════════════════════════════════════════════\n');
    }

  }

  /// Initialize Android equalizer
  Future<void> _initializeAndroid(AudioPlayer player) async {
    try {
      _androidEqualizer = AndroidEqualizer();
      _loudnessEnhancer = AndroidLoudnessEnhancer();

      await player.setAudioSource(
        AudioSource.uri(Uri.parse(Assets.assetsSilence)),
        preload: false,
      );

      final params = await _androidEqualizer!.parameters;

      _minDecibels = params.minDecibels;
      _maxDecibels = params.maxDecibels;
      _centerFrequencies = params.bands.map((band) => band.centerFrequency).toList();
      _bandLevels = List.filled(params.bands.length, 0.0);

      await applyPreset('Normal');

      log('Android Equalizer initialized with ${_bandLevels.length} bands');
      log('Frequency range: $_minDecibels dB to $_maxDecibels dB');
    } catch (e) {
      log('Error initializing Android equalizer: $e');
      _initializeDummyEqualizer();
    }
  }

  /// Initialize iOS equalizer
  Future<void> _initializeIOS(dynamic player) async {
    try {
      if (player is IOSAudioPlayer) {
        _iosPlayer = player;
      } else {
        log('iOS player is not IOSAudioPlayer type');
        _initializeDummyEqualizer();
        return;
      }

      // Get frequencies from iOS player
      final frequencies = await _iosPlayer!.getEqualizerFrequencies();
      if (frequencies != null && frequencies.isNotEmpty) {
        _centerFrequencies = frequencies;
        _bandLevels = List.filled(_centerFrequencies.length, 0.0);
        _minDecibels = -15.0;
        _maxDecibels = 15.0;

        await applyPreset('Normal');

        log('iOS Equalizer initialized with ${_bandLevels.length} bands');
      } else {
        _initializeDummyEqualizer();
      }
    } catch (e) {
      log('Error initializing iOS equalizer: $e');
      _initializeDummyEqualizer();
    }
  }

  /// Initialize dummy equalizer for unsupported platforms
  void _initializeDummyEqualizer() {
    _centerFrequencies = [60.0, 230.0, 910.0, 3600.0, 14000.0];
    _bandLevels = List.filled(5, 0.0);
    _minDecibels = -15.0;
    _maxDecibels = 15.0;
    log('Using dummy equalizer (platform not supported or initialization failed)');
  }

  /// Create AudioPlayer with equalizer (Android only)
  AudioPlayer createAndroidPlayerWithEqualizer() {
    if (!Platform.isAndroid) {
      return AudioPlayer();
    }

    _androidEqualizer = AndroidEqualizer();
    _loudnessEnhancer = AndroidLoudnessEnhancer();

    return AudioPlayer(
      audioPipeline: AudioPipeline(
        androidAudioEffects: [
          _androidEqualizer!,
          _loudnessEnhancer!,
        ],
      ),
    );
  }

  /// Create iOS audio player
  Future<IOSAudioPlayer> createIOSPlayer() async {
    final player = IOSAudioPlayer();
    await player.initialize();
    _iosPlayer = player;
    return player;
  }

  /// Toggle equalizer on/off
  Future<void> toggleEnabled() async {
    await setEnabled(!_isEnabled);
  }

  /// Set equalizer enabled state
  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;

    _isEnabled = enabled;

    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        await _androidEqualizer!.setEnabled(enabled);
      } catch (e) {
        log('Error setting Android equalizer enabled: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      await _iosPlayer!.setEqualizerEnabled(enabled);
    }

    _equalizerChangedController.add(null);
  }

  /// Set band gain
  Future<void> setBandLevel(int bandIndex, double gain) async {
    if (bandIndex < 0 || bandIndex >= _bandLevels.length) return;

    final clampedGain = gain.clamp(_minDecibels, _maxDecibels);
    _bandLevels[bandIndex] = clampedGain;

    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        final params = await _androidEqualizer!.parameters;
        await params.bands[bandIndex].setGain(clampedGain);
      } catch (e) {
        log('Error setting Android band level: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      await _iosPlayer!.setEqualizerBandLevel(bandIndex, clampedGain);
    }

    _currentPreset = 'Custom';
    _presets['Custom'] = List.from(_bandLevels);

    _equalizerChangedController.add(null);
  }

  /// Apply preset
  Future<void> applyPreset(String presetName) async {
    if (!_presets.containsKey(presetName)) return;

    _currentPreset = presetName;
    final presetLevels = _presets[presetName]!;

    if (presetLevels.length != _bandLevels.length) {
      _bandLevels = _adjustPresetToBands(presetLevels);
    } else {
      _bandLevels = List.from(presetLevels);
    }

    // Apply to platform-specific equalizer
    if (Platform.isAndroid && _androidEqualizer != null) {
      try {
        final params = await _androidEqualizer!.parameters;
        for (int i = 0; i < _bandLevels.length && i < params.bands.length; i++) {
          await params.bands[i].setGain(_bandLevels[i]);
        }
      } catch (e) {
        log('Error applying Android preset: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      for (int i = 0; i < _bandLevels.length; i++) {
        await _iosPlayer!.setEqualizerBandLevel(i, _bandLevels[i]);
      }
    }

    _equalizerChangedController.add(null);
  }

  /// Adjust preset levels to match actual number of bands
  List<double> _adjustPresetToBands(List<double> preset) {
    final result = <double>[];
    final ratio = preset.length / _centerFrequencies.length;

    for (int i = 0; i < _centerFrequencies.length; i++) {
      final index = (i * ratio).floor().clamp(0, preset.length - 1);
      result.add(preset[index]);
    }

    return result;
  }

  /// Set bass boost (0.0 to 1.0)
  Future<void> setBassBoost(double strength) async {
    _bassBoost = strength.clamp(0.0, 1.0);

    if (Platform.isAndroid && _loudnessEnhancer != null) {
      try {
        await _loudnessEnhancer!.setTargetGain(_bassBoost * 1000);
        await _loudnessEnhancer!.setEnabled(_bassBoost > 0);
      } catch (e) {
        log('Error setting Android bass boost: $e');
      }
    } else if (Platform.isIOS && _iosPlayer != null) {
      await _iosPlayer!.setBassBoost(_bassBoost);
    }

    _equalizerChangedController.add(null);
  }

  /// Set virtualizer (0.0 to 1.0)
  Future<void> setVirtualizer(double strength) async {
    _virtualizer = strength.clamp(0.0, 1.0);
    // Note: just_audio doesn't have built-in virtualizer for either platform
    // This is a placeholder for UI state
    _equalizerChangedController.add(null);
  }

  /// Reset equalizer to flat
  Future<void> reset() async {
    await applyPreset('Flat');
    await setBassBoost(0.0);
    await setVirtualizer(0.0);
  }

  void dispose() {
    _equalizerChangedController.close();
    _iosPlayer?.dispose();
  }
}*/
