import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'en': {
      'appName': 'Offline Payment QR',
      'lampHint': 'Turn on the lamp to unlock or setup PIN',
      'lampStyle': 'Lamp Style',
      'deskLamp': 'Architect Desk Lamp',
      'vintageBulb': 'Vintage Edison Bulb',
      'lantern': 'Industrial Lantern',
      'enterPin': 'Enter 4-Digit Security PIN',
      'createPin': 'Create Master PIN',
      'confirmPin': 'Confirm Master PIN',
      'pinMismatch': 'PINs do not match. Please try again.',
      'pinSetSuccess': 'Master PIN secured successfully.',
      'unlockBiometrics': 'Unlock with Biometrics',
      'wrongPin': 'Incorrect PIN. Try again.',
      'createQr': 'Create QR',
      'upiMode': 'UPI ID',
      'bankMode': 'Bank Transfer (NPCI)',
      'payeeName': 'Payee / Business Name',
      'upiId': 'UPI ID (e.g. rahul@oksbi)',
      'accountNumber': 'Account Number',
      'ifscCode': 'IFSC Code (e.g. SBIN0001234)',
      'amount': 'Amount in INR (₹)',
      'openAmount': 'Customer enters amount (Open)',
      'note': 'Remarks / Note (Optional)',
      'generate': 'Generate QR Code',
      'splitBill': 'Split Bill Among People',
      'scamNotice': 'SECURITY: Never enter your PIN to receive money. Always check payee name.',
      'bankNotice': 'Bank transfers use the official NPCI UPI format. A UPI ID is recommended for 100% app compatibility.',
      'history': 'Saved & History',
      'favorites': 'Favorites',
      'settings': 'Settings',
      'offlineModeTag': '100% Offline & Private',
      'print': 'Print Receipt',
      'saveImage': 'Save to Gallery',
      'copyLink': 'Copy UPI Link',
      'share': 'Share Card',
      'searchHistory': 'Search payees, tags, or amounts...',
      'exportPdf': 'Export PDF Report',
      'exportCsv': 'Export CSV',
      'backupEncrypted': 'Encrypted Backup & Restore',
      'deviceTransfer': 'Device-to-Device QR Sync',
      'lockApp': 'Lock App (Ctrl+L)',
      'lowPower': 'Low Power / Lightweight 3D Graphics',
      'language': 'Language',
    },
    'hi': {
      'appName': 'ऑफ़लाइन भुगतान क्यूआर',
      'lampHint': 'अनलॉक या पिन सेट करने के लिए लैंप चालू करें',
      'lampStyle': 'लैंप शैली',
      'deskLamp': 'आर्किटेक्ट डेस्क लैंप',
      'vintageBulb': 'विंटेज एडिसन बल्ब',
      'lantern': 'औद्योगिक लालटेन',
      'enterPin': '4-अंकीय सुरक्षा पिन दर्ज करें',
      'createPin': 'मास्टर पिन बनाएं',
      'confirmPin': 'मास्टर पिन की पुष्टि करें',
      'pinMismatch': 'पिन मेल नहीं खाते। पुनः प्रयास करें।',
      'pinSetSuccess': 'मास्टर पिन सुरक्षित रूप से सेट हो गया।',
      'unlockBiometrics': 'बायोमेट्रिक से अनलॉक करें',
      'wrongPin': 'गलत पिन। पुनः प्रयास करें।',
      'createQr': 'क्यूआर बनाएं',
      'upiMode': 'यूपीआई आईडी',
      'bankMode': 'बैंक ट्रांसफर (एनपीसीआई)',
      'payeeName': 'प्राप्तकर्ता / व्यापार का नाम',
      'upiId': 'यूपीआई आईडी (उदा. rahul@oksbi)',
      'accountNumber': 'खाता संख्या',
      'ifscCode': 'आईएफएससी कोड (उदा. SBIN0001234)',
      'amount': 'राशि रुपये में (₹)',
      'openAmount': 'ग्राहक राशि दर्ज करेगा (ओपन)',
      'note': 'टिप्पणी / विवरण (वैकल्पिक)',
      'generate': 'क्यूआर कोड बनाएं',
      'splitBill': 'लोगों में बिल विभाजित करें',
      'scamNotice': 'सुरक्षा: पैसे प्राप्त करने के लिए कभी पिन न डालें। हमेशा नाम सत्यापित करें।',
      'bankNotice': 'बैंक ट्रांसफर आधिकारिक एनपीसीआई प्रारूप का उपयोग करता है। पूर्ण अनुकूलता के लिए यूपीआई आईडी अनुशंसित है।',
      'history': 'सहेजे गए व इतिहास',
      'favorites': 'पसंदीदा',
      'settings': 'सेटिंग्स',
      'offlineModeTag': '100% ऑफ़लाइन व सुरक्षित',
      'print': 'रसीद प्रिंट करें',
      'saveImage': 'गैलरी में सहेजें',
      'copyLink': 'यूपीआई लिंक कॉपी करें',
      'share': 'कार्ड साझा करें',
      'searchHistory': 'प्राप्तकर्ता, टैग या राशि खोजें...',
      'exportPdf': 'पीडीएफ रिपोर्ट निर्यात करें',
      'exportCsv': 'सीएसवी निर्यात करें',
      'backupEncrypted': 'एन्क्रिप्टेड बैकअप व पुनर्स्थापना',
      'deviceTransfer': 'डिवाइस-टू-डिवाइस क्यूआर सिंक',
      'lockApp': 'ऐप लॉक करें (Ctrl+L)',
      'lowPower': 'कम पावर ग्राफिक्स मोड',
      'language': 'भाषा (Language)',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return Future.value(AppLocalizations(locale));
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
