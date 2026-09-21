import 'package:flutter_test/flutter_test.dart';
import 'package:offline_payment_qr/features/qr_create/domain/upi_validator.dart';

void main() {
  group('UPI Validator & Formatter Tests', () {
    test('Validates correct UPI IDs', () {
      expect(UpiValidator.validateUpiId('merchant@okhdfcbank'), isNull);
      expect(UpiValidator.validateUpiId('user.name-123@paytm'), isNull);
      expect(UpiValidator.validateUpiId('9876543210@ybl'), isNull);
    });

    test('Rejects invalid UPI IDs', () {
      expect(UpiValidator.validateUpiId(''), isNotNull);
      expect(UpiValidator.validateUpiId('merchantWithoutHandle'), isNotNull);
      expect(UpiValidator.validateUpiId('@handleOnly'), isNotNull);
      expect(UpiValidator.validateUpiId('a@b'), isNotNull);
    });

    test('Validates correct IFSC Codes', () {
      expect(UpiValidator.validateIfsc('HDFC0001234'), isNull);
      expect(UpiValidator.validateIfsc('SBIN0000456'), isNull);
      expect(UpiValidator.validateIfsc('ICIC0009876'), isNull);
    });

    test('Rejects invalid IFSC Codes', () {
      expect(UpiValidator.validateIfsc(''), isNotNull);
      expect(UpiValidator.validateIfsc('HDFC1001234'), isNotNull); // 5th char must be '0'
      expect(UpiValidator.validateIfsc('HDF0001234'), isNotNull);  // short prefix
      expect(UpiValidator.validateIfsc('HDFCA0012345'), isNotNull); // too long
    });

    test('Correctly formats Bank Transfer to NPCI UPI format', () {
      final formatted = UpiValidator.formatBankToUpiId(
        accountNumber: '123456789012',
        ifsc: 'HDFC0001234',
      );
      expect(formatted, '123456789012@HDFC0001234.ifsc.npci');
    });

    test('Builds valid standard UPI payment URI', () {
      final uriStr = UpiValidator.buildUpiUrl(
        pa: 'store@sbi',
        pn: 'Super Store',
        am: 499.50,
        tn: 'Grocery Bill',
      );

      expect(uriStr, startsWith('upi://pay?'));
      expect(uriStr, contains('pa=store%40sbi'));
      expect(uriStr, contains('pn=Super+Store'));
      expect(uriStr, contains('am=499.50'));
      expect(uriStr, contains('cu=INR'));
      expect(uriStr, contains('tn=Grocery+Bill'));
    });

    test('Validates positive 2-decimal amounts', () {
      expect(UpiValidator.validateAmount('100'), isNull);
      expect(UpiValidator.validateAmount('250.75'), isNull);
      expect(UpiValidator.validateAmount('0.50'), isNull);
      expect(UpiValidator.validateAmount('0'), isNotNull);
      expect(UpiValidator.validateAmount('-50'), isNotNull);
      expect(UpiValidator.validateAmount('12.345'), isNotNull); // 3 decimals rejected
      expect(UpiValidator.validateAmount('', isOpenAmount: true), isNull);
    });
  });
}
