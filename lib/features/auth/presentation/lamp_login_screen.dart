import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/security/security_service.dart';
import '../../../core/services/audio_haptic_service.dart';
import '../../../core/services/platform_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/pbr_theme.dart';
import '../../../l10n/app_localizations.dart';
import 'desk_lamp_painter.dart';

class LampLoginScreen extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const LampLoginScreen({
    Key? key,
    required this.onAuthenticated,
  }) : super(key: key);

  @override
  State<LampLoginScreen> createState() => _LampLoginScreenState();
}

class _LampLoginScreenState extends State<LampLoginScreen>
    with SingleTickerProviderStateMixin {
  final SecurityService _security = SecurityService();
  final AudioHapticService _audio = AudioHapticService();
  final LocalStore _store = LocalStore();
  final FocusNode _keyboardFocusNode = FocusNode();

  bool _isLampOn = false;
  bool _isHoveringSwitch = false;
  bool _isPinCreated = false;
  bool _canUseBiometrics = false;
  bool _isSettingUpPin = false;

  late AnimationController _lampAnimController;
  late Animation<double> _glowAnimation;
  double _flickerFactor = 0.0;
  Timer? _flickerTimer;

  String _enteredPin = '';
  String _confirmPin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthState();

    _lampAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _glowAnimation = CurvedAnimation(
      parent: _lampAnimController,
      curve: Curves.easeInOutCubic,
    );

    _lampAnimController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _checkAuthState() async {
    final hasPin = await _security.isPinCreated();
    final bioAvailable = await _security.canUseBiometrics();
    setState(() {
      _isPinCreated = hasPin;
      _isSettingUpPin = !hasPin;
      _canUseBiometrics = bioAvailable;
    });

    // Block screenshots on login screen (mobile only)
    await PlatformService().enableSecureScreen();
  }

  @override
  void dispose() {
    _flickerTimer?.cancel();
    _lampAnimController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  // Toggle Lamp with realistic physical ignition flicker
  void _toggleLamp() {
    setState(() {
      _isLampOn = !_isLampOn;
      _errorMessage = null;
      if (!_isLampOn) {
        _enteredPin = '';
        _confirmPin = '';
      }
    });

    _audio.playSwitchClick(isOn: _isLampOn);

    if (_isLampOn) {
      // Simulate real incandescent filament ignition micro-flicker
      _flickerTimer?.cancel();
      int flickerStep = 0;
      _flickerTimer = Timer.periodic(const Duration(milliseconds: 40), (timer) {
        flickerStep++;
        if (flickerStep < 7) {
          setState(() {
            _flickerFactor = math.Random().nextDouble() * 0.75;
          });
        } else {
          setState(() {
            _flickerFactor = 0.0;
          });
          timer.cancel();
        }
      });
      _lampAnimController.forward();
    } else {
      _flickerTimer?.cancel();
      _flickerFactor = 0.0;
      _lampAnimController.reverse();
    }
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;
    _audio.playKeyTap();

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _handlePinSubmit();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      _audio.playKeyTap();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _handlePinSubmit() async {
    if (_isSettingUpPin) {
      if (_confirmPin.isEmpty) {
        // First PIN entered, now ask to confirm
        setState(() {
          _confirmPin = _enteredPin;
          _enteredPin = '';
        });
        return;
      } else {
        // Confirming PIN
        if (_enteredPin == _confirmPin) {
          final success = await _security.createPin(_enteredPin);
          if (success) {
            _audio.playSuccessFeedback();
            widget.onAuthenticated();
          }
        } else {
          _audio.playErrorFeedback();
          setState(() {
            _errorMessage = 'PIN mismatch. Please start again.';
            _enteredPin = '';
            _confirmPin = '';
          });
        }
      }
    } else {
      // Existing PIN verification
      final isValid = await _security.verifyPin(_enteredPin);
      if (isValid) {
        _audio.playSuccessFeedback();
        widget.onAuthenticated();
      } else {
        _audio.playErrorFeedback();
        setState(() {
          _errorMessage = 'Incorrect PIN. Try again.';
          _enteredPin = '';
        });
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    final authenticated = await _security.authenticateWithBiometrics();
    if (authenticated) {
      _audio.playSuccessFeedback();
      widget.onAuthenticated();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Focus(
      focusNode: _keyboardFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
          _toggleLamp();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 1. Custom 3D Lamp Lighting Canvas (PBR Shader Simulator)
            Positioned.fill(
              child: CustomPaint(
                painter: DeskLampPainter(
                  lampState: _glowAnimation.value,
                  flicker: _flickerFactor,
                  style: _store.lampStyle,
                  isHoveringSwitch: _isHoveringSwitch,
                  lowPower: _store.lowPowerMode,
                ),
              ),
            ),

            // 2. Interactive Switch Target (Hit box matching desk lamp switch position)
            Positioned(
              left: size.width < 600 ? size.width * 0.5 - 35 : size.width * 0.32 - 15,
              top: size.height * 0.38 - 15,
              width: 80,
              height: 70,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _isHoveringSwitch = true),
                onExit: (_) => setState(() => _isHoveringSwitch = false),
                child: GestureDetector(
                  onTap: _toggleLamp,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.transparent,
                  ),
                ),
              ),
            ),

            // 3. Hint when Lamp is OFF (Subtle breathing prompt)
            if (!_isLampOn)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app, size: 16, color: PbrTheme.brassGold),
                        const SizedBox(width: 8),
                        Text(
                          l10n.translate('lampHint'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 4. Photorealistic Glassmorphic Login Card (Illuminated ONLY when Lamp is ON)
            Positioned(
              left: size.width < 600 ? 24 : size.width * 0.48,
              right: size.width < 600 ? 24 : size.width * 0.12,
              bottom: size.height * 0.08,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                opacity: _isLampOn ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !_isLampOn,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    decoration: PbrTheme.glassDecoration(
                      isDark: true,
                      opacity: 0.88,
                      isLit: true,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Card Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              color: PbrTheme.brassGold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSettingUpPin
                                  ? (_confirmPin.isEmpty
                                      ? l10n.translate('createPin')
                                      : l10n.translate('confirmPin'))
                                  : l10n.translate('enterPin'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: PbrTheme.tungstenHot,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // 4-Digit PIN Indicators (Glowing LEDs)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final isFilled = index < _enteredPin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled
                                    ? PbrTheme.tungstenHot
                                    : Colors.white.withOpacity(0.12),
                                border: Border.all(
                                  color: isFilled
                                      ? PbrTheme.brassGold
                                      : Colors.white24,
                                  width: 1.5,
                                ),
                                boxShadow: isFilled
                                    ? [
                                        BoxShadow(
                                          color: PbrTheme.tungstenWarm.withOpacity(0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : [],
                              ),
                            );
                          }),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: PbrTheme.scamRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // 3x4 Metallic Keypad
                        _buildMetallicKeypad(),

                        const SizedBox(height: 14),

                        // Biometrics / Switch Off Options
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: _toggleLamp,
                              icon: const Icon(Icons.lightbulb_outline, size: 16),
                              label: const Text('Lamp Off', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white60,
                              ),
                            ),
                            if (_canUseBiometrics && !_isSettingUpPin)
                              IconButton(
                                onPressed: _handleBiometricAuth,
                                icon: const Icon(
                                  Icons.fingerprint,
                                  color: PbrTheme.brassGold,
                                  size: 28,
                                ),
                                tooltip: l10n.translate('unlockBiometrics'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetallicKeypad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'DEL'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 68, height: 48);
              }
              final isDel = key == 'DEL';
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 64,
                height: 46,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (isDel) {
                        _onBackspacePressed();
                      } else {
                        _onDigitPressed(key);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    splashColor: PbrTheme.tungstenWarm.withOpacity(0.3),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.12),
                            Colors.white.withOpacity(0.04),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isDel
                          ? const Icon(Icons.backspace_outlined, size: 18, color: Colors.white70)
                          : Text(
                              key,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
