import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/multi_select_sheet.dart';
import '../../../core/widgets/project_picker_field.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../cubit/company_profile_cubit.dart';
import '../models/company_profile_model.dart';

/// Editable public company profile (serden-company-profile design).
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  static const _allHighlights = [
    'Tile',
    'Floor',
    'Showers',
    'Kitchen',
    'Bathroom',
    'Major Remodel',
    'Residential',
    'Free estimates',
    'Building Materials',
    'Restoration',
    'Commercial',
    'Roofing',
    'Waterproofing',
    'Tile2',
  ];
  static const _maxHighlights = 3;

  final _picker = ImagePicker();

  // ── Controllers ─────────────────────────────────────────────────────────────
  final _companyNameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  final _yearFoundedCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _areaServedCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();

  // ── Selection state ─────────────────────────────────────────────────────────
  List<String> _categories = [];
  List<String> _highlights = [];
  bool _listedInDirectory = true;
  bool _dirty = false;

  /// Bare filename from the API (build full URL via AppConstants.proLogoUrl).
  String? _proLogo;

  /// Project photos from the API / just-uploaded photos.
  List<ProPhoto> _projectPhotos = [];

  bool _initializedFromApi = false;
  int? _proId;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyProfileCubit>().load(authState.user.userId);
    }
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _aboutCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _websiteCtrl.dispose();
    _licenseCtrl.dispose();
    _insuranceCtrl.dispose();
    _yearFoundedCtrl.dispose();
    _hoursCtrl.dispose();
    _areaServedCtrl.dispose();
    _facebookCtrl.dispose();
    _instagramCtrl.dispose();
    _linkedInCtrl.dispose();
    _xCtrl.dispose();
    _youtubeCtrl.dispose();
    super.dispose();
  }

  void _seedFromProfile(CompanyProfile p) {
    _proId = p.proId;
    _proLogo = p.proLogo;
    _projectPhotos = List.of(p.projectPhotos);
    _companyNameCtrl.text = p.proName ?? '';
    _aboutCtrl.text = p.aboutCompany ?? '';
    _addressCtrl.text = p.streetAddress ?? '';
    _cityCtrl.text = p.city ?? '';
    _stateCtrl.text = p.state ?? '';
    _zipCtrl.text = p.zipCode ?? '';
    _phoneCtrl.text = p.phone ?? '';
    _emailCtrl.text = p.email ?? '';
    _websiteCtrl.text = p.website ?? '';
    _licenseCtrl.text = p.licenseNumber ?? '';
    _insuranceCtrl.text = p.insuranceNumber ?? '';
    _yearFoundedCtrl.text = p.yearFounded ?? '';
    _hoursCtrl.text = p.businessHours ?? '';
    _areaServedCtrl.text = p.areaServed ?? '';
    _facebookCtrl.text = p.facebookUrl ?? '';
    _instagramCtrl.text = p.instagramUrl ?? '';
    _linkedInCtrl.text = p.linkedInUrl ?? '';
    _xCtrl.text = p.xUrl ?? '';
    _youtubeCtrl.text = p.youtubeUrl ?? '';
    _categories = List.of(p.serviceCategories);
    _highlights = List.of(p.highlights);
    _listedInDirectory = p.listedInDirectory;
  }

  // ── Completion meter ─────────────────────────────────────────────────────────
  int get _completionPercent {
    const total = 13;
    var done = 0;
    if (_companyNameCtrl.text.trim().isNotEmpty) done++;
    if (_aboutCtrl.text.trim().isNotEmpty) done++;
    if (_addressCtrl.text.trim().isNotEmpty) done++;
    if (_cityCtrl.text.trim().isNotEmpty) done++;
    if (_phoneCtrl.text.trim().isNotEmpty) done++;
    if (_emailCtrl.text.trim().isNotEmpty) done++;
    if (_websiteCtrl.text.trim().isNotEmpty) done++;
    if (_licenseCtrl.text.trim().isNotEmpty) done++;
    if (_insuranceCtrl.text.trim().isNotEmpty) done++;
    if (_areaServedCtrl.text.trim().isNotEmpty) done++;
    if (_categories.isNotEmpty) done++;
    if (_highlights.isNotEmpty) done++;
    if (_hoursCtrl.text.trim().isNotEmpty) done++;
    return (done / total * 100).round();
  }

  String get _meterHint {
    final missing = <String>[
      if (_websiteCtrl.text.trim().isEmpty) 'website',
      if (_hoursCtrl.text.trim().isEmpty) 'business hours',
      if (_areaServedCtrl.text.trim().isEmpty) 'area served',
    ];
    if (missing.isEmpty) return 'Profile complete — looking sharp';
    return 'Add your ${missing.take(2).join(' and ')} to finish';
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  void _save() {
    final profile = CompanyProfile(
      proId: _proId,
      proName: _companyNameCtrl.text.trim(),
      aboutCompany: _aboutCtrl.text.trim(),
      streetAddress: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim(),
      zipCode: _zipCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      website: _websiteCtrl.text.trim(),
      licenseNumber: _licenseCtrl.text.trim(),
      insuranceNumber: _insuranceCtrl.text.trim(),
      yearFounded: _yearFoundedCtrl.text.trim(),
      businessHours: _hoursCtrl.text.trim(),
      areaServed: _areaServedCtrl.text.trim(),
      serviceCategories: List.of(_categories),
      highlights: List.of(_highlights),
      facebookUrl: _facebookCtrl.text.trim(),
      instagramUrl: _instagramCtrl.text.trim(),
      linkedInUrl: _linkedInCtrl.text.trim(),
      xUrl: _xCtrl.text.trim(),
      youtubeUrl: _youtubeCtrl.text.trim(),
      listedInDirectory: _listedInDirectory,
    );
    context.read<CompanyProfileCubit>().save(profile);
  }

  // ── Image pickers ─────────────────────────────────────────────────────────────
  Future<void> _pickAndUploadLogo() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    if (_proId == null) return;
    context.read<CompanyProfileCubit>().uploadLogo(_proId!, file.path);
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    if (_proId == null) return;
    context.read<CompanyProfileCubit>().addProjectPhoto(_proId!, file.path);
  }

  Future<ImageSource?> _showImageSourcePicker() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.greenDeep),
              title: const Text(
                'Take photo',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.greenDeep),
              title: const Text(
                'Choose from library',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pickers ──────────────────────────────────────────────────────────────────
  Future<void> _openCategoriesSheet() async {
    final result = await showMultiSelectSheet(
      context: context,
      title: 'Service categories',
      allItems: kProjectCategories,
      selected: _categories,
    );
    if (result != null) {
      setState(() {
        _categories = result;
        _dirty = true;
      });
    }
  }

  Future<void> _openHighlightsSheet() async {
    final result = await showMultiSelectSheet(
      context: context,
      title: 'Highlights',
      allItems: _allHighlights,
      selected: _highlights,
      maxItems: _maxHighlights,
      searchable: false,
    );
    if (result != null) {
      setState(() {
        _highlights = result;
        _dirty = true;
      });
    }
  }

  Future<void> _openAddHighlightSheet() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddHighlightSheet(),
    );
    if (result != null && result.trim().isNotEmpty) {
      final name = result.trim();
      if (_highlights.length < _maxHighlights &&
          !_highlights.contains(name)) {
        setState(() {
          _highlights.add(name);
          _dirty = true;
        });
      }
    }
  }

  // ── URL helpers ──────────────────────────────────────────────────────────────
  String? _logoDisplayUrl() {
    final logo = _proLogo;
    if (logo == null || logo.isEmpty) return null;
    if (logo.startsWith('http')) return logo;
    return AppConstants.proLogoUrl(logo);
  }

  String _photoDisplayUrl(ProPhoto photo) {
    final url = photo.url;
    if (url != null && url.startsWith('http')) return url;
    final fn = photo.fileName;
    if (fn != null && fn.isNotEmpty) return AppConstants.projectPhotoUrl(fn);
    return '';
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyProfileCubit, CompanyProfileState>(
      listener: (context, state) {
        if (state is CompanyProfileLoaded) {
          if (!_initializedFromApi) {
            setState(() {
              _initializedFromApi = true;
              _seedFromProfile(state.profile);
            });
          } else {
            // Keep logo and project photos in sync with cubit state after uploads.
            if (state.profile.proLogo != _proLogo) {
              setState(() => _proLogo = state.profile.proLogo);
            }
            if (state.profile.projectPhotos.length !=
                _projectPhotos.length) {
              setState(() =>
                  _projectPhotos = List.of(state.profile.projectPhotos));
            }
          }
          if (state.justSaved) {
            setState(() => _dirty = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile saved')),
            );
          }
          if (state.saveError != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.saveError!)),
            );
          }
        }
      },
      builder: (context, state) {
        if (state is CompanyProfileLoading && !_initializedFromApi) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _topBar(isSaving: false),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CompanyProfileError && !_initializedFromApi) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _topBar(isSaving: false),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_outlined,
                              size: 42, color: AppColors.inkFaint),
                          const SizedBox(height: 12),
                          Text(state.message,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.inkSoft)),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              final authState =
                                  context.read<AuthBloc>().state;
                              if (authState is AuthAuthenticated) {
                                context
                                    .read<CompanyProfileCubit>()
                                    .load(authState.user.userId);
                              }
                            },
                            child: const Text('Retry'),
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

        final isSaving =
            state is CompanyProfileLoaded && state.isSaving;
        final isUploadingLogo =
            state is CompanyProfileLoaded && state.isUploadingLogo;
        final isUploadingPhoto =
            state is CompanyProfileLoaded && state.isUploadingPhoto;
        final pct = _completionPercent;
        final logoUrl = _logoDisplayUrl();

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(isSaving: isSaving),
                // ── Progress meter ───────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  decoration: const BoxDecoration(
                    border:
                        Border(bottom: BorderSide(color: AppColors.line)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Company profile',
                              style: AppTextStyles.headingMedium),
                          TextButton.icon(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            icon: const Icon(
                                Icons.visibility_outlined,
                                size: 13),
                            label:
                                const Text('View public listing'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
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
                // ── Form ────────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      // Logo
                      const SectionHeader(
                          title: 'Company logo',
                          padding: EdgeInsets.fromLTRB(4, 0, 4, 8)),
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Logo image / placeholder / upload spinner
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: isUploadingLogo
                                    ? Container(
                                        color: AppColors.grayTint,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.greenDeep,
                                          ),
                                        ),
                                      )
                                    : logoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: logoUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) =>
                                                Container(
                                              color: AppColors.grayTint,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color:
                                                      AppColors.greenDeep,
                                                ),
                                              ),
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                _logoPlaceholder(),
                                          )
                                        : _logoPlaceholder(),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: isUploadingLogo
                                      ? null
                                      : _pickAndUploadLogo,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize
                                        .shrinkWrap,
                                    textStyle: const TextStyle(
                                      fontFamily:
                                          AppTextStyles.fontFamily,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: Text(logoUrl != null
                                      ? 'Replace logo'
                                      : 'Upload logo'),
                                ),
                                if (logoUrl != null) ...[
                                  const SizedBox(height: 6),
                                  TextButton(
                                    onPressed: isUploadingLogo
                                        ? null
                                        : () => setState(
                                            () => _proLogo = null),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap,
                                      foregroundColor:
                                          AppColors.inkFaint,
                                      textStyle: const TextStyle(
                                        fontFamily:
                                            AppTextStyles.fontFamily,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: const Text('Remove'),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Company info
                      const SectionHeader(title: 'Company info'),
                      AppCard(
                        child: Column(
                          children: [
                            _field('Company name',
                                hint: 'e.g. Acme Construction LLC',
                                controller: _companyNameCtrl),
                            _field(
                              'About company',
                              hint: 'Describe your company, specialty, and what sets you apart…',
                              controller: _aboutCtrl,
                              maxLines: 5,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      // Location
                      const SectionHeader(title: 'Location'),
                      AppCard(
                        child: Column(
                          children: [
                            _field('Address',
                                hint: '1104 Main St, Ste 610',
                                controller: _addressCtrl),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _labeledField('City',
                                          hint: 'Vancouver',
                                          controller: _cityCtrl)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: _labeledField('State',
                                          hint: 'WA',
                                          controller: _stateCtrl)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: _labeledField(
                                          'Zip code',
                                          hint: '98660',
                                          controller: _zipCtrl)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contact
                      const SectionHeader(title: 'Contact'),
                      AppCard(
                        child: Column(
                          children: [
                            _field('Phone number',
                                hint: '(360) 555-0100',
                                controller: _phoneCtrl),
                            _field('Email address',
                                hint: 'hello@yourcompany.com',
                                controller: _emailCtrl),
                            _field('Website',
                                hint: 'https://yourcompany.com',
                                controller: _websiteCtrl,
                                showDivider: false),
                          ],
                        ),
                      ),

                      // Service categories
                      SectionHeader(
                        title: 'Service categories',
                        trailing:
                            '${_categories.length} selected',
                      ),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (_categories.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final cat in _categories)
                                    _removableChip(
                                      label: cat,
                                      onRemove: () => setState(() {
                                        _categories.remove(cat);
                                        _dirty = true;
                                      }),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            _dropdownTrigger(
                              label: _categories.isEmpty
                                  ? 'Select service categories'
                                  : 'Edit service categories',
                              onTap: _openCategoriesSheet,
                            ),
                          ],
                        ),
                      ),

                      // Highlights
                      SectionHeader(
                        title: 'Highlights',
                        trailing:
                            '${_highlights.length}/$_maxHighlights selected',
                      ),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            if (_highlights.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final h in _highlights)
                                    _removableChip(
                                      label: '✓ $h',
                                      onRemove: () => setState(() {
                                        _highlights.remove(h);
                                        _dirty = true;
                                      }),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            _dropdownTrigger(
                              label: _highlights.isEmpty
                                  ? 'Select highlights'
                                  : 'Edit highlights',
                              onTap: _openHighlightsSheet,
                            ),
                            const Divider(
                                height: 20,
                                thickness: 1,
                                color: AppColors.line),
                            _textTrigger(
                              icon: Icons.add,
                              label: 'Add custom highlight',
                              onTap: _openAddHighlightSheet,
                            ),
                          ],
                        ),
                      ),

                      // Social media
                      const SectionHeader(title: 'Social media'),
                      AppCard(
                        child: Column(
                          children: [
                            _socialRow(Icons.facebook,
                                'https://facebook.com/yourpage',
                                controller: _facebookCtrl),
                            _socialRow(
                                Icons.camera_alt_outlined,
                                'https://instagram.com/yourhandle',
                                controller: _instagramCtrl),
                            _socialRow(
                                Icons.business_center_outlined,
                                'https://linkedin.com/company/yourco',
                                controller: _linkedInCtrl),
                            _socialRow(
                                Icons.close,
                                'https://x.com/yourhandle',
                                controller: _xCtrl),
                            _socialRow(
                                Icons.play_circle_outline,
                                'https://youtube.com/@yourchannel',
                                controller: _youtubeCtrl,
                                showDivider: false),
                          ],
                        ),
                      ),

                      // More info
                      const SectionHeader(title: 'More info'),
                      AppCard(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: AppColors.line)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _labeledField(
                                          'License number',
                                          hint: 'e.g. CCB-123456',
                                          controller:
                                              _licenseCtrl)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: _labeledField(
                                          'Insurance number',
                                          hint: 'e.g. INS-4471820',
                                          controller:
                                              _insuranceCtrl)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: const BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: AppColors.line)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: _labeledField(
                                          'Year founded',
                                          hint: 'e.g. 2018',
                                          controller:
                                              _yearFoundedCtrl)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _labeledField(
                                      'Business hours',
                                      hint: 'Mon–Fri, 8am–5pm',
                                      controller: _hoursCtrl,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _field(
                              'Area served',
                              hint: 'e.g. Vancouver, Camas, Portland metro',
                              controller: _areaServedCtrl,
                              helper:
                                  'Cities or regions where you take jobs.',
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      // Project photos
                      const SectionHeader(title: 'Project photos'),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          height: 80,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final photo in _projectPhotos) ...[
                                _photoBoxFromUrl(
                                    _photoDisplayUrl(photo)),
                                const SizedBox(width: 8),
                              ],
                              if (isUploadingPhoto) ...[
                                _uploadingPhotoBox(),
                                const SizedBox(width: 8),
                              ],
                              _addPhotoBox(
                                  onTap: _pickAndUploadPhoto),
                            ],
                          ),
                        ),
                      ),

                      // Visibility
                      const SectionHeader(title: 'Visibility'),
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'List in public directory',
                                    style: AppTextStyles.rowTitle
                                        .copyWith(fontSize: 14.5),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'When on, your company appears in '
                                        'Serden directory searches for '
                                        'homeowners near you.',
                                    style: AppTextStyles.caption
                                        .copyWith(
                                            fontSize: 12,
                                            height: 1.45),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: _listedInDirectory,
                              onChanged: (v) => setState(() {
                                _listedInDirectory = v;
                                _dirty = true;
                              }),
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
      },
    );
  }

  // ── Top bar ──────────────────────────────────────────────────────────────────
  Widget _topBar({required bool isSaving}) {
    return Padding(
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
          if (isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.orange500,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _dirty ? _save : null,
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
    );
  }

  // ── Logo placeholder ─────────────────────────────────────────────────────────
  Widget _logoPlaceholder() {
    return Container(
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
    );
  }

  // ── Trigger widgets ──────────────────────────────────────────────────────────
  Widget _dropdownTrigger({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.page,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.inkSoft, height: 1.2),
              ),
            ),
            const Icon(Icons.expand_more,
                color: AppColors.inkSoft, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _textTrigger({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.greenDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.greenDeep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _removableChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Material(
      color: AppColors.greenTint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
              const Icon(Icons.close,
                  size: 12, color: AppColors.greenDeep),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field helpers ────────────────────────────────────────────────────────────
  Widget _field(
    String label, {
    required TextEditingController controller,
    String? hint,
    String? helper,
    int maxLines = 1,
    bool showDivider = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labeledField(label,
              controller: controller,
              hint: hint,
              maxLines: maxLines),
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
    String label, {
    required TextEditingController controller,
    String? hint,
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
          maxLines: maxLines,
          onChanged: (_) => setState(() => _dirty = true),
          style: AppTextStyles.rowTitle.copyWith(
            fontSize: 14.5,
            fontWeight:
                maxLines > 1 ? FontWeight.w500 : FontWeight.w600,
            height: maxLines > 1 ? 1.55 : 1.2,
          ),
          decoration: InputDecoration(
            hintText: hint,
            isDense: true,
            filled: true,
            fillColor: AppColors.page,
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.inkFaint, height: 1.2),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 13, vertical: 11),
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
      ],
    );
  }

  Widget _socialRow(
    IconData icon,
    String hint, {
    required TextEditingController controller,
    bool showDivider = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              controller: controller,
              onChanged: (_) => setState(() => _dirty = true),
              style: AppTextStyles.bodySmall
                  .copyWith(fontSize: 13.5, color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hint,
                isDense: true,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Photo box widgets ────────────────────────────────────────────────────────
  Widget _photoBoxFromUrl(String url) {
    return SizedBox(
      width: 80,
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: url.isEmpty
            ? Container(
                color: AppColors.grayTint,
                child: const Icon(Icons.image_outlined,
                    size: 22, color: AppColors.inkFaint),
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.grayTint,
                  child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.greenDeep),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.grayTint,
                  child: const Icon(Icons.broken_image_outlined,
                      size: 22, color: AppColors.inkFaint),
                ),
              ),
      ),
    );
  }

  Widget _uploadingPhotoBox() {
    return SizedBox(
      width: 80,
      height: 80,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grayTint,
          borderRadius: BorderRadius.circular(11),
        ),
        child: const Center(
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.greenDeep),
        ),
      ),
    );
  }

  Widget _addPhotoBox({required VoidCallback onTap}) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
    );
  }
}

// ── Add Highlight Bottom Sheet ─────────────────────────────────────────────────

class _AddHighlightSheet extends StatefulWidget {
  const _AddHighlightSheet();

  @override
  State<_AddHighlightSheet> createState() => _AddHighlightSheetState();
}

class _AddHighlightSheetState extends State<_AddHighlightSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add New Highlight',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close,
                      size: 20, color: AppColors.inkSoft),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Highlight Name',
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,

              textCapitalization: TextCapitalization.words,
              style: AppTextStyles.rowTitle
                  .copyWith(fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hint: Text("e.g. Free Estimates, 24/7 Service",
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.inkFaint)),
                isDense: true,
                filled: true,
                fillColor: AppColors.page,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide:
                      const BorderSide(color: AppColors.line, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(
                      color: AppColors.greenDeep, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.line),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      side: const BorderSide(color: AppColors.line),
                      foregroundColor: AppColors.ink,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final name = _ctrl.text.trim();
                      if (name.isNotEmpty) Navigator.pop(context, name);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.greenDeep,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      textStyle: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Add Highlight'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
