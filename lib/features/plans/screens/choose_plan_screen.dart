import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class ChoosePlanScreen extends StatefulWidget {
  final String initialPlan;
  const ChoosePlanScreen({super.key, this.initialPlan = 'basic'});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  bool _annual = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Material(
                  color: const Color(0xFFE4E4E8),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => context.pop(),
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  // Header text
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SERDEN',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              color: AppColors.green800,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Unlock the full potential of your business',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              height: 1.18,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Choose the plan that fits how you work, and upgrade any time.',
                            style: TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 14.5,
                              height: 1.4,
                              color: AppColors.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Billing toggle
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                      child: _BillingToggle(
                        annual: _annual,
                        onChanged: (v) => setState(() => _annual = v),
                      ),
                    ),
                  ),
                  // Plan cards
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _PlanCard(
                          name: 'Basic',
                          price: r'$0',
                          period: _annual ? '/ year' : '/ month',
                          savings: null,
                          description: 'No credit card required.',
                          ctaLabel: 'Join for free',
                          primaryCta: false,
                          features: const [
                            'Listed in our business directory',
                            'Free basic business profile',
                            'Post in the forum',
                            'Unlimited clients',
                            'Up to 3 estimates & invoices per month',
                          ],
                        ),
                        const SizedBox(height: 14),
                        _PlanCard(
                          name: 'Pro',
                          price: _annual ? r'$100' : r'$9.99',
                          period: _annual ? '/ year' : '/ month',
                          savings: _annual
                              ? 'Save 16% (\$20) paid annually'
                              : null,
                          description:
                              'Best for professional freelancers and small teams.',
                          ctaLabel: 'Buy now',
                          primaryCta: false,
                          leadFeature: 'Everything in Basic, plus:',
                          features: const [
                            'Up to 25 estimates & invoices per month',
                            'Profile highlighted in the directory',
                            'Boosted search ranking',
                            '"Request a quote" lead button',
                            'Access to the lead portal',
                          ],
                        ),
                        const SizedBox(height: 14),
                        _PlanCard(
                          name: 'Elite',
                          price: _annual ? r'$1,000' : r'$99',
                          period: _annual ? '/ year' : '/ month',
                          savings: _annual
                              ? 'Save 16% (\$188) paid annually'
                              : null,
                          description:
                              'Best for growing or enterprise teams.',
                          ctaLabel: 'Buy now',
                          primaryCta: true,
                          featured: true,
                          leadFeature: 'Everything in Pro, plus:',
                          features: const [
                            'Unlimited estimates & invoices',
                            'Profile displayed in bold in the directory',
                            'Boosted search ranking',
                            '"Request a quote" lead button',
                            'Access to the lead portal',
                            'High visibility — always shown first',
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Prices shown in USD. Cancel anytime.\nAnnual plans billed once per year.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 11.5,
                            height: 1.6,
                            color: Color(0xFFAEAEB2),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Billing toggle ──────────────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  final bool annual;
  final ValueChanged<bool> onChanged;

  const _BillingToggle({required this.annual, required this.onChanged});

  static const _padding = 3.0;
  static const _duration = Duration(milliseconds: 260);
  static const _curve = Curves.easeInOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillW = (constraints.maxWidth - _padding * 2) / 2;
          final pillH = constraints.maxHeight - _padding * 2;
          return Stack(
            children: [
              // Sliding green pill — one element, animates position
              AnimatedPositioned(
                duration: _duration,
                curve: _curve,
                top: _padding,
                left: annual
                    ? _padding + pillW
                    : _padding,
                width: pillW,
                height: pillH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.green800,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green800.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              // Labels on top of the pill
              Positioned.fill(
                child: Row(
                  children: [
                    _SegmentLabel(
                      label: 'Monthly',
                      active: !annual,
                      duration: _duration,
                      onTap: () => onChanged(false),
                    ),
                    _SegmentLabel(
                      label: 'Annual',
                      active: annual,
                      duration: _duration,
                      onTap: () => onChanged(true),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final String label;
  final bool active;
  final Duration duration;
  final VoidCallback onTap;

  const _SegmentLabel({
    required this.label,
    required this.active,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedDefaultTextStyle(
          duration: duration,
          curve: Curves.easeInOut,
          style: TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF6E6E73),
          ),
          child: Center(child: Text(label)),
        ),
      ),
    );
  }
}

// ─── Plan card ───────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final String? savings;
  final String description;
  final String ctaLabel;
  final bool primaryCta;
  final List<String> features;
  final String? leadFeature;
  final bool featured;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    this.savings,
    required this.description,
    required this.ctaLabel,
    required this.primaryCta,
    required this.features,
    this.leadFeature,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: featured ? AppColors.green800 : const Color(0xFFE5E5EA),
              width: featured ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: featured
                ? [
                    BoxShadow(
                      color: AppColors.green800.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Plan name
              Text(
                name,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              // Price row — slides up/down on billing period change
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final slide = Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: Row(
                  key: ValueKey('$price$period'),
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      period,
                      style: const TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              // Savings badge — crossfades in/out
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SizedBox(
                  key: ValueKey(savings),
                  height: 20,
                  width: double.infinity,
                  child: savings != null
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            savings!,
                            style: const TextStyle(
                              fontFamily: AppTextStyles.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.green800,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              // Description
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 14),
                child: Text(
                  description,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    height: 1.4,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
              // CTA button
              _CtaButton(label: ctaLabel, primary: primaryCta),
              const SizedBox(height: 14),
              // Lead feature text
              if (leadFeature != null) ...[
                Text(
                  leadFeature!,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF3A3A3C),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              // Feature list
              for (final f in features) _FeatureRow(feature: f),
            ],
          ),
        ),
        // "Most popular" badge
        if (featured)
          Positioned(
            top: -12,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Most popular',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── CTA button ──────────────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final String label;
  final bool primary;

  const _CtaButton({required this.label, required this.primary});

  @override
  Widget build(BuildContext context) {
    if (primary) {
      return SizedBox(
        width: double.infinity,
        child: Material(
          color: AppColors.green800,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white12,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.green800, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 13),
          foregroundColor: AppColors.green800,
          backgroundColor: Colors.transparent,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: AppColors.green800,
          ),
        ),
      ),
    );
  }
}

// ─── Feature row ─────────────────────────────────────────────────────────────

class _FeatureRow extends StatelessWidget {
  final String feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            decoration: const BoxDecoration(
              color: AppColors.greenTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 11,
              color: AppColors.green800,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF3A3A3C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
