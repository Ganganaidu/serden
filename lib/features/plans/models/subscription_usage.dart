import 'package:equatable/equatable.dart';

enum PlanTier {
  basic,
  pro,
  elite;

  String get label => switch (this) {
        PlanTier.basic => 'Basic',
        PlanTier.pro => 'Pro',
        PlanTier.elite => 'Elite',
      };

  /// Maps the API `tier` string ("Basic", "SerdenPro", …); unknown → basic.
  static PlanTier fromApi(String? tier) {
    final t = (tier ?? '').toLowerCase();
    if (t.contains('elite')) return PlanTier.elite;
    if (t.contains('pro')) return PlanTier.pro;
    return PlanTier.basic;
  }
}

/// `GET /api/SubscriptionUsage/user/{userId}`.
class SubscriptionUsage extends Equatable {
  final PlanTier tier;
  final String? subscriptionStatus;
  final int estimatesUsed;
  final int estimatesLimit;
  final int invoicesUsed;
  final int invoicesLimit;
  final DateTime? billingPeriodStart;
  final DateTime? billingPeriodEnd;

  const SubscriptionUsage({
    this.tier = PlanTier.basic,
    this.subscriptionStatus,
    this.estimatesUsed = 0,
    this.estimatesLimit = 0,
    this.invoicesUsed = 0,
    this.invoicesLimit = 0,
    this.billingPeriodStart,
    this.billingPeriodEnd,
  });

  factory SubscriptionUsage.fromJson(Map<String, dynamic> json) =>
      SubscriptionUsage(
        tier: PlanTier.fromApi(json['tier'] as String?),
        subscriptionStatus: json['subscriptionStatus'] as String?,
        estimatesUsed: (json['estimatesUsed'] as num?)?.toInt() ?? 0,
        estimatesLimit: (json['estimatesLimit'] as num?)?.toInt() ?? 0,
        invoicesUsed: (json['invoicesUsed'] as num?)?.toInt() ?? 0,
        invoicesLimit: (json['invoicesLimit'] as num?)?.toInt() ?? 0,
        billingPeriodStart:
            DateTime.tryParse(json['billingPeriodStart'] as String? ?? ''),
        billingPeriodEnd:
            DateTime.tryParse(json['billingPeriodEnd'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [
        tier,
        subscriptionStatus,
        estimatesUsed,
        estimatesLimit,
        invoicesUsed,
        invoicesLimit,
        billingPeriodEnd,
      ];
}
