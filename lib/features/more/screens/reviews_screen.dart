import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_overlay.dart';

class _Review {
  final int id;
  final String name;
  final String date;
  final String category;
  final String tag;
  final String text;
  String? response;

  _Review({
    required this.id,
    required this.name,
    required this.date,
    required this.category,
    required this.tag,
    required this.text,
    this.response,
  });
}

/// Public profile reviews with rating summary and owner responses
/// (serden-reviews design).
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  // Real reviews API isn't wired up yet — show sample data only in mock
  // mode; a real logged-in user starts with none (empty state).
  final List<_Review> _reviews =
      AppConfig.useMockData ? _mockReviews() : [];

  static List<_Review> _mockReviews() => [
    _Review(
      id: 1,
      name: 'Jennifer M.',
      date: 'May 31, 2026',
      category: 'Kitchen',
      tag: 'Kitchen remodel',
      text:
          'We used Serden to remodel our kitchen. The whole experience was wonderful — Dennis was so helpful and had great suggestions to help us make design choices that fit our vision and budget. Victor and Alex did most of the work and they were fantastic.',
    ),
    _Review(
      id: 2,
      name: 'Robert T.',
      date: 'May 14, 2026',
      category: 'Addition',
      tag: 'Home addition',
      text:
          'Very professional, up front about price, great communication and extremely high quality work. Our project manager David and his assistant Alex were on top of everything since day one.',
      response:
          "Thank you, Robert! David and Alex will be glad to hear this. We're so happy with how the addition turned out.",
    ),
    _Review(
      id: 3,
      name: 'Sarah K.',
      date: 'Apr 22, 2026',
      category: 'Bathroom',
      tag: 'Bathroom remodel',
      text:
          'We had the very best bathroom remodel experience with Serden. We received a handful of bids, theirs right in the middle on price but way above the rest on detail and professionalism.',
    ),
    _Review(
      id: 4,
      name: 'Marcus P.',
      date: 'Apr 9, 2026',
      category: 'Siding',
      tag: 'Siding',
      text:
          'Leo and his crew did an amazing job on the siding. Project manager David was easy to communicate with and very pleasant to deal with — answered every question with professionalism.',
    ),
    _Review(
      id: 5,
      name: 'Amanda C.',
      date: 'Mar 18, 2026',
      category: 'Kitchen',
      tag: 'Kitchen remodel',
      text:
          'From the very start, our designer Jasmine listened to our ideas and executed a more beautiful design than we had imagined. Andrew, Jacob, Alex, and Tim were extremely professional and our job site was always clean and tidy.',
    ),
  ];

  static const _categories = [
    'All reviews',
    'Kitchen',
    'Bathroom',
    'Siding',
    'Addition',
  ];

  String _search = '';
  int _categoryIndex = 0;
  int? _openFormId;
  final _responseController = TextEditingController();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  int get _awaiting => _reviews.where((r) => r.response == null).length;

  List<_Review> get _filtered {
    final q = _search.trim().toLowerCase();
    final category =
        _categoryIndex == 0 ? null : _categories[_categoryIndex];
    return _reviews
        .where((r) =>
            (category == null || r.category == category) &&
            (q.isEmpty ||
                r.text.toLowerCase().contains(q) ||
                r.name.toLowerCase().contains(q) ||
                r.tag.toLowerCase().contains(q)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _header(context),
          _controls(),
          Expanded(child: _list()),
        ],
      ),
      floatingActionButton: AppFab(
        label: 'Request reviews',
        icon: Icons.star_outline,
        onPressed: () {},
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Container(
      color: AppColors.green800,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 6,
        left: 20,
        right: 20,
        bottom: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.arrow_back_ios_new,
                      size: 14, color: Color(0xCCFFFFFF)),
                  SizedBox(width: 4),
                  Text(
                    'More',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xCCFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Reviews', style: AppTextStyles.headerTitle),
          const SizedBox(height: 3),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '4.9 rating',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' · '),
                _awaiting > 0
                    ? TextSpan(
                        text: '$_awaiting awaiting your response',
                        style: const TextStyle(
                          color: AppColors.overdueOnHeader,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : const TextSpan(text: 'every review answered'),
              ],
            ),
            style: AppTextStyles.headerSubtitle,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Column(
                  children: [
                    const Text(
                      '4.9',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: Colors.white,
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          const Icon(Icons.star,
                              size: 13, color: AppColors.star),
                      ],
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      '153 reviews',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xA6FFFFFF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: const [
                      _DistRow(label: '5★', fraction: 0.93, count: 142),
                      SizedBox(height: 5),
                      _DistRow(label: '4★', fraction: 0.06, count: 9),
                      SizedBox(height: 5),
                      _DistRow(label: '3★', fraction: 0.01, count: 2),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _search = v),
            style: AppTextStyles.bodyMedium.copyWith(height: 1.2),
            decoration: InputDecoration(
              hintText: 'Search reviews',
              prefixIcon: const Icon(Icons.search,
                  size: 17, color: AppColors.inkFaint),
              isDense: true,
              filled: true,
              fillColor: AppColors.page,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
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
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final selected = index == _categoryIndex;
                return Material(
                  color: selected ? AppColors.green800 : AppColors.page,
                  shape: StadiumBorder(
                    side: BorderSide(
                      color:
                          selected ? AppColors.green800 : AppColors.line,
                    ),
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _categoryIndex = index),
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : AppColors.inkSoft,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _list() {
    final rows = _filtered;
    if (rows.isEmpty) {
      return const EmptyState(
        title: 'No matches',
        description: 'Try a different word or category.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        for (final review in rows) _reviewCard(review),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: Text(
            'Reviews are collected from verified Serden clients and synced from Google.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(fontSize: 11.5, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(_Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(name: review.name, size: 40),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name,
                        style:
                            AppTextStyles.rowTitle.copyWith(fontSize: 14.5)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        for (var i = 0; i < 5; i++)
                          const Icon(Icons.star,
                              size: 12, color: AppColors.star),
                        const SizedBox(width: 7),
                        Text(review.date,
                            style: AppTextStyles.caption.copyWith(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenTint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.verified_user_outlined,
                        size: 11, color: AppColors.greenDeep),
                    SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenDeep,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            review.text,
            style: AppTextStyles.bodySmall
                .copyWith(fontSize: 13.5, height: 1.6),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.grayTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              review.tag,
              style: const TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          if (review.response != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 13, vertical: 11),
              decoration: const BoxDecoration(
                color: AppColors.greenTint,
                border: Border(
                  left: BorderSide(color: AppColors.greenDeep, width: 3),
                ),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RESPONSE FROM SERDEN GROUP',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.greenDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.response!,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 12.5, height: 1.55),
                  ),
                ],
              ),
            )
          else if (_openFormId == review.id)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _responseController,
                    maxLines: 3,
                    autofocus: true,
                    style: AppTextStyles.bodySmall
                        .copyWith(fontSize: 13.5, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText:
                          'Thank ${review.name.split(' ').first} and mention your team by name…',
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.page,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(
                            color: AppColors.line, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(11),
                        borderSide: const BorderSide(
                            color: AppColors.greenDeep, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            setState(() => _openFormId = null),
                        style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkSoft),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final text = _responseController.text.trim();
                          if (text.isEmpty) return;
                          setState(() {
                            review.response = text;
                            _openFormId = null;
                            _responseController.clear();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          textStyle: AppTextStyles.buttonText
                              .copyWith(fontSize: 13),
                        ),
                        child: const Text('Post response'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _openFormId = review.id;
                    _responseController.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  side: const BorderSide(color: AppColors.line, width: 1.5),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline, size: 13),
                label: const Text('Respond'),
              ),
            ),
        ],
      ),
    );
  }
}

class _DistRow extends StatelessWidget {
  final String label;
  final double fraction;
  final int count;

  const _DistRow({
    required this.label,
    required this.fraction,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 20,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xBFFFFFFF),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              color: AppColors.star,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 28,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: AppTextStyles.fontFamily,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0x99FFFFFF),
            ),
          ),
        ),
      ],
    );
  }
}
