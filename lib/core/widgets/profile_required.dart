import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/bloc/auth_bloc.dart';
import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The Pro profile (and so the `proId` every API call is keyed on) only exists
/// once the company profile has been published.
bool hasCompanyProfile(BuildContext context) {
  final state = context.read<AuthBloc>().state;
  return state is AuthAuthenticated && state.user.proId != null;
}

/// Returns true when the company profile is set up. Otherwise shows a dialog
/// that sends the user to the company profile page, and returns false.
Future<bool> ensureCompanyProfile(BuildContext context) async {
  if (hasCompanyProfile(context)) return true;
  final setUp = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Set up your company profile',
          style: AppTextStyles.headingSmall.copyWith(fontSize: 17)),
      content: const Text(
        'Add your company details first. Once they are saved you can create '
        'estimates, invoices and clients.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not now'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text('Set up',
              style: TextStyle(
                  color: AppColors.greenDeep, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (setUp == true && context.mounted) {
    context.push(AppRoutes.companyProfile);
  }
  return false;
}
