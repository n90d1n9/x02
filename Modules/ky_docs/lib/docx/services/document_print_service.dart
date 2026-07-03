import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DocumentPrintService {
  const DocumentPrintService();

  Future<void> printPlainText(String text) async {
    await Printing.layoutPdf(
      onLayout: (_) async {
        final pdf = pw.Document();
        final font = await PdfGoogleFonts.robotoRegular();
        pdf.addPage(
          pw.Page(
            build: (context) => pw.Text(text, style: pw.TextStyle(font: font)),
          ),
        );
        return pdf.save();
      },
    );
  }
}
