import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/form_nav_bar.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../../core/widgets/state_picker_field.dart';
import '../../../core/router/app_router.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/client_bloc.dart';
import '../models/client_model.dart';

/// New or edit client form.
///
/// Create mode: opened blank (or pre-filled from contacts if [importContacts]
/// is true). Save dispatches [ClientCreateRequested].
///
/// Edit mode: opened with [clientToEdit] pre-filled. Save dispatches
/// [ClientUpdateRequested]. A "Delete client" button at the bottom dispatches
/// [ClientDeleteRequested] after confirmation.
///
/// The caller (ClientDetailScreen) receives the result via GoRouter's push
/// return value:
///   - `{'client': updatedClient}` on successful update
///   - `{'deleted': true}` on successful delete
///   - `null` on discard / back navigation
class AddClientScreen extends StatefulWidget {
  final bool importContacts;
  final Client? clientToEdit;

  const AddClientScreen({
    super.key,
    this.importContacts = false,
    this.clientToEdit,
  });

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phoneMobile = TextEditingController();
  final _phoneOther = TextEditingController();
  final _address = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _zip = TextEditingController();
  final _notes = TextEditingController();

  bool _saving = false;
  bool get _isEdit => widget.clientToEdit != null;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));

    if (_isEdit) {
      _prefillFromClient(widget.clientToEdit!);
    } else if (widget.importContacts) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _pickContact());
    }
  }

  @override
  void dispose() {
    for (final c in [
      _name, _email, _phoneMobile, _phoneOther,
      _address, _address2, _city, _state, _zip, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefillFromClient(Client c) {
    _name.text = c.name;
    _email.text = c.email ?? '';
    _phoneMobile.text = c.phoneMobile ?? '';
    _phoneOther.text = c.phoneOther ?? '';
    _address.text = c.address ?? '';
    _address2.text = c.address2 ?? '';
    _city.text = c.city ?? '';
    _state.text = c.state ?? '';
    _zip.text = c.zipCode ?? '';
    _notes.text = c.privateNotes ?? '';
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _pickContact() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Contacts permission denied. '
                'Grant access in Settings to use this feature.')),
      );
      return;
    }
    final contact = await FlutterContacts.openExternalPick();
    if (contact == null || !mounted) return;
    final full = await FlutterContacts.getContact(contact.id,
        withProperties: true, withPhoto: false);
    if (full == null || !mounted) return;
    setState(() {
      final display = full.displayName.trim();
      if (display.isNotEmpty) _name.text = display;
      if (full.emails.isNotEmpty) _email.text = full.emails.first.address.trim();
      if (full.phones.isNotEmpty) {
        final mobile = full.phones.firstWhere(
          (p) => p.label == PhoneLabel.mobile || p.label == PhoneLabel.iPhone,
          orElse: () => full.phones.first,
        );
        _phoneMobile.text = mobile.number.trim();
        final others = full.phones.where((p) => p != mobile).toList();
        if (others.isNotEmpty) _phoneOther.text = others.first.number.trim();
      }
      if (full.addresses.isNotEmpty) {
        final addr = full.addresses.first;
        _address.text  = addr.street.trim();
        _address2.text = addr.subLocality.trim();
        _city.text     = addr.city.trim();
        _state.text    = addr.state.trim();
        _zip.text      = addr.postalCode.trim();
      }
    });
  }

  void _save() {
    final nameText = _name.text.trim();
    if (nameText.isEmpty) return;

    if (_isEdit) {
      final updated = widget.clientToEdit!.copyWith(
        name: nameText,
        email: _nullIfEmpty(_email.text),
        phoneMobile: _nullIfEmpty(_phoneMobile.text),
        phoneOther: _nullIfEmpty(_phoneOther.text),
        address: _nullIfEmpty(_address.text),
        address2: _nullIfEmpty(_address2.text),
        city: _nullIfEmpty(_city.text),
        state: _nullIfEmpty(_state.text),
        zipCode: _nullIfEmpty(_zip.text),
        privateNotes: _nullIfEmpty(_notes.text),
      );
      context.read<ClientBloc>().add(ClientUpdateRequested(updated));
    } else {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;
      final proId = authState.user.proId;
      if (proId == null) return;
      context.read<ClientBloc>().add(
            ClientCreateRequested(
              proId: proId,
              name: nameText,
              email: _nullIfEmpty(_email.text),
              phoneMobile: _nullIfEmpty(_phoneMobile.text),
              phoneOther: _nullIfEmpty(_phoneOther.text),
              address: _nullIfEmpty(_address.text),
              address2: _nullIfEmpty(_address2.text),
              city: _nullIfEmpty(_city.text),
              state: _nullIfEmpty(_state.text),
              zipCode: _nullIfEmpty(_zip.text),
              privateNotes: _nullIfEmpty(_notes.text),
            ),
          );
    }
  }

  void _confirmDelete() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete client?'),
        content: const Text(
            'This will permanently remove the client and cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ClientBloc>().add(
                    ClientDeleteRequested(widget.clientToEdit!.clientId),
                  );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ClientBloc, ClientsState>(
      listenWhen: (_, curr) =>
          curr is ClientCreating ||
          curr is ClientCreateSuccess ||
          curr is ClientCreateFailure ||
          curr is ClientUpdateInProgress ||
          curr is ClientUpdateSuccess ||
          curr is ClientUpdateFailure ||
          curr is ClientDeleteInProgress ||
          curr is ClientDeleteSuccess ||
          curr is ClientDeleteFailure,
      listener: (context, state) {
        if (state is ClientCreating || state is ClientUpdateInProgress || state is ClientDeleteInProgress) {
          setState(() => _saving = true);
        } else if (state is ClientCreateSuccess) {
          setState(() => _saving = false);
          context.pop();
        } else if (state is ClientUpdateSuccess) {
          setState(() => _saving = false);
          context.pop({'client': state.updated});
        } else if (state is ClientDeleteSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Client deleted'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go(AppRoutes.clients);
        } else if (state is ClientCreateFailure ||
            state is ClientUpdateFailure ||
            state is ClientDeleteFailure) {
          final msg = state is ClientCreateFailure
              ? state.message
              : state is ClientUpdateFailure
                  ? state.message
                  : (state as ClientDeleteFailure).message;
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
          isLoading: _saving,
          child: Scaffold(
            appBar: FormNavBar(
              title: _isEdit ? 'Edit client' : 'New client',
              trailingLabel: 'Save',
              trailingEnabled: _canSave,
              onTrailing: _save,
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (!_isEdit) ...[
                  OutlinedButton.icon(
                    onPressed: _pickContact,
                    icon: const Icon(Icons.person_add_alt_outlined, size: 17),
                    label: const Text('Import from contacts'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or enter manually',
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                ],
                Row(
                  children: [
                    _name.text.trim().isEmpty
                        ? Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: AppColors.grayTint,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person_outline,
                                size: 24, color: AppColors.inkFaint),
                          )
                        : AvatarWidget(name: _name.text.trim(), size: 60),
                    const SizedBox(width: 14),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Add photo'),
                    ),
                  ],
                ),
                const SectionHeader(
                    title: 'Basic info',
                    padding: EdgeInsets.fromLTRB(4, 16, 4, 8)),
                AppCard(
                  child: Column(
                    children: [
                      _FieldBlock(
                        label: 'Client name',
                        child: _input(
                          controller: _name,
                          hint: 'First and last name',
                          keyboardType: TextInputType.name,
                        ),
                      ),
                      _FieldBlock(
                        label: 'Email',
                        optional: true,
                        child: _input(
                          controller: _email,
                          hint: 'name@email.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      _FieldBlock(
                        showDivider: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: _labeled(
                                'Mobile number',
                                _input(
                                  controller: _phoneMobile,
                                  hint: '(503) 555-0100',
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _labeled(
                                'Home number',
                                _input(
                                  controller: _phoneOther,
                                  hint: '(503) 555-0100',
                                  keyboardType: TextInputType.phone,
                                ),
                                optional: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Billing address'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                  child: Text(
                    'Where invoices and bills will be sent.',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ),
                AppCard(
                  child: Column(
                    children: [
                      _FieldBlock(
                        label: 'Address line 1',
                        child:
                            _input(controller: _address, hint: 'Street address'),
                      ),
                      _FieldBlock(
                        label: 'Address line 2',
                        optional: true,
                        child: _input(
                            controller: _address2, hint: 'Apt, suite, unit'),
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
                                'ZIP / postal',
                                _input(
                                  controller: _zip,
                                  hint: '97124',
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Additional information'),
                AppCard(
                  child: _FieldBlock(
                    label: 'Notes',
                    optionalText: '· only you see these',
                    showDivider: false,
                    child: _input(
                      controller: _notes,
                      hint: "Gate code, dog's name, referred by…",
                      maxLines: 4,
                    ),
                  ),
                ),
                if (_isEdit) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _confirmDelete,
                    icon: const Icon(Icons.delete_outline, size: 17),
                    label: const Text('Delete client'),
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
    TextEditingController? controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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

  Widget _labeled(String label, Widget child, {bool optional = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label: label, optional: optional),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String? label;
  final bool optional;
  final String? optionalText;
  final bool showDivider;
  final Widget child;

  const _FieldBlock({
    this.label,
    this.optional = false,
    this.optionalText,
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
            _FieldLabel(
              label: label!,
              optional: optional,
              optionalText: optionalText,
            ),
            const SizedBox(height: 6),
          ],
          child,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool optional;
  final String? optionalText;

  const _FieldLabel({
    required this.label,
    this.optional = false,
    this.optionalText,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (optional || optionalText != null)
            TextSpan(
              text: ' ${optionalText ?? '· optional'}',
              style: const TextStyle(
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
    );
  }
}

