import 'package:flutter/material.dart';

import '../../../shared/widgets/document_form.dart';

class NewInvoiceScreen extends StatelessWidget {
  const NewInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocumentForm(isInvoice: true, documentNumber: 98);
  }
}
