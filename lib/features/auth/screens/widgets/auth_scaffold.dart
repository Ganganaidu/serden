import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Auth layout: dark green hero with logo on top, off-white sheet
/// sliding up from the bottom that holds the form.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green800,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              // The sheet below grows with the number of form fields (e.g.
              // Sign Up has 4 fields vs Sign In's 2), which shrinks this
              // Expanded area correspondingly. FittedBox scales the whole
              // hero block down together if it doesn't fit, instead of
              // overflowing — keeps it fully visible on short screens or
              // with the keyboard open, at a slightly smaller size.
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.green700,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Text(
                          'S',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          'Join the network homeowners trust to find local pros.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                            color: Color(0xB3FFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _Sheet(title: title, subtitle: subtitle, children: children),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _Sheet({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 24, end: 0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, offset, child) => Transform.translate(
        offset: Offset(0, offset),
        child: Opacity(
          opacity: 1 - offset / 24,
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.78,
        ),
        decoration: const BoxDecoration(
          color: AppColors.sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 32,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            10,
            24,
            28 + MediaQuery.of(context).padding.bottom + bottomInset,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.grabber,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(title, style: AppTextStyles.headingLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.inkSoft, height: 1.3),
              ),
              const SizedBox(height: 22),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Labeled input used on the auth sheets.
class AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffix;
  final String? helper;

  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffix,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelMedium),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: suffix,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 6),
            Text(
              helper!,
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
