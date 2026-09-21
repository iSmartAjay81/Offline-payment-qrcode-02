import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/audio_haptic_service.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/platform_service.dart';
import '../../../core/storage/local_store.dart';
import '../../../core/theme/pbr_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../qr_create/domain/qr_payload.dart';

class QrDisplayScreen extends StatefulWidget {
  final QrRecord record;
  final QrCustomization style;
  final QrExpiry expiry;

  const QrDisplayScreen({
    Key? key,
    required this.record,
    this.style = const QrCustomization(),
    this.expiry = QrExpiry.none,
  }) : super(key: key);

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  final GlobalKey _qrCardRepaintKey = GlobalKey();
  final PlatformService _platform = PlatformService();
  final AudioHapticService _audio = AudioHapticService();
  final ExportService _export = ExportService();
  final LocalStore _store = LocalStore();

  Timer? _countdownTimer;
  Duration? _remainingTime;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    // Auto boost brightness on mobile devices
    _platform.boostBrightness();

    final dur = widget.expiry.duration;
    if (dur != null) {
      _remainingTime = dur;
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remainingTime!.inSeconds > 0) {
          setState(() {
            _remainingTime = _remainingTime! - const Duration(seconds: 1);
          });
        } else {
          setState(() {
            _isExpired = true;
          });
          t.cancel();
        }
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _platform.restoreBrightness();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours.toString().padLeft(2, '0');
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Future<void> _copyUpiLink() async {
    final url = widget.record.toUpiUrl();
    await _platform.copyToClipboard(url);
    _audio.playKeyTap();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI payment link copied to clipboard!')),
      );
    }
  }

  Future<void> _printReceipt() async {
    _audio.playKeyTap();
    try {
      final qrImage = await _captureCardImage();
      if (qrImage != null) {
        await _export.printSingleQrReceipt(
          payeeName: widget.record.payeeName,
          upiId: widget.record.upiId,
          amount: widget.record.amount,
          note: widget.record.note,
          qrImageBytes: qrImage,
        );
      }
    } catch (e) {
      debugPrint('Print error: $e');
    }
  }

  Future<ui.Image?> _captureCardImageWidget() async {
    try {
      final boundary = _qrCardRepaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;
      return await boundary.toImage(pixelRatio: 3.0);
    } catch (e) {
      debugPrint('Capture card error: $e');
      return null;
    }
  }

  Future<dynamic> _captureCardImage() async {
    final image = await _captureCardImageWidget();
    if (image == null) return null;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final upiUrl = widget.record.toUpiUrl();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.translate('createQr')),
        actions: [
          IconButton(
            icon: Icon(
              widget.record.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: widget.record.isFavorite ? Colors.redAccent : null,
            ),
            tooltip: 'Favorite Payee',
            onPressed: () {
              setState(() {
                widget.record.isFavorite = !widget.record.isFavorite;
              });
              _store.toggleFavorite(widget.record.id);
              _audio.playKeyTap();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                // Expiry Badge
                if (_remainingTime != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isExpired ? PbrTheme.scamRed.withOpacity(0.15) : PbrTheme.alertGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isExpired ? PbrTheme.scamRed : PbrTheme.alertGold,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isExpired ? Icons.timer_off : Icons.timer,
                          size: 14,
                          color: _isExpired ? PbrTheme.scamRed : PbrTheme.alertGold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isExpired
                              ? 'QR Expired'
                              : 'Expires in: ${_formatDuration(_remainingTime!)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _isExpired ? PbrTheme.scamRed : PbrTheme.alertGold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // High Fidelity Clean QR Payment Card (Shareable on WhatsApp/Instagram)
                RepaintBoundary(
                  key: _qrCardRepaintKey,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.style.backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Card Top Header: Payee info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: PbrTheme.brassGold,
                              child: Text(
                                widget.record.payeeName.isNotEmpty
                                    ? widget.record.payeeName[0].toUpperCase()
                                    : '₹',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.record.payeeName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: widget.style.foregroundColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.record.upiId,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.style.foregroundColor.withOpacity(0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: PbrTheme.brassBurnished.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.record.type,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: PbrTheme.brassBurnished,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Center QR Code with High Error Correction
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Opacity(
                              opacity: _isExpired ? 0.2 : 1.0,
                              child: QrImageView(
                                data: upiUrl,
                                version: QrVersions.auto,
                                size: 240.0,
                                eyeStyle: QrEyeStyle(
                                  eyeShape: widget.style.isRounded
                                      ? QrEyeShape.circle
                                      : QrEyeShape.square,
                                  color: widget.style.foregroundColor,
                                ),
                                dataModuleStyle: QrDataModuleStyle(
                                  dataModuleShape: widget.style.isRounded
                                      ? QrDataModuleShape.circle
                                      : QrDataModuleShape.square,
                                  color: widget.style.foregroundColor,
                                ),
                                errorCorrectionLevel: QrErrorCorrectLevel.H,
                              ),
                            ),
                            if (widget.style.centerBadgeText != null && !_isExpired)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: widget.style.backgroundColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  widget.style.centerBadgeText!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: widget.style.foregroundColor,
                                  ),
                                ),
                              ),
                            if (_isExpired)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: PbrTheme.scamRed,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'EXPIRED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Amount Badge
                        if (widget.record.amount != null && widget.record.amount! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.style.foregroundColor.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '₹ ${widget.record.amount!.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: widget.style.foregroundColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Customer Enters Amount',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.style.foregroundColor.withOpacity(0.7),
                            ),
                          ),

                        if (widget.record.note != null && widget.record.note!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '"${widget.record.note}"',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: widget.style.foregroundColor.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Standard UPI Acceptance Logo bar
                        Text(
                          'Scan with GPay • PhonePe • Paytm • BHIM • Cred',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: widget.style.foregroundColor.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Primary Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _copyUpiLink,
                      icon: const Icon(Icons.link, size: 18),
                      label: Text(l10n.translate('copyLink')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PbrTheme.brassGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _printReceipt,
                      icon: const Icon(Icons.print_outlined, size: 18),
                      label: Text(l10n.translate('print')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Official In-App Mandatory Notice
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF181C24) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.verified_user_outlined, size: 16, color: PbrTheme.successEmerald),
                          SizedBox(width: 8),
                          Text(
                            'Offline Transparency Note',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: PbrTheme.successEmerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppConstants.offlineDisclaimer,
                        style: const TextStyle(fontSize: 11, height: 1.35, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
