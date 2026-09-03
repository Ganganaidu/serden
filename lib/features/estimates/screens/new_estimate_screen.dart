import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../shared/widgets/document_form.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../models/estimate_model.dart';

/// New / edit estimate. For a new estimate it first asks the API for the
/// next estimate number; editing skips that and reuses the existing number.
class NewEstimateScreen extends StatefulWidget {
  final Estimate? estimateToEdit;

  const NewEstimateScreen({super.key, this.estimateToEdit});

  @override
  State<NewEstimateScreen> createState() => _NewEstimateScreenState();
}

class _NewEstimateScreenState extends State<NewEstimateScreen> {
  int _documentNumber = 0;
  bool _resolving = true;

  @override
  void initState() {
    super.initState();
    final edit = widget.estimateToEdit;
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
    final result = await Injection.estimateRepository.fetchNextNumber(proId);
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
      isInvoice: false,
      documentNumber: _documentNumber,
      estimateToEdit: widget.estimateToEdit,
    );
  }
}
