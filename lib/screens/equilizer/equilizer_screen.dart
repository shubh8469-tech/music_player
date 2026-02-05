import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music_app/themes/color.dart';

import '../../commonWidgets/app_bar_with_icon_title.dart';
import '../../commonWidgets/level_bar_Sliders.dart';
import '../../commonWidgets/textWidget.dart';
import '../../generated/assets.dart';
import '../../services/diagnose_equalizer.dart';
import '../../services/unified_equalizer_service.dart';
import '../../themes/font.dart';
import '../tabs/music_service.dart';

class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final MusicPlayerService _musicService = MusicPlayerService();
  late final UnifiedEqualizerService _eqService;

  /// Convert from dB (-15 to 15) to UI range (-1.5 to 1.5)
  double _dbToUI(double db) {
    return db / 10.0;
  }

  /// Convert from UI range (-1.5 to 1.5) to dB (-15 to 15)
  double _uiToDb(double uiValue) {
    return uiValue * 10.0;
  }



  final presetList = [
    "Custom",
    "Normal",
    "Rock",
    "Dance",
    "Pop",
    "Hip Hop",
    "Acoustic",
    "Heavy Metal",
    "Folk",
    "Head Phones",
    "Loud",
    "Piano",
    "Bass Boost",
    "Electronic",
    "Flat",
    "Classical",
    "Straightness",
    "Jazz",
    "Treble Boost",
    "Vocal Boost",
    "Latin",
    "Deep",
    "Lounge",
    "R&B",
  ];

  int selectedPreset = 0; // Start with "Custom"

  // Will be populated from actual equalizer
  List<double> frequencies = [0.0, 0.0, 0.0, 0.0, 0.0];
  List<double> _customFrequencies = [0.0, 0.0, 0.0, 0.0, 0.0]; // Store user's custom values

  List<String> frequencyLabels = ["60Hz", "230Hz", "910Hz", "4kHz", "14kHz"];

  String selectedReverb = "None";
  final reverbOptions = ["None", "Small Room", "Medium Room", "Large Room", "Medium Hall", "Large Hall", "Plate"];

  int bassBoostLevel = 0;
  int virtualizerLevel = 0;

  bool _isInitialized = false;

  bool _hasError = false;
  String _errorMessage = '';
  bool _isEqEnabled = false;

  @override
  void initState() {
    super.initState();
    _eqService = _musicService.equalizerService;
    _isEqEnabled = _eqService.isEnabled;
    _isInitialized = true;

    // Load current state from service
    if (_eqService.bandLevels.isNotEmpty) {
      frequencies = _eqService.bandLevels.map((db) => _dbToUI(db)).toList();
      _customFrequencies = List.from(frequencies);
    }

    // Get current preset
    final currentPresetName = _eqService.currentPreset;
    final presetIndex = presetList.indexWhere((p) => p.toLowerCase() == currentPresetName.toLowerCase());
    if (presetIndex >= 0) {
      selectedPreset = presetIndex;
    }

    // Load current reverb - ADD THIS
    selectedReverb = _eqService.reverbType;
    localSelectedIndex = reverbOptions.indexOf(selectedReverb);
    if (localSelectedIndex < 0) localSelectedIndex = 0;

    // Load bass boost and virtualizer
    bassBoostLevel = (_eqService.bassBoost * 20).round();
    virtualizerLevel = (_eqService.virtualizer * 20).round();

    print('Equalizer Service initialized');
    print('Current preset: ${presetList[selectedPreset]}');
    print('Current reverb: $selectedReverb');
    print('Bass boost: $bassBoostLevel');
    print('Virtualizer: $virtualizerLevel');

    _runDiagnostic();
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

  Future<void> _initializeEqualizer() async {
    try {
      print('═══════════════════════════════════════════════════');
      print('🎵 EQUALIZER INITIALIZATION STARTED');
      print('═══════════════════════════════════════════════════');

      print('🎧 Audio Player State:');
      print('   - Is Playing: ${_musicService.player.playing}');
      print('   - Duration: ${_musicService.player.duration}');
      print('   - Position: ${_musicService.player.position}');

      if (Platform.isAndroid) {
        try {
          final sessionId = await _musicService.player.androidAudioSessionId;
          print('📱 Android Audio Session ID: $sessionId');
          if (sessionId != null && sessionId > 0) {
            print('✅ Audio session is ACTIVE and VALID');
          } else {
            print('❌ Audio session is INVALID or NOT STARTED');
          }
        } catch (e) {
          print('⚠️  Could not get Android audio session ID: $e');
        }
      }

      // Always show UI immediately with current state
      setState(() {
        if (_eqService.bandLevels.isNotEmpty) {
          print('✅ Equalizer has ${_eqService.bandLevels.length} bands');
          frequencies = _eqService.bandLevels.map((db) => _dbToUI(db)).toList();

          // Initialize custom frequencies with current band levels
          _customFrequencies = List.from(frequencies);

          // Update frequency labels from actual equalizer
          if (_eqService.centerFrequencies.isNotEmpty) {
            frequencyLabels = _eqService.centerFrequencies.map((freq) {
              if (freq >= 1000) {
                return '${(freq / 1000).toStringAsFixed(0)}kHz';
              } else {
                return '${freq.toStringAsFixed(0)}Hz';
              }
            }).toList();
            print('📊 Frequency bands: $frequencyLabels');
          }

          // Get current preset (should be Custom by default)
          final currentPresetName = _eqService.currentPreset;
          final presetIndex = presetList.indexWhere((p) => p.toLowerCase() == currentPresetName.toLowerCase());
          if (presetIndex >= 0) {
            selectedPreset = presetIndex;
          } else {
            selectedPreset = 0; // Default to Custom if not found
          }
          print('🎛️  Current preset: $currentPresetName (index: $selectedPreset)');

          // Get bass boost level (0.0-1.0 to 0-20)
          bassBoostLevel = (_eqService.bassBoost * 20).round();
          print('🔊 Bass Boost level: $bassBoostLevel');

          // Get virtualizer level (0.0-1.0 to 0-20)
          virtualizerLevel = (_eqService.virtualizer * 20).round();
          print('🎧 Virtualizer level: $virtualizerLevel');
        } else {
          print('⚠️  Equalizer has NO bands from service - this should not happen anymore');
        }

        // Always set initialized to true to show UI
        _isInitialized = true;
        print('═══════════════════════════════════════════════════');
        print('✅ EQUALIZER INITIALIZED');
        print('   - Frequencies: $frequencies');
        print('   - Custom Frequencies: $_customFrequencies');
        print('   - Selected preset: ${presetList[selectedPreset]}');
        print('   - Is Enabled: ${_eqService.isEnabled}');
        print('═══════════════════════════════════════════════════');
      });

      // Enable equalizer by default
      print('🔧 Enabling equalizer...');
      await _eqService.setEnabled(true);
      print('✅ Equalizer enabled: ${_eqService.isEnabled}');

      // Listen to equalizer changes
      _eqService.equalizerChanged.listen((_) {
        print('🔄 Equalizer settings changed - reloading state');
        if (mounted) {
          _loadEqualizerState();
        }
      });

      print('🎵 EQUALIZER INITIALIZATION COMPLETE');
      print('═══════════════════════════════════════════════════\n');
    } catch (e) {
      print('═══════════════════════════════════════════════════');
      print('❌ ERROR INITIALIZING EQUALIZER: $e');
      print('═══════════════════════════════════════════════════');
      setState(() {
        _isInitialized = true; // Show UI even on error
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _loadEqualizerState() {
    setState(() {
      bassBoostLevel = (_eqService.bassBoost * 20).round();
      virtualizerLevel = (_eqService.virtualizer * 20).round();
    });
  }

  List<double> _getPresetFrequencies(String presetName) {
    // Map preset names to frequency values (-1.5 to 1.5 range)
    final presetData = {
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

    return presetData[presetName] ?? [0.0, 0.0, 0.0, 0.0, 0.0];
  }

  Future<void> _applyPreset(int index) async {
    if (index >= presetList.length) return;

    final presetName = presetList[index];
    print('═══════════════════════════════════════════════════');
    print(' APPLYING PRESET');
    print('   - Preset: $presetName (index: $index)');
    print('   - Previous preset: ${presetList[selectedPreset]}');

    // Check if audio is playing
    final isPlaying = _musicService.player.playing;
    print('   - Audio Playing: $isPlaying');
    if (!isPlaying) {
      print(' WARNING: Audio is NOT playing - you may not hear changes!');
    }

    setState(() {
      selectedPreset = index;

      if (presetName == 'Custom') {
        // Restore user's saved custom values
        frequencies = List.from(_customFrequencies);
        print('   - Restored custom frequencies: $frequencies');
      } else {
        // Load preset values
        frequencies = _getPresetFrequencies(presetName);
        print('   - Loaded preset frequencies: $frequencies');
      }
    });

    // Apply to backend
    if (presetName == 'Custom') {
      print('   - Applying CUSTOM preset to backend...');
      // Apply custom frequencies to backend
      for (int i = 0; i < frequencies.length; i++) {
        try {
          final gainDb = _uiToDb(frequencies[i]);
          await _eqService.setBandLevel(i, gainDb);
          print('     ✓ Band $i: ${gainDb.toStringAsFixed(1)} dB');
        } catch (e) {
          print('Error setting custom band level $i: $e');
        }
      }
      print('Custom preset applied');
      print('═══════════════════════════════════════════════════\n');
      return;
    }

    print('   - Mapping to backend preset...');

    // Map UI preset names to backend preset names
    String backendPresetName = presetName;

    switch (presetName.toLowerCase()) {
      case 'bass boost':
        backendPresetName = 'Hip Hop';
        break;
      default:
        if (!_eqService.presetNames.contains(presetName)) {
          backendPresetName = 'Normal';
        }
    }

    // Apply preset to backend if it exists
    if (_eqService.presetNames.contains(backendPresetName)) {
      try {
        print('   - Applying backend preset: $backendPresetName');
        await _eqService.applyPreset(backendPresetName);
        print('Backend preset applied successfully');
      } catch (e) {
        print('Error applying preset to backend: $e');
      }
    } else {
      // Apply frequencies to backend manually
      print('   - Backend preset not found, applying manually...');
      // Apply frequencies to backend manually
      for (int i = 0; i < frequencies.length; i++) {
        try {
          final gainDb = _uiToDb(frequencies[i]);
          await _eqService.setBandLevel(i, gainDb);
          print('      Band $i: ${gainDb.toStringAsFixed(1)} dB');
        } catch (e) {
          print('      Band $i ERROR: $e');
        }
      }
      print(' Manual preset application complete');
    }
  }

  Future<void> _setBandLevel(int index, double value) async {
    print('═══════════════════════════════════════════════════');
    print('  SETTING BAND LEVEL');
    print('   - Band Index: $index (${frequencyLabels[index]})');
    print('   - UI Value: $value (range: -1.5 to +1.5)');

    // Convert from -1.5/1.5 range to -15/15 dB range
    final gainDb = _uiToDb(value);
    print('Gain in dB: $gainDb');

    final isPlaying = _musicService.player.playing;
    print('   - Audio Playing: $isPlaying');
    if (!isPlaying) {
      print(' WARNING: Audio is NOT playing - you may not hear changes!');
    }

    try {
      await _eqService.setBandLevel(index, gainDb);
      print('Band level SET successfully in equalizer service');

      // Verify the change was applied
      if (_eqService.bandLevels.isNotEmpty && index < _eqService.bandLevels.length) {
        final actualLevel = _eqService.bandLevels[index];
        print('   - Verified actual level: ${actualLevel.toStringAsFixed(1)} dB');
        if ((actualLevel - gainDb).abs() < 0.1) {
          print(' SYNC CONFIRMED: Value matches what we set');
        } else {
          print('️  SYNC WARNING: Value differs from what we set!');
        }
      }
    } catch (e) {
      print(' ERROR setting band level: $e');
    }

    setState(() {
      frequencies[index] = value;
      _customFrequencies[index] = value; // SAVE to custom values
      // Mark as custom preset
      selectedPreset = 0;
    });

    print('   - Updated UI frequencies: $frequencies');
    print('   - Saved to custom: $_customFrequencies');
    print('   - Switched to Custom preset');
    print('═══════════════════════════════════════════════════\n');
  }

  Future<void> _setBassBoost(int level) async {
    print('═══════════════════════════════════════════════════');
    print('SETTING BASS BOOST');
    print('   - Level: $level/20');

    // Convert from 0-20 to 0.0-1.0
    final strength = (level / 20.0).clamp(0.0, 1.0);
    print('   - Strength: ${(strength * 100).toStringAsFixed(0)}%');

    final isPlaying = _musicService.player.playing;
    print('   - Audio Playing: $isPlaying');

    try {
      await _eqService.setBassBoost(strength);
      print(' Bass boost applied successfully');
    } catch (e) {
      print(' ERROR setting bass boost: $e');
    }

    setState(() {
      bassBoostLevel = level;
    });

    print('═══════════════════════════════════════════════════\n');
  }

  Future<void> _setVirtualizer(int level) async {
    print('═══════════════════════════════════════════════════');
    print('SETTING VIRTUALIZER');
    print('   - Level: $level/20');

    // Convert from 0-20 to 0.0-1.0
    final strength = level / 20.0;
    print('   - Strength: ${(strength * 100).toStringAsFixed(0)}%');

    final isPlaying = _musicService.player.playing;
    print('   - Audio Playing: $isPlaying');

    try {
      await _eqService.setVirtualizer(strength);
      print(' Virtualizer applied successfully');
    } catch (e) {
      print(' ERROR setting virtualizer: $e');
    }

    setState(() {
      virtualizerLevel = level;
    });

    print('═══════════════════════════════════════════════════\n');
  }

  @override
  Widget build(BuildContext context) {
    int half = (presetList.length / 2).ceil();
    final row1 = presetList.take(half).toList();
    final row2 = presetList.skip(half).toList();

    return SafeArea(
      bottom: true,
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBarWithIconTitle(
              title: "Equalizer",
              backgroundColor: AppColors.primaryOrange,
              titleColor: AppColors.white,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              showBackButton: false,
              actions: [
                Row(
                  children: [
                    Switch(
                      value: _eqService.isEnabled,
                      onChanged: (value) async {
                        if (value) {
                          // TURN ON
                          await _eqService.setEnabled(true);

                          // Initialize ONLY if not already initialized
                          if (!_isInitialized) {
                            await _initializeEqualizer();
                            _isInitialized = true;
                          }
                        } else {
                          // TURN OFF (do NOT reset initialized!)
                          await _eqService.setEnabled(false);

                          // KEEP last mode + UI visible
                          // So do NOT set _isInitialized = false;
                        }

                        setState(() {});
                      },
                      // onChanged: (value) async {
                      //   await _eqService.setEnabled(value);
                      //   setState(() {
                      //     _isEqEnabled = value;
                      //   });
                      // },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white.withValues(alpha: 0.5),
                      inactiveThumbColor: Colors.white70,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                    ),
                    SizedBox(width: 8.w),
                  ],
                ),
                // Reset button

                /*IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: () async {
                    await _eqService.reset();
                    setState(() {
                      selectedPreset = presetList.indexOf('Flat');
                      if (selectedPreset < 0) selectedPreset = 0;
                    });
                  },
                ),*/
              ],
            ),
            body: !_isInitialized
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppColors.primaryOrange),
                        SizedBox(height: 16.h),
                        Texts('Loading Equalizer...', fontSize: 14.sp, color: AppColors.textColor),
                      ],
                    ),
                  )
                : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, color: AppColors.primaryOrange, size: 48.w),
                        SizedBox(height: 16.h),
                        Texts('Failed to load equalizer', fontSize: 14.sp, color: AppColors.textColor),
                        SizedBox(height: 8.h),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isInitialized = false;
                              _hasError = false;
                            });
                            _initializeEqualizer();
                          },
                          child: Texts('Retry', fontSize: 14.sp, color: AppColors.primaryOrange),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsets.symmetric(vertical: 15.w),
                        child: Container(
                          color: AppColors.white,
                          height: MediaQuery.of(context).size.height,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Preset chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Container(
                                  padding: EdgeInsets.only(left: 15.w),
                                  margin: EdgeInsets.only(right: 15.w),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 10.w,
                                            runSpacing: 5.h,
                                            children: List.generate(row1.length, (i) {
                                              final index = i;
                                              return ChoiceChip(
                                                showCheckmark: false,
                                                backgroundColor: AppColors.chipUnselected,
                                                side: BorderSide.none,
                                                label: Text(row1[i]),
                                                selected: selectedPreset == index,
                                                selectedColor: AppColors.primaryOrange,
                                                labelStyle: TextStyle(
                                                  color: selectedPreset == index ? Colors.white : Colors.black,
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: AppFonts.inter,
                                                ),
                                                shape: const StadiumBorder(),
                                                onSelected: (_) => _applyPreset(index),
                                              );
                                            }),
                                          ),
                                          SizedBox(height: 6.h),
                                          Wrap(
                                            spacing: 10.w,
                                            runSpacing: 5.h,
                                            children: List.generate(row2.length, (i) {
                                              final index = i + row1.length;
                                              return ChoiceChip(
                                                side: BorderSide.none,
                                                backgroundColor: AppColors.chipUnselected,
                                                showCheckmark: false,
                                                label: Text(row2[i]),
                                                selected: selectedPreset == index,
                                                selectedColor: AppColors.primaryOrange,
                                                labelStyle: TextStyle(
                                                  color: selectedPreset == index ? Colors.white : Colors.black,
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: AppFonts.inter,
                                                ),
                                                shape: const StadiumBorder(),
                                                onSelected: (_) => _applyPreset(index),
                                              );
                                            }),
                                          ),
                                          SizedBox(height: 20.h),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Frequency sliders
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: List.generate(frequencies.length, (i) {
                                        return Column(
                                          children: [
                                            Texts(
                                              "${frequencies[i] > 0 ? "+" : ""}${frequencies[i].toStringAsFixed(1)}",
                                              color: frequencies[i] > 0 ? AppColors.primaryOrange : AppColors.textColor,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w400,
                                              fontFamily: AppFonts.inter,
                                            ),
                                            SizedBox(
                                              height: 280.h,
                                              child: RotatedBox(
                                                quarterTurns: -1,
                                                child: SliderTheme(
                                                  data: SliderTheme.of(context).copyWith(
                                                    trackHeight: 4.h,
                                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                                                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
                                                  ),
                                                  child: Slider(
                                                    value: frequencies[i],
                                                    min: -1.5,
                                                    max: 1.5,
                                                    activeColor: AppColors.primaryOrange,
                                                    inactiveColor: AppColors.black.withValues(alpha: 0.2),
                                                    onChanged: (value) => _setBandLevel(i, value),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Texts(
                                              frequencyLabels[i],
                                              fontSize: 12.sp,
                                              color: AppColors.textColor,
                                              fontWeight: FontWeight.w400,
                                              fontFamily: AppFonts.inter,
                                            ),
                                          ],
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20.h),

                              // Effects section
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 14.w),
                                margin: EdgeInsets.symmetric(horizontal: 15.w),
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Reverb
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Texts("Reverb", fontSize: 16.sp, fontWeight: FontWeight.w600),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Texts(selectedReverb, fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textColor),
                                          SizedBox(width: 6.w),
                                          SvgPicture.asset(
                                            Assets.svgIcDownArrow,
                                            width: 20.w,
                                            height: 20.h,
                                            colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn),
                                          ),
                                        ],
                                      ),
                                      onTap: () => _showReverbBottomSheet(),
                                    ),

                                    SizedBox(height: 16.h),

                                    // Bass Boost
                                    Row(
                                      children: [
                                        Texts("Bass Boost", fontSize: 14.sp),
                                        SizedBox(width: 10.w),
                                        Expanded(
                                          child: LevelBarSlider(level: bassBoostLevel, displayMaxLevel: 20, onChanged: (value) => _setBassBoost(value)),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 20.h),

                                    // Virtualizer
                                    Row(
                                      children: [
                                        Texts("Virtualizer", fontSize: 14.sp),
                                        SizedBox(width: 15.w),
                                        Expanded(
                                          child: LevelBarSlider(level: virtualizerLevel, displayMaxLevel: 20, onChanged: (value) => _setVirtualizer(value)),
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 20.h),
                                  ],
                                ),
                              ),

                              // Platform info
                              if (!_eqService.isAndroid && !_eqService.isIOS) ...[
                                SizedBox(height: 20.h),
                                Container(
                                  margin: EdgeInsets.symmetric(horizontal: 15.w),
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryOrange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: AppColors.primaryOrange, size: 20.w),
                                      SizedBox(width: 10.w),
                                      Expanded(
                                        child: Texts('Equalizer is available on Android and iOS devices', fontSize: 12.sp, color: AppColors.textColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (!_eqService.isEnabled)
                        Positioned.fill(
                          child: ClipRRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                              child: Container(height: MediaQuery.of(context).size.height, color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  int localSelectedIndex = 0;

  void _showReverbBottomSheet() {
    final currentIndex = reverbOptions.indexOf(_eqService.reverbType);
    localSelectedIndex = currentIndex >= 0 ? currentIndex : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(Assets.svgIcLineBottom),
                  SizedBox(height: 20.h),
                  Texts('Select Reverb', fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
                  SizedBox(height: 16.h),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        ...List.generate(reverbOptions.length, (index) {
                          var item = reverbOptions[index];
                          return ListTile(
                            dense: true,
                            visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                            title: Texts(
                              item,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFonts.inter,
                              color: index == localSelectedIndex ? AppColors.primaryOrange : AppColors.textColor,
                            ),
                            trailing: SvgPicture.asset(index == localSelectedIndex ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck, height: 20.h, width: 20.w),
                            onTap: () async {
                              print('═══════════════════════════════════════════════════');
                              print('🎵 REVERB SELECTION');
                              print('   - Selected: $item');
                              print('   - Previous: ${reverbOptions[localSelectedIndex]}');

                              setModalState(() {
                                localSelectedIndex = index;
                              });

                              // Apply reverb to the equalizer service
                              try {
                                await _eqService.setReverb(item);

                                setState(() {
                                  selectedReverb = item;
                                });

                                print('✅ Reverb applied successfully');
                              } catch (e) {
                                print('❌ Error applying reverb: $e');
                              }
                              print('═══════════════════════════════════════════════════\n');

                              Navigator.pop(context);
                              // Note: Reverb is UI-only for now
                              // You can implement actual reverb if needed
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    // Don't dispose the services as they're singletons
    super.dispose();
  }
}

/*
class EqualizerScreen extends StatefulWidget {
  const EqualizerScreen({super.key});

  @override
  State<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  final presetList = [
    "Custom",
    "Normal",
    "Rock",
    "Dance",
    "Pop",
    "Hip Hop",
    "Acoustic",
    "Heavy Metal",
    "Folk",
    "Head Phones",
    "Loud",
    "Piano",
    "Bass Boost",
    "Electronic",
    "Flat",
    "Classical",
    "Straightness",
    "Jazz",
    "Treble Boost",
    "Vocal Boost",
    "Latin",
    "Deep",
    "Lounge",
    "R&B",
  ];

  int selectedPreset = 0;

  List<double> frequencies = [0.8, 0.0, 0.8, 0.8, 0.8];
  final frequencyLabels = ["60Hz", "230Hz", "910Hz", "4kHz", "14kHz"];

  String selectedReverb = "None";
  final reverbOptions = ["None", "Small Room", "Medium Room", "Large Room", "Medium Hall", "Large Hall", "Plate"];

  int bassBoostLevel = 0;
  int virtualizerLevel = 5;

  @override
  Widget build(BuildContext context) {
    int half = (presetList.length / 2).ceil();
    final row1 = presetList.take(half).toList();
    final row2 = presetList.skip(half).toList();

    return SafeArea(
      bottom: true,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primaryOrange,
          elevation: 0,
          title: Texts("Equalizer", fontSize: 16.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter, color: AppColors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              context.pop();
            },
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(vertical: 15.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: EdgeInsets.only(left: 15.w),
                  margin: EdgeInsets.only(right: 15.w),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10.w,
                            runSpacing: 5.h,
                            children: List.generate(row1.length, (i) {
                              final index = i;
                              return ChoiceChip(
                                showCheckmark: false,
                                backgroundColor: AppColors.chipUnselected,
                                side: BorderSide.none,
                                label: Text(row1[i]),
                                selected: selectedPreset == index,
                                selectedColor: AppColors.primaryOrange,
                                labelStyle: TextStyle(
                                  color: selectedPreset == index ? Colors.white : Colors.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFonts.inter,
                                ),
                                shape: StadiumBorder(),
                                onSelected: (_) {
                                  setState(() => selectedPreset = index);
                                },
                              );
                            }),
                          ),
                          SizedBox(height: 6.h),
                          Wrap(
                            spacing: 10.w,
                            runSpacing: 5.h,
                            children: List.generate(row2.length, (i) {
                              final index = i + row1.length;
                              return ChoiceChip(
                                side: BorderSide.none,
                                backgroundColor: AppColors.chipUnselected,
                                showCheckmark: false,
                                label: Text(row2[i]),
                                selected: selectedPreset == index,
                                selectedColor: AppColors.primaryOrange,
                                labelStyle: TextStyle(
                                  color: selectedPreset == index ? Colors.white : Colors.black,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: AppFonts.inter,
                                ),
                                shape: StadiumBorder(),
                                onSelected: (_) {
                                  setState(() => selectedPreset = index);
                                },
                              );
                            }),
                          ),
                          SizedBox(height: 20.h),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(frequencies.length, (i) {
                        return Column(
                          children: [
                            Texts(
                              "${frequencies[i] > 0 ? "+" : ""}${frequencies[i].toStringAsFixed(1)}",
                              color: AppColors.primaryOrange,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppFonts.inter,
                            ),
                            SizedBox(
                              height: 280.h,
                              child: RotatedBox(
                                quarterTurns: -1,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 4.h, // thicker track
                                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.r),
                                    overlayShape: RoundSliderOverlayShape(overlayRadius: 14.r),
                                  ),
                                  child: Slider(
                                    value: frequencies[i],
                                    min: -1.5,
                                    max: 1.5,
                                    activeColor: AppColors.primaryOrange,
                                    inactiveColor: AppColors.black.withValues(alpha: 0.2),
                                    onChanged: (value) {
                                      setState(() => frequencies[i] = value);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Texts(frequencyLabels[i], fontSize: 12.sp, color: AppColors.textColor, fontWeight: FontWeight.w400, fontFamily: AppFonts.inter),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                margin: EdgeInsets.symmetric(horizontal: 15.w),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reverb
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Texts("Reverb", fontSize: 16.sp, fontWeight: FontWeight.w600),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Texts(selectedReverb, fontSize: 14.sp, fontWeight: FontWeight.w500, color: AppColors.textColor),
                          SizedBox(width: 6.w),
                          SvgPicture.asset(Assets.svgIcDownArrow, width: 20.w, height: 20.h, colorFilter: const ColorFilter.mode(AppColors.black, BlendMode.srcIn)),
                        ],
                      ),
                      onTap: () => _showReverbBottomSheet(),
                    ),

                    SizedBox(height: 16.h),

                    // Bass Boost
                    Row(
                      children: [
                        Texts("Bass Boost", fontSize: 14.sp),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: LevelBarSlider(level: bassBoostLevel, displayMaxLevel: 21, onChanged: (value) => setState(() => bassBoostLevel = value)),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),

                    // Virtualizer
                    Row(
                      children: [
                        Texts("Virtualizer", fontSize: 14.sp),
                        SizedBox(width: 15.w),
                        Expanded(
                          child: LevelBarSlider(level: virtualizerLevel, displayMaxLevel: 21, onChanged: (value) => setState(() => virtualizerLevel = value)),
                        ),
                      ],
                    ),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),

              // Reverb section
            ],
          ),
        ),
      ),
    );
  }

  int localSelectedIndex = 0;

  void _showReverbBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(Assets.svgIcLineBottom),
              SizedBox(height: 20.h),
              Texts('Select Reverb', fontSize: 18.sp, fontWeight: FontWeight.w500, fontFamily: AppFonts.inter),
              SizedBox(height: 16.h),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...List.generate(reverbOptions.length, (index) {
                      var item = reverbOptions[index];
                      return ListTile(
                        dense: true,
                        visualDensity: VisualDensity(horizontal: 0.w, vertical: -2.h),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                        title: Texts(
                          item,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          fontFamily: AppFonts.inter,
                          color: index == localSelectedIndex ? AppColors.primaryOrange : AppColors.textColor,
                        ),
                        trailing: SvgPicture.asset(index == localSelectedIndex ? Assets.svgIcRadioCheckl : Assets.svgIcRadioUncheck, height: 20.h, width: 20.w),
                        onTap: () {
                          setState(() {
                            localSelectedIndex = index;
                            selectedReverb = reverbOptions[index];
                          });
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
*/
