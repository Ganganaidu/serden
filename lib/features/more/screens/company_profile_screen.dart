import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';

/// Editable public company profile (serden-company-profile design).
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  static const _allCategories = [
    'Accountant', 'Appraiser', 'Architect', 'Attorney & law',
    'Bathroom remodeler', 'Cabinets & woodworking', 'Carpentry',
    'Chimney services', 'Cleaning services', 'Concrete contractor',
    'Decks & patios', 'Drywall', 'Electrician', 'Fencing', 'Flooring',
    'Garage doors', 'General contractor', 'Handyman', 'Home builder',
    'Home inspector', 'HVAC', 'Insurance agent', 'Kitchen remodeler',
    'Landscaping', 'Painting', 'Plumbing', 'Real estate agent', 'Roofing',
    'Siding', 'Windows & doors',
  ];

  static const _allHighlights = [
    'Tile', 'Floor', 'Showers', 'Kitchen', 'Bathroom',
    'Major remodel', 'Residential', 'Free estimates',
  ];
  static const _maxHighlights = 3;

  final _categories = <String>[
    'General contractor',
    'Kitchen remodeler',
    'Bathroom remodeler',
    'Siding',
  ];
  final _highlights = <String>['Kitchen', 'Bathroom', 'Major remodel'];

  final _website = TextEditingController();
  final _hours = TextEditingController();
  String _categorySearch = '';
  bool _dirty = false;
  bool _listedInDirectory = true;

  @override
  void initState() {
    super.initState();
    _website.addListener(() => setState(() {}));
    _hours.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _website.dispose();
    _hours.dispose();
    super.dispose();
  }

  int get _completionPercent {
    // 13 profile checks as in the design; website and hours start empty.
    const filled = 11;
    var done = filled;
    if (_website.text.trim().isNotEmpty) done++;
    if (_hours.text.trim().isNotEmpty) done++;
    return (done / 13 * 100).round();
  }

  String get _meterHint {
    final missing = <String>[
      if (_website.text.trim().isEmpty) 'website',
      if (_hours.text.trim().isEmpty) 'business hours',
    ];
    if (missing.isEmpty) return 'Profile complete — looking sharp';
    return 'Add your ${missing.join(' and ')} to finish';
  }

  void _markDirty() => setState(() => _dirty = true);

  @override
  Widget build(BuildContext context) {
    final pct = _completionPercent;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 6, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: const [
                        Icon(Icons.arrow_back_ios_new,
                            size: 14, color: AppColors.inkSoft),
                        SizedBox(width: 4),
                        Text(
                          'More',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _dirty
                        ? () => setState(() => _dirty = false)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.orange500,
                      disabledForegroundColor: AppColors.inkFaint,
                      textStyle: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Company profile',
                          style: AppTextStyles.headingMedium),
                      TextButton.icon(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: const TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 13),
                        label: const Text('View public listing'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pct% complete',
                        style: const TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Complete profiles get more leads',
                        style: AppTextStyles.caption
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 7,
                      backgroundColor: AppColors.grayTint,
                      color: AppColors.greenDeep,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _meterHint,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: pct >= 100
                          ? AppColors.greenDeep
                          : AppColors.orangeDeep,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  const SectionHeader(
                      title: 'Company logo',
                      padding: EdgeInsets.fromLTRB(4, 0, 4, 8)),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                color: AppColors.docNavy,
                                child: const Text(
                                  'S',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'SERDEN',
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                  color: AppColors.docNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Replace logo'),
                            ),
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                foregroundColor: AppColors.inkFaint,
                                textStyle: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Company info'),
                  AppCard(
                    child: Column(
                      children: [
                        _field('Company name', 'Serden Group LLC'),
                        _field(
                          'About company',
                          'Serden Group LLC is a leading general contractor '
                              'specializing in kitchen and bathroom remodels, as '
                              'well as siding installations in the Vancouver, WA '
                              'area. With years of experience and a team of '
                              'skilled professionals, we are dedicated to '
                              'providing high-quality craftsmanship and '
                              'exceptional customer service.',
                          maxLines: 5,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Location'),
                  AppCard(
                    child: Column(
                      children: [
                        _field('Address', '1104 Main St, Ste 610'),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                  child: _labeledField('City', 'Vancouver')),
                              const SizedBox(width: 10),
                              Expanded(child: _labeledField('State', 'WA')),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _labeledField('Zip code', '98660')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Contact'),
                  AppCard(
                    child: Column(
                      children: [
                        _field('Phone number', '(360) 836-7775'),
                        _field('Email address', 'serdengroup@gmail.com'),
                        _field('Website', '',
                            hint: 'https://yourcompany.com',
                            controller: _website,
                            showDivider: false),
                      ],
                    ),
                  ),
                  SectionHeader(
                    title: 'Service categories',
                    trailing: '${_categories.length} selected',
                  ),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final category in _categories)
                              _selectedChip(category),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          onChanged: (v) =>
                              setState(() => _categorySearch = v),
                          style: AppTextStyles.bodySmall
                              .copyWith(fontSize: 13.5, height: 1.2),
                          decoration: InputDecoration(
                            hintText: 'Search categories to add',
                            prefixIcon: const Icon(Icons.search,
                                size: 15, color: AppColors.inkFaint),
                            isDense: true,
                            filled: true,
                            fillColor: AppColors.page,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 9),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: const BorderSide(
                                  color: AppColors.line, width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(11),
                              borderSide: const BorderSide(
                                  color: AppColors.greenDeep, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _categoryOptions(),
                      ],
                    ),
                  ),
                  SectionHeader(
                    title: 'Highlights',
                    trailing:
                        '${_highlights.length}/$_maxHighlights selected',
                  ),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final highlight in _allHighlights)
                          _highlightChip(highlight),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Social media'),
                  AppCard(
                    child: Column(
                      children: [
                        _socialRow(Icons.facebook, 'Facebook URL'),
                        _socialRow(Icons.camera_alt_outlined, 'Instagram URL'),
                        _socialRow(Icons.business_center_outlined,
                            'LinkedIn URL'),
                        _socialRow(Icons.close, 'X.com URL'),
                        _socialRow(Icons.play_circle_outline, 'YouTube URL',
                            showDivider: false),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'More info'),
                  AppCard(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: AppColors.line)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  child: _labeledField(
                                      'License number', 'SERDEGL826PD')),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _labeledField(
                                      'Insurance number', 'INS-4471820')),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: AppColors.line)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                  child:
                                      _labeledField('Year founded', '2018')),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _labeledField(
                                  'Business hours',
                                  '',
                                  hint: 'Mon–Fri, 8am–5pm',
                                  controller: _hours,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _field(
                          'Area served',
                          'Vancouver, Camas, Portland metro',
                          helper: 'Cities or regions where you take jobs.',
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Project photos'),
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _photoBox(),
                        const SizedBox(width: 8),
                        _photoBox(),
                        const SizedBox(width: 8),
                        _photoBox(),
                        const SizedBox(width: 8),
                        _addPhotoBox(),
                      ],
                    ),
                  ),
                  const SectionHeader(title: 'Visibility'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('List in public directory',
                                  style: AppTextStyles.rowTitle
                                      .copyWith(fontSize: 14.5)),
                              const SizedBox(height: 3),
                              Text(
                                'When on, your company appears in Serden directory searches for homeowners near you.',
                                style: AppTextStyles.caption
                                    .copyWith(fontSize: 12, height: 1.45),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Switch(
                          value: _listedInDirectory,
                          onChanged: (v) {
                            setState(() => _listedInDirectory = v);
                            _markDirty();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryOptions() {
    final q = _categorySearch.trim().toLowerCase();
    final options = _allCategories
        .where((c) =>
            !_categories.contains(c) &&
            (q.isEmpty || c.toLowerCase().contains(q)))
        .take(q.isEmpty ? 8 : 30)
        .toList();

    if (options.isEmpty) {
      return Text('No matching category.',
          style: AppTextStyles.caption.copyWith(fontSize: 12.5));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ActionChip(
            label: Text('+ $option'),
            labelStyle: AppTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w600),
            backgroundColor: AppColors.page,
            shape: const StadiumBorder(
                side: BorderSide(color: AppColors.line)),
            onPressed: () {
              setState(() => _categories.add(option));
              _markDirty();
            },
          ),
      ],
    );
  }

  Widget _selectedChip(String label) {
    return Material(
      color: AppColors.greenTint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () {
          setState(() => _categories.remove(label));
          _markDirty();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenDeep,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 12, color: AppColors.greenDeep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _highlightChip(String label) {
    final selected = _highlights.contains(label);
    return Material(
      color: selected ? AppColors.greenTint : AppColors.page,
      shape: StadiumBorder(
        side: BorderSide(
            color: selected ? AppColors.greenTint : AppColors.line),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            if (selected) {
              _highlights.remove(label);
            } else if (_highlights.length < _maxHighlights) {
              _highlights.add(label);
            }
          });
          _markDirty();
        },
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            selected ? '✓ $label' : label,
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected ? AppColors.greenDeep : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    String value, {
    String? hint,
    String? helper,
    TextEditingController? controller,
    int maxLines = 1,
    bool showDivider = true,
  }) {
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
          _labeledField(label, value,
              hint: hint, controller: controller, maxLines: maxLines),
          if (helper != null) ...[
            const SizedBox(height: 5),
            Text(helper,
                style: AppTextStyles.caption
                    .copyWith(fontSize: 11.5, height: 1.45)),
          ],
        ],
      ),
    );
  }

  Widget _labeledField(
    String label,
    String value, {
    String? hint,
    TextEditingController? controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: controller == null ? value : null,
          maxLines: maxLines,
          onChanged: (_) => _markDirty(),
          style: AppTextStyles.rowTitle.copyWith(
            fontSize: 14.5,
            fontWeight: maxLines > 1 ? FontWeight.w500 : FontWeight.w600,
            height: maxLines > 1 ? 1.55 : 1.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
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
        ),
      ],
    );
  }

  Widget _socialRow(IconData icon, String hint, {bool showDivider = true}) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.grayTint,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: AppColors.inkSoft),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (_) => _markDirty(),
              style: AppTextStyles.bodySmall
                  .copyWith(fontSize: 13.5, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoBox() {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.grayTint,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(Icons.image_outlined,
              size: 22, color: AppColors.inkFaint),
        ),
      ),
    );
  }

  Widget _addPhotoBox() {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(11),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.inkFaint,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add, size: 18, color: AppColors.inkSoft),
                  SizedBox(height: 2),
                  Text(
                    'Add photo',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
