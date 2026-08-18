import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/di/injection.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/form_nav_bar.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/project_picker_field.dart';
import '../../../core/widgets/state_picker_field.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/lead_bloc.dart';
import '../models/lead_model.dart';

class AddLeadScreen extends StatefulWidget {
  final Lead? leadToEdit;

  const AddLeadScreen({super.key, this.leadToEdit});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _streetAddress = TextEditingController();
  final _addressLine2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _requestText = TextEditingController();
  final _leadSource = TextEditingController();
  final _leadCostController = TextEditingController();
  final _currencyFormatter = _CurrencyInputFormatter();

  LeadStatus _status = LeadStatus.newLead;
  String? _projectType;
  bool _saving = false;
  final List<XFile> _pendingPhotos = [];
  bool _uploadingPhotos = false;

  bool get _isEdit => widget.leadToEdit != null;

  @override
  void initState() {
    super.initState();
    _firstName.addListener(() => setState(() {}));
    _lastName.addListener(() => setState(() {}));
    if (_isEdit) _prefill(widget.leadToEdit!);
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _phone,
      _email,
      _streetAddress,
      _addressLine2,
      _city,
      _state,
      _zip,
      _requestText,
      _leadSource,
      _leadCostController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(Lead l) {
    _firstName.text = l.firstName ?? '';
    _lastName.text = l.lastName ?? '';
    _phone.text = l.phone ?? '';
    _email.text = l.email ?? '';
    _streetAddress.text = l.streetAddress ?? '';
    _addressLine2.text = l.addressLine2 ?? '';
    _city.text = l.city ?? '';
    _state.text = l.state ?? '';
    _zip.text = l.zipCode ?? '';
    _requestText.text = l.requestText ?? '';
    _leadSource.text = l.leadSource ?? '';
    _currencyFormatter.seed(l.leadCost);
    _leadCostController.text = _currencyFormatter.displayText;
    _status = l.status;
    _projectType = l.categoryName;
  }

  bool get _canSave =>
      (_firstName.text.trim().isNotEmpty ||
          _lastName.text.trim().isNotEmpty) &&
      !_saving;

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  void _save() {
    if (!_canSave) return;

    if (_isEdit) {
      final updated = widget.leadToEdit!.copyWith(
        firstName: _nullIfEmpty(_firstName.text),
        lastName: _nullIfEmpty(_lastName.text),
        phone: _nullIfEmpty(_phone.text),
        email: _nullIfEmpty(_email.text),
        streetAddress: _nullIfEmpty(_streetAddress.text),
        addressLine2: _nullIfEmpty(_addressLine2.text),
        city: _nullIfEmpty(_city.text),
        state: _nullIfEmpty(_state.text),
        zipCode: _nullIfEmpty(_zip.text),
        requestText: _nullIfEmpty(_requestText.text),
        categoryName: _projectType,
        leadSource: _nullIfEmpty(_leadSource.text),
        leadCost: _currencyFormatter.doubleValue,
        status: _status,
      );
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;
      context.read<LeadBloc>().add(
            LeadUpdateRequested(
              lead: updated,
              userId: authState.user.userId,
            ),
          );
    } else {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;
      context.read<LeadBloc>().add(
            LeadCreateRequested(
              userId: authState.user.userId,
              firstName: _nullIfEmpty(_firstName.text),
              lastName: _nullIfEmpty(_lastName.text),
              phone: _nullIfEmpty(_phone.text),
              email: _nullIfEmpty(_email.text),
              streetAddress: _nullIfEmpty(_streetAddress.text),
              addressLine2: _nullIfEmpty(_addressLine2.text),
              city: _nullIfEmpty(_city.text),
              state: _nullIfEmpty(_state.text),
              zipCode: _nullIfEmpty(_zip.text),
              requestText: _nullIfEmpty(_requestText.text),
              categoryName: _projectType,
              leadSource: _nullIfEmpty(_leadSource.text),
              leadCost: _currencyFormatter.doubleValue,
              status: _status,
            ),
          );
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete lead?'),
        content: const Text(
            'This will permanently remove the lead and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(dialogContext);
              final authState = context.read<AuthBloc>().state;
              if (authState is! AuthAuthenticated) return;
              context.read<LeadBloc>().add(LeadDeleteRequested(
                    requestId: widget.leadToEdit!.requestId,
                    userId: authState.user.userId,
                  ));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() => _pendingPhotos.addAll(picked));
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (picked == null) return;
    setState(() => _pendingPhotos.add(picked));
  }

  Future<void> _uploadPhotosAndPop(
      int requestId, Map<String, dynamic>? popResult) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      if (mounted) context.pop(popResult);
      return;
    }
    setState(() => _uploadingPhotos = true);
    for (final photo in _pendingPhotos) {
      await Injection.leadRepository
          .uploadPhoto(requestId, authState.user.userId, photo.path);
    }
    if (mounted) {
      setState(() => _uploadingPhotos = false);
      context.pop(popResult);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LeadBloc, LeadsState>(
      listenWhen: (_, curr) =>
          curr is LeadCreating ||
          curr is LeadCreateSuccess ||
          curr is LeadCreateFailure ||
          curr is LeadUpdateInProgress ||
          curr is LeadUpdateSuccess ||
          curr is LeadUpdateFailure ||
          curr is LeadDeleteInProgress ||
          curr is LeadDeleteSuccess ||
          curr is LeadDeleteFailure,
      listener: (context, state) {
        if (state is LeadCreating ||
            state is LeadUpdateInProgress ||
            state is LeadDeleteInProgress) {
          setState(() => _saving = true);
        } else if (state is LeadCreateSuccess) {
          setState(() => _saving = false);
          if (_pendingPhotos.isNotEmpty) {
            _uploadPhotosAndPop(state.created.requestId, null);
          } else {
            context.pop();
          }
        } else if (state is LeadUpdateSuccess) {
          setState(() => _saving = false);
          if (_pendingPhotos.isNotEmpty) {
            _uploadPhotosAndPop(
                state.updated.requestId, {'lead': state.updated});
          } else {
            context.pop({'lead': state.updated});
          }
        } else if (state is LeadDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lead deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(AppRoutes.leads);
        } else if (state is LeadCreateFailure ||
            state is LeadUpdateFailure ||
            state is LeadDeleteFailure) {
          final msg = state is LeadCreateFailure
              ? state.message
              : state is LeadUpdateFailure
                  ? state.message
                  : (state as LeadDeleteFailure).message;
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: AppColors.orangeDeep,
            ),
          );
        }
      },
      builder: (context, state) {
        return LoadingOverlay(
          isLoading: _saving || _uploadingPhotos,
          child: Scaffold(
            appBar: FormNavBar(
              title: _isEdit ? 'Edit lead' : 'New lead',
              trailingLabel: 'Save',
              trailingEnabled: _canSave,
              onTrailing: _save,
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                const SectionHeader(
                    title: 'Contact info',
                    padding: EdgeInsets.fromLTRB(4, 0, 4, 8)),
                AppCard(
                  child: Column(
                    children: [
                      _FieldBlock(
                        child: Row(
                          children: [
                            Expanded(
                              child: _labeled(
                                  'First name',
                                  _input(
                                      controller: _firstName,
                                      hint: 'First',
                                      keyboardType: TextInputType.name)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _labeled(
                                  'Last name',
                                  _input(
                                      controller: _lastName,
                                      hint: 'Last',
                                      keyboardType: TextInputType.name)),
                            ),
                          ],
                        ),
                      ),
                      _FieldBlock(
                        label: 'Phone',
                        optional: true,
                        child: _input(
                          controller: _phone,
                          hint: '(503) 555-0100',
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      _FieldBlock(
                        label: 'Email',
                        optional: true,
                        showDivider: false,
                        child: _input(
                          controller: _email,
                          hint: 'name@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Address'),
                AppCard(
                  child: Column(
                    children: [
                      _FieldBlock(
                        label: 'Street address',
                        optional: true,
                        child: _input(
                            controller: _streetAddress,
                            hint: 'Street address'),
                      ),
                      _FieldBlock(
                        label: 'Address line 2',
                        optional: true,
                        child: _input(
                            controller: _addressLine2, hint: 'Apt, suite'),
                      ),
                      _FieldBlock(
                        showDivider: false,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 14,
                              child: _labeled('City',
                                  _input(controller: _city, hint: 'City')),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 10,
                              child: _labeled('State',
                                  StatePickerField(controller: _state)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 10,
                              child: _labeled(
                                  'ZIP',
                                  _input(
                                    controller: _zip,
                                    hint: '97124',
                                    keyboardType: TextInputType.number,
                                  )),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Project details'),
                AppCard(
                  child: Column(
                    children: [
                      _FieldBlock(
                        label: 'Project type',
                        optional: true,
                        child: ProjectPickerField(
                          value: _projectType,
                          onChanged: (v) => setState(() => _projectType = v),
                        ),
                      ),
                      _FieldBlock(
                        label: 'Project description',
                        optional: true,
                        showDivider: false,
                        child: _input(
                          controller: _requestText,
                          hint: 'Remodel a kitchen, fix roof leak…',
                          maxLines: 3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Lead info'),
                AppCard(
                  child: Column(
                    children: [
                      _FieldBlock(
                        label: 'Status',
                        child: _StatusDropdown(
                          value: _status,
                          onChanged: (s) => setState(() => _status = s),
                        ),
                      ),
                      _FieldBlock(
                        label: 'Lead source',
                        optional: true,
                        child: _input(
                          controller: _leadSource,
                          hint: 'Referral, Google, HomeAdvisor…',
                        ),
                      ),
                      _FieldBlock(
                        label: 'Lead cost',
                        optional: true,
                        showDivider: false,
                        child: _input(
                          controller: _leadCostController,
                          hint: '0.00',
                          keyboardType: TextInputType.number,
                          inputFormatters: [_currencyFormatter],
                        ),
                      ),
                    ],
                  ),
                ),
                // Photos section
                const SectionHeader(title: 'Photos'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_pendingPhotos.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1,
                            ),
                            itemCount: _pendingPhotos.length,
                            itemBuilder: (context, i) => _PendingPhotoTile(
                              file: _pendingPhotos[i],
                              onRemove: () => setState(
                                  () => _pendingPhotos.removeAt(i)),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _saving ? null : _pickPhotos,
                                icon: const Icon(
                                    Icons.photo_library_outlined,
                                    size: 16),
                                label: const Text('Library'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.greenDeep,
                                  side: const BorderSide(
                                      color: AppColors.greenDeep),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _saving ? null : _pickFromCamera,
                                icon: const Icon(
                                    Icons.camera_alt_outlined,
                                    size: 16),
                                label: const Text('Camera'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.greenDeep,
                                  side: const BorderSide(
                                      color: AppColors.greenDeep),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline, size: 17),
                    label: const Text('Delete lead'),
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
      },
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: AppTextStyles.rowTitle.copyWith(
        fontWeight: maxLines > 1 ? FontWeight.w500 : FontWeight.w600,
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
    );
  }

  Widget _labeled(String label, Widget child) {
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
        child,
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  final LeadStatus value;
  final ValueChanged<LeadStatus> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.page,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.line, width: 1.5),
      ),
      child: DropdownButton<LeadStatus>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        style: AppTextStyles.rowTitle.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        items: const [
          DropdownMenuItem(value: LeadStatus.newLead, child: Text('New')),
          DropdownMenuItem(
              value: LeadStatus.contacted, child: Text('Contacted')),
          DropdownMenuItem(
              value: LeadStatus.quoted, child: Text('Estimate sent')),
          DropdownMenuItem(value: LeadStatus.won, child: Text('Won')),
          DropdownMenuItem(value: LeadStatus.lost, child: Text('Lost')),
        ],
        onChanged: (s) {
          if (s != null) onChanged(s);
        },
      ),
    );
  }
}

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

// ─── Pending photo tile ───────────────────────────────────────────────────────

class _PendingPhotoTile extends StatelessWidget {
  final XFile file;
  final VoidCallback onRemove;

  const _PendingPhotoTile({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(file.path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.grayTint,
              child: const Icon(Icons.image_outlined,
                  color: AppColors.inkFaint),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
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
}

// ─── Currency input formatter ─────────────────────────────────────────────────
// Cash-register style: digits shift left from cents.
// Typing "1" → "0.01", "15" → "0.15", "150" → "1.50".

class _CurrencyInputFormatter extends TextInputFormatter {
  int _cents = 0;

  void seed(double? value) {
    _cents = value == null ? 0 : (value * 100).round();
  }

  String get displayText => _cents == 0 ? '' : _format();

  double? get doubleValue => _cents == 0 ? null : _cents / 100.0;

  String _format() {
    final d = _cents ~/ 100;
    final c = _cents % 100;
    return '$d.${c.toString().padLeft(2, '0')}';
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final oldDigits = oldValue.text.replaceAll(RegExp(r'\D'), '');
    final newDigits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (newDigits.length < oldDigits.length) {
      _cents = _cents ~/ 10;
    } else if (newDigits.length > oldDigits.length) {
      final last = newDigits.isEmpty ? '' : newDigits[newDigits.length - 1];
      final d = int.tryParse(last);
      if (d != null) {
        _cents = _cents * 10 + d;
        if (_cents > 99999999) _cents = _cents ~/ 10;
      }
    }

    final text = _cents == 0 ? '' : _format();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
