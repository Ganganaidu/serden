import 'package:flutter/material.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'turnstile_sheet.dart';

Future<void> showForgotPasswordSheet(
  BuildContext context, {
  String? initialEmail,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ForgotPasswordSheet(initialEmail: initialEmail),
  );
}

class _ForgotPasswordSheet extends StatefulWidget {
  final String? initialEmail;
  const _ForgotPasswordSheet({this.initialEmail});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  late final TextEditingController _email;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  static String? _validateEmail(String value) {
    if (value.isEmpty) return 'Please enter your email address.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
    return ok ? null : 'Enter a valid email address.';
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      setState(() => _error = emailError);
      return;
    }

    // Obtain a Turnstile token before calling the API.
    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TurnstileSheet(),
    );

    if (token == null || !mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await Injection.authRepository
        .forgotPassword(email, turnstileToken: token);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (_) => setState(() {
        _loading = false;
        _sent = true;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sheetBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 10, 24, 28 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.grabber,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Icon
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.greenTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_reset_outlined,
              color: AppColors.greenDeep,
              size: 24,
            ),
          ),
          Text('Reset your password', style: AppTextStyles.headingLarge),
          const SizedBox(height: 6),
          Text(
            _sent
                ? 'Check your inbox — we sent a reset link to ${_email.text.trim()}.'
                : 'Enter the email linked to your account and we\'ll send you a reset link.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.inkSoft, height: 1.4),
          ),
          if (!_sent) ...[
            const SizedBox(height: 24),
            _Label('Email address'),
            const SizedBox(height: 6),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofocus: (widget.initialEmail ?? '').isEmpty,
              style: AppTextStyles.bodyLarge,
              decoration: const InputDecoration(
                hintText: 'you@yourbusiness.com',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.redDeep,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send reset link'),
              ),
            ),
          ],
          if (_sent) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to sign in'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.labelMedium);
  }
}
