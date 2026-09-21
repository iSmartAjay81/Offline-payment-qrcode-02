import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_constants.dart';
import 'core/storage/local_store.dart';
import 'core/theme/pbr_theme.dart';
import 'features/auth/presentation/lamp_login_screen.dart';
import 'features/desktop/desktop_layout_wrapper.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize encrypted local store & preferences
  await LocalStore().init();

  runApp(const OfflinePaymentQrApp());
}

class OfflinePaymentQrApp extends StatefulWidget {
  const OfflinePaymentQrApp({Key? key}) : super(key: key);

  @override
  State<OfflinePaymentQrApp> createState() => _OfflinePaymentQrAppState();
}

class _OfflinePaymentQrAppState extends State<OfflinePaymentQrApp>
    with WidgetsBindingObserver {
  final LocalStore _store = LocalStore();
  bool _isAuthenticated = false;
  Timer? _inactivityTimer;
  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locale = Locale(_store.currentLanguage);
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // Detect App Backgrounding (Mobile privacy defense)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _lockApp();
    }
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_isAuthenticated) {
      _inactivityTimer = Timer(AppConstants.autoLockDuration, () {
        _lockApp();
      });
    }
  }

  void _lockApp() {
    if (mounted && _isAuthenticated) {
      setState(() {
        _isAuthenticated = false;
      });
    }
  }

  void _onUserInteraction([_]) {
    if (_isAuthenticated) {
      _resetInactivityTimer();
    }
  }

  void _updateLanguage() {
    setState(() {
      _locale = Locale(_store.currentLanguage);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: PbrTheme.lightTheme(),
        darkTheme: PbrTheme.darkTheme(),
        themeMode: ThemeMode.dark, // Default to dark room PBR atmosphere
        locale: _locale,
        supportedLocales: const [
          Locale('en', ''),
          Locale('hi', ''),
        ],
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: _isAuthenticated
            ? DesktopLayoutWrapper(
                onLockApp: _lockApp,
                onLanguageChanged: _updateLanguage,
              )
            : LampLoginScreen(
                onAuthenticated: () {
                  setState(() {
                    _isAuthenticated = true;
                  });
                  _resetInactivityTimer();
                },
              ),
      ),
    );
  }
}
