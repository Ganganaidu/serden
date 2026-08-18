import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/form_nav_bar.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../cubit/items_cubit.dart';
import '../cubit/markups_cubit.dart';
import '../models/item_model.dart';
import '../models/markup_template.dart';
import 'markup_form_sheet.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item;
  final int proId;

  const ItemFormScreen({super.key, this.item, required this.proId});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _rate;
  late final TextEditingController _description;
  late final TextEditingController _privateNote;
  late ItemMarkup _markup;

  bool _saving = false;

  bool get _isEdit => widget.item != null;
  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _rate = TextEditingController(
      text: item?.unitPrice != null ? item!.unitPrice!.toStringAsFixed(2) : '',
    );
    _description = TextEditingController(text: item?.description ?? '');
    _privateNote = TextEditingController(text: item?.privateNote ?? '');
    _markup = item?.markup ?? ItemMarkup.none;
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    _description.dispose();
    _privateNote.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!_canSave) return;
    final name = _name.text.trim();
    final price = double.tryParse(_rate.text.trim());
    final description = _nullIfEmpty(_description.text);
    final privateNote = _nullIfEmpty(_privateNote.text);

    setState(() => _saving = true);

    final cubit = context.read<ItemsCubit>();

    if (_isEdit) {
      final updated = widget.item!.copyWith(
        name: name,
        unitPrice: price,
        description: description,
        markup: _markup,
        privateNote: privateNote,
      );
      final result = await cubit.update(updated);
      if (!mounted) return;
      result.fold(
        (f) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.orangeDeep));
        },
        (_) => context.pop(),
      );
    } else {
      final result = await cubit.create(
        proId: widget.proId,
        name: name,
        unitPrice: price,
        description: description,
        markup: _markup,
        privateNote: privateNote,
      );
      if (!mounted) return;
      result.fold(
        (f) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.orangeDeep));
        },
        (_) => context.pop(),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text(
            '"${widget.item!.name}" will be permanently removed from your catalog.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    final result =
        await context.read<ItemsCubit>().delete(widget.item!.itemId);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(f.message), backgroundColor: AppColors.orangeDeep));
      },
      (_) => context.pop(),
    );
  }

  // ── Markup sheet flow ────────────────────────────────────────────────────────

  Future<void> _openMarkupSheet() async {
    final markupsCubit = context.read<MarkupsCubit>();

    // Always re-fetch so web updates are visible immediately.
    markupsCubit.fetch(widget.proId);

    final listResult = await showModalBottomSheet<_MarkupPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: markupsCubit,
        child: _MarkupListSheet(proId: widget.proId),
      ),
    );

    if (listResult == null || !mounted) return;

    if (listResult.openCreate) {
      final template = await showModalBottomSheet<MarkupTemplate>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => BlocProvider.value(
          value: markupsCubit,
          child: MarkupFormSheet(proId: widget.proId),
        ),
      );
      if (template != null && mounted) {
        setState(() => _markup = template.toItemMarkup());
      }
    } else {
      setState(() =>
          _markup = listResult.template?.toItemMarkup() ?? ItemMarkup.none);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _saving,
      child: Scaffold(
        appBar: FormNavBar(
          title: _isEdit ? 'Edit item' : 'New item',
          trailingLabel: 'Save',
          trailingEnabled: _canSave,
          onTrailing: _save,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const SectionHeader(
              title: 'Item details',
              padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
            ),
            AppCard(
              child: Column(
                children: [
                  _FieldBlock(
                    label: 'Item name',
                    child: _input(
                      controller: _name,
                      hint: 'e.g. Drywall installation',
                      autofocus: !_isEdit,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  _FieldBlock(
                    label: 'Rate',
                    showDivider: false,
                    child: _input(
                      controller: _rate,
                      hint: '0.00',
                      prefixText: '\$ ',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SectionHeader(title: 'Markup'),
            AppCard(
              child: _MarkupTile(
                markup: _markup,
                onTap: _openMarkupSheet,
              ),
            ),
            const SectionHeader(title: 'Description'),
            AppCard(
              child: _FieldBlock(
                label: 'Description',
                optional: true,
                showDivider: false,
                child: _input(
                  controller: _description,
                  hint: 'Labor and materials, scope details…',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SectionHeader(title: 'Private note'),
            AppCard(
              child: _FieldBlock(
                label: 'Private note',
                optional: true,
                showDivider: false,
                child: _input(
                  controller: _privateNote,
                  hint: 'Internal notes — not visible to clients',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            if (_isEdit) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _saving ? null : _confirmDelete,
                icon: const Icon(Icons.delete_outline, size: 17),
                label: const Text('Delete item'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool autofocus = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      style: AppTextStyles.rowTitle.copyWith(
        fontWeight: maxLines > 1 ? FontWeight.w500 : FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: prefixText,
        isDense: true,
        filled: true,
        fillColor: AppColors.page,
        hintStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.inkFaint, height: 1.2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide:
              const BorderSide(color: AppColors.greenDeep, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Pick result ──────────────────────────────────────────────────────────────

class _MarkupPickResult {
  final MarkupTemplate? template;
  final bool openCreate;

  const _MarkupPickResult.selected(this.template) : openCreate = false;
  const _MarkupPickResult.create()
      : template = null,
        openCreate = true;
}

// ─── Markup tile (form row) ───────────────────────────────────────────────────

class _MarkupTile extends StatelessWidget {
  final ItemMarkup markup;
  final VoidCallback onTap;

  const _MarkupTile({required this.markup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (!markup.hasMarkup) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: const [
              Icon(Icons.add_circle_outline,
                  size: 18, color: AppColors.greenDeep),
              SizedBox(width: 8),
              Text(
                'Add item markup',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.greenDeep,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    markup.name ?? 'Markup',
                    style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    markup.displayRate,
                    style: AppTextStyles.caption.copyWith(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDeep,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 20, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

// ─── Markup list sheet ────────────────────────────────────────────────────────

class _MarkupListSheet extends StatelessWidget {
  final int proId;
  const _MarkupListSheet({required this.proId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Item Markup',
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close,
                        size: 22, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.line),
            // List content — "No markup" is always the first row
            BlocBuilder<MarkupsCubit, MarkupsState>(
              builder: (context, state) {
                final templates = state is MarkupsLoaded ? state.templates : <MarkupTemplate>[];
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // No markup — always visible as first list item
                    InkWell(
                      onTap: () => Navigator.of(context)
                          .pop(const _MarkupPickResult.selected(null)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'No markup',
                                style: AppTextStyles.rowTitle
                                    .copyWith(color: AppColors.inkSoft),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.line),
                    // State-specific content below
                    if (state is MarkupsInitial || state is MarkupsLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (state is MarkupsError)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.inkSoft),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () =>
                                  context.read<MarkupsCubit>().fetch(proId),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    else if (templates.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'No markups yet — create one below.',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.inkFaint, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      for (final t in templates) ...[
                        InkWell(
                          onTap: () => Navigator.of(context)
                              .pop(_MarkupPickResult.selected(t)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(t.name,
                                      style: AppTextStyles.rowTitle),
                                ),
                                Text(
                                  t.displayRate,
                                  style: AppTextStyles.rowTitle.copyWith(
                                    color: AppColors.inkSoft,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                      ],
                  ],
                );
              },
            ),
            // + New Markup
            InkWell(
              onTap: () => Navigator.of(context)
                  .pop(const _MarkupPickResult.create()),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.green800,
                      ),
                      child: const Icon(Icons.add,
                          size: 18, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'New Markup',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Field block ──────────────────────────────────────────────────────────────

class _FieldBlock extends StatelessWidget {
  final String? label;
  final bool optional;
  final bool showDivider;
  final Widget child;

  const _FieldBlock({
    this.label,
    this.optional = false,
    this.showDivider = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text.rich(
              TextSpan(
                text: label!,
                children: [
                  if (optional)
                    const TextSpan(
                      text: ' · optional',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkFaint,
                      ),
                    ),
                ],
              ),
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 6),
          ],
          child,
        ],
      ),
    );
  }
}
