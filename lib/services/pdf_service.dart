import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/project.dart';
import 'package:flutter/services.dart' show rootBundle;

class PDFService {
  static Future<void> generatePDF(Project project) async {
    // Create a new PDF document
    final pdf = pw.Document();

    // Load the Roboto font from assets (you'll need to add these to your pubspec.yaml)
    final regularFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    // Define the page theme
    final theme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
    );

    // Add a page to the PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: theme,
        build: (context) => [
          _buildHeader(project),
          pw.SizedBox(height: 20),
          _buildProjectDetails(project),
          pw.SizedBox(height: 20),
          _buildItemsTable(project),
          pw.SizedBox(height: 20),
          _buildTotal(project),
          pw.SizedBox(height: 40),
          _buildFooter(),
        ],
      ),
    );

    try {
      // Share the PDF
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Rechnung_${project.name}.pdf',
      );
    } catch (e) {
      print('Error generating PDF: $e');

      // Fallback to a simpler version if there's an error
      await _generateSimplePDF(project);
    }
  }

  // Simplified fallback PDF with minimal formatting
  static Future<void> _generateSimplePDF(Project project) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Rechnung', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 20),
            pw.Text('Projekt: ${project.name}'),
            pw.Text('Datum: ${_formatDate(project.date)}'),
            pw.SizedBox(height: 20),
            pw.Text('Positionen:'),
            pw.SizedBox(height: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: project.items.map((item) =>
                  pw.Text('${item.quantity} ${item.unit} ${item.description}: ${item.totalPrice.toStringAsFixed(2)} €')
              ).toList(),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Gesamtpreis: ${project.totalPrice.toStringAsFixed(2)} €',
                style: pw.TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Rechnung_${project.name}_simplified.pdf',
    );
  }

  static pw.Widget _buildHeader(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Rechnung',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Andreas Dräxl\nWindshausen 84 1/2\n83131 Nußdorf am Inn',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildProjectDetails(Project project) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Projekt: ${project.name}',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Datum: ${_formatDate(project.date)}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Project project) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(4), // Beschreibung
        1: const pw.FlexColumnWidth(1), // Menge
        2: const pw.FlexColumnWidth(1), // Einheit
        3: const pw.FlexColumnWidth(1.5), // Preis/E
        4: const pw.FlexColumnWidth(1.5), // Gesamt
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableHeader('Beschreibung'),
            _buildTableHeader('Menge'),
            _buildTableHeader('Einheit'),
            _buildTableHeader('Preis/Einheit'),
            _buildTableHeader('Gesamt'),
          ],
        ),
        // Data rows
        ...project.items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.description),
            _buildTableCell(item.quantity.toString()),
            _buildTableCell(item.unit),
            _buildTableCell('${item.pricePerUnit.toStringAsFixed(2)} €'),
            _buildTableCell('${item.totalPrice.toStringAsFixed(2)} €'),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTotal(Project project) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gesamtpreis:',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14
            ),
          ),
          pw.Text(
            '${project.totalPrice.toStringAsFixed(2)} €',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 14
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Vielen Dank für Ihr Vertrauen!',
        style: const pw.TextStyle(fontSize: 12),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}