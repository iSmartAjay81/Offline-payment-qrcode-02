import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../storage/local_store.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  // Export history to CSV formatted text
  String generateHistoryCsv(List<QrRecord> records) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln('Date,Payee Name,Type,UPI ID,Account Number,IFSC,Amount (INR),Category,Note');

    for (final r in records) {
      final dateStr = r.createdAt.toIso8601String();
      final payee = _escapeCsv(r.payeeName);
      final type = _escapeCsv(r.type);
      final upi = _escapeCsv(r.upiId);
      final acc = _escapeCsv(r.accountNumber ?? '');
      final ifsc = _escapeCsv(r.ifsc ?? '');
      final amount = r.amount != null ? r.amount!.toStringAsFixed(2) : 'Variable';
      final cat = _escapeCsv(r.category);
      final note = _escapeCsv(r.note ?? '');

      buffer.writeln('$dateStr,$payee,$type,$upi,$acc,$ifsc,$amount,$cat,$note');
    }
    return buffer.toString();
  }

  String _escapeCsv(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // Generate and optionally print or save a PDF Report of QR History
  Future<Uint8List> generateHistoryPdf(List<QrRecord> records) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Offline Payment QR - Transaction History',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateTime.now().toString().split('.')[0],
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Report generated 100% on-device. No cloud or network connection used.',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Date', 'Payee', 'Type', 'UPI / VPA', 'Amount', 'Tag'],
              data: records.map((r) {
                return [
                  r.createdAt.toString().split(' ')[0],
                  r.payeeName,
                  r.type,
                  r.upiId,
                  r.amount != null ? 'INR ${r.amount!.toStringAsFixed(2)}' : 'Open',
                  r.category,
                ];
              }).toList(),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 9,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blueGrey800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellHeight: 24,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.center,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerRight,
                5: pw.Alignment.center,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Paragraph(
              text: 'Note: This document is an offline record of created QR codes and does not constitute a bank settlement slip. All payments are completed through the payer’s UPI bank application.',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ];
        },
      ),
    );

    return await doc.save();
  }

  // Direct print or preview
  Future<void> printHistoryReport(List<QrRecord> records) async {
    final pdfBytes = await generateHistoryPdf(records);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Offline_Payment_QR_History.pdf',
    );
  }

  // Print single QR receipt
  Future<void> printSingleQrReceipt({
    required String payeeName,
    required String upiId,
    required double? amount,
    required String? note,
    required Uint8List qrImageBytes,
  }) async {
    final doc = pw.Document();

    final image = pw.MemoryImage(qrImageBytes);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Thermal receipt or standard
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'UPI PAYMENT QR',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Scan to Pay with Any UPI App',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
                ),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 8),
                pw.Image(image, width: 140, height: 140),
                pw.SizedBox(height: 8),
                pw.Text(
                  payeeName,
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  upiId,
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800),
                ),
                if (amount != null && amount > 0) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Amount: INR ${amount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ],
                if (note != null && note.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Note: $note',
                    style: const pw.TextStyle(fontSize: 8, fontStyle: pw.FontStyle.italic),
                  ),
                ],
                pw.SizedBox(height: 12),
                pw.Divider(thickness: 0.5),
                pw.Text(
                  'Generated Offline. Never share your bank PIN.',
                  style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'UPI_QR_${payeeName.replaceAll(" ", "_")}.pdf',
    );
  }
}
