import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../widgets/paper_document.dart';

/// Prints a paper document (estimate / invoice) through the OS print dialog
/// (AirPrint on iOS, the print framework on Android — which also offers
/// "Save as PDF").
///
/// Each widget in [pages] is rendered off-screen at real letter width, captured
/// as an image, and placed on its own PDF page, so the printout matches the
/// on-screen preview. [onReady] fires once the system print UI is about to
/// appear (use it to dismiss a loader).
class DocumentPrinter {
  DocumentPrinter._();

  static const double _pixelRatio = 2.5;

  static Future<void> print(
    BuildContext context, {
    required List<Widget> pages,
    required String jobName,
    VoidCallback? onReady,
  }) async {
    final overlay = Overlay.of(context, rootOverlay: true);
    final keys = [for (final _ in pages) GlobalKey()];

    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -(kPaperWidth + 100),
        top: 0,
        width: kPaperWidth,
        child: Material(
          color: Colors.white,
          child: Column(
            children: [
              for (var i = 0; i < pages.length; i++)
                RepaintBoundary(key: keys[i], child: pages[i]),
            ],
          ),
        ),
      ),
    );

    overlay.insert(entry);
    final doc = pw.Document(title: jobName);
    try {
      // Let layout finish and network images (logo, photos) load.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 800));
      await WidgetsBinding.instance.endOfFrame;

      for (final key in keys) {
        final boundary =
            key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary == null) continue;
        final image = await boundary.toImage(pixelRatio: _pixelRatio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) continue;

        final width = PdfPageFormat.letter.width;
        final height = width * image.height / image.width;
        final pdfImage = pw.MemoryImage(data.buffer.asUint8List());
        doc.addPage(pw.Page(
          pageFormat: PdfPageFormat(width, height),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Image(pdfImage, fit: pw.BoxFit.fill),
        ));
      }
    } finally {
      entry.remove();
    }

    final bytes = await doc.save();
    await Printing.layoutPdf(
      name: jobName,
      onLayout: (_) async {
        // The platform is about to present its print UI.
        onReady?.call();
        return bytes;
      },
    );
  }
}
