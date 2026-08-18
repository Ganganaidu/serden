import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../cubit/reviews_cubit.dart';

const _kDefaultMessage = '''Hello,

Thank you for the opportunity to work with TechVision Solutions. If you were happy with our service, we would really appreciate a quick review.

Your feedback helps other homeowners feel confident choosing us.

Thank you for your time and support.''';

class RequestReviewSheet extends StatefulWidget {
  final int proId;
  final String fromEmail;

  const RequestReviewSheet({
    super.key,
    required this.proId,
    required this.fromEmail,
  });

  @override
  State<RequestReviewSheet> createState() => _RequestReviewSheetState();
}

class _RequestReviewSheetState extends State<RequestReviewSheet> {
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController(
      text: "We'd love your feedback!");
  final _messageController = TextEditingController(text: _kDefaultMessage);
  bool _sending = false;

  bool get _canSend =>
      _emailController.text.trim().isNotEmpty && !_sending;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final toEmail = _emailController.text.trim();
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();
    if (toEmail.isEmpty) return;

    setState(() => _sending = true);
    final result = await context.read<ReviewsCubit>().sendRequest(
          proId: widget.proId,
          toEmail: toEmail,
          fromEmail: widget.fromEmail,
          subject: subject.isNotEmpty ? subject : "We'd love your feedback!",
          message: message,
        );
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message),
            backgroundColor: AppColors.orangeDeep,
          ),
        );
      },
      (_) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review request sent!'),
            backgroundColor: AppColors.greenDeep,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: bottom),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Email a review request',
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: AppColors.grayTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            size: 18, color: AppColors.inkSoft),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the customer's email address to send them a link to your review page.",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // To field
                _label('To'),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration('customer@email.com'),
                ),
                const SizedBox(height: 16),

                // Subject field
                _label('Subject'),
                const SizedBox(height: 6),
                TextField(
                  controller: _subjectController,
                  style: AppTextStyles.bodyMedium,
                  decoration: _inputDecoration("We'd love your feedback!"),
                ),
                const SizedBox(height: 16),

                // Message field
                _label('Message'),
                const SizedBox(height: 6),
                TextField(
                  controller: _messageController,
                  maxLines: 8,
                  minLines: 6,
                  style: AppTextStyles.bodySmall
                      .copyWith(height: 1.6, color: AppColors.ink),
                  decoration: _inputDecoration(null),
                ),
                const SizedBox(height: 24),

                // Send button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canSend ? _send : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green800,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.inkFaint.withValues(alpha: 0.3),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text('Send request'),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider + share section
                const Divider(height: 1, color: AppColors.line),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Review page link copied!')),
                    );
                  },
                  child: const Text(
                    'Share your personalized review page.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.greenDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Text or email past customers with your personalized review page link.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.inkSoft,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.inkSoft,
        ),
      );

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inkFaint,
          height: 1.2,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.greenDeep, width: 1.5),
        ),
      );
}
