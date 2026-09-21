import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    wOptions: WindowsOptions(useBackwardCompatibility: false),
    mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _keyPinHash = 'secure_vault_pin_hash';
  static const String _keyPinSalt = 'secure_vault_pin_salt';
  static const String _keyDbMasterKey = 'secure_vault_db_aes_key';

  // Check if PIN has been set up initially
  Future<bool> isPinCreated() async {
    try {
      final hash = await _secureStorage.read(key: _keyPinHash);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking PIN existence: $e');
      return false;
    }
  }

  // Create new Master PIN with 32-byte cryptographically secure salt
  Future<bool> createPin(String pin) async {
    try {
      final saltBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      final saltHex = base64Url.encode(saltBytes);
      final hash = _hashPin(pin, saltHex);

      await _secureStorage.write(key: _keyPinHash, value: hash);
      await _secureStorage.write(key: _keyPinSalt, value: saltHex);

      // Generate or ensure AES master key exists
      await _getOrCreateMasterKey();
      return true;
    } catch (e) {
      debugPrint('Error setting PIN: $e');
      return false;
    }
  }

  // Verify PIN against stored salted hash
  Future<bool> verifyPin(String enteredPin) async {
    try {
      final storedHash = await _secureStorage.read(key: _keyPinHash);
      final storedSalt = await _secureStorage.read(key: _keyPinSalt);

      if (storedHash == null || storedSalt == null) return false;

      final calculatedHash = _hashPin(enteredPin, storedSalt);
      return storedHash == calculatedHash;
    } catch (e) {
      debugPrint('PIN verification failed: $e');
      return false;
    }
  }

  String _hashPin(String pin, String saltHex) {
    final bytes = utf8.encode('$saltHex:$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Check biometric support (Fingerprint, Face ID, Windows Hello)
  Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('Biometrics check error: $e');
      return false;
    }
  }

  // Authenticate using biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access Offline Payment QR',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      debugPrint('Biometrics authentication error: $e');
      return false;
    }
  }

  // Retrieve or create 256-bit AES master encryption key
  Future<String> _getOrCreateMasterKey() async {
    String? masterKey = await _secureStorage.read(key: _keyDbMasterKey);
    if (masterKey == null) {
      final keyBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
      masterKey = base64Url.encode(keyBytes);
      await _secureStorage.write(key: _keyDbMasterKey, value: masterKey);
    }
    return masterKey;
  }

  // Encrypt raw text using AES-256 (CBC with random IV)
  Future<String> encryptData(String plainText) async {
    try {
      final keyString = await _getOrCreateMasterKey();
      final keyBytes = base64Url.decode(keyString);
      final key = enc.Key(Uint8List.fromList(keyBytes));
      final iv = enc.IV.fromSecureRandom(16);

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(plainText, iv: iv);

      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('Encryption failed: $e');
      throw Exception('Encryption failed');
    }
  }

  // Decrypt ciphertext using AES-256
  Future<String> decryptData(String cipherPayload) async {
    try {
      final parts = cipherPayload.split(':');
      if (parts.length != 2) throw Exception('Invalid ciphertext format');

      final iv = enc.IV.fromBase64(parts[0]);
      final encryptedData = enc.Encrypted.fromBase64(parts[1]);

      final keyString = await _getOrCreateMasterKey();
      final keyBytes = base64Url.decode(keyString);
      final key = enc.Key(Uint8List.fromList(keyBytes));

      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      debugPrint('Decryption failed: $e');
      throw Exception('Decryption failed');
    }
  }

  // Reset/Wipe vault (for tests or complete factory reset)
  Future<void> wipeAll() async {
    await _secureStorage.deleteAll();
  }
}
