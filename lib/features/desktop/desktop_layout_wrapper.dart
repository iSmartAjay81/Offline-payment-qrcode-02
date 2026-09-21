import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/audio_haptic_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/platform_service.dart';
import '../../core/storage/local_store.dart';
import '../../core/theme/pbr_theme.dart';
import '../../l10n/app_localizations.dart';
import '../history/presentation/history_screen.dart';
import '../qr_create/domain/qr_payload.dart';
import '../qr_create/presentation/qr_create_screen.dart';
import '../qr_display/presentation/qr_display_screen.dart';
import '../settings/presentation/settings_screen.dart';

class DesktopLayoutWrapper extends StatefulWidget {
  final VoidCallback onLockApp;
  final VoidCallback onLanguageChanged;

  const DesktopLayoutWrapper({
    Key? key,
    required this.onLockApp,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<DesktopLayoutWrapper> createState() => _DesktopLayoutWrapperState();
}

class _DesktopLayoutWrapperState extends State<DesktopLayoutWrapper> {
  final FocusNode _desktopFocusNode = FocusNode();
  final LocalStore _store = LocalStore();
  final PlatformService _platform = PlatformService();
  final AudioHapticService _audio = AudioHapticService();
  final ExportService _export = ExportService();

  int _selectedTabIndex = 0;

  // Active QR state for desktop live preview
  QrRecord? _activeRecord;
  QrCustomization _activeStyle = const QrCustomization();
  QrExpiry _activeExpiry = QrExpiry.none;

  @override
  void initState() {
    super.initState();
    _initDesktopWindow();

    // Default sample QR for desktop live preview
    _activeRecord = _store.history.isNotEmpty
        ? _store.history.first
        : QrRecord(
            id: 'sample',
            payeeName: 'Merchant Store',
            upiId: 'merchant@oksbi',
            amount: 250.0,
            note: 'Payment for goods',
            type: 'UPI',
            createdAt: DateTime.now(),
          );
  }

  Future<void> _initDesktopWindow() async {
    if (_platform.isDesktop) {
      try {
        await windowManager.ensureInitialized();
        const windowOptions = WindowOptions(
          size: Size(1020, 720),
          minimumSize: Size(900, 600),
          center: true,
          title: AppConstants.appName,
        );
        await windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
        });
      } catch (e) {
        debugPrint('WindowManager error: $e');
      }
    }
  }

  @override
  void dispose() {
    _desktopFocusNode.dispose();
    super.dispose();
  }

  // Handle Desktop Global Shortcuts (Ctrl+N, Ctrl+S, Ctrl+P, Ctrl+L)
  KeyEventResult _handleKeyEvents(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final isCtrlOrCmd = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    if (isCtrlOrCmd) {
      if (event.logicalKey == LogicalKeyboardKey.keyL) {
        _audio.playKeyTap();
        widget.onLockApp();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyN) {
        _audio.playKeyTap();
        setState(() => _selectedTabIndex = 0);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyS && _activeRecord != null) {
        _audio.playKeyTap();
        _store.toggleFavorite(_activeRecord!.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toggled favorite for active QR')),
        );
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.keyP && _activeRecord != null) {
        _audio.playKeyTap();
        _export.printSingleQrReceipt(
          payeeName: _activeRecord!.payeeName,
          upiId: _activeRecord!.upiId,
          amount: _activeRecord!.amount,
          note: _activeRecord!.note,
          qrImageBytes: Uint8List(0),
        );
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _onQrGenerated(QrRecord record, QrCustomization style, QrExpiry expiry) {
    setState(() {
      _activeRecord = record;
      _activeStyle = style;
      _activeExpiry = expiry;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    // On mobile / narrow screens, push the dedicated full screen
    if (screenWidth < 900) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QrDisplayScreen(
            record: record,
            style: style,
            expiry: expiry,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktopWide = size.width >= 900;

    return Focus(
      focusNode: _desktopFocusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvents,
      child: Scaffold(
        body: Row(
          children: [
            // Left Navigation Rail (Desktop & Tablet)
            if (isDesktopWide)
              NavigationRail(
                selectedIndex: _selectedTabIndex,
                backgroundColor: const Color(0xFF13171F),
                selectedIconTheme: const IconThemeData(color: PbrTheme.brassGold),
                unselectedIconTheme: const IconThemeData(color: Colors.white54),
                selectedLabelTextStyle: const TextStyle(color: PbrTheme.brassGold, fontSize: 12),
                unselectedLabelTextStyle: const TextStyle(color: Colors.white54, fontSize: 12),
                onDestinationSelected: (index) {
                  _audio.playKeyTap();
                  setState(() => _selectedTabIndex = index);
                },
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: CircleAvatar(
                    backgroundColor: PbrTheme.brassGold,
                    radius: 20,
                    child: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 22),
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: IconButton(
                        icon: const Icon(Icons.lock_outline, color: PbrTheme.alertGold),
                        tooltip: '${l10n.translate('lockApp')} (Ctrl+L)',
                        onPressed: widget.onLockApp,
                      ),
                    ),
                  ),
                ),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  NavigationRailDestination(
                    icon: const Icon(Icons.add_box_outlined),
                    selectedIcon: const Icon(Icons.add_box),
                    label: Text(l10n.translate('createQr')),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.history_outlined),
                    selectedIcon: const Icon(Icons.history),
                    label: Text(l10n.translate('history')),
                  ),
                  NavigationRailDestination(
                    icon: const Icon(Icons.settings_outlined),
                    selectedIcon: const Icon(Icons.settings),
                    label: Text(l10n.translate('settings')),
                  ),
                ],
              ),

            // Center / Main Content Form
            Expanded(
              flex: isDesktopWide ? 5 : 10,
              child: _buildCurrentTab(),
            ),

            // Right Desktop Live Preview Pane (Wide Desktop Only)
            if (isDesktopWide)
              Expanded(
                flex: 5,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F1218),
                    border: Border(left: BorderSide(color: Colors.white12, width: 1)),
                  ),
                  child: _activeRecord != null
                      ? QrDisplayScreen(
                          record: _activeRecord!,
                          style: _activeStyle,
                          expiry: _activeExpiry,
                        )
                      : const Center(
                          child: Text(
                            'Enter details to preview QR in real-time',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                ),
              ),
          ],
        ),
        // Bottom Navigation Bar for Mobile / Compact Displays
        bottomNavigationBar: !isDesktopWide
            ? NavigationBar(
                selectedIndex: _selectedTabIndex,
                onDestinationSelected: (index) {
                  _audio.playKeyTap();
                  setState(() => _selectedTabIndex = index);
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(Icons.qr_code),
                    label: l10n.translate('createQr'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.history),
                    label: l10n.translate('history'),
                  ),
                  NavigationDestination(
                    icon: const Icon(Icons.settings),
                    label: l10n.translate('settings'),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTabIndex) {
      case 0:
        return QrCreateScreen(onGenerate: _onQrGenerated);
      case 1:
        return HistoryScreen(
          onSelectRecord: (rec) {
            setState(() {
              _activeRecord = rec;
              _selectedTabIndex = 0;
            });
          },
        );
      case 2:
        return SettingsScreen(
          onLockApp: widget.onLockApp,
          onLanguageChanged: widget.onLanguageChanged,
        );
      default:
        return const SizedBox();
    }
  }
}
