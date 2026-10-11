import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../shared/widgets/document_form.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../models/invoice_model.dart';

/// New invoice. First asks the API for the next invoice number.
class NewInvoiceScreen extends StatefulWidget {
  final Invoice? invoiceToEdit;

  const NewInvoiceScreen({super.key, this.invoiceToEdit});

  @override
  State<NewInvoiceScreen> createState() => _NewInvoiceScreenState();
}

class _NewInvoiceScreenState extends State<NewInvoiceScreen> {
  int _documentNumber = 0;
  bool _resolving = true;


  @override
  void initState() {
    super.initState();
    final edit = widget.invoiceToEdit;
    if (edit != null) {
      _documentNumber = edit.number;
      _resolving = false;
      return;
    }
    _fetchNextNumber();
  }

  Future<void> _fetchNextNumber() async {
    final authState = context.read<AuthBloc>().state;
    final proId =
        authState is AuthAuthenticated ? authState.user.proId : null;
    if (proId == null) {
      setState(() => _resolving = false);
      return;
    }
    final result = await Injection.invoiceRepository.fetchNextNumber(proId);
    if (!mounted) return;
    setState(() {
      _documentNumber = result.fold(
        (_) => 0,
        (n) => int.tryParse(n.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      );
      _resolving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_resolving) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return DocumentForm(
      isInvoice: true,
      documentNumber: _documentNumber,
      invoiceToEdit: widget.invoiceToEdit,
    );
  }
}
