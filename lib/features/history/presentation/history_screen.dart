import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/audio_haptic_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/platform_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/pbr_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../qr_display/presentation/qr_display_screen.dart';
import 'qr_scanner_dialog.dart';

class HistoryScreen extends StatefulWidget {
  final Function(QrRecord record) onSelectRecord;

  const HistoryScreen({
    Key? key,
    required this.onSelectRecord,
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LocalStore _store = LocalStore();
  final ExportService _export = ExportService();
  final AudioHapticService _audio = AudioHapticService();
  final PlatformService _platform = PlatformService();

  String _searchQuery = '';
  String _selectedCategory = 'All';

  List<QrRecord> get _filteredRecords {
    return _store.history.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.payeeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          r.upiId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (r.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (r.amount?.toString().contains(_searchQuery) ?? false);

      final matchesCategory = _selectedCategory == 'All' ||
          (_selectedCategory == 'Favorites' && r.isFavorite) ||
          r.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _exportPdf() {
    _audio.playKeyTap();
    _export.printHistoryReport(_filteredRecords);
  }

  void _exportCsv() {
    _audio.playKeyTap();
    final csv = _export.generateHistoryCsv(_filteredRecords);
    _platform.copyToClipboard(csv);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('History CSV copied to clipboard!')),
    );
  }

  void _openDeviceTransferDialog() {
    _audio.playKeyTap();
    final payload = _store.createDeviceTransferPayload();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: PbrTheme.glassDecoration(isDark: true, opacity: 0.95, isLit: true),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.sync_alt, color: PbrTheme.brassGold),
                  SizedBox(width: 8),
                  Text(
                    'Device-to-Device Sync',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan this QR code from another device to transfer your saved payees offline with zero internet.',
                style: TextStyle(fontSize: 12, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: payload,
                  size: 200,
                  version: QrVersions.auto,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Done', style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openScannerDialog() {
    _audio.playKeyTap();
    showDialog(
      context: context,
      builder: (ctx) => QrScannerDialog(
        onPayeeImported: (newRecord) {
          setState(() {
            _store.addRecord(newRecord);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Imported payee: ${newRecord.payeeName}')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final records = _filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Import Payee by QR',
            onPressed: _openScannerDialog,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'pdf') _exportPdf();
              if (val == 'csv') _exportCsv();
              if (val == 'sync') _openDeviceTransferDialog();
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.translate('exportPdf')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.translate('exportCsv')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    const Icon(Icons.sync_alt, size: 18),
                    const SizedBox(width: 8),
                    Text(l10n.translate('deviceTransfer')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.translate('searchHistory'),
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: ['All', 'Favorites', 'General', 'Personal', 'Business', 'Dining', 'Bills'].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    selected: isSelected,
                    selectedColor: PbrTheme.brassGold.withOpacity(0.3),
                    onSelected: (_) => setState(() => _selectedCategory = cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // History List
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_outlined, size: 48, color: Colors.grey.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        const Text('No QR records found', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final r = records[index];
                      return Dismissible(
                        key: Key(r.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: PbrTheme.scamRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          _store.deleteRecord(r.id);
                          _audio.playKeyTap();
                        },
                        child: Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: PbrTheme.brassGold.withOpacity(0.15),
                              child: Text(
                                r.payeeName.isNotEmpty ? r.payeeName[0].toUpperCase() : '₹',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: PbrTheme.brassGold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r.payeeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (r.amount != null && r.amount! > 0)
                                  Text(
                                    '₹${r.amount!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: PbrTheme.brassBurnished,
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              '${r.upiId} • ${r.category}',
                              style: const TextStyle(fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                r.isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: r.isFavorite ? Colors.redAccent : null,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => r.isFavorite = !r.isFavorite);
                                _store.toggleFavorite(r.id);
                                _audio.playKeyTap();
                              },
                            ),
                            onTap: () {
                              _audio.playKeyTap();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => QrDisplayScreen(record: r),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
