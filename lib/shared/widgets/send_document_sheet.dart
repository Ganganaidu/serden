import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/send_document_draft.dart';

/// Bottom sheet to compose the email that sends an estimate or invoice.
/// Resolves to the draft when the user taps Send, or null on Cancel/close.
Future<SendDocumentDraft?> showSendDocumentSheet(
  BuildContext context, {
  required String title,
  required String toEmail,
  required String subject,
  required String message,
}) {
  return showModalBottomSheet<SendDocumentDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SendDocumentSheet(
      title: title,
      toEmail: toEmail,
      subject: subject,
      message: message,
    ),
  );
}

/// Default subject, e.g. "Your Estimate #1004 from Aman Corporation".
String documentSubject(String kind, int number, String? businessName) {
  final from = (businessName ?? '').trim();
  return from.isEmpty
      ? 'Your $kind #$number'
      : 'Your $kind #$number from $from';
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class _SendDocumentSheet extends StatefulWidget {
  final String title;
  final String toEmail;
  final String subject;
  final String message;

  const _SendDocumentSheet({
    required this.title,
    required this.toEmail,
    required this.subject,
    required this.message,
  });

  @override
  State<_SendDocumentSheet> createState() => _SendDocumentSheetState();
}

class _SendDocumentSheetState extends State<_SendDocumentSheet> {
  late final _to = TextEditingController(text: widget.toEmail);
  late final _subject = TextEditingController(text: widget.subject);
  late final _message = TextEditingController(text: widget.message);
  bool _sendMeACopy = false;

  String? _toError;
  String? _subjectError;

  @override
  void dispose() {
    _to.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  void _send() {
    final to = _to.text.trim();
    final subject = _subject.text.trim();
    final toError = to.isEmpty
        ? 'Required.'
        : _emailPattern.hasMatch(to)
            ? null
            : 'Enter a valid email address.';
    final subjectError = subject.isEmpty ? 'Required.' : null;

    if (toError != null || subjectError != null) {
      setState(() {
        _toError = toError;
        _subjectError = subjectError;
      });
      return;
    }

    Navigator.of(context).pop(
      SendDocumentDraft(
        toEmail: to,
        subject: subject,
        message: _message.text.trim(),
        sendMeACopy: _sendMeACopy,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lift the sheet above the keyboard on both iOS and Android.
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(widget.title,
                        style: AppTextStyles.headingSmall
                            .copyWith(color: AppColors.primary)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.inkSoft),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Label('To'),
              TextField(
                controller: _to,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'client@example.com',
                  errorText: _toError,
                ),
                onChanged: (_) {
                  if (_toError != null) setState(() => _toError = null);
                },
              ),
              const SizedBox(height: 16),
              _Label('Subject'),
              TextField(
                controller: _subject,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(errorText: _subjectError),
                onChanged: (_) {
                  if (_subjectError != null) {
                    setState(() => _subjectError = null);
                  }
                },
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Send me a copy', style: AppTextStyles.bodySmall),
                  Switch(
                    value: _sendMeACopy,
                    onChanged: (v) => setState(() => _sendMeACopy = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _Label('Message'),
              TextField(
                controller: _message,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.fieldBorder),
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _send,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Send'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: AppTextStyles.labelMedium),
      );
}
