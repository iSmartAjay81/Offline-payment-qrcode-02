class AppConstants {
  static const String appName = 'Offline Payment QR';
  static const String appVersion = '1.0.0';

  // Legal & Scam Disclaimers
  static const String offlineDisclaimer = 
      'This app only generates QR codes. Payments occur strictly in your chosen bank or UPI app. No data ever leaves this device.';
  
  static const String scamWarningPin = 
      'SECURITY WARNING: You NEVER need to enter a PIN to receive money. Never share your bank PIN or OTP with anyone.';
  
  static const String scamWarningPayee = 
      'VERIFICATION: Always verify the merchant or payee name shown on your banking app before authorizing any payment.';

  static const String scamWarningQrScan = 
      'FRAUD ALERT: Beware of requests to scan a QR code to receive a refund, prize, or lottery reward. Scanning a payment QR always pays out money.';

  // UPI Specifications & NPCI Standards
  static const String currencyINR = 'INR';
  static const String upiSchemePrefix = 'upi://pay?';

  // Strict Validation Regular Expressions
  static final RegExp upiIdRegex = RegExp(
    r'^[a-zA-Z0-9.\-_]{2,256}@[a-zA-Z]{2,64}$',
  );

  // IFSC: 4 letters + '0' + 6 alphanumeric
  static final RegExp ifscRegex = RegExp(
    r'^[A-Z]{4}0[A-Z0-9]{6}$',
  );

  // Indian Bank Account Number: 9 to 18 digits
  static final RegExp bankAccountRegex = RegExp(
    r'^\d{9,18}$',
  );

  // Amount: Positive currency with optional 2 decimal places
  static final RegExp amountRegex = RegExp(
    r'^(?!0(\.00?)?$)\d+(\.\d{1,2})?$',
  );

  // Timing
  static const Duration autoLockDuration = Duration(minutes: 1);
}
