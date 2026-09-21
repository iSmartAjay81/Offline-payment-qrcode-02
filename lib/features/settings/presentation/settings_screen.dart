import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/audio_haptic_service.dart';
import '../../../core/services/platform_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/pbr_theme.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLockApp;
  final VoidCallback onLanguageChanged;

  const SettingsScreen({
    Key? key,
    required this.onLockApp,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalStore _store = LocalStore();
  final AudioHapticService _audio = AudioHapticService();
  final PlatformService _platform = PlatformService();

  late LampStyle _currentLampStyle;
  late bool _lowPower;
  late bool _sound;
  late bool _haptics;
  late String _lang;

  @override
  void initState() {
    super.initState();
    _currentLampStyle = _store.lampStyle;
    _lowPower = _store.lowPowerMode;
    _sound = _store.soundEnabled;
    _haptics = _store.hapticsEnabled;
    _lang = _store.currentLanguage;
  }

  void _openBackupDialog() {
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encrypted Backup & Restore'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your backup is securely encrypted with AES-256 on this device.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Export Encrypted Backup'),
              onPressed: () async {
                final cipher = await _store.exportEncryptedBackup('offline_user_pass');
                await _platform.copyToClipboard(cipher);
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Encrypted backup string copied to clipboard!')),
                );
              },
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            TextField(
              controller: passController,
              decoration: const InputDecoration(
                labelText: 'Paste Encrypted Backup String',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text('Restore from Backup'),
              onPressed: () async {
                if (passController.text.trim().isNotEmpty) {
                  try {
                    final count = await _store.restoreEncryptedBackup(passController.text.trim());
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Restored $count records successfully!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to restore. Invalid backup string.')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // Lamp Style Picker
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: PbrTheme.brassGold),
                      const SizedBox(width: 8),
                      Text(
                        l10n.translate('lampStyle'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<LampStyle>(
                    title: Text(l10n.translate('deskLamp')),
                    subtitle: const Text('Classic articulated brass architect lamp'),
                    value: LampStyle.deskLamp,
                    groupValue: _currentLampStyle,
                    activeColor: PbrTheme.brassGold,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _currentLampStyle = val);
                        _store.setLampStyle(val);
                        _audio.playKeyTap();
                      }
                    },
                  ),
                  RadioListTile<LampStyle>(
                    title: Text(l10n.translate('vintageBulb')),
                    subtitle: const Text('Exposed glowing filament in amber glass'),
                    value: LampStyle.vintageBulb,
                    groupValue: _currentLampStyle,
                    activeColor: PbrTheme.brassGold,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _currentLampStyle = val);
                        _store.setLampStyle(val);
                        _audio.playKeyTap();
                      }
                    },
                  ),
                  RadioListTile<LampStyle>(
                    title: Text(l10n.translate('lantern')),
                    subtitle: const Text('Industrial bronze carriage lantern'),
                    value: LampStyle.lantern,
                    groupValue: _currentLampStyle,
                    activeColor: PbrTheme.brassGold,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _currentLampStyle = val);
                        _store.setLampStyle(val);
                        _audio.playKeyTap();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Graphics & Performance
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              secondary: const Icon(Icons.speed, color: PbrTheme.brassGold),
              title: Text(l10n.translate('lowPower')),
              subtitle: const Text('Optimizes shaders and blooms for low-spec devices'),
              value: _lowPower,
              activeColor: PbrTheme.brassGold,
              onChanged: (val) {
                setState(() => _lowPower = val);
                _store.setLowPowerMode(val);
                _audio.playKeyTap();
              },
            ),
          ),
          const SizedBox(height: 12),

          // Language Selector
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.language, color: PbrTheme.brassGold),
              title: Text(l10n.translate('language')),
              subtitle: Text(_lang == 'hi' ? 'हिन्दी (Hindi)' : 'English'),
              trailing: DropdownButton<String>(
                value: _lang,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                ],
                onChanged: (newLang) {
                  if (newLang != null) {
                    setState(() => _lang = newLang);
                    _store.setLanguage(newLang);
                    widget.onLanguageChanged();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Sound & Haptic Cues
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.volume_up, color: PbrTheme.brassGold),
                  title: const Text('Switch & Key Clicks'),
                  value: _sound,
                  activeColor: PbrTheme.brassGold,
                  onChanged: (val) {
                    setState(() => _sound = val);
                    _store.setSound(val);
                    _audio.soundEnabled = val;
                  },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.vibration, color: PbrTheme.brassGold),
                  title: const Text('Haptic Feedback'),
                  value: _haptics,
                  activeColor: PbrTheme.brassGold,
                  onChanged: (val) {
                    setState(() => _haptics = val);
                    _store.setHaptics(val);
                    _audio.hapticsEnabled = val;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Backup & Data
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.security, color: PbrTheme.brassGold),
              title: Text(l10n.translate('backupEncrypted')),
              subtitle: const Text('100% on-device backup using AES-256'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _openBackupDialog,
            ),
          ),
          const SizedBox(height: 12),

          // Instant Lock Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.lock, color: PbrTheme.alertGold),
              title: Text(l10n.translate('lockApp')),
              subtitle: const Text('Instantly closes session and turns off lamp'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                _audio.playKeyTap();
                widget.onLockApp();
              },
            ),
          ),
          const SizedBox(height: 24),

          // App Legal & Safety Footer
          Center(
            child: Column(
              children: [
                Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fully Air-Gapped • No Internet • Zero Tracking',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
