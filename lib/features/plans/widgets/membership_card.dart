import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/subscription_usage.dart';

/// "Membership" card on the account page: plan summary, monthly usage, an
/// expandable "What's included" list, and the upgrade action.
class MembershipCard extends StatefulWidget {
  /// Null while loading.
  final PlanTier? tier;
  final SubscriptionUsage? usage;

  const MembershipCard({super.key, required this.tier, this.usage});

  @override
  State<MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends State<MembershipCard> {
  bool _expanded = false;

  static const _included = {
    PlanTier.basic: [
      'Free business listing in the Serden directory',
      'Business profile with photos, services and contact details',
      'Collect and reply to customer reviews',
      'Up to 3 estimates and invoices a month',
      'Unlimited clients and saved line items',
      'Post and answer questions in the pro community',
    ],
    PlanTier.pro: [
      'Everything in Basic',
      'Up to 25 estimates and invoices a month',
      'Highlighted profile in directory search results',
      'Boosted ranking so homeowners see you sooner',
      '"Request a Quote" button on your listing',
      'Lead portal to track and respond to quote requests',
    ],
    PlanTier.elite: [
      'Everything in Pro',
      'Unlimited estimates and invoices',
      'Bold listing that stands out in every result',
      'Top placement — always shown first in the directory',
      'Priority on homeowner quote requests in your area',
    ],
  };

  static String _tagline(PlanTier t) => switch (t) {
        PlanTier.basic =>
          'Free forever. Your company can be listed in the Serden directory at no cost.',
        PlanTier.pro =>
          'For working contractors who want a steady stream of jobs.',
        PlanTier.elite =>
          'Maximum exposure in your market, with top placement and priority leads.',
      };

  @override
  Widget build(BuildContext context) {
    final tier = widget.tier;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        padding: const EdgeInsets.all(16),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: tier == null
                ? const _Loading(key: ValueKey('loading'))
                : _body(context, tier),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PlanTier tier) {
    final usage = widget.usage;
    final paid = tier != PlanTier.basic;
    final next = switch (tier) {
      PlanTier.basic => PlanTier.pro,
      PlanTier.pro => PlanTier.elite,
      PlanTier.elite => null,
    };

    return Column(
      key: ValueKey(tier),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.greenTint,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.badge_outlined,
                  size: 20, color: AppColors.green800),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Membership', style: AppTextStyles.headingMedium),
                  SizedBox(height: 1),
                  Text('Your Serden plan and billing.',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
            _StatusPill(label: paid ? '${tier.label} plan' : 'Free plan'),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TierBadge(tier: tier),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Serden ${tier.label}',
                      style: AppTextStyles.headingMedium
                          .copyWith(fontSize: 19)),
                  const SizedBox(height: 4),
                  Text(
                    _tagline(tier),
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontSize: 13.5, height: 1.4, color: AppColors.inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (usage != null) ..._usage(usage),
        const SizedBox(height: 14),
        _includedPanel(tier),
        if (paid && usage?.billingPeriodEnd != null) ...[
          const SizedBox(height: 12),
          Text(
            'Current period ends ${_date(usage!.billingPeriodEnd!)}',
            style: AppTextStyles.caption,
          ),
        ],
        if (next != null) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.line),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context
                  .push('${AppRoutes.choosePlan}?plan=${next.name}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green800,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: const StadiumBorder(),
                textStyle: AppTextStyles.buttonText.copyWith(fontSize: 15),
              ),
              child: Text(paid ? 'Upgrade to ${next.label}' : 'Upgrade membership'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            switch (tier) {
              PlanTier.basic =>
                'Pro and Elite add a highlighted listing, boosted ranking and a Request a Quote button.',
              _ => 'Elite adds unlimited documents, top placement and priority leads.',
            },
            style: AppTextStyles.caption.copyWith(height: 1.45),
          ),
        ],
        if (paid) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => _showCancelDialog(context, tier),
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.orange500,
                  padding: EdgeInsets.zero),
              child: const Text('Cancel membership'),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _usage(SubscriptionUsage u) {
    final rows = <Widget>[
      if (u.invoicesLimit > 0)
        _UsageBar(label: 'Invoices this month', used: u.invoicesUsed, limit: u.invoicesLimit),
      if (u.estimatesLimit > 0)
        _UsageBar(label: 'Estimates this month', used: u.estimatesUsed, limit: u.estimatesLimit),
    ];
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      for (final r in rows) ...[r, const SizedBox(height: 10)],
    ];
  }

  Widget _includedPanel(PlanTier tier) {
    final items = _included[tier]!;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E9),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "WHAT'S INCLUDED IN SERDEN ${tier.label.toUpperCase()}",
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.green800,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.green800),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 280),
            sizeCurve: Curves.easeInOut,
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++)
                    TweenAnimationBuilder<double>(
                      key: ValueKey('$tier-$i-$_expanded'),
                      tween: Tween(begin: 0, end: _expanded ? 1 : 0),
                      duration: Duration(milliseconds: 250 + i * 70),
                      curve: Curves.easeOut,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                            offset: Offset(0, 8 * (1 - t)), child: child),
                      ),
                      child: _IncludedRow(text: items[i]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _date(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${m[d.month - 1]} ${d.day}, ${d.year}';
  }

  void _showCancelDialog(BuildContext context, PlanTier tier) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel membership?'),
        content: Text(
          'Your ${tier.label} access will remain active until the end of your '
          'current billing period. To proceed, please contact support@serden.com.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      );
}

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.greenTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                  color: AppColors.green800, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.green800,
              ),
            ),
          ],
        ),
      );
}

class _TierBadge extends StatelessWidget {
  final PlanTier tier;
  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final color = switch (tier) {
      PlanTier.basic => const Color(0xFF2FC58B),
      PlanTier.pro => AppColors.orange500,
      PlanTier.elite => const Color(0xFFC9A227),
    };
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.green800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'SERDEN',
            style: TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tier.label.toUpperCase(),
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.green800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final int used;
  final int limit;
  const _UsageBar({required this.label, required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final ratio = (used / limit).clamp(0.0, 1.0);
    final full = used >= limit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.caption)),
            Text('$used / $limit',
                style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: full ? AppColors.redDeep : AppColors.ink)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: AppColors.grayTint,
              color: full ? AppColors.redDeep : AppColors.green800,
            ),
          ),
        ),
      ],
    );
  }
}

class _IncludedRow extends StatelessWidget {
  final String text;
  const _IncludedRow({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: Color(0xFFE4EBE5), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 12, color: AppColors.green800),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: 14, height: 1.35, color: AppColors.ink)),
            ),
          ],
        ),
      );
}
