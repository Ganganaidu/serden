import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Shows a searchable multi-select bottom sheet.
///
/// Returns the new list of selected items, or null if the sheet was dismissed
/// without tapping "Done".
///
/// [maxItems]: optional upper bound on selections. When the limit is reached,
/// unselected rows are dimmed and their checkboxes are disabled.
///
/// [searchable]: when true (default), a search field is shown.
Future<List<String>?> showMultiSelectSheet({
  required BuildContext context,
  required String title,
  required List<String> allItems,
  required List<String> selected,
  int? maxItems,
  bool searchable = true,
}) {
  return showModalBottomSheet<List<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, sc) => _MultiSelectSheet(
        scrollController: sc,
        title: title,
        allItems: allItems,
        selected: List.of(selected),
        maxItems: maxItems,
        searchable: searchable,
      ),
    ),
  );
}

class _MultiSelectSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String title;
  final List<String> allItems;
  final List<String> selected;
  final int? maxItems;
  final bool searchable;

  const _MultiSelectSheet({
    required this.scrollController,
    required this.title,
    required this.allItems,
    required this.selected,
    this.maxItems,
    this.searchable = true,
  });

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late List<String> _selected;
  late List<String> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = List.of(widget.selected);
    _filtered = widget.allItems;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? widget.allItems
          : widget.allItems.where((s) => s.toLowerCase().contains(q)).toList();
    });
  }

  void _toggle(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else if (widget.maxItems == null ||
          _selected.length < widget.maxItems!) {
        _selected.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final atMax =
        widget.maxItems != null && _selected.length >= widget.maxItems!;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: AppTextStyles.headingSmall),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.orange500,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.maxItems != null
                    ? '${_selected.length}/${widget.maxItems} selected'
                        '${atMax ? ' — max reached' : ''}'
                    : '${_selected.length} selected',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 12.5,
                  color: atMax ? AppColors.orangeDeep : AppColors.inkSoft,
                ),
              ),
            ),
          ),
          if (widget.searchable) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearch,
                autofocus: false,
                style: AppTextStyles.rowTitle
                    .copyWith(fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.inkFaint),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.inkFaint,
                    size: 20,
                  ),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.page,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide:
                        const BorderSide(color: AppColors.line, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                        color: AppColors.greenDeep, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No results',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.inkFaint),
                    ),
                  )
                : ListView.separated(
                    controller: widget.scrollController,
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).padding.bottom + 16,
                    ),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: AppColors.line,
                      indent: 16,
                    ),
                    itemBuilder: (_, i) {
                      final name = _filtered[i];
                      final isSelected = _selected.contains(name);
                      final disabled = !isSelected && atMax;
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: disabled ? null : (_) => _toggle(name),
                        dense: true,
                        title: Text(
                          name,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: disabled
                                ? AppColors.inkFaint
                                : isSelected
                                    ? AppColors.greenDeep
                                    : AppColors.ink,
                          ),
                        ),
                        activeColor: AppColors.greenDeep,
                        checkColor: Colors.white,
                        controlAffinity: ListTileControlAffinity.trailing,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
