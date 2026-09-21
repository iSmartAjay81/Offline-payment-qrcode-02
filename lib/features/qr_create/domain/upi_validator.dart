import '../../../core/constants/app_constants.dart';

class UpiValidator {
  // Validate UPI ID (e.g. user@okhdfcbank or 9876543210@paytm)
  static String? validateUpiId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'UPI ID is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.upiIdRegex.hasMatch(trimmed)) {
      return 'Invalid UPI ID format (expected name@handle)';
    }
    return null;
  }

  // Validate Payee Name
  static String? validatePayeeName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Payee / Business name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  // Validate IFSC Code: 4 Letters + '0' + 6 alphanumeric
  static String? validateIfsc(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'IFSC code is required';
    }
    final upper = value.trim().toUpperCase();
    if (!AppConstants.ifscRegex.hasMatch(upper)) {
      return 'Invalid IFSC (e.g. HDFC0001234)';
    }
    return null;
  }

  // Validate Bank Account Number (9 to 18 digits)
  static String? validateAccountNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Account number is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.bankAccountRegex.hasMatch(trimmed)) {
      return 'Must be 9 to 18 digits';
    }
    return null;
  }

  // Validate Amount: positive decimal with up to 2 decimal places
  static String? validateAmount(String? value, {bool isOpenAmount = false}) {
    if (isOpenAmount) return null; // Amount is optional if customer enters amount
    if (value == null || value.trim().isEmpty) {
      return 'Amount is required';
    }
    final trimmed = value.trim();
    if (!AppConstants.amountRegex.hasMatch(trimmed)) {
      return 'Enter valid amount > 0 (e.g. 150.00)';
    }
    final numVal = double.tryParse(trimmed);
    if (numVal == null || numVal <= 0) {
      return 'Amount must be greater than 0';
    }
    return null;
  }

  // Format Bank Transfer details into NPCI standardized UPI address
  static String formatBankToUpiId({
    required String accountNumber,
    required String ifsc,
  }) {
    final cleanAcc = accountNumber.trim();
    final cleanIfsc = ifsc.trim().toUpperCase();
    return '$cleanAcc@$cleanIfsc.ifsc.npci';
  }

  // Generate complete UPI payment URL
  static String buildUpiUrl({
    required String pa,
    required String pn,
    double? am,
    String? tn,
  }) {
    final buffer = StringBuffer('upi://pay?');
    buffer.write('pa=${Uri.encodeComponent(pa)}');
    buffer.write('&pn=${Uri.encodeComponent(pn)}');
    if (am != null && am > 0) {
      buffer.write('&am=${am.toStringAsFixed(2)}');
    }
    buffer.write('&cu=INR');
    if (tn != null && tn.trim().isNotEmpty) {
      buffer.write('&tn=${Uri.encodeComponent(tn.trim())}');
    }
    return buffer.toString();
  }
}
