import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/project.dart';

class PDFService {
  static Future<void> generatePDF(Project project) async {
    final pdf = pw.Document();

    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Container(
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(project, boldFont),
              pw.SizedBox(height: 40),
              _buildProjectDetails(project, font, boldFont),
              pw.SizedBox(height: 20),
              _buildItemsTable(project, font, boldFont),
              pw.SizedBox(height: 20),
              _buildTotal(project, boldFont),
              pw.Spacer(),
              _buildFooter(font),
            ],
          ),
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Rechnung_${project.name}.pdf',
    );
  }

  static pw.Widget _buildHeader(Project project, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Rechnung',
          style: pw.TextStyle(
            font: boldFont,
            fontSize: 24,
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

  static pw.Widget _buildProjectDetails(Project project, pw.Font font, pw.Font boldFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Projekt: ${project.name}',
          style: pw.TextStyle(font: boldFont, fontSize: 14),
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'Datum: ${_formatDate(project.date)}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(Project project, pw.Font font, pw.Font boldFont) {
    return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10),
        child: pw.Table(
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
            _buildTableHeader('Beschreibung', boldFont),
            _buildTableHeader('Menge', boldFont),
            _buildTableHeader('Einheit', boldFont),
            _buildTableHeader('Preis/Einheit', boldFont),
            _buildTableHeader('Gesamt', boldFont),
          ],
        ),
        // Daten
        ...project.items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.description, font),
            _buildTableCell(item.quantity.toString(), font),
            _buildTableCell(item.unit, font),
            _buildTableCell('${item.pricePerUnit.toStringAsFixed(2)} €', font),
            _buildTableCell('${item.totalPrice.toStringAsFixed(2)} €', font),
          ],
        )),
      ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: boldFont),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font),
        textAlign: pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTotal(Project project, pw.Font boldFont) {
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
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
          pw.Text(
            '${project.totalPrice.toStringAsFixed(2)} €',
            style: pw.TextStyle(font: boldFont, fontSize: 14),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Font font) {
    return pw.Center(
      child: pw.Text(
        'Vielen Dank für Ihr Vertrauen!',
        style: pw.TextStyle(font: font, fontSize: 12),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}