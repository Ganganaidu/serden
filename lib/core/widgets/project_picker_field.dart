import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

const List<String> kProjectCategories = [
  'Accountant',
  'Appraiser',
  'Architect',
  'Attorney & Law',
  'Bathroom Remodeler',
  'Cabinets & Woodworking',
  'Carpentry',
  'Chimney Services',
  'Cleaning Services',
  'Concrete & Foundation',
  'Countertops',
  'Decks & Patio Covers',
  'Designer',
  'Door Contractor',
  'Drywall & Plaster',
  'Electricians',
  'Engineer',
  'Excavation',
  'Fence Contractor',
  'Financial Planner',
  'Fire Protection Contractor',
  'Flooring',
  'Framing',
  'Garage Door Contractor',
  'General Contractor',
  'Glass & Mirrors',
  'Gutter Contractor',
  'Handyman',
  'Home Builders',
  'Home Inspectors',
  'HVAC',
  'Insulation',
  'Insurance Agents',
  'Kitchen Remodeler',
  'Landscaping & Lawncare',
  'Loans & Banks',
  'Masonry',
  'Moving Company',
  'Painting',
  'Pest Control',
  'Plumbing',
  'Property Management',
  'Railing Contractor',
  'Real Estate Agents',
  'Remodeling',
  'Roofing',
  'Security',
  'Septic System Contractor',
  'Siding & Exteriors',
  'Solar Energy Contractor',
  'Sunroom Contractor',
  'Surveyor',
  'Swimming Pool Contractor',
  'Tile Contractor',
  'Title & Escrow',
  'Utility Contractor',
  'Wallpaper Contractor',
  'Waterproofing Service',
  'Well Drilling Contractor',
  'Window Contractor',
];

/// Read-only field that opens a searchable project-type bottom sheet.
/// Calls [onChanged] with the selected category name, or null to clear.
class ProjectPickerField extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const ProjectPickerField({
    super.key,
    required this.value,
    required this.onChanged,
  });

  Future<void> _pick(BuildContext context) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => _ProjectPickerSheet(
          scrollController: scrollController,
          currentValue: value,
        ),
      ),
    );
    if (picked == null) return;
    onChanged(picked.isEmpty ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.page,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? 'Select project type',
                style: value != null
                    ? AppTextStyles.rowTitle
                        .copyWith(fontWeight: FontWeight.w600)
                    : AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.inkFaint, height: 1.2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, color: AppColors.inkSoft, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _ProjectPickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  final String? currentValue;

  const _ProjectPickerSheet({
    required this.scrollController,
    this.currentValue,
  });

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<String> _filtered = kProjectCategories;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? kProjectCategories
          : kProjectCategories
              .where((s) => s.toLowerCase().contains(q))
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
          Text('Project type', style: AppTextStyles.headingSmall),
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
                hintText: 'Search project types…',
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
          const Divider(height: 1, color: AppColors.line),
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Text(
                      'No project types found',
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
                      final isSelected = name == widget.currentValue;
                      return ListTile(
                        dense: true,
                        title: Text(
                          name,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppColors.greenDeep
                                : AppColors.ink,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check,
                                color: AppColors.greenDeep, size: 18)
                            : null,
                        onTap: () => Navigator.pop(context, name),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
