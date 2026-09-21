import 'package:flutter/services.dart';

class PlatformService {
  static final PlatformService _instance = PlatformService._internal();
  factory PlatformService() => _instance;
  PlatformService._internal();

  bool get isDesktop => false;
  bool get isMobile => false;

  Future<void> boostBrightness() async {}

  Future<void> restoreBrightness() async {}

  Future<void> enableSecureScreen() async {}

  Future<void> disableSecureScreen() async {}

  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }
}