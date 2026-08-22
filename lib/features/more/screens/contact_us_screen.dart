import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/form_nav_bar.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/screens/widgets/turnstile_sheet.dart';
import '../cubit/contact_us_cubit.dart';

const _subjects = [
  'Support',
  'Report Bug',
  'Advertisement',
  'Other',
];

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _name = TextEditingController();
  final _company = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _description = TextEditingController();

  String? _subject;

  @override
  void dispose() {
    _name.dispose();
    _company.dispose();
    _email.dispose();
    _phone.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _name.text.trim().isNotEmpty &&
      _email.text.trim().isNotEmpty &&
      _phone.text.trim().isNotEmpty &&
      _subject != null;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    // Show Cloudflare Turnstile verification before sending.
    final token = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TurnstileSheet(
        subtitle: 'One quick check before sending your message.',
      ),
    );

    if (token == null || !mounted) return;

    context.read<ContactUsCubit>().submit(
          name: _name.text.trim(),
          company: _company.text.trim().isEmpty ? null : _company.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          subject: _subject!,
          description: _description.text.trim().isEmpty
              ? null
              : _description.text.trim(),
          turnstileToken: token,
        );
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thanks for contacting us!'),
        content: const Text(
          "We've received your message and will get back to you within 1 business day.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (mounted) context.go(AppRoutes.more);
  }

  void _showSubjectPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Text(
                'Select a subject',
                style: AppTextStyles.rowTitle.copyWith(fontSize: 16),
              ),
            ),
            const Divider(height: 1),
            ..._subjects.map(
              (s) => ListTile(
                title: Text(
                  s,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _subject == s ? AppColors.greenDeep : AppColors.ink,
                  ),
                ),
                trailing: _subject == s
                    ? const Icon(Icons.check,
                        color: AppColors.greenDeep, size: 20)
                    : null,
                onTap: () {
                  setState(() => _subject = s);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContactUsCubit, ContactUsState>(
      listener: (context, state) {
        if (state is ContactUsSuccess) {
          _showSuccessDialog();
        } else if (state is ContactUsFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.orangeDeep,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is ContactUsSubmitting;
        return LoadingOverlay(
          isLoading: isSubmitting,
          child: Scaffold(
            appBar: FormNavBar(
              title: 'Contact us',
              trailingLabel: 'Send',
              trailingEnabled: _canSubmit && !isSubmitting,
              onTrailing: _submit,
            ),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                const SectionHeader(
                  title: 'Your info',
                  padding: EdgeInsets.fromLTRB(4, 0, 4, 8),
                ),
                AppCard(
                  child: Column(
                    children: [
                      _FieldBlock(
                        label: 'Name',
                        child: _input(
                          controller: _name,
                          hint: 'Your full name',
                          keyboardType: TextInputType.name,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      _FieldBlock(
                        label: 'Company',
                        optional: true,
                        child: _input(
                          controller: _company,
                          hint: 'Your company name',
                        ),
                      ),
                      _FieldBlock(
                        label: 'Email',
                        child: _input(
                          controller: _email,
                          hint: 'name@email.com',
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      _FieldBlock(
                        label: 'Phone',
                        showDivider: false,
                        child: _input(
                          controller: _phone,
                          hint: '(503) 555-0100',
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),
                const SectionHeader(title: 'Message'),
                AppCard(
                  child: Column(
                    children: [
                      _FieldBlock(
                        label: 'Subject',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _showSubjectPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 13, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.page,
                              border: Border.all(
                                color: AppColors.line,
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _subject ?? 'Select a subject',
                                    style: AppTextStyles.rowTitle.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _subject != null
                                          ? AppColors.ink
                                          : AppColors.inkFaint,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.inkSoft,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _FieldBlock(
                        label: 'Description',
                        optional: true,
                        showDivider: false,
                        child: _input(
                          controller: _description,
                          hint: 'Describe the issue or question in detail…',
                          maxLines: 5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'We typically respond within 1 business day.',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                  ),
                ),
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
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
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
            _FieldLabel(label: label!, optional: optional),
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

  const _FieldLabel({required this.label, this.optional = false});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
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
    );
  }
}
