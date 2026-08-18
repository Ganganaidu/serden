import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/main_shell.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../cubit/taxes_cubit.dart';
import '../models/tax_model.dart';

class TaxesScreen extends StatefulWidget {
  const TaxesScreen({super.key});

  @override
  State<TaxesScreen> createState() => _TaxesScreenState();
}

class _TaxesScreenState extends State<TaxesScreen> with WidgetsBindingObserver {
  String _search = '';
  DateTime? _backgroundedAt;

  int? get _proId {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated ? auth.user.proId : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final proId = _proId;
    if (proId != null) context.read<TaxesCubit>().fetch(proId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final bg = _backgroundedAt;
      _backgroundedAt = null;
      if (bg != null &&
          DateTime.now().difference(bg) > const Duration(minutes: 2)) {
        _refresh();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _refresh() {
    final proId = _proId;
    if (proId != null) context.read<TaxesCubit>().fetch(proId);
  }

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await context
          .read<TaxesCubit>()
          .stream
          .firstWhere((s) => s is TaxesLoaded || s is TaxesError)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  List<TaxRate> _filtered(List<TaxRate> taxes) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return taxes;
    return taxes.where((t) => t.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _openSheet({TaxRate? tax}) async {
    final proId = _proId;
    if (proId == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<TaxesCubit>(),
        child: _TaxSheet(proId: proId, tax: tax),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaxesCubit, TaxesState>(
      builder: (context, state) {
        final taxes = state is TaxesLoaded ? state.taxes : <TaxRate>[];
        final filtered = _filtered(taxes);

        return Scaffold(
          backgroundColor: AppColors.page,
          body: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────
              Container(
                color: AppColors.green800,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 6,
                  left: 20,
                  right: 20,
                  bottom: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () => context.pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.arrow_back_ios_new,
                                size: 14, color: Color(0xCCFFFFFF)),
                            SizedBox(width: 4),
                            Text(
                              'Settings',
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Taxes', style: AppTextStyles.headerTitle),
                    const SizedBox(height: 3),
                    Text(
                      state is TaxesLoaded
                          ? '${taxes.length} ${taxes.length == 1 ? 'tax rate' : 'tax rates'} saved'
                          : 'Manage your tax rates',
                      style: AppTextStyles.headerSubtitle,
                    ),
                    HeaderSearchBar(
                      hint: 'Search tax rates',
                      onChanged: (v) => setState(() => _search = v),
                    ),
                  ],
                ),
              ),

              // ── Body ────────────────────────────────────────────────────
              Expanded(child: _body(context, state, filtered)),
            ],
          ),
          floatingActionButton: AppFab(
            label: 'New tax',
            onPressed: () => _openSheet(),
          ),
        );
      },
    );
  }

  Widget _body(
      BuildContext context, TaxesState state, List<TaxRate> filtered) {
    if (state is TaxesLoading || state is TaxesInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is TaxesError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: AppColors.inkFaint),
              const SizedBox(height: 16),
              Text(state.message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.inkSoft)),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _refresh,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is TaxesLoaded && state.taxes.isEmpty) {
      return const EmptyState(
        title: 'No tax rates yet',
        description:
            'Add your tax rates here — they\'ll be available to apply on any estimate or invoice.',
        icon: Icons.percent_outlined,
      );
    }

    if (filtered.isEmpty) {
      return const EmptyState(
        title: 'No matches',
        description: 'Try a different search term.',
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: AppColors.orange500,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: filtered.length,
        itemBuilder: (_, i) => _TaxRow(
          tax: filtered[i],
          onTap: () => _openSheet(tax: filtered[i]),
        ),
      ),
    );
  }
}

// ─── Tax list row ─────────────────────────────────────────────────────────────

class _TaxRow extends StatelessWidget {
  final TaxRate tax;
  final VoidCallback onTap;

  const _TaxRow({required this.tax, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tax.name,
                  style: AppTextStyles.rowTitle
                      .copyWith(fontSize: 15, height: 1.35),
                ),
              ),
              Text(
                tax.displayRate,
                style: AppTextStyles.rowAmount.copyWith(
                  fontSize: 15,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  size: 18, color: AppColors.inkFaint),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Tax bottom sheet (create + edit) ────────────────────────────────────────

class _TaxSheet extends StatefulWidget {
  final int proId;
  final TaxRate? tax;

  const _TaxSheet({required this.proId, this.tax});

  @override
  State<_TaxSheet> createState() => _TaxSheetState();
}

class _TaxSheetState extends State<_TaxSheet> {
  late final TextEditingController _name;
  late final TextEditingController _rate;
  bool _saving = false;

  bool get _isEdit => widget.tax != null;

  bool get _canSubmit {
    final r = double.tryParse(_rate.text.trim()) ?? -1;
    return _name.text.trim().isNotEmpty && r >= 0 && !_saving;
  }

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.tax?.name ?? '');
    _rate = TextEditingController(
      text: widget.tax != null
          ? widget.tax!.rate.toStringAsFixed(2)
          : '',
    );
    _name.addListener(() => setState(() {}));
    _rate.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final name = _name.text.trim();
    final rate = double.tryParse(_rate.text.trim()) ?? 0;

    setState(() => _saving = true);
    final cubit = context.read<TaxesCubit>();

    if (_isEdit) {
      final updated = widget.tax!.copyWith(name: name, rate: rate);
      final result = await cubit.update(updated);
      if (!mounted) return;
      result.fold(
        (f) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(f.message),
                backgroundColor: AppColors.orangeDeep),
          );
        },
        (_) => Navigator.of(context).pop(),
      );
    } else {
      final result = await cubit.create(
        proId: widget.proId,
        name: name,
        rate: rate,
      );
      if (!mounted) return;
      result.fold(
        (f) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(f.message),
                backgroundColor: AppColors.orangeDeep),
          );
        },
        (_) => Navigator.of(context).pop(),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete tax rate?'),
        content: Text(
            '"${widget.tax!.name}" will be removed from your tax rates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result = await context.read<TaxesCubit>().delete(widget.tax!.id);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.orangeDeep),
        );
      },
      (_) => Navigator.of(context).pop(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottom),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: LoadingOverlay(
            isLoading: _saving,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grabber,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close,
                            color: AppColors.inkSoft, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEdit ? 'Edit Tax Rate' : 'New Tax Rate',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 20),

                // Two side-by-side fields
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tax Name
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _requiredLabel('Tax Name'),
                            const SizedBox(height: 6),
                            _field(
                              controller: _name,
                              hint: 'e.g., Sales Tax',
                              autofocus: !_isEdit,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Tax Rate
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _requiredLabel('Tax Rate (%)'),
                            const SizedBox(height: 6),
                            _field(
                              controller: _rate,
                              hint: '0',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,4}')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Delete row (edit mode only)
                if (_isEdit) ...[
                  const Divider(height: 1, color: AppColors.line),
                  InkWell(
                    onTap: _saving ? null : _confirmDelete,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Row(
                        children: const [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppColors.redDeep),
                          SizedBox(width: 8),
                          Text(
                            'Delete tax rate',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.redDeep,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.line),
                  const SizedBox(height: 16),
                ],

                // Action buttons
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving
                              ? null
                              : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.inkSoft,
                            side: const BorderSide(color: AppColors.line),
                            shape: const StadiumBorder(),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _canSubmit ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green800,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.inkFaint.withValues(alpha: 0.4),
                            shape: const StadiumBorder(),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : Text(_isEdit ? 'SAVE' : 'ADD'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _requiredLabel(String text) {
    return Text.rich(
      TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
        children: const [
          TextSpan(
            text: '  *',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool autofocus = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      style: AppTextStyles.rowTitle.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: AppColors.page,
        hintStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.inkFaint, height: 1.2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.fieldBorder, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.greenDeep, width: 1.5),
        ),
      ),
    );
  }
}
