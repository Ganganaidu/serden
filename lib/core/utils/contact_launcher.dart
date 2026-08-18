import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class ContactLauncher {
  static Future<void> call(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _show(context, 'No phone number on file');
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (!await launchUrl(uri)) {
      if (context.mounted) _show(context, 'Could not open phone dialer');
    }
  }

  static Future<void> text(BuildContext context, String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _show(context, 'No phone number on file');
      return;
    }
    final uri = Uri(scheme: 'sms', path: phone.trim());
    if (!await launchUrl(uri)) {
      if (context.mounted) _show(context, 'Could not open messages');
    }
  }

  static Future<void> email(BuildContext context, String? emailAddress) async {
    if (emailAddress == null || emailAddress.trim().isEmpty) {
      _show(context, 'No email address on file');
      return;
    }
    final uri = Uri(scheme: 'mailto', path: emailAddress.trim());
    if (!await launchUrl(uri)) {
      if (context.mounted) _show(context, 'Could not open email app');
    }
  }

  static void _show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
