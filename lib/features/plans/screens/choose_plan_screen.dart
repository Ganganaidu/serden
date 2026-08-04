import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_text_styles.dart';

/// Plan picker (Serden Plans design). This screen intentionally uses the
/// iOS-flavored neutral palette from its mockup rather than the app header
/// chrome — it is presented as a full-screen paywall.
class ChoosePlanScreen extends StatefulWidget {
  final String initialPlan;
  const ChoosePlanScreen({super.key, this.initialPlan = 'basic'});

  @override
  State<ChoosePlanScreen> createState() => _ChoosePlanScreenState();
}

class _ChoosePlanScreenState extends State<ChoosePlanScreen> {
  static const _greenDeep = Color(0xFF0E5C45);
  static const _greenTint = Color(0xFFDFF3E8);
  static const _ink = Color(0xFF1C1C1E);
  static const _inkSoft = Color(0xFF6E6E73);

  bool _annual = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Material(
                  color: const Color(0xFFE4E4E8),
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () => context.pop(),
                    customBorder: const CircleBorder(),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child:
                          Icon(Icons.close, size: 16, color: _inkSoft),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 10, 22, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SERDEN',
                          style: TextStyle(
                            fontFamily: AppTextStyles.fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: _greenDeep,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Unlock the full potential of your business',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            height: 1.18,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Choose the plan that fits how you work, and upgrade any time.',
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.4,
                            color: _inkSoft,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 6),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0x29787880),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          _billingSegment('Monthly', !_annual,
                              () => setState(() => _annual = false)),
                          const SizedBox(width: 2),
                          _billingSegment('Annual', _annual,
                              () => setState(() => _annual = true),
                              savePill: true),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                    child: Column(
                      children: [
                        _planCard(
                          name: 'Basic',
                          price: '\$0',
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
                        const SizedBox(height: 12),
                        _planCard(
                          name: 'Pro',
                          price: _annual ? '\$100' : '\$9.99',
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
                        const SizedBox(height: 12),
                        _planCard(
                          name: 'Elite',
                          price: _annual ? '\$1,000' : '\$99',
                          period: _annual ? '/ year' : '/ month',
                          savings: _annual
                              ? 'Save 16% (\$188) paid annually'
                              : null,
                          description: 'Best for growing or enterprise teams.',
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
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 22, 4),
                    child: Text(
                      'Prices shown in USD. Cancel anytime. Annual plans billed once per year.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.5,
                        color: Color(0xFFAEAEB2),
                      ),
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

  Widget _billingSegment(String label, bool active, VoidCallback onTap,
      {bool savePill = false}) {
    return Expanded(
      child: Material(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        elevation: active ? 1 : 0,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: active ? _ink : _inkSoft,
                ),
              ),
              if (savePill) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: _greenTint,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Save 16%',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _greenDeep,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _planCard({
    required String name,
    required String price,
    required String period,
    required String? savings,
    required String description,
    required String ctaLabel,
    required bool primaryCta,
    required List<String> features,
    String? leadFeature,
    bool featured = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: featured ? _greenDeep : const Color(0xFFE5E5EA),
              width: featured ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: featured
                ? [
                    BoxShadow(
                      color: _greenDeep.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    period,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 18,
                child: savings == null
                    ? null
                    : Text(
                        savings,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _greenDeep,
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 12),
                child: Text(
                  description,
                  style:
                      TextStyle(fontSize: 13, height: 1.4, color: _inkSoft),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: primaryCta ? _greenDeep : const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        ctaLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: primaryCta ? Colors.white : _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (leadFeature != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    leadFeature,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3A3A3C),
                    ),
                  ),
                ),
              for (final feature in features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: const BoxDecoration(
                          color: _greenTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 10, color: _greenDeep),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: Color(0xFF3A3A3C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (featured)
          Positioned(
            top: -11,
            left: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _greenDeep,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text(
                'Most popular',
                style: TextStyle(
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
