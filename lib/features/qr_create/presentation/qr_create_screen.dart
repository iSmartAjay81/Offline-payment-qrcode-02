import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/audio_haptic_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/pbr_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/qr_payload.dart';
import '../domain/upi_validator.dart';
import 'custom_qr_dialog.dart';
import 'split_bill_dialog.dart';

class QrCreateScreen extends StatefulWidget {
  final Function(QrRecord record, QrCustomization style, QrExpiry expiry) onGenerate;
  final QrRecord? prefillRecord;

  const QrCreateScreen({
    Key? key,
    required this.onGenerate,
    this.prefillRecord,
  }) : super(key: key);

  @override
  State<QrCreateScreen> createState() => _QrCreateScreenState();
}

class _QrCreateScreenState extends State<QrCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final AudioHapticService _audio = AudioHapticService();
  final LocalStore _store = LocalStore();

  bool _isBankMode = false;
  bool _isOpenAmount = false;
  QrExpiry _expiry = QrExpiry.none;
  QrCustomization _qrStyle = const QrCustomization();

  // Controllers
  late TextEditingController _payeeNameController;
  late TextEditingController _upiIdController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;

  String _category = 'General';

  @override
  void initState() {
    super.initState();
    final p = widget.prefillRecord;
    _isBankMode = p?.type == 'BANK';
    _payeeNameController = TextEditingController(text: p?.payeeName ?? '');
    _upiIdController = TextEditingController(text: p?.type == 'UPI' ? (p?.upiId ?? '') : '');
    _accountNumberController = TextEditingController(text: p?.accountNumber ?? '');
    _ifscController = TextEditingController(text: p?.ifsc ?? '');
    _amountController = TextEditingController(
      text: p?.amount != null && p!.amount! > 0 ? p.amount!.toStringAsFixed(2) : '',
    );
    _noteController = TextEditingController(text: p?.note ?? '');
    _category = p?.category ?? 'General';
  }

  @override
  void dispose() {
    _payeeNameController.dispose();
    _upiIdController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      _audio.playErrorFeedback();
      return;
    }

    _audio.playSuccessFeedback();

    final payeeName = _payeeNameController.text.trim();
    final note = _noteController.text.trim();
    final double? amount = _isOpenAmount ? null : double.tryParse(_amountController.text.trim());

    late String effectiveUpiId;
    if (_isBankMode) {
      effectiveUpiId = UpiValidator.formatBankToUpiId(
        accountNumber: _accountNumberController.text.trim(),
        ifsc: _ifscController.text.trim(),
      );
    } else {
      effectiveUpiId = _upiIdController.text.trim();
    }

    final record = QrRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      payeeName: payeeName,
      upiId: effectiveUpiId,
      accountNumber: _isBankMode ? _accountNumberController.text.trim() : null,
      ifsc: _isBankMode ? _ifscController.text.trim().toUpperCase() : null,
      amount: amount,
      note: note.isNotEmpty ? note : null,
      type: _isBankMode ? 'BANK' : 'UPI',
      createdAt: DateTime.now(),
      category: _category,
    );

    // Save to local encrypted store
    _store.addRecord(record);

    widget.onGenerate(record, _qrStyle, _expiry);
  }

  void _openCustomStyleDialog() {
    showDialog(
      context: context,
      builder: (ctx) => CustomQrDialog(
        initial: _qrStyle,
        onApply: (newStyle) {
          setState(() => _qrStyle = newStyle);
        },
      ),
    );
  }

  void _openSplitBillDialog() {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final name = _payeeNameController.text.trim().isNotEmpty
        ? _payeeNameController.text.trim()
        : 'Split Payment';

    late String upi;
    if (_isBankMode) {
      upi = UpiValidator.formatBankToUpiId(
        accountNumber: _accountNumberController.text.trim(),
        ifsc: _ifscController.text.trim(),
      );
    } else {
      upi = _upiIdController.text.trim();
    }

    showDialog(
      context: context,
      builder: (ctx) => SplitBillDialog(
        totalAmount: amt,
        payeeName: name,
        upiId: upi,
        baseNote: _noteController.text.trim(),
        onSelectParticipant: (participant) {
          setState(() {
            _amountController.text = participant.amount.toStringAsFixed(2);
            _noteController.text = participant.note;
            _isOpenAmount = false;
          });
          _submit();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mode Selector: UPI ID vs Bank Transfer
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E222B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isBankMode = false);
                        _audio.playKeyTap();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isBankMode
                              ? PbrTheme.brassGold
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.translate('upiMode'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: !_isBankMode ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isBankMode = true);
                        _audio.playKeyTap();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isBankMode
                              ? PbrTheme.brassGold
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.translate('bankMode'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _isBankMode ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Bank Mode Explanatory Hint
            if (_isBankMode)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: PbrTheme.alertGold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PbrTheme.alertGold.withOpacity(0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: PbrTheme.alertGold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.translate('bankNotice'),
                        style: const TextStyle(fontSize: 11.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),

            // Payee Name Field
            TextFormField(
              controller: _payeeNameController,
              decoration: InputDecoration(
                labelText: l10n.translate('payeeName'),
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: UpiValidator.validatePayeeName,
            ),
            const SizedBox(height: 14),

            // Form Fields conditional on Mode
            if (!_isBankMode) ...[
              TextFormField(
                controller: _upiIdController,
                decoration: InputDecoration(
                  labelText: l10n.translate('upiId'),
                  prefixIcon: const Icon(Icons.alternate_email),
                  hintText: 'e.g. yourname@oksbi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: UpiValidator.validateUpiId,
              ),
            ] else ...[
              TextFormField(
                controller: _accountNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.translate('accountNumber'),
                  prefixIcon: const Icon(Icons.account_balance),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: UpiValidator.validateAccountNumber,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.translate('ifscCode'),
                  prefixIcon: const Icon(Icons.pin),
                  hintText: 'e.g. HDFC0001234',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: UpiValidator.validateIfsc,
              ),
            ],
            const SizedBox(height: 14),

            // Amount Field & Customer Enters Toggle
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    enabled: !_isOpenAmount,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.translate('amount'),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (v) => UpiValidator.validateAmount(v, isOpenAmount: _isOpenAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Open amount checkbox
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                l10n.translate('openAmount'),
                style: const TextStyle(fontSize: 13),
              ),
              value: _isOpenAmount,
              activeColor: PbrTheme.brassGold,
              onChanged: (val) {
                setState(() {
                  _isOpenAmount = val ?? false;
                  if (_isOpenAmount) _amountController.clear();
                });
              },
            ),

            // Fast Amount Quick Chips
            if (!_isOpenAmount)
              Wrap(
                spacing: 8,
                children: [50, 100, 200, 500, 1000, 2000].map((quickAmt) {
                  return ActionChip(
                    label: Text('₹$quickAmt', style: const TextStyle(fontSize: 11)),
                    onPressed: () {
                      _amountController.text = quickAmt.toDouble().toStringAsFixed(2);
                      _audio.playKeyTap();
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 14),

            // Remarks / Note
            TextFormField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: l10n.translate('note'),
                prefixIcon: const Icon(Icons.edit_note),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Tag / Category Picker
            Row(
              children: [
                const Text('Category: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _category,
                  underline: const SizedBox(),
                  items: ['General', 'Personal', 'Business', 'Dining', 'Bills'].map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const Spacer(),
                // Expiry Selector
                DropdownButton<QrExpiry>(
                  value: _expiry,
                  underline: const SizedBox(),
                  items: QrExpiry.values.map((exp) {
                    return DropdownMenuItem(
                      value: exp,
                      child: Text('⏱ ${exp.label}', style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _expiry = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Actions: Split Bill & Custom Style
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _openSplitBillDialog,
                  icon: const Icon(Icons.call_split, size: 16),
                  label: Text(l10n.translate('splitBill'), style: const TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _openCustomStyleDialog,
                  icon: const Icon(Icons.palette_outlined, size: 16),
                  label: const Text('Style QR', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Generate Button (PBR Metallic Style)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: PbrTheme.brassGold,
                  foregroundColor: Colors.black,
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _submit,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_2, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      l10n.translate('generate'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scam warning card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: PbrTheme.scamRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PbrTheme.scamRed.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: PbrTheme.scamRed, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.translate('scamNotice'),
                      style: const TextStyle(fontSize: 11, color: PbrTheme.scamRed, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
