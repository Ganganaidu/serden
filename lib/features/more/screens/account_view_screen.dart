import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/models/user_model.dart';
import '../cubit/account_view_cubit.dart';
import '../cubit/my_account_cubit.dart';

/// Read-only "My account" overview (serden-account-view design).
class AccountViewScreen extends StatefulWidget {
  const AccountViewScreen({super.key});

  @override
  State<AccountViewScreen> createState() => _AccountViewScreenState();
}

class _AccountViewScreenState extends State<AccountViewScreen> {
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<AccountViewCubit>().load(authState.user.userId);
    }
  }

  Future<void> _copyId(String id) async {
    await Clipboard.setData(ClipboardData(text: id));
    if (!mounted) return;
    setState(() => _copied = true);
    Future<void>.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocListener<MyAccountCubit, MyAccountState>(
      listener: (context, state) {
        if (state is MyAccountPasswordChanged) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password updated successfully')),
          );
        } else if (state is MyAccountError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
          context.read<MyAccountCubit>().reset();
        }
      },
      child: Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
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
                    onPressed: () => context.push(AppRoutes.myAccount),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 12),
              child: Text('My account', style: AppTextStyles.headingMedium),
            ),
            Expanded(
              child: BlocBuilder<AccountViewCubit, AccountViewState>(
                builder: (context, proState) {
                  final pro = proState is AccountViewLoaded ? proState : null;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    children: [
                      _profileCard(user, pro),
                      const SectionHeader(title: 'Account details'),
                      AppCard(
                        child: Column(
                          children: [
                            _valueRow(
                              'Full name',
                              user != null && user.fullName.isNotEmpty
                                  ? user.fullName
                                  : '—',
                            ),
                            _valueRow('Username', user?.username ?? '—'),
                            _valueRow('Email', user?.email ?? '—'),
                            _serdenIdRow(
                                pro?.serdenProId ?? user?.publicId ?? '—'),
                            _actionRow(
                              'Change password',
                              showDivider: false,
                              onTap: () => _openChangePassword(user),
                            ),
                          ],
                        ),
                      ),
                      const SectionHeader(title: 'Membership and billing'),
                      AppCard(
                        child: Column(
                          children: [
                            _membershipRow(user),
                            _iconRow(
                              icon: Icons.credit_card_outlined,
                              title: 'Payment method',
                              subtitle: 'Manage billing',
                              showDivider: _isActive(user),
                              onTap: () {},
                            ),
                            if (_isActive(user)) _cancelMembershipRow(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: () => context
                            .read<AuthBloc>()
                            .add(const AuthSignOutRequested()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.inkSoft,
                          side: const BorderSide(color: AppColors.line),
                          backgroundColor: AppColors.card,
                          textStyle:
                              AppTextStyles.buttonText.copyWith(fontSize: 14.5),
                        ),
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Sign out'),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 14),
                        child: Text(
                          'Serden for iOS · v4.2.1',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.inkFaint,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  String _subscriptionSubtitle(UserModel? user) {
    if (user == null) return '—';
    final status = user.subscriptionStatus ?? 'Active';
    final end = user.subscriptionEndDate;
    if (end == null) return status;
    final formatted =
        '${_monthName(end.month)} ${end.day}, ${end.year}';
    return 'Renews $formatted';
  }

  String _monthName(int month) => const [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][month];

  bool _isActive(UserModel? user) {
    if (user == null) return false;
    final status = (user.subscriptionStatus ?? '').toLowerCase();
    if (status.isEmpty ||
        status == 'none' ||
        status == 'inactive' ||
        status == 'expired' ||
        status == 'canceled' ||
        status == 'cancelled') {
      return false;
    }
    final end = user.subscriptionEndDate;
    if (end != null && end.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  void _openChangePassword(UserModel? user) {
    if (user == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<MyAccountCubit>(),
        child: _ChangePasswordSheet(email: user.email),
      ),
    );
  }

  void _showCancelDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel membership?'),
        content: const Text(
          'Your Pro access will remain active until the end of your current '
          'billing period. To proceed, please contact support@serden.com.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(String label,
      {bool showDivider = true, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: showDivider
            ? const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.line)))
            : null,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label,
                style: AppTextStyles.rowTitle.copyWith(fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }

  Widget _membershipRow(UserModel? user) {
    final active = _isActive(user);
    return InkWell(
      onTap: () => context.push(AppRoutes.choosePlan),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.line)),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    active ? AppColors.greenTint : AppColors.grayTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.verified_user_outlined,
                size: 18,
                color: active
                    ? AppColors.greenDeep
                    : AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Pro membership',
                          style: AppTextStyles.rowTitle
                              .copyWith(fontSize: 14.5)),
                      if (active) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.greenTint,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Active',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenDeep,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subscriptionSubtitle(user),
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }

  Widget _cancelMembershipRow() {
    return InkWell(
      onTap: _showCancelDialog,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined,
                size: 18, color: AppColors.orange500),
            const SizedBox(width: 12),
            Text(
              'Cancel membership',
              style: AppTextStyles.rowTitle.copyWith(
                  fontSize: 14, color: AppColors.orange500),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(UserModel? user, AccountViewLoaded? pro) {
    final initials = [user?.firstName, user?.lastName]
        .map((v) => (v?.trim().isEmpty ?? true) ? '' : v!.trim()[0])
        .join()
        .toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.green800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              shape: BoxShape.circle,
            ),
            child: Text(
              initials.isEmpty ? '—' : initials,
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
                  user?.fullName.isEmpty == false ? user!.fullName : '—',
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (pro?.phone?.isNotEmpty == true) pro!.phone!,
                    if (user?.email.isNotEmpty == true) user!.email,
                  ].join('\n'),
                  style: AppTextStyles.headerSubtitle
                      .copyWith(fontSize: 12.5, height: 1.55),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.verified_user_outlined,
                          size: 12, color: AppColors.overdueOnHeader),
                      SizedBox(width: 5),
                      Text(
                        'Serdefied Pro',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueRow(String label, String value,
      {bool chevron = false, bool showDivider = true, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.line))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Text(label, style: AppTextStyles.rowTitle.copyWith(fontSize: 14)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium
                    .copyWith(fontSize: 13.5, color: AppColors.inkSoft),
              ),
            ),
            if (chevron) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.inkFaint),
            ],
          ],
        ),
      ),
    );
  }

  Widget _serdenIdRow(String id) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(
        children: [
          Text('Serden ID',
              style: AppTextStyles.rowTitle.copyWith(fontSize: 14)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              id,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 13.5,
                color: AppColors.inkSoft,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _copied ? AppColors.greenTint : AppColors.grayTint,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () => _copyId(id),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_outlined,
                      size: 12,
                      color: _copied ? AppColors.greenDeep : AppColors.inkSoft,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      _copied ? 'Copied' : 'Copy',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _copied
                            ? AppColors.greenDeep
                            : AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool greenIcon = false,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(bottom: BorderSide(color: AppColors.line))
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: greenIcon ? AppColors.greenTint : AppColors.grayTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                size: 18,
                color: greenIcon ? AppColors.greenDeep : AppColors.inkSoft,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.rowTitle.copyWith(fontSize: 14.5)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption.copyWith(fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends StatefulWidget {
  final String email;
  const _ChangePasswordSheet({required this.email});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _currentCtrl.text.isNotEmpty &&
      _newCtrl.text.length >= 6 &&
      _newCtrl.text == _confirmCtrl.text;

  void _submit() {
    context.read<MyAccountCubit>().changePassword(
          email: widget.email,
          currentPassword: _currentCtrl.text,
          newPassword: _newCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyAccountCubit, MyAccountState>(
      listener: (context, state) {
        if (state is MyAccountPasswordChanged) {
          Navigator.of(context).pop();
        }
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            Text('Change password', style: AppTextStyles.headingMedium),
            const SizedBox(height: 20),
            _passwordField(
              'Current password',
              _currentCtrl,
              _showCurrent,
              () => setState(() => _showCurrent = !_showCurrent),
            ),
            const SizedBox(height: 12),
            _passwordField(
              'New password',
              _newCtrl,
              _showNew,
              () => setState(() => _showNew = !_showNew),
            ),
            const SizedBox(height: 12),
            _passwordField(
              'Confirm new password',
              _confirmCtrl,
              _showConfirm,
              () => setState(() => _showConfirm = !_showConfirm),
            ),
            const SizedBox(height: 24),
            BlocBuilder<MyAccountCubit, MyAccountState>(
              builder: (context, state) {
                final loading = state is MyAccountSaving;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSubmit && !loading ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange500,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.orange500.withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Update password'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _passwordField(
    String label,
    TextEditingController ctrl,
    bool visible,
    VoidCallback toggle,
  ) {
    return TextField(
      controller: ctrl,
      obscureText: !visible,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.greenDeep),
        ),
        suffixIcon: IconButton(
          onPressed: toggle,
          icon: Icon(
            visible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 18,
            color: AppColors.inkSoft,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
