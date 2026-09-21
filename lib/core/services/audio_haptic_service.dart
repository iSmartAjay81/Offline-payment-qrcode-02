import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioHapticService {
  static final AudioHapticService _instance = AudioHapticService._internal();
  factory AudioHapticService() => _instance;
  AudioHapticService._internal();

  bool soundEnabled = true;
  bool hapticsEnabled = true;

  // Mechanical switch click simulation
  Future<void> playSwitchClick({bool isOn = true}) async {
    if (hapticsEnabled) {
      if (isOn) {
        await HapticFeedback.mediumImpact();
      } else {
        await HapticFeedback.lightImpact();
      }
    }

    if (soundEnabled) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (e) {
        debugPrint('Sound error: $e');
      }
    }
  }

  // Keypad / PIN tap feedback
  Future<void> playKeyTap() async {
    if (hapticsEnabled) {
      await HapticFeedback.selectionClick();
    }
    if (soundEnabled) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (e) {
        debugPrint('Sound error: $e');
      }
    }
  }

  // Success chime / haptic
  Future<void> playSuccessFeedback() async {
    if (hapticsEnabled) {
      await HapticFeedback.heavyImpact();
    }
  }

  // Error alert
  Future<void> playErrorFeedback() async {
    if (hapticsEnabled) {
      await HapticFeedback.vibrate();
    }
  }
}
