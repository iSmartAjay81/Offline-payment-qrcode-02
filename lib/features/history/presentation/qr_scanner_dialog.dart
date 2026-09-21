import 'package:flutter/material.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/pbr_theme.dart';
import '../../qr_create/domain/upi_validator.dart';

class QrScannerDialog extends StatefulWidget {
  final Function(QrRecord record) onPayeeImported;

  const QrScannerDialog({
    Key? key,
    required this.onPayeeImported,
  }) : super(key: key);

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final TextEditingController _inputController = TextEditingController();
  String? _parseError;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _parsePayload(String raw) {
    setState(() => _parseError = null);
    final text = raw.trim();

    if (text.isEmpty) {
      setState(() => _parseError = 'Please provide a valid QR payload');
      return;
    }

    // Check if it's a device sync payload
    if (text.startsWith('OFFLINE_QR_SYNC:')) {
      try {
        final count = LocalStore().importDeviceTransferPayload(text);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully imported $count payees!')),
        );
        return;
      } catch (e) {
        setState(() => _parseError = 'Failed to decode device sync payload: $e');
        return;
      }
    }

    // Standard UPI URI Parser
    try {
      final uri = Uri.parse(text);
      if (uri.scheme != 'upi' && !text.startsWith('upi://')) {
        setState(() => _parseError = 'Payload is not a valid UPI payment QR (must begin with upi://pay)');
        return;
      }

      final params = uri.queryParameters;
      final pa = params['pa'];
      final pn = params['pn'] ?? 'Imported Payee';
      final am = params['am'] != null ? double.tryParse(params['am']!) : null;
      final tn = params['tn'];

      if (pa == null || UpiValidator.validateUpiId(pa) != null) {
        setState(() => _parseError = 'Invalid UPI ID found in QR: $pa');
        return;
      }

      final record = QrRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        payeeName: pn,
        upiId: pa,
        amount: am,
        note: tn,
        type: 'UPI',
        createdAt: DateTime.now(),
        isFavorite: true,
      );

      widget.onPayeeImported(record);
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _parseError = 'Could not parse QR code data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(24),
        decoration: PbrTheme.glassDecoration(isDark: true, opacity: 0.95, isLit: true),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.qr_code_scanner, color: PbrTheme.brassGold),
                SizedBox(width: 8),
                Text(
                  'Import Payee via QR',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Paste a scanned UPI URI or offline sync code below:',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _inputController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'upi://pay?pa=name@upi&pn=Merchant%20Name&am=100...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
              ),
            ),
            if (_parseError != null) ...[
              const SizedBox(height: 8),
              Text(
                _parseError!,
                style: const TextStyle(color: PbrTheme.scamRed, fontSize: 11),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PbrTheme.brassGold,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () => _parsePayload(_inputController.text),
                  child: const Text('Import Payee'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
