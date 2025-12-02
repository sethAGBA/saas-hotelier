import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models.dart';

class PdfService {
  Future<File> generateTicket({
    required DiningTable table,
    required List<OrderItem> items,
    required String restaurantName,
    required double subtotal,
    required double discount,
    required double tip,
    required double total,
    String? customDirectory,
  }) async {
    final doc = pw.Document();
    const receiptWidth = PdfPageFormat.mm * 58;
    final estimatedHeightMm =
        (80 + (items.length * 6)).clamp(120, 400).toDouble();
    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat(
        receiptWidth,
        PdfPageFormat.mm * estimatedHeightMm,
      ).copyWith(
        marginLeft: 8,
        marginRight: 8,
        marginTop: 8,
        marginBottom: 8,
      ),
      textDirection: pw.TextDirection.ltr,
    );
    String formatAmount(double value) => '${value.toStringAsFixed(0)} FCFA';

    doc.addPage(
      pw.MultiPage(
        pageTheme: pageTheme,
        build: (context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    restaurantName,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text('Ticket table ${table.number}',
                      style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    DateTime.now().toString(),
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(),
            pw.SizedBox(height: 4),
            ...items.map(
              (order) => pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        order.menuItem.name,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text(
                      '${order.quantity}x',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      formatAmount(
                        order.menuItem.price * order.quantity,
                      ),
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Sous-total', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(formatAmount(subtotal),
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            if (discount > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Remise', style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    '-${formatAmount(discount)}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Pourboire', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(formatAmount(tip),
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  formatAmount(total),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Merci pour votre visite !',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ];
        },
      ),
    );

    Directory targetDir;
    if (customDirectory != null && customDirectory.isNotEmpty) {
      targetDir = Directory(customDirectory);
      if (!await targetDir.exists()) {
        targetDir = await targetDir.create(recursive: true);
      }
    } else {
      targetDir = await getApplicationDocumentsDirectory();
    }

    final file = File(
      '${targetDir.path}/ticket_table_${table.number}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await doc.save());
    return file;
  }
}
