import 'package:flutter/material.dart';
import '../../../core/theme/pbr_theme.dart';
import '../domain/qr_payload.dart';

class CustomQrDialog extends StatefulWidget {
  final QrCustomization initial;
  final ValueChanged<QrCustomization> onApply;

  const CustomQrDialog({
    Key? key,
    required this.initial,
    required this.onApply,
  }) : super(key: key);

  @override
  State<CustomQrDialog> createState() => _CustomQrDialogState();
}

class _CustomQrDialogState extends State<CustomQrDialog> {
  late Color _fgColor;
  late Color _bgColor;
  late bool _isRounded;
  late TextEditingController _badgeController;

  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Obsidian & Gold',
      'fg': const Color(0xFF14171E),
      'bg': const Color(0xFFFFFDF5),
    },
    {
      'name': 'Royal Indigo',
      'fg': const Color(0xFF1E1B4B),
      'bg': const Color(0xFFEEF2FF),
    },
    {
      'name': 'Deep Emerald',
      'fg': const Color(0xFF064E3B),
      'bg': const Color(0xFFECFDF5),
    },
    {
      'name': 'High Contrast Standard',
      'fg': Colors.black,
      'bg': Colors.white,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fgColor = widget.initial.foregroundColor;
    _bgColor = widget.initial.backgroundColor;
    _isRounded = widget.initial.isRounded;
    _badgeController = TextEditingController(text: widget.initial.centerBadgeText ?? '');
  }

  @override
  void dispose() {
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
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
                Icon(Icons.palette_outlined, color: PbrTheme.brassGold, size: 22),
                SizedBox(width: 8),
                Text(
                  'Customize QR Style',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Color Themes (Optimized for 100% scannability):',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presets.map((p) {
                final isSelected = _fgColor == p['fg'] && _bgColor == p['bg'];
                return ChoiceChip(
                  label: Text(p['name'] as String),
                  selected: isSelected,
                  selectedColor: PbrTheme.brassGold.withOpacity(0.3),
                  backgroundColor: const Color(0xFF232833),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? PbrTheme.tungstenHot : Colors.white70,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _fgColor = p['fg'] as Color;
                        _bgColor = p['bg'] as Color;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Rounded Modules Switch
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Rounded Style Modules',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              value: _isRounded,
              activeColor: PbrTheme.brassGold,
              onChanged: (val) => setState(() => _isRounded = val),
            ),
            const SizedBox(height: 12),
            // Center Logo / Initials (Max 3 chars to preserve error correction)
            TextField(
              controller: _badgeController,
              maxLength: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Center Monogram (e.g. ₹ or VIP)',
                labelStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                helperText: 'Keeps QR scannable with high error correction (Level H)',
                helperStyle: const TextStyle(color: Colors.white38, fontSize: 11),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: PbrTheme.brassGold),
                ),
              ),
            ),
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
                  onPressed: () {
                    widget.onApply(
                      QrCustomization(
                        foregroundColor: _fgColor,
                        backgroundColor: _bgColor,
                        isRounded: _isRounded,
                        centerBadgeText: _badgeController.text.trim().isNotEmpty
                            ? _badgeController.text.trim()
                            : null,
                      ),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Apply Style'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
