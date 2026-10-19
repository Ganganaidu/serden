import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../cubit/company_profile_cubit.dart';
import '../models/company_profile_model.dart';
import 'widgets/area_search_sheet.dart';
import 'widgets/option_picker_sheet.dart';

/// Editable public company listing. Mirrors the web "Directory listing" page
/// (MyCompany.razor): same fields, same validation, same endpoints.
class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  static const _maxHighlights = 3;
  static const _maxAreas = 100;
  static const _customHours = 'Custom';
  static const _presetHours = [
    '24 Hours',
    'Mon-Fri 9AM-6PM',
    'Mon-Fri 8AM-5PM',
    'Mon-Fri 8AM-6PM',
    'Mon-Sat 9AM-6PM',
    'Mon-Sat 8AM-5PM',
    'Mon-Sun 9AM-6PM',
    'Mon-Sun 8AM-8PM',
  ];
  static final _zipPattern = RegExp(r'^\d{5}(-\d{4})?$');
  static final _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final _picker = ImagePicker();
  final _scrollCtrl = ScrollController();

  // ── Controllers ─────────────────────────────────────────────────────────────
  final _companyNameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _stateCtrl =
      TextEditingController(); // only when the state list failed to load
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  final _yearFoundedCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _xCtrl = TextEditingController();
  final _youtubeCtrl = TextEditingController();

  // Scroll targets for validation errors and the checklist.
  final _keys = <String, GlobalKey>{
    for (final k in const [
      'name',
      'phone',
      'email',
      'street',
      'zip',
      'city',
      'state',
      'year',
      'categories',
      'logo',
      'about',
      'highlights',
      'areas',
      'photos',
      'visibility',
    ])
      k: GlobalKey(),
  };

  // ── Form state ──────────────────────────────────────────────────────────────
  CompanyProfile _base = const CompanyProfile();
  ProfileCatalogs _catalogs = const ProfileCatalogs();
  String _state = '';
  String _hoursOption = '';
  Set<int> _categoryIds = {};
  Set<int> _tagIds = {};
  List<ServiceArea> _areas = [];
  bool _areasReady = false;
  bool _isInDirectory = true;
  String? _proLogo;
  String? _pendingLogoPath;
  List<ProPhoto> _projectPhotos = [];
  final Map<String, String> _errors = {};
  bool _dirty = false;
  bool _checklistOpen = false;
  bool _initialized = false;
  int _lastSavedCount = 0;

  bool get _isNew => _base.isNew;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<CompanyProfileCubit>().load(authState.user.userId);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _editTick.dispose();
    for (final c in [
      _companyNameCtrl,
      _aboutCtrl,
      _addressCtrl,
      _cityCtrl,
      _zipCtrl,
      _stateCtrl,
      _phoneCtrl,
      _emailCtrl,
      _websiteCtrl,
      _licenseCtrl,
      _insuranceCtrl,
      _yearFoundedCtrl,
      _hoursCtrl,
      _facebookCtrl,
      _instagramCtrl,
      _linkedInCtrl,
      _xCtrl,
      _youtubeCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _seedFromProfile(CompanyProfile p, ProfileCatalogs catalogs) {
    _base = p;
    _catalogs = catalogs;
    _proLogo = p.proLogo;
    _pendingLogoPath = null;
    _projectPhotos = List.of(p.projectPhotos);
    _companyNameCtrl.text = p.proName;
    _aboutCtrl.text = p.aboutCompany;
    _addressCtrl.text = p.streetAddress;
    _cityCtrl.text = p.city;
    _state = p.state;
    _stateCtrl.text = p.state;
    _zipCtrl.text = p.zipCode;
    _phoneCtrl.text = p.phone;
    _emailCtrl.text = p.email;
    _websiteCtrl.text = p.website;
    _licenseCtrl.text = p.licenseNumber;
    _insuranceCtrl.text = p.insuranceNumber;
    _yearFoundedCtrl.text = p.yearFounded?.toString() ?? '';
    _hoursCtrl.text = p.businessHours;
    _hoursOption = p.businessHours.isEmpty
        ? ''
        : (_presetHours.contains(p.businessHours)
              ? p.businessHours
              : _customHours);
    _facebookCtrl.text = p.facebookUrl;
    _instagramCtrl.text = p.instagramUrl;
    _linkedInCtrl.text = p.linkedInUrl;
    _xCtrl.text = p.twitterUrl;
    _youtubeCtrl.text = p.youTubeUrl;
    _categoryIds = p.categoryIds.toSet();
    _tagIds = p.serviceTagIds.toSet();
    _areas = List.of(p.serviceAreas);
    _areasReady = p.areasReady;
    _isInDirectory = p.isInDirectory;
    _errors.clear();
    _dirty = false;
  }

  CompanyProfile _buildProfile() => CompanyProfile(
    proId: _base.proId,
    userId: _base.userId,
    serdenProId: _base.serdenProId,
    slug: _base.slug,
    publicId: _base.publicId,
    isActive: _base.isActive,
    addressLine2: _base.addressLine2,
    latitude: _base.latitude,
    longitude: _base.longitude,
    proName: _companyNameCtrl.text.trim(),
    aboutCompany: _aboutCtrl.text.trim(),
    streetAddress: _addressCtrl.text.trim(),
    city: _cityCtrl.text.trim(),
    state: _state.trim(),
    zipCode: _zipCtrl.text.trim(),
    phone: _phoneCtrl.text.trim(),
    email: _emailCtrl.text.trim(),
    website: _websiteCtrl.text.trim(),
    licenseNumber: _licenseCtrl.text.trim(),
    insuranceNumber: _insuranceCtrl.text.trim(),
    yearFounded: int.tryParse(_yearFoundedCtrl.text.trim()),
    businessHours: _hoursCtrl.text.trim(),
    facebookUrl: _facebookCtrl.text.trim(),
    instagramUrl: _instagramCtrl.text.trim(),
    linkedInUrl: _linkedInCtrl.text.trim(),
    twitterUrl: _xCtrl.text.trim(),
    youTubeUrl: _youtubeCtrl.text.trim(),
    isInDirectory: _isInDirectory,
    proLogo: _proLogo,
    categoryIds: _categoryIds.toList(),
    serviceTagIds: _tagIds.toList(),
    serviceAreas: List.of(_areas),
    areasReady: _areasReady,
    projectPhotos: _projectPhotos,
  );

  /// Bumped on every edit so the checklist updates without rebuilding the
  /// whole page per keystroke.
  final _editTick = ValueNotifier<int>(0);

  void _markDirty() {
    _editTick.value++;
    if (!_dirty) setState(() => _dirty = true);
  }

  // ── Validation (same rules as the web form) ─────────────────────────────────
  bool _validate() {
    final e = <String, String>{};
    if (_companyNameCtrl.text.trim().isEmpty) {
      e['name'] = 'Enter your company name.';
    }
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (_phoneCtrl.text.trim().isEmpty) {
      e['phone'] = 'Enter a phone number so customers can reach you.';
    } else if (digits.length != 10) {
      e['phone'] = 'Enter a 10-digit phone number, like (512) 555-0142.';
    }
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty && !_emailPattern.hasMatch(email)) {
      e['email'] = 'Enter a valid email address, like hello@yourcompany.com.';
    }
    if (_addressCtrl.text.trim().isEmpty) {
      e['street'] = 'Enter your street address.';
    }
    final zip = _zipCtrl.text.trim();
    if (zip.isEmpty) {
      e['zip'] = 'Enter your ZIP code.';
    } else if (!_zipPattern.hasMatch(zip)) {
      e['zip'] = 'Enter a 5-digit ZIP code.';
    }
    if (_cityCtrl.text.trim().isEmpty) e['city'] = 'Enter your city.';
    if (_state.trim().isEmpty) e['state'] = 'Choose your state.';
    final yearText = _yearFoundedCtrl.text.trim();
    if (yearText.isNotEmpty) {
      final year = int.tryParse(yearText);
      final now = DateTime.now().year;
      if (year == null || year < 1800 || year > now) {
        e['year'] = 'Enter a year between 1800 and $now.';
      }
    }
    setState(() {
      _errors
        ..clear()
        ..addAll(e);
    });
    return e.isEmpty;
  }

  void _scrollTo(String key) {
    final ctx = _keys[key]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        alignment: 0.1,
      );
    }
  }

  // ── Save ────────────────────────────────────────────────────────────────────
  void _save() {
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      const order = [
        'name',
        'phone',
        'email',
        'street',
        'zip',
        'city',
        'state',
        'year',
      ];
      _scrollTo(order.firstWhere(_errors.containsKey));
      return;
    }
    if (_tagIds.length > _maxHighlights) {
      _snack('You can choose up to $_maxHighlights highlights.');
      return;
    }
    context.read<CompanyProfileCubit>().save(
      _buildProfile(),
      pendingLogoPath: _pendingLogoPath,
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // ── ZIP lookup ──────────────────────────────────────────────────────────────
  Future<void> _onZipChanged(String value) async {
    _markDirty();
    final zip = value.trim();
    if (zip.length < 5 || !RegExp(r'^\d{5}').hasMatch(zip)) return;
    final info = await context.read<CompanyProfileCubit>().lookupZip(
      zip.substring(0, 5),
    );
    if (!mounted ||
        info == null ||
        !_zipCtrl.text.trim().startsWith(zip.substring(0, 5))) {
      return;
    }
    setState(() {
      _cityCtrl.text = info.$1;
      if (_catalogs.states.containsKey(info.$2)) _state = info.$2;
      _errors
        ..remove('city')
        ..remove('state');
    });
  }

  // ── Image pickers ───────────────────────────────────────────────────────────
  Future<void> _pickLogo() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 85);
    if (file == null || !mounted) return;
    final tooBig = await File(file.path).length() > 5 * 1024 * 1024;
    if (!mounted) return;
    if (tooBig) {
      _snack('Images can be up to 5 MB.');
      return;
    }
    if (_isNew) {
      // No listing to upload against yet; it is uploaded right after the first save.
      setState(() {
        _pendingLogoPath = file.path;
        _dirty = true;
      });
    } else {
      context.read<CompanyProfileCubit>().uploadLogo(file.path);
    }
  }

  Future<void> _pickPhotos() async {
    final source = await _showImageSourcePicker();
    if (source == null) return;
    final List<XFile> files;
    if (source == ImageSource.gallery) {
      files = await _picker.pickMultiImage(imageQuality: 85, limit: 20);
    } else {
      final f = await _picker.pickImage(source: source, imageQuality: 85);
      files = f == null ? [] : [f];
    }
    if (files.isEmpty || !mounted) return;
    final ok = <String>[];
    for (final f in files) {
      if (await File(f.path).length() > 5 * 1024 * 1024) {
        _snack('${f.name} is over 5 MB and was skipped.');
      } else {
        ok.add(f.path);
      }
    }
    if (ok.isNotEmpty && mounted) {
      context.read<CompanyProfileCubit>().addProjectPhotos(ok);
    }
  }

  Future<bool> _confirm(String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deletePhoto(ProPhoto photo) async {
    if (await _confirm('Delete this photo from your listing?', 'Delete') &&
        mounted) {
      context.read<CompanyProfileCubit>().deleteProjectPhoto(photo.photoId);
    }
  }

  Future<void> _removeLogo() async {
    if (_pendingLogoPath != null) {
      setState(() => _pendingLogoPath = null);
      return;
    }
    if (await _confirm('Remove your logo from your listing?', 'Remove') &&
        mounted) {
      context.read<CompanyProfileCubit>().removeLogo();
    }
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
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.greenDeep,
                ),
                title: const Text(
                  'Take photo',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.greenDeep,
                ),
                title: const Text(
                  'Choose from library',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Pickers ─────────────────────────────────────────────────────────────────
  Future<void> _openCategories() async {
    final result = await showOptionPickerSheet(
      context: context,
      title: 'Service categories',
      searchHint:
          'Search ${_catalogs.categories.length} categories, e.g. Roofing',
      options: _catalogs.categories,
      selected: _categoryIds,
    );
    if (result != null) {
      setState(() {
        _categoryIds = result;
        _dirty = true;
      });
    }
  }

  Future<void> _openHighlights() async {
    final result = await showOptionPickerSheet(
      context: context,
      title: 'Highlights',
      searchHint: 'Search highlights, e.g. Free estimates',
      options: _catalogs.highlights,
      selected: _tagIds,
      maxItems: _maxHighlights,
    );
    if (result != null) {
      setState(() {
        _tagIds = result;
        _dirty = true;
      });
    }
  }

  Future<void> _addArea() async {
    if (_areas.length >= _maxAreas) {
      _snack('You can add up to $_maxAreas areas.');
      return;
    }
    final cubit = context.read<CompanyProfileCubit>();
    final area = await showAreaSearchSheet(
      context: context,
      search: cubit.searchLocations,
      freeText: !_areasReady,
    );
    if (area == null) return;
    final duplicate = _areas.any(
      (a) => area.locationId != null
          ? a.locationId == area.locationId
          : a.areaName.toLowerCase() == area.areaName.toLowerCase(),
    );
    if (!duplicate) {
      setState(() {
        _areas.add(area);
        _dirty = true;
      });
    }
  }

  // ── Checklist (same ten items as the web "Listing checklist") ───────────────
  List<({String label, bool done, String key})> get _checklist => [
    (
      label: 'Company name',
      done: _companyNameCtrl.text.trim().isNotEmpty,
      key: 'name',
    ),
    (
      label: 'Phone number',
      done: _phoneCtrl.text.replaceAll(RegExp(r'\D'), '').length == 10,
      key: 'phone',
    ),
    (
      label: 'Business address',
      done:
          _addressCtrl.text.trim().isNotEmpty &&
          _cityCtrl.text.trim().isNotEmpty &&
          _state.isNotEmpty &&
          _zipCtrl.text.trim().isNotEmpty,
      key: 'street',
    ),
    (
      label: 'Service categories',
      done: _categoryIds.isNotEmpty,
      key: 'categories',
    ),
    (
      label: 'Logo',
      done: _pendingLogoPath != null || (_proLogo ?? '').isNotEmpty,
      key: 'logo',
    ),
    (
      label: 'About your company',
      done: _aboutCtrl.text.trim().isNotEmpty,
      key: 'about',
    ),
    (label: 'Highlights', done: _tagIds.isNotEmpty, key: 'highlights'),
    (label: 'Areas served', done: _areas.isNotEmpty, key: 'areas'),
    (label: 'Project photos', done: _projectPhotos.isNotEmpty, key: 'photos'),
    (label: 'Shown in the directory', done: _isInDirectory, key: 'visibility'),
  ];

  // ── URL helpers ─────────────────────────────────────────────────────────────
  String? _logoNetworkUrl() {
    final logo = _proLogo;
    if (logo == null || logo.isEmpty) return null;
    return logo.startsWith('http') ? logo : AppConstants.proLogoUrl(logo);
  }

  String _photoUrl(ProPhoto p) =>
      AppConstants.proProjectPhotoUrl(p.proId, p.fileName);

  String _optionName(List<ProfileOption> options, int id) {
    for (final o in options) {
      if (o.id == id) return o.name;
    }
    return '';
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompanyProfileCubit, CompanyProfileState>(
      listener: (context, state) {
        if (state is! CompanyProfileLoaded) return;
        if (!_initialized) {
          setState(() {
            _initialized = true;
            _lastSavedCount = state.savedCount;
            _seedFromProfile(state.profile, state.catalogs);
          });
        } else if (state.savedCount != _lastSavedCount) {
          // A save finished: show what the server stored (ids, slug, areas).
          setState(() {
            _lastSavedCount = state.savedCount;
            _seedFromProfile(state.profile, state.catalogs);
          });
          // First publish creates the Pro: hand the new proId to the session
          // so estimates, invoices and clients stop asking for a profile.
          final newProId = state.profile.proId;
          if (newProId != null && newProId != 0) {
            context.read<AuthBloc>().add(AuthProIdUpdated(newProId));
          }
          _snack(
            state.profile.isInDirectory
                ? 'Saved. Your changes are live in the directory.'
                : 'Saved. Your company is hidden from the directory.',
          );
        } else {
          // Logo / photo uploads and deletes happen outside the form.
          setState(() {
            _proLogo = state.profile.proLogo;
            _projectPhotos = List.of(state.profile.projectPhotos);
          });
        }
        if (state.saveError != null) _snack(state.saveError!);
      },
      builder: (context, state) {
        if (!_initialized && state is! CompanyProfileError) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _topBar(isSaving: false, canSave: false),
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is CompanyProfileError && !_initialized) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  _topBar(isSaving: false, canSave: false),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 42,
                            color: AppColors.inkFaint,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.inkSoft,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _load,
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

        final loaded = state is CompanyProfileLoaded ? state : null;
        final isSaving = loaded?.isSaving ?? false;
        final isUploadingLogo = loaded?.isUploadingLogo ?? false;
        final isUploadingPhoto = loaded?.isUploadingPhoto ?? false;
        final logoUrl = _logoNetworkUrl();
        final hasLogo = _pendingLogoPath != null || logoUrl != null;

        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _topBar(isSaving: isSaving, canSave: _dirty || _isNew),
                _statusHeader(),
                Expanded(
                  child: ListView(
                    controller: _scrollCtrl,
                    // The page is a form of ~3,500px. Building it all once avoids
                    // re-creating text fields and chip rows as they scroll into
                    // view, and keeps every section reachable by the checklist.
                    scrollCacheExtent: const ScrollCacheExtent.pixels(6000),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: _editTick,
                        builder: (_, __, ___) => _checklistCard(),
                      ),

                      // Logo
                      SectionHeader(
                        key: _keys['logo'],
                        title: 'Company logo',
                        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                      ),
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
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
                                        : _pendingLogoPath != null
                                        ? Image.file(
                                            File(_pendingLogoPath!),
                                            cacheWidth: 220,
                                            fit: BoxFit.cover,
                                          )
                                        : logoUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: logoUrl,
                                            memCacheWidth: 220,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(
                                              color: AppColors.grayTint,
                                            ),
                                            errorWidget: (_, __, ___) =>
                                                _logoPlaceholder(),
                                          )
                                        : _logoPlaceholder(),
                                  ),
                                ),
                                if (hasLogo && !isUploadingLogo)
                                  Positioned(
                                    top: -7,
                                    right: -7,
                                    child: GestureDetector(
                                      onTap: _removeLogo,
                                      child: Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: AppColors.green800,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _linkButton(
                                    hasLogo ? 'Replace logo' : 'Upload logo',
                                    isUploadingLogo ? null : _pickLogo,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isNew
                                        ? 'Uploads when you save your listing. JPG, PNG, GIF or WebP, up to 5 MB.'
                                        : 'JPG, PNG, GIF or WebP, up to 5 MB.',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Company info
                      const SectionHeader(title: 'Company info'),
                      AppCard(
                        child: Column(
                          children: [
                            _field(
                              'Company name',
                              fieldKey: 'name',
                              hint: 'e.g. Acme Construction LLC',
                              controller: _companyNameCtrl,
                            ),
                            _field(
                              'About company',
                              fieldKey: 'about',
                              hint:
                                  'Describe your company, specialty, and what sets you apart…',
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
                            _field(
                              'Street address',
                              fieldKey: 'street',
                              hint: '1104 Main St, Ste 610',
                              controller: _addressCtrl,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: _labeledField(
                                      'ZIP code',
                                      fieldKey: 'zip',
                                      hint: '98660',
                                      controller: _zipCtrl,
                                      keyboardType: TextInputType.number,
                                      formatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'[0-9-]'),
                                        ),
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                      onChanged: _onZipChanged,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 5,
                                    child: _labeledField(
                                      'City',
                                      fieldKey: 'city',
                                      hint: 'Vancouver',
                                      controller: _cityCtrl,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(flex: 4, child: _stateField()),
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
                            _field(
                              'Phone number',
                              fieldKey: 'phone',
                              hint: '(360) 555-0100',
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              formatters: [_PhoneFormatter()],
                            ),
                            _field(
                              'Email address',
                              fieldKey: 'email',
                              hint: 'hello@yourcompany.com',
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            _field(
                              'Website',
                              hint: 'https://yourcompany.com',
                              controller: _websiteCtrl,
                              keyboardType: TextInputType.url,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      // Service categories
                      SectionHeader(
                        key: _keys['categories'],
                        title: 'Service categories',
                        trailing: '${_categoryIds.length} selected',
                      ),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Choose every category that fits your work. Customers browsing a category will find you there.',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_categoryIds.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final id in _categoryIds)
                                    _removableChip(
                                      label: _optionName(
                                        _catalogs.categories,
                                        id,
                                      ),
                                      onRemove: () => setState(() {
                                        _categoryIds.remove(id);
                                        _dirty = true;
                                      }),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            _dropdownTrigger(
                              label: _categoryIds.isEmpty
                                  ? 'Select service categories'
                                  : 'Edit service categories',
                              onTap: _openCategories,
                            ),
                          ],
                        ),
                      ),

                      // Highlights
                      SectionHeader(
                        key: _keys['highlights'],
                        title: 'Highlights',
                        trailing: '${_tagIds.length}/$_maxHighlights selected',
                      ),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Short tags shown on your listing, like “Free estimates” or “Residential”.',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_tagIds.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final id in _tagIds)
                                    _removableChip(
                                      label: _optionName(
                                        _catalogs.highlights,
                                        id,
                                      ),
                                      onRemove: () => setState(() {
                                        _tagIds.remove(id);
                                        _dirty = true;
                                      }),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            _dropdownTrigger(
                              label: _tagIds.isEmpty
                                  ? 'Select highlights'
                                  : 'Edit highlights',
                              onTap: _openHighlights,
                            ),
                          ],
                        ),
                      ),

                      // Areas served
                      SectionHeader(
                        key: _keys['areas'],
                        title: 'Areas served',
                        trailing: '${_areas.length} added',
                      ),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add each city, county, state or ZIP code you work in. Customers searching any of them will find you.',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_areas.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final a in _areas)
                                    _removableChip(
                                      label: a.typeLabel == null
                                          ? a.areaName
                                          : '${a.areaName} · ${a.typeLabel}',
                                      onRemove: () => setState(() {
                                        _areas.remove(a);
                                        _dirty = true;
                                      }),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            _dropdownTrigger(
                              label: _areasReady
                                  ? 'Type a city, county, state or ZIP code'
                                  : 'Add an area served',
                              icon: Icons.search,
                              onTap: _addArea,
                            ),
                          ],
                        ),
                      ),

                      // Social media
                      const SectionHeader(title: 'Social profiles'),
                      AppCard(
                        child: Column(
                          children: [
                            _socialRow(
                              Icons.facebook,
                              'facebook.com/yourcompany',
                              controller: _facebookCtrl,
                            ),
                            _socialRow(
                              Icons.camera_alt_outlined,
                              'instagram.com/yourcompany',
                              controller: _instagramCtrl,
                            ),
                            _socialRow(
                              Icons.business_center_outlined,
                              'linkedin.com/company/yourcompany',
                              controller: _linkedInCtrl,
                            ),
                            _socialRow(
                              Icons.close,
                              'x.com/yourcompany',
                              controller: _xCtrl,
                            ),
                            _socialRow(
                              Icons.play_circle_outline,
                              'youtube.com/@yourcompany',
                              controller: _youtubeCtrl,
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),

                      // More details
                      const SectionHeader(title: 'More details'),
                      AppCard(
                        child: Column(
                          children: [
                            _pairRow(
                              _labeledField(
                                'License number',
                                hint: 'e.g. CCB-123456',
                                controller: _licenseCtrl,
                              ),
                              _labeledField(
                                'Insurance policy number',
                                hint: 'e.g. INS-4471820',
                                controller: _insuranceCtrl,
                              ),
                            ),
                            _pairRow(
                              _labeledField(
                                'Year founded',
                                fieldKey: 'year',
                                hint: 'e.g. 2009',
                                controller: _yearFoundedCtrl,
                                keyboardType: TextInputType.number,
                                formatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                              ),
                              _hoursField(),
                              last: _hoursOption != _customHours,
                            ),
                            if (_hoursOption == _customHours)
                              _field(
                                'Custom business hours',
                                hint:
                                    'e.g. Mon–Fri 8am–5pm, Sat by appointment',
                                controller: _hoursCtrl,
                                showDivider: false,
                              ),
                          ],
                        ),
                      ),

                      // Project photos
                      SectionHeader(
                        key: _keys['photos'],
                        title: 'Project photos',
                        trailing: '${_projectPhotos.length}',
                      ),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 84,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (final photo in _projectPhotos) ...[
                                    _photoBox(photo),
                                    const SizedBox(width: 8),
                                  ],
                                  if (isUploadingPhoto) ...[
                                    _uploadingPhotoBox(),
                                    const SizedBox(width: 8),
                                  ],
                                  _addPhotoBox(
                                    onTap: _isNew || isUploadingPhoto
                                        ? null
                                        : _pickPhotos,
                                  ),
                                ],
                              ),
                            ),
                            if (_isNew) ...[
                              const SizedBox(height: 10),
                              Text(
                                'Save your listing first, then add photos.',
                                style: AppTextStyles.caption.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Visibility
                      SectionHeader(
                        key: _keys['visibility'],
                        title: 'Visibility',
                      ),
                      AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'List in public directory',
                                    style: AppTextStyles.rowTitle.copyWith(
                                      fontSize: 14.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'When on, your company appears in Serden directory searches for homeowners near you.',
                                    style: AppTextStyles.caption.copyWith(
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Switch(
                              value: _isInDirectory,
                              onChanged: (v) => setState(() {
                                _isInDirectory = v;
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

  // ── Top bar / status ────────────────────────────────────────────────────────
  Widget _topBar({required bool isSaving, required bool canSave}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 6, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(8),
            child: const Row(
              children: [
                Icon(
                  Icons.arrow_back_ios_new,
                  size: 14,
                  color: AppColors.inkSoft,
                ),
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
              onPressed: canSave ? _save : null,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.orange500,
                disabledForegroundColor: AppColors.inkFaint,
                textStyle: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(_isNew && _initialized ? 'Publish' : 'Save'),
            ),
        ],
      ),
    );
  }

  Widget _statusHeader() {
    final String text;
    final Color color;
    if (!_initialized || _isNew) {
      text = 'Not listed yet';
      color = AppColors.inkSoft;
    } else if (_base.isInDirectory) {
      text = 'Live in the directory';
      color = AppColors.greenDeep;
    } else {
      text = 'Hidden from the directory';
      color = AppColors.inkSoft;
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Directory listing',
              style: AppTextStyles.headingMedium,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checklistCard() {
    final items = _checklist;
    final done = items.where((i) => i.done).length;
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _checklistOpen = !_checklistOpen),
            child: Row(
              children: [
                const Icon(Icons.checklist, size: 18, color: AppColors.ink),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Listing checklist',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  '$done of ${items.length} done',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green800,
                  ),
                ),
                Icon(
                  _checklistOpen ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.inkSoft,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / items.length,
              minHeight: 7,
              backgroundColor: AppColors.grayTint,
              color: AppColors.greenDeep,
            ),
          ),
          if (_checklistOpen) ...[
            const SizedBox(height: 8),
            for (final item in items)
              InkWell(
                onTap: () => _scrollTo(item.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      Icon(
                        item.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: item.done
                            ? AppColors.greenDeep
                            : AppColors.inkFaint,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.label,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: item.done ? AppColors.inkSoft : AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // ── Logo placeholder ────────────────────────────────────────────────────────
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

  Widget _linkButton(String label, VoidCallback? onTap, {Color? color}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        alignment: Alignment.centerLeft,
        foregroundColor: color,
        textStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: Text(label),
    );
  }

  // ── Trigger widgets ─────────────────────────────────────────────────────────
  Widget _dropdownTrigger({
    required String label,
    required VoidCallback onTap,
    IconData icon = Icons.expand_more,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.inkSoft,
                  height: 1.2,
                ),
              ),
            ),
            Icon(icon, color: AppColors.inkSoft, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _removableChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Material(
      color: AppColors.green800,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 13, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field helpers ───────────────────────────────────────────────────────────
  Widget _field(
    String label, {
    required TextEditingController controller,
    String? fieldKey,
    String? hint,
    int maxLines = 1,
    bool showDivider = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: _labeledField(
        label,
        controller: controller,
        fieldKey: fieldKey,
        hint: hint,
        maxLines: maxLines,
        keyboardType: keyboardType,
        formatters: formatters,
      ),
    );
  }

  Widget _pairRow(Widget left, Widget right, {bool last = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right),
        ],
      ),
    );
  }

  InputDecoration _decoration({String? hint, String? error}) => InputDecoration(
    hintText: hint,
    errorText: error,
    isDense: true,
    filled: true,
    fillColor: AppColors.page,
    hintStyle: AppTextStyles.bodyMedium.copyWith(
      color: AppColors.inkFaint,
      height: 1.2,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.line, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.greenDeep, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.redDeep, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(11),
      borderSide: const BorderSide(color: AppColors.redDeep, width: 1.5),
    ),
  );

  Widget _labeledField(
    String label, {
    required TextEditingController controller,
    String? fieldKey,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? formatters,
    void Function(String)? onChanged,
  }) {
    final error = fieldKey == null ? null : _errors[fieldKey];
    return Column(
      key: fieldKey == null ? null : _keys[fieldKey],
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
          keyboardType: keyboardType,
          inputFormatters: formatters,
          onChanged: (v) {
            if (fieldKey != null && _errors.remove(fieldKey) != null) {
              setState(() {}); // clear the red error text
            }
            if (onChanged != null) {
              onChanged(v);
            } else {
              _markDirty();
            }
          },
          style: AppTextStyles.rowTitle.copyWith(
            fontSize: 14.5,
            fontWeight: maxLines > 1 ? FontWeight.w500 : FontWeight.w600,
            height: maxLines > 1 ? 1.55 : 1.2,
          ),
          decoration: _decoration(hint: hint, error: error),
        ),
      ],
    );
  }

  Widget _stateField() {
    final states = _catalogs.states;
    final error = _errors['state'];
    if (states.isEmpty) {
      // The state list failed to load; the code can still be typed.
      return _labeledField(
        'State',
        fieldKey: 'state',
        hint: 'WA',
        controller: _stateCtrl,
        formatters: [LengthLimitingTextInputFormatter(2)],
        onChanged: (v) {
          _state = v.trim().toUpperCase();
          _markDirty();
        },
      );
    }
    final value = states.containsKey(_state) ? _state : null;
    return Column(
      key: _keys['state'],
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'State',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(
            'Select',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.inkFaint),
          ),
          decoration: _decoration(error: error),
          style: AppTextStyles.rowTitle.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          items: [
            for (final e in states.entries)
              DropdownMenuItem(
                value: e.key,
                child: Text(
                  '${e.key} · ${e.value}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          selectedItemBuilder: (_) => [
            for (final e in states.entries) Text(e.key),
          ],
          onChanged: (v) => setState(() {
            _state = v ?? '';
            _errors.remove('state');
            _dirty = true;
          }),
        ),
      ],
    );
  }

  Widget _hoursField() {
    // A saved value that isn't a preset shows as Custom, as on the web.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Business hours',
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _hoursOption,
          isExpanded: true,
          decoration: _decoration(),
          style: AppTextStyles.rowTitle.copyWith(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('Not specified')),
            for (final h in _presetHours)
              DropdownMenuItem(value: h, child: Text(h)),
            const DropdownMenuItem(
              value: _customHours,
              child: Text(_customHours),
            ),
          ],
          onChanged: (v) => setState(() {
            _hoursOption = v ?? '';
            if (_hoursOption != _customHours) _hoursCtrl.text = _hoursOption;
            _dirty = true;
          }),
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
              controller: controller,
              keyboardType: TextInputType.url,
              onChanged: (_) => _markDirty(),
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 13.5,
                color: AppColors.ink,
              ),
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

  // ── Photo box widgets ───────────────────────────────────────────────────────
  Widget _photoBox(ProPhoto photo) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: CachedNetworkImage(
                imageUrl: _photoUrl(photo),
                memCacheWidth: 260,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.grayTint,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.greenDeep,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.grayTint,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 22,
                    color: AppColors.inkFaint,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: () => _deletePhoto(photo),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadingPhotoBox() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.grayTint,
        borderRadius: BorderRadius.circular(11),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.greenDeep,
        ),
      ),
    );
  }

  Widget _addPhotoBox({required VoidCallback? onTap}) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: SizedBox(
        width: 84,
        height: 84,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inkFaint, width: 1.5),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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

/// Formats digits as `(512) 555-0142`, capped at 10 digits (as the web form does).
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final b = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 0) b.write('(');
      if (i == 3) b.write(') ');
      if (i == 6) b.write('-');
      b.write(digits[i]);
    }
    final text = b.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
