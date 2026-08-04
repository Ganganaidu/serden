import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum DocumentStatus {
  draft,
  sent,
  viewed,
  approved,
  declined,
  partial,
  paid,
  overdue;

  static DocumentStatus fromString(String value) =>
      DocumentStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase(),
        orElse: () => DocumentStatus.draft,
      );
}

/// Tinted pill status chip with a leading icon
/// (e.g. "Viewed 2h ago", "Paid Jan 20").
class StatusChip extends StatelessWidget {
  final DocumentStatus status;

  /// Custom label, e.g. "Viewed 2h ago". Defaults to the status name.
  final String? label;

  const StatusChip({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _style;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 4),
          Text(label ?? _defaultLabel, style: AppTextStyles.chip.copyWith(color: fg)),
        ],
      ),
    );
  }

  (Color, Color, IconData) get _style => switch (status) {
        DocumentStatus.viewed => (
            AppColors.orangeTint,
            AppColors.orangeDeep,
            Icons.visibility_outlined
          ),
        DocumentStatus.sent => (
            AppColors.grayTint,
            AppColors.grayDeep,
            Icons.send_outlined
          ),
        DocumentStatus.draft => (
            AppColors.grayTint,
            AppColors.grayDeep,
            Icons.edit_outlined
          ),
        DocumentStatus.approved => (
            AppColors.greenTint,
            AppColors.greenDeep,
            Icons.check
          ),
        DocumentStatus.declined => (
            AppColors.redTint,
            AppColors.redDeep,
            Icons.close
          ),
        DocumentStatus.partial => (
            AppColors.greenTint,
            AppColors.greenDeep,
            Icons.timelapse
          ),
        DocumentStatus.paid => (
            AppColors.greenTint,
            AppColors.greenDeep,
            Icons.check
          ),
        DocumentStatus.overdue => (
            AppColors.redTint,
            AppColors.redDeep,
            Icons.schedule
          ),
      };

  String get _defaultLabel => switch (status) {
        DocumentStatus.draft => 'Draft',
        DocumentStatus.sent => 'Sent',
        DocumentStatus.viewed => 'Viewed',
        DocumentStatus.approved => 'Approved',
        DocumentStatus.declined => 'Declined',
        DocumentStatus.partial => 'Partly paid',
        DocumentStatus.paid => 'Paid',
        DocumentStatus.overdue => 'Overdue',
      };
}

/// Legacy alias so older call sites keep working.
@Deprecated('Use StatusChip')
typedef StatusBadge = StatusChip;
