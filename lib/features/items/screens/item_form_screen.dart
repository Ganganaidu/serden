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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(f.message),
                backgroundColor: AppColors.orangeDeep),
          );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(f.message),
                backgroundColor: AppColors.orangeDeep),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.orangeDeep),
        );
      },
      (_) => context.pop(),
    );
  }

  // ── Markup sheet flow ────────────────────────────────────────────────────────

  Future<void> _openMarkupSheet() async {
    final markupsCubit = context.read<MarkupsCubit>();

    // Show the list sheet and wait for a result.
    // Result is either an ItemMarkup (selected) or null (dismissed / go create).
    final listResult = await showModalBottomSheet<_MarkupPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkupListSheet(markups: markupsCubit.state),
    );

    if (listResult == null || !mounted) return;

    if (listResult.openCreate) {
      // User tapped "+ New Markup" — open the create sheet.
      final newMarkup = await showModalBottomSheet<ItemMarkup>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const _MarkupCreateSheet(),
      );
      if (newMarkup != null && mounted) {
        markupsCubit.addMarkup(newMarkup);
        setState(() => _markup = newMarkup);
      }
    } else if (listResult.markup != null) {
      setState(() => _markup = listResult.markup!);
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
                onRemove: _markup.hasMarkup
                    ? () => setState(() => _markup = ItemMarkup.none)
                    : null,
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

// ─── Markup pick result ───────────────────────────────────────────────────────

class _MarkupPickResult {
  final ItemMarkup? markup;
  final bool openCreate;

  const _MarkupPickResult.selected(this.markup) : openCreate = false;
  const _MarkupPickResult.create()
      : markup = null,
        openCreate = true;
}

// ─── Markup list sheet ────────────────────────────────────────────────────────

class _MarkupListSheet extends StatelessWidget {
  final List<ItemMarkup> markups;
  const _MarkupListSheet({required this.markups});

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
            // Markup rows
            if (markups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No markups yet — create one below.',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.inkFaint, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ),
            for (final markup in markups) ...[
              _MarkupRow(
                markup: markup,
                onTap: () => Navigator.of(context)
                    .pop(_MarkupPickResult.selected(markup)),
              ),
              const Divider(height: 1, color: AppColors.line),
            ],
            // + New Markup
            InkWell(
              onTap: () =>
                  Navigator.of(context).pop(const _MarkupPickResult.create()),
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

class _MarkupRow extends StatelessWidget {
  final ItemMarkup markup;
  final VoidCallback onTap;

  const _MarkupRow({required this.markup, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                markup.name ?? 'Markup',
                style: AppTextStyles.rowTitle,
              ),
            ),
            Text(
              markup.displayRate,
              style: AppTextStyles.rowTitle.copyWith(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Markup create sheet ──────────────────────────────────────────────────────

class _MarkupCreateSheet extends StatefulWidget {
  const _MarkupCreateSheet();

  @override
  State<_MarkupCreateSheet> createState() => _MarkupCreateSheetState();
}

class _MarkupCreateSheetState extends State<_MarkupCreateSheet> {
  late final TextEditingController _name;
  late final TextEditingController _rate;
  MarkupType _type = MarkupType.percent;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _rate = TextEditingController();
    _name.addListener(() => setState(() {}));
    _rate.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final r = double.tryParse(_rate.text.trim()) ?? 0;
    return _name.text.trim().isNotEmpty && r > 0;
  }

  void _submit() {
    final name = _name.text.trim();
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    if (name.isEmpty || rate <= 0) return;
    Navigator.of(context)
        .pop(ItemMarkup(name: name, type: _type, rate: rate));
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.greenDeep, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'New Markup',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.greenDeep,
                      ),
                    ),
                  ],
                ),
              ),
              // Form body
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Markup Name'),
                    const SizedBox(height: 6),
                    _field(
                      controller: _name,
                      hint: 'e.g. Overhead',
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
                    // % / $ radio toggle
                    Row(
                      children: [
                        _RadioOption(
                          label: '%',
                          value: MarkupType.percent,
                          groupValue: _type,
                          onChanged: (v) => setState(() => _type = v),
                        ),
                        const SizedBox(width: 28),
                        _RadioOption(
                          label: '\$',
                          value: MarkupType.flat,
                          groupValue: _type,
                          onChanged: (v) => setState(() => _type = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _label('Markup Rate'),
                    const SizedBox(height: 6),
                    _field(
                      controller: _rate,
                      hint: '0',
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      suffixText: _type == MarkupType.percent ? '%' : '\$',
                    ),
                    const SizedBox(height: 16),
                    // Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_outline,
                            size: 14, color: AppColors.inkSoft),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'This markup gets added to this line item rate only. It will never be visible to your clients.',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
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
                            child: const Text('ADD'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: AppColors.inkSoft,
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool autofocus = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? suffixText,
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
        suffixText: suffixText,
        suffixStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
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

// ─── Markup tile (shows in form) ──────────────────────────────────────────────

class _MarkupTile extends StatelessWidget {
  final ItemMarkup markup;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const _MarkupTile({
    required this.markup,
    required this.onTap,
    this.onRemove,
  });

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
            if (onRemove != null)
              GestureDetector(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child:
                      Icon(Icons.close, size: 16, color: AppColors.inkSoft),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.inkFaint),
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

// ─── Radio option ─────────────────────────────────────────────────────────────

class _RadioOption extends StatelessWidget {
  final String label;
  final MarkupType value;
  final MarkupType groupValue;
  final ValueChanged<MarkupType> onChanged;

  const _RadioOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.greenDeep : AppColors.inkFaint,
                width: 2,
              ),
            ),
            child: selected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.greenDeep,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
