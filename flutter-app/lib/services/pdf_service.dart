import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/voter.dart';

/// Service for generating PDF walk sheets
class PdfService {
  static final PdfService _instance = PdfService._();
  factory PdfService() => _instance;
  PdfService._();

  /// Generate a printable walk sheet PDF
  Future<Uint8List> generateWalkSheet({
    required String cutListName,
    required List<Voter> voters,
    String? canvasserName,
    bool includeParty = true,
    bool includePhone = false,
  }) async {
    final pdf = pw.Document();

    // Header page with summary
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Walk Sheet',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              cutListName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),
            _buildInfoRow('Generated:', _formatDate(DateTime.now())),
            _buildInfoRow('Total Voters:', '${voters.length}'),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),
            _buildInfoRow('Canvasser:', canvasserName ?? '_______________________'),
            _buildInfoRow('Date:', '_______________________'),
            _buildInfoRow('Start Time:', '_______________________'),
            _buildInfoRow('End Time:', '_______________________'),
            pw.SizedBox(height: 32),
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _buildInfoRow('Doors Knocked:', '____'),
                  _buildInfoRow('Contacts Made:', '____'),
                  _buildInfoRow('Supportive:', '____'),
                  _buildInfoRow('Opposed:', '____'),
                  _buildInfoRow('Not Home:', '____'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Voter pages with table
    final voterChunks = _chunkList(voters, 18); // 18 voters per page
    for (int pageIndex = 0; pageIndex < voterChunks.length; pageIndex++) {
      final chunk = voterChunks[pageIndex];
      final startNum = pageIndex * 18 + 1;

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(24),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Page header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    cutListName,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Page ${pageIndex + 2} of ${voterChunks.length + 1}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              // Voter table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FixedColumnWidth(28), // #
                  1: const pw.FlexColumnWidth(2.5), // Name
                  2: const pw.FlexColumnWidth(3), // Address
                  if (includeParty) 3: const pw.FixedColumnWidth(32), // Party
                  if (includePhone)
                    (includeParty ? 4 : 3): const pw.FlexColumnWidth(1.2), // Phone
                  (includeParty && includePhone
                          ? 5
                          : (includeParty || includePhone ? 4 : 3)):
                      const pw.FlexColumnWidth(1.2), // Result
                  (includeParty && includePhone
                          ? 6
                          : (includeParty || includePhone ? 5 : 4)):
                      const pw.FlexColumnWidth(2), // Notes
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _tableHeader('#'),
                      _tableHeader('Name'),
                      _tableHeader('Address'),
                      if (includeParty) _tableHeader('P'),
                      if (includePhone) _tableHeader('Phone'),
                      _tableHeader('Result'),
                      _tableHeader('Notes'),
                    ],
                  ),
                  // Voter rows
                  ...chunk.asMap().entries.map((entry) {
                    final index = entry.key;
                    final voter = entry.value;
                    return pw.TableRow(
                      children: [
                        _tableCell('${startNum + index}', center: true),
                        _tableCell(voter.displayName),
                        _tableCell(voter.fullAddress, small: true),
                        if (includeParty)
                          _tableCell(_getPartyAbbrev(voter.partyDescription),
                              center: true),
                        if (includePhone)
                          _tableCell(voter.primaryPhone, small: true),
                        _tableCell('', height: 24), // Empty for handwriting
                        _tableCell('', height: 24), // Empty for notes
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),
              // Legend
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'S=Supportive  O=Opposed  U=Undecided  NH=Not Home  R=Refused',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Text(value),
        ],
      ),
    );
  }

  pw.Widget _tableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _tableCell(String text,
      {bool center = false, bool small = false, double? height}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      height: height,
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: small ? 8 : 9),
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  String _getPartyAbbrev(String party) {
    final lower = party.toLowerCase();
    if (lower.contains('republican')) return 'R';
    if (lower.contains('democrat')) return 'D';
    if (lower.contains('libertarian')) return 'L';
    if (lower.contains('independent')) return 'I';
    if (lower.contains('green')) return 'G';
    if (party.isNotEmpty) return party[0].toUpperCase();
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(
        i,
        i + chunkSize > list.length ? list.length : i + chunkSize,
      ));
    }
    return chunks;
  }

  /// Print the PDF directly
  Future<void> printPdf(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }

  /// Share the PDF via system share sheet
  Future<void> sharePdf(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  /// Check if printing is available
  Future<bool> isPrintingAvailable() async {
    return await Printing.info().then((info) => info.canPrint);
  }
}
