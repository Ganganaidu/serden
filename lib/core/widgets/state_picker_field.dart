import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const List<(String, String)> _kUsStates = [
  ('AL', 'Alabama'), ('AK', 'Alaska'), ('AZ', 'Arizona'), ('AR', 'Arkansas'),
  ('CA', 'California'), ('CO', 'Colorado'), ('CT', 'Connecticut'),
  ('DE', 'Delaware'), ('FL', 'Florida'), ('GA', 'Georgia'),
  ('HI', 'Hawaii'), ('ID', 'Idaho'), ('IL', 'Illinois'), ('IN', 'Indiana'),
  ('IA', 'Iowa'), ('KS', 'Kansas'), ('KY', 'Kentucky'), ('LA', 'Louisiana'),
  ('ME', 'Maine'), ('MD', 'Maryland'), ('MA', 'Massachusetts'),
  ('MI', 'Michigan'), ('MN', 'Minnesota'), ('MS', 'Mississippi'),
  ('MO', 'Missouri'), ('MT', 'Montana'), ('NE', 'Nebraska'),
  ('NV', 'Nevada'), ('NH', 'New Hampshire'), ('NJ', 'New Jersey'),
  ('NM', 'New Mexico'), ('NY', 'New York'), ('NC', 'North Carolina'),
  ('ND', 'North Dakota'), ('OH', 'Ohio'), ('OK', 'Oklahoma'),
  ('OR', 'Oregon'), ('PA', 'Pennsylvania'), ('RI', 'Rhode Island'),
  ('SC', 'South Carolina'), ('SD', 'South Dakota'), ('TN', 'Tennessee'),
  ('TX', 'Texas'), ('UT', 'Utah'), ('VT', 'Vermont'), ('VA', 'Virginia'),
  ('WA', 'Washington'), ('WV', 'West Virginia'), ('WI', 'Wisconsin'),
  ('WY', 'Wyoming'), ('DC', 'Washington D.C.'),
];

/// Read-only field that opens a searchable state-picker bottom sheet when
/// tapped. Writes the selected two-letter abbreviation into [controller].
///
/// Drop-in replacement for a plain TextField wherever a state input is needed.
class StatePickerField extends StatelessWidget {
  final TextEditingController controller;

  const StatePickerField({super.key, required this.controller});

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) =>
            _StatePickerSheet(scrollController: scrollController),
      ),
    );
    if (picked != null) controller.text = picked;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: () => _pick(context),
      style: AppTextStyles.rowTitle.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: 'Select',
        isDense: true,
        filled: true,
        fillColor: AppColors.page,
        hintStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.inkFaint, height: 1.2),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        suffixIconConstraints: const BoxConstraints(maxHeight: 36),
        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 8),
          child: Icon(Icons.expand_more, color: AppColors.inkSoft, size: 18),
        ),
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

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _StatePickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  const _StatePickerSheet({required this.scrollController});

  @override
  State<_StatePickerSheet> createState() => _StatePickerSheetState();
}

class _StatePickerSheetState extends State<_StatePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<(String, String)> _filtered = _kUsStates;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _kUsStates
          : _kUsStates
              .where((s) =>
                  s.$1.toLowerCase().contains(q) ||
                  s.$2.toLowerCase().contains(q))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 16),
          Text('State', style: AppTextStyles.headingSmall),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              autofocus: false,
              style:
                  AppTextStyles.rowTitle.copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Search states…',
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
                  borderSide:
                      const BorderSide(color: AppColors.greenDeep, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No states found',
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
                      final (abbr, name) = _filtered[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '$abbr — $name',
                          style: AppTextStyles.rowTitle
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                        onTap: () => Navigator.pop(context, abbr),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
