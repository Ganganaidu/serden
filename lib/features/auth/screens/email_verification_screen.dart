import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class EmailVerificationScreen extends StatelessWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green800,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              // Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.green700,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Check your email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We sent a verification link to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click the link in the email to activate your account, then come back and sign in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.65),
                  height: 1.6,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.signIn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.green800,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Go to Sign In'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
