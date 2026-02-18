import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../services/diagnose_equalizer.dart';
import '../../services/unified_equalizer_service.dart';
import '../tabs/music_service.dart';

/// UI range for sliders: -1.5 to 1.5 (maps to dB -15 to 15)
const double _uiMin = -1.5;
const double _uiMax = 1.5;

/// Convert from dB to UI range (-1.5 to 1.5), clamping to valid range
double dbToUI(double db) {
  return (db / 10.0).clamp(_uiMin, _uiMax);
}

/// Convert from UI range (-1.5 to 1.5) to dB (-15 to 15)
double uiToDb(double uiValue) {
  return (uiValue.clamp(_uiMin, _uiMax)) * 10.0;
}

class EqualizerProvider extends ChangeNotifier {
  EqualizerProvider() {
    _musicService = MusicPlayerService();
    _eqService = _musicService.equalizerService;
    _init();
  }

  late final MusicPlayerService _musicService;
  late final UnifiedEqualizerService _eqService;
  StreamSubscription<void>? _eqChangedSubscription;

  final presetList = [
    "Custom", "Normal", "Rock", "Dance", "Pop", "Hip Hop", "Acoustic",
    "Heavy Metal", "Folk", "Head Phones", "Loud", "Piano", "Bass Boost",
    "Electronic", "Flat", "Classical", "Straightness", "Jazz", "Treble Boost",
    "Vocal Boost", "Latin", "Deep", "Lounge", "R&B",
  ];

  final reverbOptions = [
    "None", "Small Room", "Medium Room", "Large Room",
    "Medium Hall", "Large Hall", "Plate"
  ];

  int selectedPreset = 0;
  List<double> frequencies = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<double> customFrequencies = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<String> frequencyLabels = ["60Hz", "230Hz", "910Hz", "4kHz", "14kHz"];

  String selectedReverb = "None";
  int bassBoostLevel = 0;
  int virtualizerLevel = 0;
  int localSelectedIndex = 0;

  bool isInitialized = false;
  bool hasError = false;
  String errorMessage = '';
  bool isEqEnabled = false;

  UnifiedEqualizerService get eqService => _eqService;

  void _init() {
    isEqEnabled = _eqService.isEnabled;
    isInitialized = true;

    if (_eqService.bandLevels.isNotEmpty) {
      frequencies = _eqService.bandLevels.map((db) => dbToUI(db)).toList();
      customFrequencies = List.from(frequencies);
    }

    final currentPresetName = _eqService.currentPreset;
    final presetIndex = presetList.indexWhere((p) => p.toLowerCase() == currentPresetName.toLowerCase());
    if (presetIndex >= 0) {
      selectedPreset = presetIndex;
    }

    selectedReverb = _eqService.reverbType;
    localSelectedIndex = reverbOptions.indexOf(selectedReverb);
    if (localSelectedIndex < 0) localSelectedIndex = 0;

    bassBoostLevel = (_eqService.bassBoost * 20).round();
    virtualizerLevel = (_eqService.virtualizer * 20).round();

    _eqChangedSubscription = _eqService.equalizerChanged.listen((_) {
      loadEqualizerState();
    });

    _runDiagnostic();
  }

  @override
  void dispose() {
    _eqChangedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _runDiagnostic() async {
    await Future.delayed(const Duration(seconds: 1));
    if (Platform.isAndroid) {
      final player = _musicService.player;
      final eq = _musicService.equalizerService.androidEqualizer;
      if (player != null && eq != null) {
        await EqualizerDiagnostic.checkEqualizerSetup(player, eq);
      }
    }
  }

  Future<void> initializeEqualizer() async {
    try {
      isEqEnabled = _eqService.isEnabled;

      if (_eqService.bandLevels.isNotEmpty) {
        frequencies = _eqService.bandLevels.map((db) => dbToUI(db)).toList();
        customFrequencies = List.from(frequencies);

        if (_eqService.centerFrequencies.isNotEmpty) {
          frequencyLabels = _eqService.centerFrequencies.map((freq) {
            if (freq >= 1000) {
              return '${(freq / 1000).toStringAsFixed(0)}kHz';
            } else {
              return '${freq.toStringAsFixed(0)}Hz';
            }
          }).toList();
        }

        final currentPresetName = _eqService.currentPreset;
        final presetIndex = presetList.indexWhere((p) => p.toLowerCase() == currentPresetName.toLowerCase());
        selectedPreset = presetIndex >= 0 ? presetIndex : 0;

        bassBoostLevel = (_eqService.bassBoost * 20).round();
        virtualizerLevel = (_eqService.virtualizer * 20).round();
      }

      isInitialized = true;
      notifyListeners();

      await _eqService.setEnabled(true);
    } catch (e) {
      isInitialized = true;
      hasError = true;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void loadEqualizerState() {
    bassBoostLevel = (_eqService.bassBoost * 20).round();
    virtualizerLevel = (_eqService.virtualizer * 20).round();
    // Do NOT overwrite frequencies from backend - user's slider positions are
    // the source of truth. Overwriting caused the slider to jump to different
    // values when backend returned (e.g. rounded or differently scaled) values.
    notifyListeners();
  }

  // Note: frequency sliders are driven only by presets and manual band edits.
  // Effects like Bass Boost / Virtualizer / Reverb change audio but intentionally
  // do not re-shape the visible sliders, to match the reference app behaviour.

  List<double> _getPresetFrequencies(String presetName) {
    const presetData = {
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
    return List<double>.from(presetData[presetName] ?? [0.0, 0.0, 0.0, 0.0, 0.0]);
  }

  Future<void> applyPreset(int index) async {
    if (index >= presetList.length) return;

    final presetName = presetList[index];
    selectedPreset = index;

    if (presetName == 'Custom') {
      frequencies = List.from(customFrequencies);
    } else {
      frequencies = _getPresetFrequencies(presetName);
    }
    notifyListeners();

    if (presetName == 'Custom') {
      for (int i = 0; i < frequencies.length; i++) {
        try {
          await _eqService.setBandLevel(i, frequencies[i].clamp(_uiMin, _uiMax));
        } catch (_) {}
      }
      return;
    }

    // If this preset exists in the backend, apply it directly so that
    // `_eqService.currentPreset` stays in sync with the UI name.
    if (_eqService.presetNames.contains(presetName)) {
      try {
        await _eqService.applyPreset(presetName);
      } catch (_) {}
    } else {
      for (int i = 0; i < frequencies.length; i++) {
        try {
          await _eqService.setBandLevel(i, frequencies[i].clamp(_uiMin, _uiMax));
        } catch (_) {}
      }
    }
  }

  /// Updates UI immediately during drag (no backend call) - keeps sliding smooth
  void updateBandLevelUI(int index, double value) {
    final clampedValue = value.clamp(_uiMin, _uiMax);
    frequencies[index] = clampedValue;
    customFrequencies[index] = clampedValue;
    selectedPreset = 0;
    notifyListeners();
    // Also apply the change to the backend immediately so the effect is heard
    // while sliding, not only after releasing the thumb.
    _eqService.setBandLevel(index, clampedValue);
  }

  /// Commits current band level to backend - call when user releases the slider
  void commitBandLevelToBackend(int index) {
    final clampedValue = frequencies[index].clamp(_uiMin, _uiMax);
    // Service expects UI range (-1.5 to 1.5) and multiplies by 10 for Android
    _eqService.setBandLevel(index, clampedValue);
  }

  /// Update Bass Boost UI immediately (no backend call) for smooth interaction
  void updateBassBoostUI(int level) {
    bassBoostLevel = level;
    notifyListeners();
  }

  /// Commit Bass Boost to backend when user finishes interaction
  Future<void> commitBassBoostToBackend(int level) async {
    final strength = (level / 20.0).clamp(0.0, 1.0);
    try {
      await _eqService.setBassBoost(strength);
    } catch (_) {}
  }

  /// Update Virtualizer UI immediately (no backend call)
  void updateVirtualizerUI(int level) {
    virtualizerLevel = level;
    notifyListeners();
  }

  /// Commit Virtualizer to backend when user finishes interaction
  Future<void> commitVirtualizerToBackend(int level) async {
    final strength = (level / 20.0).clamp(0.0, 1.0);
    try {
      await _eqService.setVirtualizer(strength);
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    if (value) {
      await _eqService.setEnabled(true);
      if (!isInitialized) {
        await initializeEqualizer();
      }
    } else {
      await _eqService.setEnabled(false);
    }
    isEqEnabled = _eqService.isEnabled;
    notifyListeners();
  }

  Future<void> setReverb(String item) async {
    try {
      await _eqService.setReverb(item);
      selectedReverb = item;
      localSelectedIndex = reverbOptions.indexOf(item);
      notifyListeners();
    } catch (_) {}
  }

  void setLocalReverbIndex(int index) {
    localSelectedIndex = index;
    notifyListeners();
  }

  void retryInit() {
    isInitialized = false;
    hasError = false;
    notifyListeners();
    initializeEqualizer();
  }
}
