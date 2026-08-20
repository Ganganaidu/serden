import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/form_nav_bar.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../cubit/my_account_cubit.dart';

/// Editable "My account" form (serden-account design).
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();

  String _originalFirst = '';
  String _originalLast = '';
  String _originalEmail = '';

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _populateFromUser(authState.user);
    }
    for (final c in [_first, _last, _email]) {
      c.addListener(() => setState(() {}));
    }
  }

  void _populateFromUser(UserModel user) {
    _first.text = user.firstName;
    _last.text = user.lastName;
    _email.text = user.email;
    _originalFirst = user.firstName;
    _originalLast = user.lastName;
    _originalEmail = user.email;
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _first.text != _originalFirst ||
      _last.text != _originalLast ||
      _email.text != _originalEmail;

  String get _fullName =>
      '${_first.text.trim()} ${_last.text.trim()}'.trim();

  String get _initials => [_first.text, _last.text]
      .map((v) => v.trim().isEmpty ? '' : v.trim()[0])
      .join()
      .toUpperCase();

  void _save() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    context.read<MyAccountCubit>().save(
          userId: authState.user.userId,
          firstName: _first.text.trim(),
          lastName: _last.text.trim(),
          email: _email.text.trim(),
        );
  }

  void _showChangePassword() {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MyAccountCubit>(),
        child: _ChangePasswordSheet(email: authState.user.email),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyAccountCubit, MyAccountState>(
      listener: (context, state) {
        if (state is MyAccountSaved) {
          // Push updated user back into AuthBloc state by triggering a check
          context.read<AuthBloc>().add(const AuthCheckRequested());
          _originalFirst = _first.text;
          _originalLast = _last.text;
          _originalEmail = _email.text;
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account updated')),
          );
        } else if (state is MyAccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<MyAccountCubit>().reset();
        }
      },
      child: BlocBuilder<MyAccountCubit, MyAccountState>(
        builder: (context, state) {
          final isSaving = state is MyAccountSaving;
          return LoadingOverlay(
            isLoading: isSaving,
            child: Scaffold(
              appBar: FormNavBar(
                  title: 'My account',
                  trailingLabel: 'Save',
                  trailingEnabled: _dirty && !isSaving,
                  onTrailing: _save,
                ),
                body: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor: AppColors.green800,
                            child: Text(
                              _initials.isEmpty ? '—' : _initials,
                              style: const TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fullName.isEmpty ? 'Your name' : _fullName,
                                  style: AppTextStyles.rowTitle
                                      .copyWith(fontSize: 15.5),
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenTint,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.verified_user_outlined,
                                          size: 12,
                                          color: AppColors.greenDeep),
                                      SizedBox(width: 5),
                                      Text(
                                        'Serdefied Pro',
                                        style: TextStyle(
                                          fontFamily: AppTextStyles.fontFamily,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.greenDeep,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Change photo'),
                          ),
                        ],
                      ),
                    ),
                    const SectionHeader(title: 'Contact name'),
                    AppCard(
                      child: Column(
                        children: [
                          _fieldBlock('First name', _first),
                          _fieldBlock('Last name', _last,
                              showDivider: false),
                        ],
                      ),
                    ),
                    const SectionHeader(title: 'Business settings'),
                    AppCard(
                      child: Column(
                        children: [
                          _pickerRow('Industry', 'General contracting'),
                          _pickerRow('Currency', 'US Dollar (USD)',
                              flag: true),
                          _pickerRow('Locale', 'English (United States)',
                              showDivider: false),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
                      child: Text(
                        'Locale sets the date format, number format, and language used on your documents.',
                        style: AppTextStyles.caption
                            .copyWith(fontSize: 12, height: 1.5),
                      ),
                    ),
                    const SectionHeader(title: 'Login information'),
                    AppCard(
                      child: Column(
                        children: [
                          _fieldBlock('Email', _email,
                              keyboardType: TextInputType.emailAddress),
                          _pickerRow('Update password', '',
                              showDivider: false,
                              onTap: _showChangePassword),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    AppCard(
                      child: InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.redTint,
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.delete_outline,
                                    size: 16, color: AppColors.redDeep),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delete account and data',
                                      style: AppTextStyles.rowTitle.copyWith(
                                          fontSize: 14.5,
                                          color: AppColors.redDeep),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Permanently removes your profile, documents, and clients. This can't be undone.",
                                      style: AppTextStyles.caption
                                          .copyWith(fontSize: 12, height: 1.45),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
        },
      ),
    );
  }


  Widget _fieldBlock(String label, TextEditingController controller,
      {bool showDivider = true, TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: AppColors.line))
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Column(
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
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: AppTextStyles.rowTitle
                .copyWith(fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
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
        ],
      ),
    );
  }

  Widget _pickerRow(String label, String value,
      {bool showDivider = true, bool flag = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.line))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5)),
            ),
            if (flag) ...[
              const Text('🇺🇸', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
            ],
            if (value.isNotEmpty)
              Text(
                value,
                style: AppTextStyles.labelMedium
                    .copyWith(fontSize: 14, color: AppColors.inkSoft),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for changing password.
class _ChangePasswordSheet extends StatefulWidget {
  final String email;
  const _ChangePasswordSheet({required this.email});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _current = TextEditingController();
  final _newPw = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _current.dispose();
    _newPw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _valid =>
      _current.text.isNotEmpty &&
      _newPw.text.isNotEmpty &&
      _newPw.text == _confirm.text;

  void _submit() {
    if (!_valid) return;
    context.read<MyAccountCubit>().changePassword(
          email: widget.email,
          currentPassword: _current.text,
          newPassword: _newPw.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyAccountCubit, MyAccountState>(
      listener: (context, state) {
        if (state is MyAccountPasswordChanged) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated')),
          );
          context.read<MyAccountCubit>().reset();
        } else if (state is MyAccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<MyAccountCubit>().reset();
        }
      },
      child: BlocBuilder<MyAccountCubit, MyAccountState>(
        builder: (context, state) {
          final saving = state is MyAccountSaving;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text('Update password',
                    style: AppTextStyles.rowTitle.copyWith(fontSize: 17)),
                const SizedBox(height: 20),
                _pwField('Current password', _current, _obscureCurrent,
                    () => setState(() => _obscureCurrent = !_obscureCurrent)),
                const SizedBox(height: 12),
                _pwField('New password', _newPw, _obscureNew,
                    () => setState(() => _obscureNew = !_obscureNew)),
                const SizedBox(height: 12),
                _pwField('Confirm new password', _confirm, _obscureConfirm,
                    () => setState(
                        () => _obscureConfirm = !_obscureConfirm)),
                if (_confirm.text.isNotEmpty &&
                    _newPw.text != _confirm.text) ...[
                  const SizedBox(height: 6),
                  Text("Passwords don't match",
                      style: TextStyle(
                          color: AppColors.redDeep, fontSize: 12)),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!saving && _valid) ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Update password'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pwField(String label, TextEditingController controller, bool obscure,
      VoidCallback toggle) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      style: AppTextStyles.rowTitle.copyWith(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        filled: true,
        fillColor: AppColors.page,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              size: 18, color: AppColors.inkSoft),
          onPressed: toggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
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
