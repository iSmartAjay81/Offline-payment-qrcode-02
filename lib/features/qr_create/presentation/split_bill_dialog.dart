import 'package:flutter/material.dart';
import '../../../core/theme/pbr_theme.dart';
import '../domain/qr_payload.dart';

class SplitBillDialog extends StatefulWidget {
  final double totalAmount;
  final String payeeName;
  final String upiId;
  final String baseNote;
  final Function(SplitParticipant) onSelectParticipant;

  const SplitBillDialog({
    Key? key,
    required this.totalAmount,
    required this.payeeName,
    required this.upiId,
    required this.baseNote,
    required this.onSelectParticipant,
  }) : super(key: key);

  @override
  State<SplitBillDialog> createState() => _SplitBillDialogState();
}

class _SplitBillDialogState extends State<SplitBillDialog> {
  int _peopleCount = 3;
  late double _amount;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _amount = widget.totalAmount > 0 ? widget.totalAmount : 600.0;
    _amountController.text = _amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  List<SplitParticipant> _generateSplits() {
    final list = <SplitParticipant>[];
    final perPerson = (_amount / _peopleCount);
    // Round to 2 decimals
    final rounded = (perPerson * 100).floorToDouble() / 100;
    double remainder = _amount - (rounded * _peopleCount);

    for (int i = 1; i <= _peopleCount; i++) {
      double personShare = rounded;
      if (remainder > 0.009) {
        personShare += 0.01;
        remainder -= 0.01;
      }

      final note = widget.baseNote.isNotEmpty
          ? '${widget.baseNote} (Split $i of $_peopleCount)'
          : 'Split $i of $_peopleCount';

      list.add(
        SplitParticipant(
          index: i,
          name: 'Person $i',
          amount: (personShare * 100).roundToDouble() / 100,
          note: note,
        ),
      );
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final splits = _generateSplits();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        decoration: PbrTheme.glassDecoration(
          isDark: true,
          opacity: 0.95,
          isLit: true,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.call_split, color: PbrTheme.brassGold, size: 22),
                SizedBox(width: 8),
                Text(
                  'Split Bill Calculator',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      labelText: 'Total Bill (₹)',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(color: PbrTheme.brassGold),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                    ),
                    onChanged: (val) {
                      final parsed = double.tryParse(val);
                      if (parsed != null && parsed > 0) {
                        setState(() => _amount = parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('People', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _peopleCount > 2
                              ? () => setState(() => _peopleCount--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline, color: PbrTheme.brassGold),
                        ),
                        Text(
                          '$_peopleCount',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: _peopleCount < 20
                              ? () => setState(() => _peopleCount++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline, color: PbrTheme.brassGold),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Per Person Share: ₹${(_amount / _peopleCount).toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: PbrTheme.tungstenHot,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Select a participant to generate their individual QR:',
              style: TextStyle(fontSize: 12, color: Colors.white60),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: splits.length,
                separatorBuilder: (_, __) => const Divider(color: Colors.white10, height: 1),
                itemBuilder: (context, index) {
                  final p = splits[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: PbrTheme.brassGold.withOpacity(0.2),
                      child: Text(
                        '#${p.index}',
                        style: const TextStyle(color: PbrTheme.tungstenHot, fontSize: 13),
                      ),
                    ),
                    title: Text(
                      '₹${p.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      p.note,
                      style: const TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PbrTheme.brassGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        widget.onSelectParticipant(p);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Show QR', style: TextStyle(fontSize: 12)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close', style: TextStyle(color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
