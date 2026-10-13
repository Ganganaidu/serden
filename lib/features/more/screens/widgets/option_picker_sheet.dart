import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../models/company_profile_model.dart';

/// Searchable checklist of [ProfileOption]s (service categories, highlights).
/// Returns the chosen ids, or null when dismissed without tapping "Done".
Future<Set<int>?> showOptionPickerSheet({
  required BuildContext context,
  required String title,
  required String searchHint,
  required List<ProfileOption> options,
  required Set<int> selected,
  int? maxItems,
}) {
  return showModalBottomSheet<Set<int>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.4,
      maxChildSize: 0.94,
      expand: false,
      builder: (_, controller) => _OptionPicker(
        controller: controller,
        title: title,
        searchHint: searchHint,
        options: options,
        selected: Set.of(selected),
        maxItems: maxItems,
      ),
    ),
  );
}

class _OptionPicker extends StatefulWidget {
  final ScrollController controller;
  final String title;
  final String searchHint;
  final List<ProfileOption> options;
  final Set<int> selected;
  final int? maxItems;

  const _OptionPicker({
    required this.controller,
    required this.title,
    required this.searchHint,
    required this.options,
    required this.selected,
    this.maxItems,
  });

  @override
  State<_OptionPicker> createState() => _OptionPickerState();
}

class _OptionPickerState extends State<_OptionPicker> {
  late final Set<int> _selected = widget.selected;
  String _query = '';

  bool get _atLimit =>
      widget.maxItems != null && _selected.length >= widget.maxItems!;

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    // Searching a group name also finds its categories.
    final items = q.isEmpty
        ? widget.options
        : widget.options
              .where(
                (o) =>
                    o.name.toLowerCase().contains(q) ||
                    (o.subtitle ?? '').toLowerCase().contains(q),
              )
              .toList();

    // Material (not a coloured DecoratedBox) so the list tiles' ink shows.
    return Material(
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.grabber,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w800,
                      color: AppColors.orange500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                filled: true,
                fillColor: AppColors.page,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.line),
                ),
              ),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('No matches'))
                : ListView.builder(
                    controller: widget.controller,
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final o = items[i];
                      final checked = _selected.contains(o.id);
                      final disabled = !checked && _atLimit;
                      return Opacity(
                        opacity: disabled ? 0.45 : 1,
                        child: CheckboxListTile(
                          value: checked,
                          onChanged: disabled
                              ? null
                              : (v) => setState(
                                  () => v == true
                                      ? _selected.add(o.id)
                                      : _selected.remove(o.id),
                                ),
                          activeColor: AppColors.green800,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            o.name,
                            style: AppTextStyles.rowTitle.copyWith(
                              fontWeight: checked
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                          subtitle: o.subtitle == null || o.subtitle!.isEmpty
                              ? null
                              : Text(
                                  o.subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption,
                                ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              10 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: Row(
              children: [
                Text(
                  widget.maxItems == null
                      ? '${_selected.length} selected'
                      : '${_selected.length} of ${widget.maxItems} selected',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.green800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(_selected.clear),
                  child: const Text('Clear all'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
