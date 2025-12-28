import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../models/voter.dart';
import '../../services/pdf_service.dart';

class PdfPreviewScreen extends StatefulWidget {
  final String cutListName;
  final List<Voter> voters;

  const PdfPreviewScreen({
    super.key,
    required this.cutListName,
    required this.voters,
  });

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  final PdfService _pdfService = PdfService();
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _includeParty = true;
  bool _includePhone = false;

  @override
  void initState() {
    super.initState();
    _generatePdf();
  }

  Future<void> _generatePdf() async {
    setState(() => _isLoading = true);

    try {
      final bytes = await _pdfService.generateWalkSheet(
        cutListName: widget.cutListName,
        voters: widget.voters,
        includeParty: _includeParty,
        includePhone: _includePhone,
      );

      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e')),
        );
      }
    }
  }

  Future<void> _printPdf() async {
    if (_pdfBytes != null) {
      await _pdfService.printPdf(_pdfBytes!);
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfBytes != null) {
      final filename =
          '${widget.cutListName.replaceAll(RegExp(r'[^\w\s-]'), '')}_walksheet.pdf';
      await _pdfService.sharePdf(_pdfBytes!, filename);
    }
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Options'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Include Party'),
                subtitle: const Text('Show party affiliation column'),
                value: _includeParty,
                onChanged: (value) {
                  setDialogState(() => _includeParty = value ?? true);
                },
              ),
              CheckboxListTile(
                title: const Text('Include Phone'),
                subtitle: const Text('Show phone number column'),
                value: _includePhone,
                onChanged: (value) {
                  setDialogState(() => _includePhone = value ?? false);
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {});
              _generatePdf();
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Sheet Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showOptionsDialog,
            tooltip: 'PDF Options',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _pdfBytes != null ? _sharePdf : null,
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _pdfBytes != null ? _printPdf : null,
            tooltip: 'Print',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Generating PDF...'),
                ],
              ),
            )
          : _pdfBytes != null
              ? PdfPreview(
                  build: (_) => _pdfBytes!,
                  canChangePageFormat: false,
                  canDebug: false,
                  actions: const [], // We use AppBar actions instead
                )
              : const Center(
                  child: Text('Failed to generate PDF'),
                ),
    );
  }
}
