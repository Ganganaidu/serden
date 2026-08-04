import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/form_nav_bar.dart';
import '../../../core/widgets/loading_overlay.dart';

/// Editable "My account" form (serden-account design).
class MyAccountScreen extends StatefulWidget {
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  final _first = TextEditingController(text: 'Dennis');
  final _last = TextEditingController(text: 'Serov');
  final _email = TextEditingController(text: 'serdengroup@gmail.com');

  static const _initial = ('Dennis', 'Serov', 'serdengroup@gmail.com');

  @override
  void initState() {
    super.initState();
    for (final controller in [_first, _last, _email]) {
      controller.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _dirty =>
      _first.text != _initial.$1 ||
      _last.text != _initial.$2 ||
      _email.text != _initial.$3;

  String get _fullName =>
      '${_first.text.trim()} ${_last.text.trim()}'.trim();

  String get _initials => [_first.text, _last.text]
      .map((v) => v.trim().isEmpty ? '' : v.trim()[0])
      .join()
      .toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FormNavBar(
        title: 'My account',
        trailingLabel: 'Save',
        trailingEnabled: _dirty,
        onTrailing: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                        style:
                            AppTextStyles.rowTitle.copyWith(fontSize: 15.5),
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
                                size: 12, color: AppColors.greenDeep),
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
                _fieldBlock('Last name', _last, showDivider: false),
              ],
            ),
          ),
          const SectionHeader(title: 'Business settings'),
          AppCard(
            child: Column(
              children: [
                _pickerRow('Industry', 'General contracting'),
                _pickerRow('Currency', 'US Dollar (USD)', flag: true),
                _pickerRow('Locale', 'English (United States)',
                    showDivider: false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 0),
            child: Text(
              'Locale sets the date format, number format, and language used on your documents.',
              style: AppTextStyles.caption.copyWith(fontSize: 12, height: 1.5),
            ),
          ),
          const SectionHeader(title: 'Login information'),
          AppCard(
            child: Column(
              children: [
                _fieldBlock('Email', _email,
                    keyboardType: TextInputType.emailAddress),
                _pickerRow('Update password', '', showDivider: false),
              ],
            ),
          ),
          const SizedBox(height: 26),
          AppCard(
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                                fontSize: 14.5, color: AppColors.redDeep),
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
      {bool showDivider = true, bool flag = false}) {
    return InkWell(
      onTap: () {},
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
