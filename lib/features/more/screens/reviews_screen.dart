import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_error_widget.dart';
import '../../../core/widgets/app_fab.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../reviews/cubit/reviews_cubit.dart';
import '../../reviews/models/review_model.dart';
import '../../reviews/screens/request_review_sheet.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen>
    with WidgetsBindingObserver {
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
  DateTime? _backgroundedAt;

  int? get _proId {
    final auth = context.read<AuthBloc>().state;
    return auth is AuthAuthenticated ? auth.user.proId : null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final proId = _proId;
    if (proId != null) context.read<ReviewsCubit>().fetch(proId);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _backgroundedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final bg = _backgroundedAt;
      _backgroundedAt = null;
      if (bg != null &&
          DateTime.now().difference(bg) > const Duration(minutes: 2)) {
        _refresh();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _responseController.dispose();
    super.dispose();
  }

  void _refresh() {
    final proId = _proId;
    if (proId != null) context.read<ReviewsCubit>().fetch(proId);
  }

  Future<void> _handleRefresh() async {
    _refresh();
    try {
      await context
          .read<ReviewsCubit>()
          .stream
          .firstWhere((s) => s is ReviewsLoaded || s is ReviewsError)
          .timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  List<Review> _filtered(List<Review> reviews) {
    final q = _search.trim().toLowerCase();
    final category =
        _categoryIndex == 0 ? null : _categories[_categoryIndex];
    return reviews
        .where((r) =>
            (category == null || r.category == category) &&
            (q.isEmpty ||
                r.text.toLowerCase().contains(q) ||
                r.reviewerName.toLowerCase().contains(q) ||
                (r.tag?.toLowerCase().contains(q) ?? false)))
        .toList();
  }

  void _openRequestSheet() {
    final proId = _proId;
    if (proId == null) return;
    final auth = context.read<AuthBloc>().state;
    final fromEmail =
        auth is AuthAuthenticated ? auth.user.email : '';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<ReviewsCubit>(),
        child: RequestReviewSheet(proId: proId, fromEmail: fromEmail),
      ),
    );
  }

  Future<void> _submitResponse(Review review, String text) async {
    final auth = context.read<AuthBloc>().state;
    final userId =
        auth is AuthAuthenticated ? auth.user.userId : 0;

    final result = await context.read<ReviewsCubit>().respond(
          reviewId: review.id,
          companyResponseText: text,
          currentUserId: userId,
        );
    if (!mounted) return;
    result.fold(
      (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(f.message),
            backgroundColor: AppColors.orangeDeep),
      ),
      (_) {
        setState(() {
          _openFormId = null;
          _responseController.clear();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReviewsCubit, ReviewsState>(
      builder: (context, state) {
        return Scaffold(
          body: Column(
            children: [
              _header(context, state),
              _controls(),
              Expanded(child: _body(context, state)),
            ],
          ),
          floatingActionButton: AppFab(
            label: 'Request reviews',
            icon: Icons.star_outline,
            onPressed: _openRequestSheet,
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, ReviewsState state) {
    final loaded = state is ReviewsLoaded ? state : null;
    final avgRating = loaded?.averageRating ?? 4.9;
    final totalCount = loaded?.totalCount ?? 0;
    final awaiting = loaded?.awaitingResponse ?? 0;
    final star5 = loaded?.star5Count ?? 0;
    final star4 = loaded?.star4Count ?? 0;
    final star3 = loaded?.star3Count ?? 0;
    final total = (star5 + star4 + star3).clamp(1, double.maxFinite).toInt();

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
          if (loaded != null)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$avgRating rating',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' · '),
                  awaiting > 0
                      ? TextSpan(
                          text: '$awaiting awaiting your response',
                          style: const TextStyle(
                            color: AppColors.overdueOnHeader,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : const TextSpan(text: 'every review answered'),
                ],
              ),
              style: AppTextStyles.headerSubtitle,
            )
          else
            Text(
              'Your client reviews',
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
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
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
                    Text(
                      '$totalCount reviews',
                      style: const TextStyle(
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
                    children: [
                      _DistRow(
                          label: '5★',
                          fraction: total > 0 ? star5 / total : 0,
                          count: star5),
                      const SizedBox(height: 5),
                      _DistRow(
                          label: '4★',
                          fraction: total > 0 ? star4 / total : 0,
                          count: star4),
                      const SizedBox(height: 5),
                      _DistRow(
                          label: '3★',
                          fraction: total > 0 ? star3 / total : 0,
                          count: star3),
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
                      color: selected ? AppColors.green800 : AppColors.line,
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
                          color: selected ? Colors.white : AppColors.inkSoft,
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

  Widget _body(BuildContext context, ReviewsState state) {
    if (state is ReviewsLoading || state is ReviewsInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is ReviewsError) {
      return AppErrorWidget(message: state.message, onRetry: _refresh);
    }

    if (state is ReviewsLoaded) {
      final filtered = _filtered(state.reviews);

      if (state.reviews.isEmpty) {
        return const EmptyState(
          title: 'No reviews yet',
          description:
              'Send review requests to your clients — they\'ll appear here once submitted.',
          icon: Icons.star_outline,
        );
      }

      if (filtered.isEmpty) {
        return const EmptyState(
          title: 'No matches',
          description: 'Try a different word or category.',
        );
      }

      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: AppColors.orange500,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
          children: [
            for (final review in filtered) _reviewCard(review),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: Text(
                'Reviews are collected from verified Serden clients and synced from Google.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption
                    .copyWith(fontSize: 11.5, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _reviewCard(Review review) {
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
              AvatarWidget(name: review.reviewerName, size: 40),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style: AppTextStyles.rowTitle
                            .copyWith(fontSize: 14.5)),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        for (var i = 0; i < review.rating; i++)
                          const Icon(Icons.star,
                              size: 12, color: AppColors.star),
                        const SizedBox(width: 7),
                        Text(review.reviewDate,
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
            style: AppTextStyles.bodySmall.copyWith(fontSize: 13.5, height: 1.6),
          ),
          if (review.tag != null) const SizedBox(height: 10),
          if (review.tag != null)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.grayTint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              review.tag!,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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
                    style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 13.5, color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText:
                          'Thank ${review.reviewerName.split(' ').first} and mention your team by name…',
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
                          _submitResponse(review, text);
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
                  side:
                      const BorderSide(color: AppColors.line, width: 1.5),
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

// ─── Star distribution row ────────────────────────────────────────────────────

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
