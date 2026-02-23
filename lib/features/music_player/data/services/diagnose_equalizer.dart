import 'dart:developer';
import 'package:just_audio/just_audio.dart';

/// Helper class to diagnose equalizer issues
class EqualizerDiagnostic {
  /// Check if equalizer is properly initialized
  static Future<void> checkEqualizerSetup(
      AudioPlayer player,
      AndroidEqualizer? equalizer,
      ) async {
    log('═══════════════════════════════════════════════════');
    log('🔍 EQUALIZER DIAGNOSTIC CHECK');
    log('═══════════════════════════════════════════════════');

    // Check 1: Player state
    log('1️⃣ Checking Audio Player State:');
    log('   ├─ Is playing: ${player.playing}');
    log('   ├─ Duration: ${player.duration}');
    log('   ├─ Position: ${player.position}');
    log('   ├─ Current index: ${player.currentIndex}');
    log('   ├─ Sequence length: ${player.sequence?.length ?? 0}');
    log('   └─ Processing state: ${player.processingState}');

    // Check 2: Audio session
    log('\n2️⃣ Checking Audio Session:');
    if (player.androidAudioSessionId != null) {
      log('   ├─ ✅ Audio session ID: ${player.androidAudioSessionId}');
      log('   └─ Audio session is ACTIVE and VALID');
    } else {
      log('   └─ ❌ Audio session ID is NULL');
      log('      This means audio is not initialized properly!');
    }

    // Check 3: Equalizer object
    log('\n3️⃣ Checking Equalizer Object:');
    if (equalizer == null) {
      log('   └─ ❌ Equalizer object is NULL');
      log('      Did you create AudioPlayer with equalizer?');
      log('      Use: equalizerService.createAndroidPlayerWithEqualizer()');
      return;
    } else {
      log('   └─ ✅ Equalizer object exists');
    }

    // Check 4: Equalizer parameters
    log('\n4️⃣ Checking Equalizer Parameters:');
    try {
      final params = await equalizer.parameters;

      log('   ├─ Number of bands: ${params.bands.length}');

      if (params.bands.isEmpty) {
        log('   └─ ❌ CRITICAL: Equalizer has 0 bands!');
        log('      Possible causes:');
        log('      - Equalizer initialized before audio loaded');
        log('      - Audio session not ready');
        log('      - Device doesn\'t support equalizer');
        return;
      }

      log('   ├─ Min gain: ${params.minDecibels} dB');
      log('   ├─ Max gain: ${params.maxDecibels} dB');
      log('   └─ ✅ Equalizer parameters valid');

      // Check 5: Band details
      log('\n5️⃣ Band Details:');
      for (int i = 0; i < params.bands.length; i++) {
        final band = params.bands[i];
        log('   Band $i:');
        log('   ├─ Center frequency: ${band.centerFrequency.toStringAsFixed(0)} Hz');
        log('   ├─ Current gain: ${band.gain.toStringAsFixed(1)} dB');
      }

      log('\n✅ DIAGNOSTIC COMPLETE - Equalizer is properly initialized!');

    } catch (e, stackTrace) {
      log('\n❌ ERROR getting equalizer parameters: $e');
      log('Stack trace: $stackTrace');
    }

    log('═══════════════════════════════════════════════════');
  }

  /// Test equalizer by setting a band
  static Future<void> testEqualizerBand(
      AndroidEqualizer equalizer,
      int bandIndex,
      double gain,
      ) async {
    log('🧪 Testing equalizer band $bandIndex with gain $gain dB...');

    try {
      final params = await equalizer.parameters;

      if (bandIndex >= params.bands.length) {
        log('❌ Band index $bandIndex is out of range (max: ${params.bands.length - 1})');
        return;
      }

      final band = params.bands[bandIndex];
      log('Before: ${band.gain} dB');

      await band.setGain(gain);

      log('After: ${band.gain} dB');
      log('✅ Band test successful!');

    } catch (e) {
      log('❌ Band test failed: $e');
    }
  }

  /// Get current equalizer state as string
  static Future<String> getEqualizerState(AndroidEqualizer? equalizer) async {
    if (equalizer == null) {
      return '❌ Equalizer is null';
    }

    try {
      final params = await equalizer.parameters;
      final buffer = StringBuffer();

      buffer.writeln('Equalizer State:');
      buffer.writeln('  Bands: ${params.bands.length}');
      buffer.writeln('  Range: ${params.minDecibels} to ${params.maxDecibels} dB');

      for (int i = 0; i < params.bands.length; i++) {
        final band = params.bands[i];
        buffer.writeln('  Band $i (${band.centerFrequency.toStringAsFixed(0)}Hz): ${band.gain.toStringAsFixed(1)} dB');
      }

      return buffer.toString();
    } catch (e) {
      return '❌ Error: $e';
    }
  }
}