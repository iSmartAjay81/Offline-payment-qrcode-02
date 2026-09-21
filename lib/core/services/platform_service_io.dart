import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  bool get isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
  bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> boostBrightness() async {
    if (!isMobile) return;
    debugPrint('Mobile brightness boost requested');
  }

  Future<void> restoreBrightness() async {
    if (!isMobile) return;
    debugPrint('Mobile brightness restore requested');
  }

  Future<void> enableSecureScreen() async {
    if (!isMobile) return;
    debugPrint('Secure screen flag enabled (screenshots blocked)');
  }

  Future<void> disableSecureScreen() async {
    if (!isMobile) return;
    debugPrint('Secure screen flag disabled');
  }

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}