import 'package:flutter/material.dart';

import '../../../shared/widgets/document_form.dart';

class NewEstimateScreen extends StatelessWidget {
  const NewEstimateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocumentForm(isInvoice: false, documentNumber: 1175);
  }
}
