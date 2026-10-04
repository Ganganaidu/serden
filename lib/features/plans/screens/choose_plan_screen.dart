import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Plan picker: a horizontal pager of plan cards (Basic · Pro · Elite) with a
/// Monthly / Annual toggle. [initialPlan] is `basic`, `pro` or `elite`.
class ChoosePlanScreen extends StatefulWidget {
  final String initialPlan;
  const ChoosePlanScreen({super.key, this.initialPlan = 'basic'});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  bool _annual = true;
  late final PageController _controller;
  late int _page;

  static const _planKeys = ['basic', 'pro', 'elite'];

  @override
  void initState() {
    super.initState();
    _page = _planKeys.indexOf(widget.initialPlan.toLowerCase());
    if (_page < 0) _page = 0;
    _controller = PageController(initialPage: _page, viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Plan> get _plans => [
        const _Plan(
          name: 'Basic',
          description: 'For pros who want to be found and try the tools.',
          price: r'$0',
          period: 'forever',
          note: 'Free forever, no credit card',
          cta: 'Join for free',
          featuresTitle: 'What you get',
          features: [
            'Free business listing in the Serden directory',
            'Business profile with photos, services and contact details',
            'Collect and reply to customer reviews',
            'Up to 3 estimates and invoices a month',
            'Unlimited clients and saved line items',
            'Post and answer questions in the pro community',
          ],
        ),
        _Plan(
          name: 'Pro',
          description:
              'For working contractors who want a steady stream of jobs.',
          price: _annual ? r'$100' : r'$9.99',
          period: _annual ? '/ year' : '/ month',
          note: _annual ? r'Save $19.88 a year — about 2 months free' : null,
          cta: 'Get Pro',
          featured: true,
          featuresTitle: 'Everything in Basic, plus',
          features: const [
            'Up to 25 estimates and invoices a month',
            'Highlighted profile in directory search results',
            'Boosted ranking so homeowners see you sooner',
            '"Request a Quote" button on your listing',
            'Lead portal to track and respond to quote requests',
          ],
        ),
        _Plan(
          name: 'Elite',
          description:
              'For teams that want maximum exposure in their market.',
          price: _annual ? r'$1,000' : r'$99',
          period: _annual ? '/ year' : '/ month',
          note: _annual ? r'Save $188 a year — about 2 months free' : null,
          cta: 'Get Elite',
          featuresTitle: 'Everything in Pro, plus',
          features: const [
            'Unlimited estimates and invoices',
            'Bold listing that stands out in every result',
            'Top placement — always shown first in the directory',
            'Priority on homeowner quote requests in your area',
          ],
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final plans = _plans;
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 16, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SERDEN',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: AppColors.green800,
                      ),
                    ),
                  ),
                  Material(
                    color: AppColors.grayTint,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () => context.pop(),
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: Icon(Icons.close,
                            size: 16, color: AppColors.inkSoft),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 10, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock the full potential of your business',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.18,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Choose the plan that fits how you work, and upgrade any time.',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 14),
              child: _BillingToggle(
                annual: _annual,
                onChanged: (v) => setState(() => _annual = v),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: plans.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    var delta = (i - _page).toDouble();
                    if (_controller.hasClients &&
                        _controller.position.haveDimensions) {
                      delta = i - (_controller.page ?? _page.toDouble());
                    }
                    final t = (1 - delta.abs()).clamp(0.0, 1.0);
                    return Transform.scale(
                      scale: 0.94 + 0.06 * t,
                      child: Opacity(opacity: 0.6 + 0.4 * t, child: child),
                    );
                  },
                  child: _PlanCard(plan: plans[i]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < plans.length; i++)
                    GestureDetector(
                      onTap: () => _controller.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _page ? 22 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? AppColors.green800
                              : AppColors.grabber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Prices shown in USD. Cancel anytime.',
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 11.5,
                  color: AppColors.inkFaint,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Plan {
  final String name;
  final String description;
  final String price;
  final String period;
  final String? note;
  final String cta;
  final String featuresTitle;
  final List<String> features;
  final bool featured;

  const _Plan({
    required this.name,
    required this.description,
    required this.price,
    required this.period,
    required this.cta,
    required this.featuresTitle,
    required this.features,
    this.note,
    this.featured = false,
  });
}

// ─── Billing toggle ──────────────────────────────────────────────────────────

class _BillingToggle extends StatelessWidget {
  final bool annual;
  final ValueChanged<bool> onChanged;

  const _BillingToggle({required this.annual, required this.onChanged});

  static const _padding = 4.0;
  static const _duration = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.grayTint,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppColors.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillW = (constraints.maxWidth - _padding * 2) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: _duration,
                curve: Curves.easeInOut,
                top: _padding,
                bottom: _padding,
                left: annual ? _padding + pillW : _padding,
                width: pillW,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.green800,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              Positioned.fill(
                child: Row(
                  children: [
                    _Segment(
                      label: 'Monthly',
                      active: !annual,
                      onTap: () => onChanged(false),
                    ),
                    _Segment(
                      label: 'Annual',
                      sub: 'about 2 months free',
                      active: annual,
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

class _Segment extends StatelessWidget {
  final String label;
  final String? sub;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.inkSoft;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: _BillingToggle._duration,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
                child: Text(label),
              ),
              if (sub != null)
                AnimatedDefaultTextStyle(
                  duration: _BillingToggle._duration,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white70 : AppColors.inkFaint,
                  ),
                  child: Text(sub!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Plan card ───────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: plan.featured ? AppColors.green800 : AppColors.line,
                  width: plan.featured ? 1.8 : 1,
                ),
                boxShadow: plan.featured
                    ? [
                        BoxShadow(
                          color: AppColors.green800.withValues(alpha: 0.12),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                child: _content(context),
              ),
            ),
          ),
          if (plan.featured)
            Positioned(
              top: -12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.green800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'MOST POPULAR',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plan.name,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.green800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          plan.description,
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14.5,
            height: 1.4,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.25),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey('${plan.price}${plan.period}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    plan.price,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: AppColors.green800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    plan.period,
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
              if (plan.note != null) ...[
                const SizedBox(height: 4),
                Text(
                  plan.note!,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green800,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green800,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: Text(plan.cta),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          plan.featuresTitle.toUpperCase(),
          style: const TextStyle(
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 12),
        for (final f in plan.features) _FeatureRow(feature: f),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;
  const _FeatureRow({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: AppColors.greenTint,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.check, size: 13, color: AppColors.green800),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              feature,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14.5,
                height: 1.35,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
