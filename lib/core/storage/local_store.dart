import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../security/security_service.dart';
import '../theme/pbr_theme.dart';

class QrRecord {
  final String id;
  final String payeeName;
  final String upiId; // If bank mode, formatted as account@ifsc.ifsc.npci
  final String? accountNumber;
  final String? ifsc;
  final double? amount;
  final String? note;
  final String type; // 'UPI' or 'BANK'
  final DateTime createdAt;
  bool isFavorite;
  String category; // 'Personal', 'Business', 'Dining', 'Bills'

  QrRecord({
    required this.id,
    required this.payeeName,
    required this.upiId,
    this.accountNumber,
    this.ifsc,
    this.amount,
    this.note,
    required this.type,
    required this.createdAt,
    this.isFavorite = false,
    this.category = 'General',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'payeeName': payeeName,
        'upiId': upiId,
        'accountNumber': accountNumber,
        'ifsc': ifsc,
        'amount': amount,
        'note': note,
        'type': type,
        'createdAt': createdAt.toIso8601String(),
        'isFavorite': isFavorite,
        'category': category,
      };

  factory QrRecord.fromJson(Map<String, dynamic> json) => QrRecord(
        id: json['id'] as String,
        payeeName: json['payeeName'] as String,
        upiId: json['upiId'] as String,
        accountNumber: json['accountNumber'] as String?,
        ifsc: json['ifsc'] as String?,
        amount: (json['amount'] as num?)?.toDouble(),
        note: json['note'] as String?,
        type: (json['type'] as String?) ?? 'UPI',
        createdAt: DateTime.parse(json['createdAt'] as String),
        isFavorite: (json['isFavorite'] as bool?) ?? false,
        category: (json['category'] as String?) ?? 'General',
      );

  // Generate UPI payload URL
  String toUpiUrl() {
    final buffer = StringBuffer('upi://pay?');
    buffer.write('pa=${Uri.encodeComponent(upiId)}');
    buffer.write('&pn=${Uri.encodeComponent(payeeName)}');
    if (amount != null && amount! > 0) {
      buffer.write('&am=${amount!.toStringAsFixed(2)}');
    }
    buffer.write('&cu=INR');
    if (note != null && note!.trim().isNotEmpty) {
      buffer.write('&tn=${Uri.encodeComponent(note!.trim())}');
    }
    return buffer.toString();
  }
}

class LocalStore {
  static final LocalStore _instance = LocalStore._internal();
  factory LocalStore() => _instance;
  LocalStore._internal();

  static const String _keyHistoryEnc = 'qr_history_encrypted_v1';
  static const String _keyLampStyle = 'pref_lamp_style';
  static const String _keyLowPowerMode = 'pref_low_power_mode';
  static const String _keyLanguage = 'pref_app_language';
  static const String _keySound = 'pref_sound_enabled';
  static const String _keyHaptics = 'pref_haptics_enabled';

  final SecurityService _security = SecurityService();
  SharedPreferences? _prefs;

  final List<QrRecord> _history = [];
  List<QrRecord> get history => List.unmodifiable(_history);

  LampStyle lampStyle = LampStyle.deskLamp;
  bool lowPowerMode = false;
  String currentLanguage = 'en'; // 'en' or 'hi'
  bool soundEnabled = true;
  bool hapticsEnabled = true;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadPreferences();
    await _loadEncryptedHistory();
  }

  Future<void> _loadPreferences() async {
    if (_prefs == null) return;
    
    final styleIndex = _prefs!.getInt(_keyLampStyle) ?? 0;
    lampStyle = LampStyle.values[styleIndex.clamp(0, LampStyle.values.length - 1)];
    lowPowerMode = _prefs!.getBool(_keyLowPowerMode) ?? false;
    currentLanguage = _prefs!.getString(_keyLanguage) ?? 'en';
    soundEnabled = _prefs!.getBool(_keySound) ?? true;
    hapticsEnabled = _prefs!.getBool(_keyHaptics) ?? true;
  }

  Future<void> setLampStyle(LampStyle style) async {
    lampStyle = style;
    await _prefs?.setInt(_keyLampStyle, style.index);
  }

  Future<void> setLowPowerMode(bool enabled) async {
    lowPowerMode = enabled;
    await _prefs?.setBool(_keyLowPowerMode, enabled);
  }

  Future<void> setLanguage(String langCode) async {
    currentLanguage = langCode;
    await _prefs?.setString(_keyLanguage, langCode);
  }

  Future<void> setSound(bool enabled) async {
    soundEnabled = enabled;
    await _prefs?.setBool(_keySound, enabled);
  }

  Future<void> setHaptics(bool enabled) async {
    hapticsEnabled = enabled;
    await _prefs?.setBool(_keyHaptics, enabled);
  }

  Future<void> _loadEncryptedHistory() async {
    try {
      final cipherText = _prefs?.getString(_keyHistoryEnc);
      if (cipherText == null || cipherText.isEmpty) return;

      final plainJson = await _security.decryptData(cipherText);
      final List<dynamic> list = jsonDecode(plainJson);
      _history.clear();
      for (final item in list) {
        _history.add(QrRecord.fromJson(item as Map<String, dynamic>));
      }
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error decrypting history: $e');
    }
  }

  Future<void> _saveEncryptedHistory() async {
    try {
      final plainJson = jsonEncode(_history.map((e) => e.toJson()).toList());
      final cipherText = await _security.encryptData(plainJson);
      await _prefs?.setString(_keyHistoryEnc, cipherText);
    } catch (e) {
      debugPrint('Error saving encrypted history: $e');
    }
  }

  Future<void> addRecord(QrRecord record) async {
    _history.removeWhere((item) => item.id == record.id);
    _history.insert(0, record);
    await _saveEncryptedHistory();
  }

  Future<void> toggleFavorite(String id) async {
    final index = _history.indexWhere((e) => e.id == id);
    if (index != -1) {
      _history[index].isFavorite = !_history[index].isFavorite;
      await _saveEncryptedHistory();
    }
  }

  Future<void> deleteRecord(String id) async {
    _history.removeWhere((e) => e.id == id);
    await _saveEncryptedHistory();
  }

  Future<void> clearAllHistory() async {
    _history.clear();
    await _prefs?.remove(_keyHistoryEnc);
  }

  // Generate encrypted backup export string
  Future<String> exportEncryptedBackup(String userPassphrase) async {
    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'version': 1,
      'records': _history.map((e) => e.toJson()).toList(),
    };
    final jsonStr = jsonEncode(payload);
    // Uses internal AES key
    return await _security.encryptData(jsonStr);
  }

  // Restore encrypted backup
  Future<int> restoreEncryptedBackup(String cipherPayload) async {
    try {
      final plainJson = await _security.decryptData(cipherPayload);
      final Map<String, dynamic> data = jsonDecode(plainJson);
      final List<dynamic> recordsJson = data['records'] as List<dynamic>;

      int addedCount = 0;
      for (final item in recordsJson) {
        final record = QrRecord.fromJson(item as Map<String, dynamic>);
        if (!_history.any((e) => e.id == record.id)) {
          _history.add(record);
          addedCount++;
        }
      }
      _history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _saveEncryptedHistory();
      return addedCount;
    } catch (e) {
      debugPrint('Restore failed: $e');
      throw Exception('Invalid or corrupted backup data');
    }
  }

  // Compact payload for offline Device-to-Device QR transfer
  String createDeviceTransferPayload() {
    final favorites = _history.where((e) => e.isFavorite).toList();
    final itemsToExport = favorites.isNotEmpty ? favorites : _history.take(15).toList();
    final compact = itemsToExport.map((e) => [
          e.payeeName,
          e.upiId,
          e.amount?.toStringAsFixed(2) ?? '',
          e.note ?? '',
          e.type,
          e.category,
        ]).toList();
    return 'OFFLINE_QR_SYNC:${base64Url.encode(utf8.encode(jsonEncode(compact)))}';
  }

  // Import Device-to-Device QR transfer payload
  int importDeviceTransferPayload(String payload) {
    if (!payload.startsWith('OFFLINE_QR_SYNC:')) {
      throw Exception('Unrecognized transfer payload');
    }
    final rawBase64 = payload.replaceFirst('OFFLINE_QR_SYNC:', '');
    final jsonStr = utf8.decode(base64Url.decode(rawBase64));
    final List<dynamic> rows = jsonDecode(jsonStr);

    int count = 0;
    for (final row in rows) {
      final list = row as List<dynamic>;
      final payeeName = list[0].toString();
      final upiId = list[1].toString();
      final amountStr = list[2].toString();
      final note = list[3].toString();
      final type = list[4].toString();
      final category = list.length > 5 ? list[5].toString() : 'General';

      final record = QrRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_$count',
        payeeName: payeeName,
        upiId: upiId,
        amount: double.tryParse(amountStr),
        note: note.isNotEmpty ? note : null,
        type: type,
        category: category,
        createdAt: DateTime.now(),
        isFavorite: true,
      );

      if (!_history.any((e) => e.upiId == record.upiId)) {
        _history.insert(0, record);
        count++;
      }
    }
    _saveEncryptedHistory();
    return count;
  }
}
