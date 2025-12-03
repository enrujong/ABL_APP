import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class PdfHelper {
  static Future<void> printInvoice(
    Map<String, dynamic> trx,
    List<Map<String, dynamic>> items,
  ) async {
    final pdf = pw.Document();

    // Font standar
    final font = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return _buildLayout(trx, items, font, fontBold);
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Invoice-${trx['id']}',
    );
  }

  static pw.Widget _buildLayout(
    Map<String, dynamic> trx,
    List<Map<String, dynamic>> items,
    pw.Font font,
    pw.Font fontBold,
  ) {
    final isMasuk = trx['transaction_type'] == 'IN';
    final title = isMasuk ? 'BUKTI BARANG MASUK' : 'INVOICE / SURAT JALAN';
    const themeColor = PdfColors.blue800;

    final partnerName = trx['partners'] != null
        ? trx['partners']['name']
        : 'Umum';

    // --- FORMAT TANGGAL ---
    String dateStr = '-';
    if (trx['transaction_date'] != null) {
      final date = DateTime.parse(trx['transaction_date']).toLocal();
      dateStr = DateFormat('dd MMM yyyy, HH:mm').format(date);
    }

    // --- FORMAT JATUH TEMPO (BARU) ---
    String dueDateStr = '-';
    if (trx['due_date'] != null) {
      final dueDate = DateTime.parse(trx['due_date']).toLocal();
      dueDateStr = DateFormat('dd MMM yyyy').format(dueDate);
    }

    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PT. ABADI BERKAT LESTARINDO',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 20,
                    color: themeColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Jl. Raya Utama No. 123, Kota Besar',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: themeColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 14,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 30),
        pw.Divider(color: themeColor, thickness: 1),
        pw.SizedBox(height: 20),

        // --- INFO TRANSAKSI ---
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'KEPADA YTH:',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  partnerName.toUpperCase(),
                  style: pw.TextStyle(font: fontBold, fontSize: 14),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('No. Faktur', '#${trx['id']}', font, fontBold),
                  pw.SizedBox(height: 4),
                  _buildInfoRow('Tanggal', dateStr, font, fontBold),
                  pw.SizedBox(height: 4),
                  _buildInfoRow(
                    'Status',
                    trx['payment_status'] ?? '-',
                    font,
                    fontBold,
                    valueColor: trx['payment_status'] == 'LUNAS'
                        ? PdfColors.green
                        : PdfColors.red,
                  ),

                  // --- TAMBAHAN: INFO JATUH TEMPO ---
                  if (trx['payment_status'] == 'TEMPO') ...[
                    pw.SizedBox(height: 4),
                    _buildInfoRow(
                      'Jatuh Tempo',
                      dueDateStr,
                      font,
                      fontBold,
                      valueColor: PdfColors.red,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 30),

        // --- TABEL BARANG ---
        pw.TableHelper.fromTextArray(
          border: null,
          headerStyle: pw.TextStyle(
            font: fontBold,
            color: PdfColors.white,
            fontSize: 10,
          ),
          headerDecoration: const pw.BoxDecoration(color: themeColor),
          cellStyle: pw.TextStyle(font: font, fontSize: 10),
          cellHeight: 35,
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
          oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
          headers: ['NAMA BARANG', 'QTY', 'HARGA', 'SUBTOTAL'],
          data: items.map((item) {
            final p = item['products'];
            final unit = p != null ? (p['packaging_unit'] ?? 'Unit') : '';
            return [
              p != null ? p['name'] : 'Unknown',
              '${item['quantity_packaging']} $unit',
              formatCurrency.format(item['price_per_unit'] ?? 0),
              formatCurrency.format(item['subtotal'] ?? 0),
            ];
          }).toList(),
        ),

        pw.Divider(color: PdfColors.grey300),

        // --- TOTAL ---
        pw.SizedBox(height: 10),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'GRAND TOTAL:',
              style: pw.TextStyle(font: fontBold, fontSize: 14),
            ),
            pw.SizedBox(width: 20),
            pw.Text(
              formatCurrency.format(trx['total_amount'] ?? 0),
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 18,
                color: themeColor,
              ),
            ),
          ],
        ),

        pw.Spacer(),

        // --- FOOTER ---
        pw.Center(
          child: pw.Text(
            'Dokumen ini dicetak otomatis oleh sistem.',
            style: pw.TextStyle(
              font: font,
              fontSize: 9,
              color: PdfColors.grey500,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold, {
    PdfColor? valueColor,
  }) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(
          width: 75,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 10,
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }
}
