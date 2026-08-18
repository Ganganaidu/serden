import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../cubit/markups_cubit.dart';
import '../models/item_model.dart';
import '../models/markup_template.dart';

/// Bottom sheet for creating or editing a markup template.
///
/// Pass [template] to open in edit mode (pre-filled + delete option).
/// Omit [template] for create mode.
///
/// Pops with the [MarkupTemplate] on success (create or update), or null on
/// cancel/delete. Callers can use the return value to update local selection
/// (e.g., the item form sets `_markup`) — the cubit handles list persistence.
class MarkupFormSheet extends StatefulWidget {
  final int proId;
  final MarkupTemplate? template;

  const MarkupFormSheet({super.key, required this.proId, this.template});

  @override
  State<MarkupFormSheet> createState() => _MarkupFormSheetState();
}

class _MarkupFormSheetState extends State<MarkupFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _rate;
  late MarkupType _type;
  bool _saving = false;

  bool get _isEdit => widget.template != null;

  bool get _canSubmit {
    final r = double.tryParse(_rate.text.trim()) ?? 0;
    return _name.text.trim().isNotEmpty && r > 0 && !_saving;
  }

  @override
  void initState() {
    super.initState();
    final t = widget.template;
    _name = TextEditingController(text: t?.name ?? '');
    _rate = TextEditingController(
      text: t != null
          ? (t.rate == t.rate.roundToDouble()
              ? t.rate.toStringAsFixed(0)
              : t.rate.toStringAsFixed(2))
          : '',
    );
    _type = t?.type ?? MarkupType.percent;
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
    final name = _name.text.trim();
    final rate = double.tryParse(_rate.text.trim()) ?? 0;
    if (name.isEmpty || rate <= 0) return;

    setState(() => _saving = true);
    final cubit = context.read<MarkupsCubit>();

    if (_isEdit) {
      final updated =
          widget.template!.copyWith(name: name, type: _type, rate: rate);
      final result = await cubit.update(updated);
      if (!mounted) return;
      result.fold(
        (f) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.orangeDeep));
        },
        (t) => Navigator.of(context).pop(t),
      );
    } else {
      final result = await cubit.create(
          proId: widget.proId, name: name, type: _type, rate: rate);
      if (!mounted) return;
      result.fold(
        (f) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(f.message),
              backgroundColor: AppColors.orangeDeep));
        },
        (t) => Navigator.of(context).pop(t),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete markup?'),
        content: Text(
            '"${widget.template!.name}" will be permanently removed.'),
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
    final result =
        await context.read<MarkupsCubit>().delete(widget.template!.id);
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(f.message),
            backgroundColor: AppColors.orangeDeep));
      },
      (_) => Navigator.of(context).pop(null),
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
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Icon(
                          _isEdit ? Icons.close : Icons.arrow_back,
                          color: AppColors.greenDeep,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEdit ? 'Edit Markup' : 'New Markup',
                        style: const TextStyle(
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
                        autofocus: !_isEdit,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _MarkupRadioOption(
                            label: '%',
                            value: MarkupType.percent,
                            groupValue: _type,
                            onChanged: (v) => setState(() => _type = v),
                          ),
                          const SizedBox(width: 28),
                          _MarkupRadioOption(
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
                        suffixText:
                            _type == MarkupType.percent ? '%' : '\$',
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(Icons.lock_outline,
                              size: 14, color: AppColors.inkSoft),
                          SizedBox(width: 6),
                          Expanded(
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
                      // Delete option (edit mode only)
                      if (_isEdit) ...[
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppColors.line),
                        InkWell(
                          onTap: _saving ? null : _confirmDelete,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: const [
                                Icon(Icons.delete_outline,
                                    size: 18, color: AppColors.redDeep),
                                SizedBox(width: 8),
                                Text(
                                  'Delete markup',
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
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _saving
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.inkSoft,
                                side:
                                    const BorderSide(color: AppColors.line),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
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
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
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
                                          strokeWidth: 2,
                                          color: Colors.white),
                                    )
                                  : Text(_isEdit ? 'SAVE' : 'ADD'),
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

// ─── Radio option (% / $) ────────────────────────────────────────────────────

class _MarkupRadioOption extends StatelessWidget {
  final String label;
  final MarkupType value;
  final MarkupType groupValue;
  final ValueChanged<MarkupType> onChanged;

  const _MarkupRadioOption({
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
